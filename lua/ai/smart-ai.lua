-- This is the Smart AI, and it should be loaded and run at the server side

-- "middleclass" is the Lua OOP library written by kikito
-- more information see: https://github.com/kikito/middleclass
require "middleclass"

-- initialize the random seed for later use
math.randomseed(os.time())

sgs.ai_renegade_threshold = 0.3
-- compare functions
sgs.ai_compare_funcs = {
	hp = function(a, b)
		return a:getHp() < b:getHp()
	end,

	maxhp = function(a, b)
		return a:getMaxHP() < b:getMaxHP()
	end,

	handcard = function(a, b)
		return a:getHandcardNum() < b:getHandcardNum()
	end,

	value = function(a, b)
		return SmartAI.GetValue(a) < SmartAI.GetValue(b)
	end,

	chaofeng = function(a, b)
		local c1 = sgs.ai_chaofeng[a:getGeneralName()]	or 0
		local c2 = sgs.ai_chaofeng[b:getGeneralName()] or 0

		if c1 == c2 then
			return sgs.ai_compare_funcs.value(a, b)
		else
			return c1 > c2
		end
	end,

	defense = function(a,b)
		return SmartAI.GetDefense(a) < SmartAI.GetDefense(b)
	end,

	threat = function ( a, b)
		local players = sgs.QList2Table(a:getRoom():getOtherPlayers(a))
		local d1 = a:getHandcardNum()
		for _, player in ipairs(players) do
			if a:canSlash(player,true) then
				d1 = d1+10/(getDefense(player))
			end
		end
		players = sgs.QList2Table(b:getRoom():getOtherPlayers(b))
		local d2 = b:getHandcardNum()
		for _, player in ipairs(players) do
			if b:canSlash(player,true) then
				d2 = d2+10/(getDefense(player))
			end
		end

		local c1 = sgs.ai_chaofeng[a:getGeneralName()]	or 0
		local c2 = sgs.ai_chaofeng[b:getGeneralName()] or 0

		return d1+c1/2 > d2+c2/2
	end,
}

--- this function is only function that exposed to the host program
--- and it clones an AI instance by general name
-- @param player The ServerPlayer object that want to create the AI object
-- @return The AI object
function CloneAI(player)
	return SmartAI(player).lua_ai
end

--- FIXME: ?
function getCount(name)
	if sgs.ai_round[name] then
		sgs.ai_round[name] = sgs.ai_round[name]+1
	else
		sgs.ai_round[name] = 1
	end
		return sgs.ai_round[name]
end

-- SmartAI is the base class for all other specialized AI classes
SmartAI = class "SmartAI"
super = SmartAI

--- Calculate the value for a player, 1 hp = 2 handcard
-- @param player The ServerPlayer object
-- @return Its value
function SmartAI.GetValue(player)
	return player:getHp() * 2 + player:getHandcardNum()
end

function SmartAI.GetDefense(player)
	local defense = math.min(SmartAI.GetValue(player), player:getHp() * 3)
	if player:getArmor() and not player:getArmor():inherits("GaleShell") then
		defense = defense + 2
	end
	if not player:getArmor() and player:hasSkill("yuanyin") then
		defense = defense + 2
	end
	local m = sgs.masochism_skill:split("|")
	for _, masochism in ipairs(m) do
		if player:hasSkill(masochism) then
			defense = defense + 1
		end
	end
	if player:getArmor() and player:getArmor():inherits("EightDiagram") and player:hasSkill("yueli") then
		defense = defense + 0.3
	end
	if player:hasSkill("baoguo") then
		defense = defense + 1
	end
	if player:hasSkill("qiaojiang") and player:getHandcardNum()>1 then
		defense = defense + 0.5
	end
	if player:hasSkill("shunshui") then
		defense = defense + 0.3
	end
	return defense
end

getDefense = SmartAI.GetDefense

-- the "initialize" function is just the "constructor"
function SmartAI:initialize(player)
	self.player = player
	self.room = player:getRoom()

	self.role  = player:getRole()

	if self.role ~= "lord" then sgs.ai_assumed[self.role] = (sgs.ai_assumed[self.role] or 0) + 1 end
	-- self.room:writeToConsole(self.player:getSeat() .. " " .. self:getHegGeneralName() .. " " .. self:getHegKingdom())
	self.lua_ai = sgs.LuaAI(player)
	self.lua_ai.callback = function(method_name, ...)
		local method = self[method_name]
		if method then
			local success, result1, result2
			success, result1, result2 = pcall(method, self, ...)
			if not success then
				self.room:writeToConsole(result1)
				self.room:writeToConsole(method_name)
				self.room:writeToConsole(debug.traceback())
				self.room:writeToConsole("Event stack:")
				self.room:outputEventStack()
				self.room:writeToConsole("End of Event Stack")
			else
				return result1, result2
			end
		end
	end

	self.retain = 2
	--self.harsh_retain = true
	if not sgs.ai_loyalty[self.player:objectName()] then
		--self.room:output("initialized"..self.player:objectName()..self.role)
		sgs.ai_loyalty[self.player:objectName()] = 0
	end
	if self.player:isLord() then
		sgs.ai_loyalty[self.player:objectName()] = 160
		sgs.ai_explicit[self.player:objectName()] = "loyalist"
		if (sgs.ai_chaofeng[self.player:getGeneralName()] or 0) < 3 then
			sgs.ai_chaofeng[self.player:getGeneralName()] = 3
		end
	end

	self.keepValue = {}
	self.kept = {}
end

sgs.ai_assumed = {}

function SmartAI:printStand()
	self.room:output(self.player:getRole())
	self.room:output("enemies:")
	for _, player in ipairs(self.enemies) do
		self.room:output(player:getGeneralName())
	end
	self.room:output("end of enemies")
	self.room:output("friends:")
	for _, player in ipairs(self.friends) do
		self.room:output(player:getGeneralName())
	end
	self.room:output("end of friends")
end

function isRolePredictable()
	return useDefaultStrategy() or sgs.GetConfig("RolePredictable", true)
end

function useDefaultStrategy()
	local mode = sgs.GetConfig("GameMode", "")
	if (mode == "06_3v3") or (not mode:find("0")) then return true end
	if mode:find("02_1v1") or mode:find("03p") or mode:find("04_1v3") then return true end
end

-- this function create 2 tables contains the friends and enemies, respectively
function SmartAI:updatePlayers(inclusive)
	self.friends = sgs.QList2Table(self.lua_ai:getFriends())
	table.insert(self.friends, self.player)

	self.friends_noself = sgs.QList2Table(self.lua_ai:getFriends())
	self.enemies = sgs.QList2Table(self.lua_ai:getEnemies())

	sgs.zhangshisource = nil

	-- if self.player:isLord() then self:printFEList() end
	if isRolePredictable() then
		if (self.role == "lord") or (self.role == "loyalist") then self:refreshLoyalty(self.player,300)
		elseif (self.role == "rebel") then self:refreshLoyalty(self.player,-300)
		end

		self.retain = 2
		self.harsh_retain = false

		if useDefaultStrategy() then return end
	end

	inclusive = inclusive or true

	local flist = {}
	local elist = {}
	self.enemies = elist
	self.friends = flist


	local lord = self.room:getLord()
	local role = self.role
	self.retain = 2
	self.harsh_retain = true

	local players = self.room:getOtherPlayers(self.player)
	players = sgs.QList2Table(players)

	for _,player in ipairs(players) do
		if #players == 1 then break end
		if self:objectiveLevel(player) < 0 then table.insert(flist,player) end
	end

	self.friends_noself = {}

	for _, player in ipairs (flist) do
		table.insert(self.friends_noself,player)
	end
	table.insert(self.friends,self.player)

	if self.role == "rebel" then
		sgs.rebel_target = self.room:getLord()
		self.retain = 2
	end

	if self.player:getHp() < 2 then self.retain = 0 end
	self:sortEnemies(players)
	for _,player in ipairs(players) do
		if self:objectiveLevel(player) >= 4 then self.harsh_retain = false end
		if #elist == 0 then
			table.insert(elist,player)
			if self:objectiveLevel(player) < 4 then self.retain = 0 end
		else
			if self:objectiveLevel(player) <= 0 then return end
			table.insert(elist,player)

			if self:objectiveLevel(player) >= 4 then self.harsh_retain = false end
		end
	end
end

function SmartAI:printFEList()
	for _, player in ipairs (self.enemies) do
		self.room:writeToConsole("enemy "..player:getGeneralName()..(sgs.ai_explicit[player:objectName()] or "") .. player:getRole())
	end

	for _, player in ipairs (self.friends_noself) do
		self.room:writeToConsole("friend "..player:getGeneralName()..(sgs.ai_explicit[player:objectName()] or "") .. player:getRole())
	end

	self.room:writeToConsole(self.player:getGeneralName().." list end")
end

local function getGameProcessValues(self, players)
	local rebel_num, loyalish_num, loyal_num, renegade_num = 0, 0, 0, 0
	for _, aplayer in ipairs (players) do
		if aplayer:getRole() == "rebel" then
			rebel_num = rebel_num + 1
		elseif aplayer:getRole() == "loyal" then
			loyal_num = loyal_num + 1
		elseif aplayer:getRole() == "renegade" then
			renegade_num = renegade_num + 1
		end
	end
	local ambig_num, loyal_value, rebel_value = 0, 0, 0
	for _, aplayer in ipairs(players) do
		if (not isRolePredictable() and (sgs.ai_explicit[aplayer:objectName()] or ""):match("rebel"))
			or (isRolePredictable() and aplayer:getRole() == "rebel") then
			local rebel_hp
			if aplayer:hasSkill("beizhan") and aplayer:getHp() > 4 then rebel_hp = 4
			else rebel_hp = aplayer:getHp() end
			if aplayer:getMaxHP() == 3 then rebel_value = rebel_value + 0.5 end
			rebel_value = rebel_value + rebel_hp + math.max(self.GetDefense(aplayer) - rebel_hp * 2, 0) * 0.7
			if aplayer:getWeapon() and aplayer:getWeapon():className() ~= "Weapon" then
				rebel_value = rebel_value + math.min(1.5, math.min(sgs.weapon_range[aplayer:getWeapon():className()],self.room:alivePlayerCount()/2)/2) * 0.4
			end
			if aplayer:inMyAttackRange(self.room:getLord()) and rebel_num > 1 then
				rebel_value = rebel_value + 0.2
				if aplayer:getWeapon() and self:canPaoxiao(aplayer) then
					rebel_value = rebel_value + 0.4
				end
			end
		elseif (not isRolePredictable() and (sgs.ai_explicit[aplayer:objectName()] or ""):match("loyal")) 
			or (isRolePredictable() and aplayer:getRole() == "loyalist") or aplayer:isLord() then
			local loyal_hp
			local modifier = 1
			if aplayer:isLord() then
				if rebel_num ==1 then modifier = 1.5 else modifier = rebel_num + 1 end
			end
			if aplayer:hasSkill("benghuai") and aplayer:getHp() > 4 then loyal_hp = 4
			else loyal_hp = aplayer:getHp() end
			if aplayer:getMaxHP() == 3 then loyal_value = loyal_value + 0.5 end
			loyal_value = loyal_value + (loyal_hp + math.max(self.GetDefense(aplayer) - loyal_hp * 2, 0) * 0.7)/modifier
			if aplayer:getWeapon() and aplayer:getWeapon():className() ~= "Weapon" then
				loyal_value = loyal_value + math.min(1.5, sgs.weapon_range[aplayer:getWeapon():className()]/2) * 0.4/modifier
			end
		elseif (not aplayer:isLord() and not isRolePredictable()) then
			ambig_num = ambig_num + 1
		end
	end
	return ambig_num, loyal_value, rebel_value
end

function SmartAI:objectiveLevel(player)

	if player:objectName() == self.player:objectName() then return -2 end

	local modifier = 0
	local rene = sgs.ai_renegade_suspect[player:objectName()] or 0
	if rene > 1 then modifier = 0.5 end

	local players = self.room:getOtherPlayers(self.player)
	players = sgs.QList2Table(players)

	if #players == 1 then return 5 end

	local rebel_num, loyalish_num, loyal_num, renegade_num = 0, 0, 0, 0
	for _, aplayer in ipairs (players) do
		if aplayer:getRole() == "rebel" then
			rebel_num = rebel_num + 1
		elseif aplayer:getRole() == "loyal" then
			loyal_num = loyal_num + 1
		elseif aplayer:getRole() == "renegade" then
			renegade_num = renegade_num + 1
		end
	end

	if isRolePredictable() then
		if self.role == "renegade" then
			local _, loyal_value, rebel_value = getGameProcessValues(self, players)
			if (math.abs(loyal_value-rebel_value) < sgs.ai_renegade_threshold and loyal_value > 8) or (self:isWeak() and #self.enemies > 1) then return 0 end
			if loyal_value <= rebel_value then
				if (sgs.ai_explicit[player:objectName()] or "") == "rebel" then return 5
				else return -1 end
			else
				if (sgs.ai_explicit[player:objectName()] or "") == "rebel" then return -3
				else
					if player:isLord() then
						if rebel_num > 0 then return 3 else return 5 end
					else
						return 5
					end
				end
			end
		elseif player:getRole() == "renegade" then
			local _, loyal_value, rebel_value = getGameProcessValues(self, players)
			if self.role == (sgs.ai_explicit[player:objectName()] or "") or
				(self.player:isLord() and (sgs.ai_explicit[player:objectName()] or "") == "loyalist") then
					if rebel_num == 0 then return 5 else return -1 end
			elseif (sgs.ai_explicit[player:objectName()] or "") == "loyalist" then
				if rebel_value < loyal_value then return 4 else return 2 end
			elseif not sgs.ai_explicit[player:objectName()] then return 0
			else return 4 end
		elseif self:isFriend(player) then return -2
		else return 5
		end
	end
	loyalish_num = loyal_num + renegade_num

	if self.role == "lord" then
		if rebel_num == 0 then
			local comp_func = function(a, b)
				local aname = a:objectName()
				local bname = b:objectName()
				if (sgs.ai_anti_lord[aname] or 0)~=(sgs.ai_anti_lord[bname] or 0) then
					return (sgs.ai_anti_lord[aname] or 0) > (sgs.ai_anti_lord[bname] or 0)
				else
					return (sgs.ai_renegade_suspect[aname] or 0) > (sgs.ai_renegade_suspect[bname] or 0)
				end
			end
			table.sort(players, comp_func)
			if (sgs.ai_anti_lord[player:objectName()] or 0) > 0 or (sgs.ai_renegade_suspect[player:objectName()]  or 0) > 2 then
				if player:objectName() == players[1]:objectName() or (renegade_num == 2 and player:objectName() == players[2]:objectName())
					then return 5 else return -2 end
			elseif self:isWeak(player) then
				return -1
			else
				return 0
			end
		end

		if sgs.ai_explicit[player:objectName()] == "rebel" then return 5-modifier
		elseif sgs.ai_explicit[player:objectName()] == "rebelish" then return 5-modifier
		elseif sgs.ai_explicit[player:objectName()] == "loyalist" then return -2
		elseif sgs.ai_explicit[player:objectName()] == "loyalish" then return -1
		elseif (self:singleRole()) == "rebel" then return 4.6-modifier
		elseif (self:singleRole()) == "loyalist" then return -1
		elseif (sgs.ai_loyalty[player:objectName()] < 0) and
			(sgs.ai_card_intention["general"](player,100) > 0)
			then return 3
		else return 0 end
	elseif self.role == "loyalist" then
		if player:isLord() then return -2
		elseif #players == 2 then return 5
		elseif renegade_num == 0 and loyal_num == 1 then return 5
		elseif rebel_num == 0 and 
			((sgs.ai_anti_lord[player:objectName()] or 0) > 0 or (sgs.ai_renegade_suspect[player:objectName()]  or 0) > 2) then return 5
		elseif (sgs.ai_explicit[player:objectName()] or ""):match("rebel") then return 5-modifier
		elseif (sgs.ai_explicit[player:objectName()] or ""):match("loyal") then return -1
		elseif (self:singleRole()) == "rebel" then return 4-modifier
		elseif (self:singleRole()) == "loyalist" then return -1
		elseif (sgs.ai_loyalty[player:objectName()] < 0) and
			(sgs.ai_card_intention["general"](player,100) > 0)
			then return 3.1
		else return 0 end
	elseif self.role == "rebel" then
		if player:isLord() then return 5
		elseif (sgs.ai_explicit[player:objectName()] or ""):match("loyal") then return 5-modifier
		elseif (sgs.ai_explicit[player:objectName()] or ""):match("rebel") then return -1
		elseif (self:singleRole()) == "rebel" then return -1
		elseif (self:singleRole()) == "loyalist" then return 4-modifier
		elseif (sgs.ai_loyalty[player:objectName()] > 0) and
			(sgs.ai_card_intention["general"](player,100) < 0)
			then return 3
		else return 0 end
	elseif self.role == "renegade" then
		if SmartAI.GetValue(self.room:getLord()) < 6 and rebel_num > 0 then
			if sgs.ai_loyalty[player:objectName()] < 0 then return 5
			elseif player:isLord() then return -3 end
		end
		if rebel_num == 0 then
			if player:isLord() and self:isWeak(player) then return -1 end
			return 5
		end
		local ambig_num, loyal_value, rebel_value = getGameProcessValues(self, players)
		if ambig_num > renegade_num then return -1 end
		if (math.abs(loyal_value-rebel_value) < sgs.ai_renegade_threshold and loyal_value > 8) or (self:isWeak() and #self.enemies > 1) then return 0 end
		if loyal_value <= rebel_value then
			if sgs.ai_loyalty[player:objectName()] < 0 then return 5
			else return -1 end
		else
			if sgs.ai_loyalty[player:objectName()] < 0 or (sgs.ai_explicit[player:objectName()] or ""):match("rebel") then return -3
			else
				if player:isLord() then
					if rebel_num > 0 then return 3 else return 5 end
				else
					return 5
				end
			end
		end
	end
	return 1
end

function SmartAI:sortEnemies(players)
	local comp_func = function(a,b)
		local alevel = self:objectiveLevel(a)
		local blevel = self:objectiveLevel(b)

		if alevel~= blevel then return alevel > blevel end
		if alevel == 3 then return getDefense(a) > getDefense(b) end

		alevel = sgs.ai_chaofeng[a:getGeneralName()] or 0
		blevel = sgs.ai_chaofeng[b:getGeneralName()] or 0
		if alevel~= blevel then
			return alevel > blevel
		end

		alevel = getDefense(a)
		blevel = getDefense(b)
		if alevel~= blevel then
			return alevel < blevel
		end
	end
	table.sort(players,comp_func)
end

function SmartAI:hasWizard(players,onlyharm)
	local skill
	if onlyharm then skill = sgs.wizard_harm_skill else skill = sgs.wizard_skill end
	for _, player in ipairs(players) do
		if self:hasSkills(skill, player) then
			return true
		end
	end
end

function SmartAI:sort(players, key)
	local func =  sgs.ai_compare_funcs[key or "chaofeng"]
	table.sort(players, func)
end

function SmartAI:filterEvent(event, player, data)
	sgs.lastevent = event
	if event==sgs.ChoiceMade then
		local carduse=data:toCardUse()
		if carduse and carduse:isValid() then
			if carduse.card:inherits("ZhangshiCard") then
				sgs.zhangshisource = player
			else
				sgs.zhangshisource = nil
			end
		elseif data:toString() then
			promptlist = data:toString():split(":")
			if promptlist[1] == "cardResponsed" then
				if promptlist[3] == "@zhangshi" and promptlist[5] ~= "_nil_" then
					local intention = sgs.ai_card_intention["general"](sgs.zhangshisource, -40)
					self:refreshLoyalty(player, intention)
					sgs.zhangshisource = nil
				end
			elseif promptlist[1] == "skillInvoke" and promptlist[3] == "yes" then
				if promptlist[2] == "zhangshi" then
					sgs.zhangshisource = player
				end
			end
		end
	elseif event == sgs.CardUsed then
		self:updatePlayers()
	elseif event == sgs.CardEffect then
		self:updatePlayers()
	elseif event == sgs.Death then
		self:updatePlayers()

		if self == sgs.recorder then
			speakTrigger(nil,player,nil,"death")
			local selfexp = sgs.ai_explicit[player:objectName()]
			if selfexp then
				if selfexp == "loyalish" then selfexp = "loyalist"
				elseif selfexp == "rebelish" then selfexp = "rebel"
				end
				sgs.ai_explicit[player:objectName()] = nil
				sgs.ai_assumed[selfexp] = (sgs.ai_assumed[selfexp] or 0)+1
			end
			sgs.ai_assumed[player:getRole()] = (sgs.ai_assumed[player:getRole()] or 0)-1
		end
	end

	if (event == sgs.PhaseChange) or (event == sgs.GameStart) then
		self:updatePlayers()
		if self.player:isLord() and player:isLord() and (player:getPhase() == sgs.Player_Play or event == sgs.GameStart) then
			--self:printFEList()
		end
	end

	if not sgs.recorder then
		sgs.recorder = self
	end

	if self ~= sgs.recorder then return end
	
	if event == sgs.CardEffect then
		local struct = data:toCardEffect()
		local card = struct.card
		local from = struct.from
		local to = struct.to
		if card:inherits("Collateral") then sgs.ai_collateral = true end
		if card:inherits("Dismantlment") or card:inherits("Snatch") or card:getSkillName() == "shentou" then
			sgs.ai_snat_disma_effect = true
			sgs.ai_snat_dism_from = struct.from
		end
		if card:inherits("Slash") and to:hasSkill("leiji") and 
			(getCardsNum("Jink", to)>0 or (to:getArmor() and to:getArmor():objectName() == "eight_diagram"))
			and (to:getHandcardNum()>2 or from:getState() == "robot") then
			sgs.ai_leiji_effect = true
		end
	end
	if event == sgs.Damaged then
		local damage = data:toDamage()
		local card = damage.card
		local from = damage.from
		local to   = damage.to
		local source = self.room:getCurrent()
		
		if not damage.card then
			local intention
			intention = sgs.ai_card_intention.general(to, 100)
			
			if from then
				if from:objectName() == to:objectName() then intention = 0 end
				self:refreshLoyalty(from, intention)
				if to:isLord() and intention < 0 then
					sgs.ai_anti_lord[from:objectName()] = (sgs.ai_anti_lord[from:objectName()] or 0)+1
				end
			end
		end
	elseif event == sgs.CardUsed then
		local struct = data:toCardUse()
		local card = struct.card
		local to = struct.to
		to = sgs.QList2Table(to)
		local from  = struct.from
		local source =  self.room:getCurrent()

		if card:inherits("LijianCard") then
			if self:isFriend(to[1], to[2]) then
				self:refreshLoyalty(from, sgs.ai_card_intention["general"](to[1], 80))
				--self.room:writeToConsole("LijianCard:diaochan->" .. to[1]:getGeneralName() .. "+" .. to[2]:getGeneralName())
				if to[1]:isLord() or to[2]:isLord() then
					sgs.ai_anti_lord[from:objectName()] = (sgs.ai_anti_lord[from:objectName()] or 0) + 1
				end
			end
		else
			for _, eachTo in ipairs(to) do
				local use_intention = sgs.ai_card_intention[card:className()]
				if use_intention and from:objectName()~=eachTo:objectName() then
					local different = true
					if self:isFriend(from, eachTo) then different = false end
					local intention = use_intention(card,from,eachTo,source,different) or use_intention(card,from,eachTo,source)
					--self.room:writeToConsole(card:className() .. ":" .. from:getGeneralName() .. "->" .. eachTo:getGeneralName())
					self:refreshLoyalty(from,intention)

					if eachTo:isLord() and intention < 0 then
						sgs.ai_anti_lord[from:objectName()] = (sgs.ai_anti_lord[from:objectName()] or 0)+1
					end
				end
				self.room:output(eachTo:objectName())
			end
		end
	elseif event == sgs.CardLost then
		local move = data:toCardMove()
		local from = move.from
		local to =   move.to
		local place = move.from_place
		local card = sgs.Sanguosha:getCard(move.card_id)
		if sgs.ai_snat_disma_effect then
			sgs.ai_snat_disma_effect = false
			local intention = sgs.ai_card_intention.general(from,70)
			if place == sgs.Player_Judging then
				if not card:inherits("Lightning") and not card:inherits("Disaster") then intention = -intention else intention = 0 end
			elseif place == sgs.Player_Equip then
				if player:getLostHp() > 1 and card:inherits("SilverLion") then intention = -intention end
				if self:hasSkills(sgs.lose_equip_skill, player) then intention = 0 end
			end
			if from:isLord() and intention < 0 then
				sgs.ai_anti_lord[sgs.ai_snat_dism_from:objectName()] = (sgs.ai_anti_lord[sgs.ai_snat_dism_from:objectName()] or 0)+1
			end
			self:refreshLoyalty(sgs.ai_snat_dism_from,intention)
		end
	elseif event == sgs.StartJudge then
		local judge = data:toJudge()
		local reason = judge.reason
		if reason == "beige" then
			local caiwenji = self.room:findPlayerBySkillName("beige")
			local intention = sgs.ai_card_intention.general(player, -60)
			if player:objectName() == caiwenji:objectName() then intention = 0 end
			self:refreshLoyalty(caiwenji, intention)
		end
	end
end

function SmartAI:getFriendsNoself(player)
	if self:isFriend(self.player, player) then
		return self.friends_noself
	elseif self:isEnemy(self.player, player) then
		friends = sgs.QList2Table(self.lua_ai:getEnemies())
		for i = #friends, 1, -1 do
			if friends[i]:objectName() == player:objectName() then
				table.remove(friends, i)
			end
		end
		return friends
	else
		return {}
	end
end

function SmartAI:getFriends(player)
	if self:isFriend(self.player, player) then
		return self.friends
	elseif self:isEnemy(self.player, player) then
		return self.enemies
	else
		return {player}
	end
end

function SmartAI:getEnemies(player)
	if self:isFriend(self.player, player) then
		return self.enemies
	elseif self:isEnemy(self.player, player) then
		return self.friends
	else
		return {}
	end
end

function SmartAI:isFriend(other, another)
	if another then return self:isFriend(other)==self:isFriend(another) end
	if isRolePredictable() then return self.lua_ai:isFriend(other) end
	if self.player:objectName() == other:objectName() then return true end
	if self:objectiveLevel(other) < 0 then return true end
	return false
end

function SmartAI:isEnemy(other, another)
	if another then return self:isFriend(other)~=self:isFriend(another) end
	if isRolePredictable() then return self.lua_ai:isEnemy(other) end
	if self.player:objectName() == other:objectName() then return false end
	if self:objectiveLevel(other) >= 0 then return true end
	return false
end

function SmartAI:isNeutrality(other)
	return self.lua_ai:relationTo(other) == sgs.AI_Neutrality
end

-- get the card with the maximal card point
function SmartAI:getMaxCard(player)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	local cards = player:getHandcards()
	local max_card, max_point = nil, 0
	for _, card in sgs.qlist(cards) do
		local point = card:getNumber()
		if point > max_point then
			max_point = point
			max_card = card
		end
	end

	return max_card
end

-- the table that stores whether the skill should be invoked
-- used for SmartAI:askForSkillInvoke
sgs.ai_skill_invoke = {
	eight_diagram = function(self, data)
		if self.player:hasSkill("yueli") then return true end
		if self:getDamagedEffects(self) then return false end
		return true
	end,

	double_sword = true,
	fan = true,

	kylin_bow = function(self, data)
		local effect = data:toSlashEffect()

		if self:hasSkills(sgs.lose_equip_skill, effect.to) then
			return self:isFriend(effect.to)
		end

		return self:isEnemy(effect.to)
	end,

	double_whip = function(self, data)
		local carduse = data:toCardUse()
		local tos = sgs.QList2Table(carduse.to)
		local mengkang = self.room:findPlayerBySkillName("mengchong")
		local mk = mengkang and self:isFriend(mengkang)
		for _, target in ipairs(tos) do
			if target:isChained() then
				return self:isFriend(target) and not mk
			else
				return self:isEnemy(target) and not mk
			end
			break
		end
	end,
}

function SmartAI:askForSkillInvoke(skill_name, data)
	local invoke = sgs.ai_skill_invoke[skill_name]
	if type(invoke) == "boolean" then
		return invoke
	elseif type(invoke) == "function" then
		return invoke(self, data)
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		return skill and skill:getFrequency() == sgs.Skill_Frequent
	end
end

function SmartAI:askForYiji(cards)
	self:sort(self.friends_noself,"handcard")

	if self.player:getHandcardNum() <= 2 then
		return nil, -1
	end

	for _, card_id in ipairs(cards) do
		local card = sgs.Sanguosha:getCard(card_id)
		for _, friend in ipairs(self.friends_noself) do
			if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then
				if card:inherits("Nullification") then
					return friend, card_id
				end
			else
				if card:inherits("Jink") then
					if friend:getHp() < 2 and self:getCardsNum("Jink", friend) < 1 then
						return friend, card_id
					end
				end
				if friend:hasWeapon("crossbow") or self:getCardsNum("Slash", friend) < 1 then
					if card:inherits("Slash") then
						return friend, card_id
					end
				end
				if self:hasSkills(sgs.lose_equip_skill, friend) then
					if card:inherits("EquipCard") then return friend, card_id end
				end
				if friend:hasSkill("xiagu") then
					if card:inherits("EquipCard") then return friend, card_id end
				end
				if friend:hasSkill("shenhuo") then
					if (card:getSuit() == sgs.Card_Diamond or
						card:getSuit() == sgs.Card_Heart) and card:inherits("TrickCard") then
						return friend, card_id
					end
				end
				if friend:hasSkill("kongying") then
					if self:getCardsNum("Jink", friend) < 1 and card:inherits("Jink") then return friend, card_id
					elseif card:getSuit() == sgs.Card_Spade then return friend, card_id
					end
				end
				if friend:hasSkill("shentou") or friend:hasSkill("meicha") then
					if card:getSuit() == sgs.Card_Club then return friend, card_id end
				end

				if friend:hasSkill("guibing") then
					if card:isBlack() then return friend, card_id end
				end

				if friend:getHandcardNum() < friend:getHp() and not sgs.Sanguosha:getCard(card_id):inherits("Shit") then
					return friend, card_id
				end
			end
		end
	end
	if #self.enemies  > 0 then
		for _, card_id in ipairs(cards) do
			local card = sgs.Sanguosha:getCard(card_id)
			if card:inherits("Shit") then
				for _,enemy in ipairs(self.enemies) do
					local v1 = 0
					if sgs[enemy:getGeneralName().."_suit_value"] then
						v1 = sgs[enemy:getGeneralName().."_suit_value"][card:getSuitString()] or 0
					end
					if v1 <= 0 then
						return enemy, card_id
					end
				end
			end
		end
	end
end

-- used for SmartAI:askForUseCard
sgs.ai_skill_use = {}

function SmartAI:askForUseCard(pattern, prompt)
	local use_func = sgs.ai_skill_use[pattern]
	if use_func then
		return use_func(self, prompt) or "."
	else
		return "."
	end
end

-- yicai,badao,yitian-slash,moon-spear-slash
sgs.ai_skill_use["slash"] = function(self, prompt)
	if prompt ~= "@askforslash" then return "." end
	local slash = self:getCard("Slash")
	if not slash then return "." end
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, true) and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
			return ("%s->%s"):format(slash:toString(), enemy:objectName())
		end
	end
	return "."
end

function SmartAI:slashIsEffective(slash, to)
	if to:hasSkill("jueming") and to:getHp() == 1 then
		return false
	end
	if to:hasSkill("qianshui") and not self.player:getWeapon() then
		return false
	end

	local nature = {
		Slash = sgs.DamageStruct_Normal,
		FireSlash = sgs.DamageStruct_Fire,
		ThunderSlash = sgs.DamageStruct_Thunder,
	}

	if not self:damageIsEffective(to, nature[slash:className()]) then return false end

	if self.player:hasWeapon("qinggang_sword") or self.player:hasSkill("wuzu") or (self.player:hasSkill("yinyu") and self.player:getMark("qinggang") > 0) then
		return true
	end

	local armor = to:getArmor()
	if armor then
		if armor:objectName() == "renwang_shield" then
			return not slash:isBlack()
		elseif armor:objectName() == "vine" then
			return slash:inherits("NatureSlash") or self.player:hasWeapon("fan")
		elseif armor:objectName() == "gold_armor" then
			return not self.player:getWeapon() and not slash:inherits("NatureSlash")
		end
	end

	return true
end

function SmartAI:damageIsEffective(player, nature, source)
	player = player or self.player
	source = source or self.player
	nature = nature or sgs.DamageStruct_Normal
	if player:hasSkill("shudan") and self.room:getTag("Shudan"):toString() == player:objectName() then
		return false
	end

	if player:hasSkill("fenhui") and nature == sgs.DamageStruct_Fire then
		return false
	end

	if player:getMark("@fog") > 0 and nature ~= sgs.DamageStruct_Thunder then
		return false
	end
	return true
end

function SmartAI:canPaoxiao(player)
	player = player or self.player
	if player:hasWeapon("crossbow") or player:hasSkill("paoxiao") or player:hasFlag("SlashbySlash") then
		return true
	end
	if player:hasSkill("shalu") and player:getMark("shalu") > 0 then
		return true
	end
	if player:hasSkill("qinlong") and not player:hasEquip() then
		return true
	end
	return false
end

function SmartAI:slashIsAvailable(player)
	player = player or self.player
--	if player:hasFlag("tianyi_failed") or player:hasFlag("xianzhen_failed") then return false end

	if self:canPaoxiao() then
		return true
	end
	if player:hasSkill("huafo") then
		local rand = math.random(1, 3)
		return rand == 2
	end
	return (player:usedTimes("Slash") + player:usedTimes("FireSlash") + player:usedTimes("ThunderSlash")) < 1
end

local function prohibitUseDirectly(card, player)
	if player:hasSkill("zhuying") then return card:inherits("Analeptic")
	elseif player:hasSkill("paohong") then return card:objectName() == "slash" and card:isBlack()
	elseif player:hasSkill("huoshui") then return card:inherits("Weapon") or card:inherits("Slash")
	elseif player:hasSkill("ganran") then return card:getTypeId() == sgs.Card_Equip
	end
end

local function zeroCardView(class_name, player)
	if class_name == "Analeptic" then
		if player:hasSkill("jiushi") and player:faceUp() then
			return ("analeptic:jiushi[no_suit:0]=.")
		end
	end
end

local function isCompulsoryView(card, class_name, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if class_name == "ThunderSlash" and card_place ~= sgs.Player_Equip then
		if player:hasSkill("paohong") and card:objectName() == "slash" and card:isBlack() then return ("thunder_slash:paohong[%s:%s]=%d"):format(suit, number, card_id) end
	elseif class_name == "Peach" then
		if player:hasSkill("zhuying") and card:inherits("Analeptic") then return ("peach:zhuying[%s:%s]=%d"):format(suit, number, card_id) end
	elseif class_name == "Drivolt" then
		if player:hasSkill("huoshui") and (card:inherits("Weapon") or card:inherits("Slash")) then
			return ("drivolt:huoshui[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

local function getSkillViewCard(card, class_name, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	if class_name == "Slash" then
		if player:hasSkill("paohong") then
			if card:objectName() == "slash" and card:isBlack() then
				return ("thunder_slash:paohong[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
		if player:hasSkill("qiaojiang") then
			if card:isBlack() and not card:inherits("TrickCard") then
				return ("slash:qiaojiang[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
		if player:hasSkill("huafo") then
			if card:inherits("BasicCard") then
				return ("slash:huafo[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	elseif class_name == "Jink" then
		if player:hasSkill("qiaojiang") then
			if card:isRed() and not card:inherits("TrickCard") then
				return ("jink:qiaojiang[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	elseif class_name == "Peach" then
		if player:hasSkill("jijiu") and card:isRed() and player:getPhase()==sgs.Player_NotActive then
			return ("peach:jijiu[%s:%s]=%d"):format(suit, number, card_id)
		end
	elseif class_name == "Analeptic" then
		if card_place ~= sgs.Player_Equip then
			if player:hasSkill("meicha") and card:getSuit() == sgs.Card_Club then
				return ("analeptic:meicha[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
		if player:hasSkill("hunjiu") then
			if card:inherits("Peach") or card:inherits("Ecstasy") then
				return ("analeptic:hunjiu[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
		if player:hasSkill("huafo") then
			if card:inherits("BasicCard") then
				return ("analeptic:huafo[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	elseif class_name == "Nullification" then
		if card:inherits("EquipCard") and player:hasSkill("zhiqu") then
		-- card:inherits("SingleTargetTrick")
			return ("nullification:zhiqu[%s:%s]=%d"):format(suit, number, card_id)
		end
	elseif class_name == "Ecstasy" then
		if player:hasSkill("menghan") and card:getSuit() == sgs.Card_Spade then
			return ("ecstasy:menghan[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

function SmartAI:searchForAnaleptic(use,enemy,slash)
	if not self.toUse then return nil end

	for _,card in ipairs(self.toUse) do
		if card:getId()~= slash:getId() then return nil end
	end

	if not use.to then return nil end
	if self.player:hasUsed("Analeptic") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:fillSkillCards(cards)

	if (getDefense(self.player) < getDefense(enemy)) and
		(self.player:getHandcardNum() < 1+self.player:getHp()) or
		self.player:hasFlag("drank") then
			return
	end

	if enemy:getArmor() then
		if ((enemy:getArmor():objectName()) == "eight_diagram")
			or ((enemy:getArmor():objectName()) == "silver_lion") then
			if (self.player:getHandcardNum() <= 1+self.player:getHp()) then
				return
			end
		end
	end

	local card_str = self:getCardId("Analeptic")
	if card_str then return sgs.Card_Parse(card_str) end

	for _, anal in ipairs(cards) do
		if (anal:className() == "Analeptic") and not (anal:getEffectiveId() == slash:getEffectiveId()) and
			not isCompulsoryView(anal, "Slash", self.player, sgs.Player_Hand) then
			return anal
		end
	end
end

function SmartAI:searchForEcstasy(use,enemy,slash)
    if not self.toUse then return nil end

	for _,card in ipairs(self.toUse) do
		if card:getId()~= slash:getId() then return nil end
	end

	if not use.to then return nil end
	if self.player:hasUsed("Ecstasy") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:fillSkillCards(cards)

	if getDefense(self.player) < getDefense(enemy) and
		self.player:getHandcardNum() < self.player:getHp() + 1 then
			return
	end

	if not self.player:canSlash(enemy) or enemy:hasFlag("ecst") then
		return
	end

	local card_str = self:getCardId("Ecstasy")
	if card_str then return sgs.Card_Parse(card_str) end

	for _, mi in ipairs(cards) do
		if (mi:className() == "Ecstasy") and not (mi:getEffectiveId() == slash:getEffectiveId()) and
			not isCompulsoryView(mi, "Slash", self.player, sgs.Player_Hand) then
			return mi
		end
	end
end

function SmartAI:slashProhibit(card,enemy)
	if card == nil then
		card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	end

	if self:isFriend(enemy) then
		if card:inherits("FireSlash") or self.player:hasWeapon("fan") then
			if self:isEquip("Vine", enemy) then return true end
		end
		if enemy:isChained() and card:inherits("NatureSlash") and #(self:getChainedFriends())>1 and
			self:slashIsEffective(card,enemy) then return true end
		if self:getCardsNum("Jink",enemy) == 0 and enemy:getHp() < 2 and self:slashIsEffective(card,enemy) then return true end
		if enemy:isLord() and self:isWeak(enemy) and self:slashIsEffective(card,enemy) then return true end
		if self:hasSkills("duanchang|huilei|dushi", enemy) and self:isWeak(enemy) then return true end
		if self:isEquip("GudingBlade") and enemy:isKongcheng() then return true end
	else
		if card:inherits("NatureSlash") and self:isEquip("GoldArmor", enemy) then
			return true
		end

		if enemy:hasSkill("huanshu") then
			if self.player:hasSkill("pohuanshu") or	self:isEquip("MeteorSword") then return false end
			return true
		end

		if enemy:hasSkill("yueli") then
			if self:isEquip("EightDiagram", enemy) then return true end
		end

		if enemy:isChained() and #(self:getChainedFriends()) > #(self:getChainedEnemies()) and self:slashIsEffective(card,enemy) then
			return true
		end
		if enemy:hasSkill("foyuan") and self.player:getGeneral():isMale() and not self.player:hasEquip() then
			return true
		end

		if enemy:hasSkill("danshu") then
			local x = enemy:getLostHp()
			return self.player:getHandcardNum() <= x + 1
		end

		if enemy ~= self.room:getCurrent() and enemy:hasSkill("jueming") and enemy:getHp() == 1 then
			return true
		end
	end

	return not self:slashIsEffective(card, enemy)
end
local function hasExplicitRebel(room)
	for _, player in sgs.qlist(room:getAllPlayers()) do
		if isRolePredictable() and player:getRole() == "rebel" then return true end
		if sgs.ai_explicit[player:objectName()] and sgs.ai_explicit[player:objectName()]:match("rebel") then return true end
	end
	return false
end

function SmartAI:useBasicCard(card, use, no_distance)
	if card:getSkillName() == "paohong" and card:isBlack() then no_distance = true end
	if self.player:hasFlag("Longest") then no_distance = true end
	if self.player:hasSkill("qinlong") and not self.player:hasEquip() then
		self.slash_targets = 2
	end
--	if self.player:hasWeapon("sun_bow") and card:isRed() and not card:inherits("NatureSlash") then
--		self.slash_targets = 2
--	end
	if (self.player:getHandcardNum() == 1
	and self.player:getHandcards():first():inherits("Slash")
	and self.player:getWeapon()
	and self.player:getWeapon():inherits("Halberd")) then
		self.slash_targets = 3
	end

	self.predictedRange = self.player:getAttackRange()
	if card:inherits("Slash") and self:slashIsAvailable() then
		local target_count = 0
		if self.player:hasSkill("jishi") and self:isWeak() and self:getOverflow() == 0 then return end
		for _, friend in ipairs(self.friends_noself) do
			local slash_prohibit = false
			slash_prohibit = self:slashProhibit(card,friend)
			if (self.player:hasSkill("qiangqu") and friend:getGeneral():isFemale() and friend:isWounded() and not friend:isNude())
			or (friend:hasSkill("kongying") 
			and (self:getCardsNum("Jink", friend) > 0 or (not self:isWeak(friend) and self:isEquip("EightDiagram",friend)))
			and (hasExplicitRebel(self.room) or not friend:isLord()))
			then
				if not slash_prohibit then
					if ((self.player:canSlash(friend, not no_distance)) or
						(use.isDummy and (self.player:distanceTo(friend) <= self.predictedRange))) and
						self:slashIsEffective(card, friend) then
						use.card = card
						if use.to then
							use.to:append(friend)
							self:speak("hostile", self.player:getGeneral():isFemale())
						end
						target_count = target_count+1
						if self.slash_targets <= target_count then return end
					end
				end
--				break
			end
		end

		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local slash_prohibit = false
			slash_prohibit = self:slashProhibit(card,enemy)
			if not slash_prohibit then
				if ((self.player:canSlash(enemy, not no_distance)) or
				(use.isDummy and self.predictedRange and (self.player:distanceTo(enemy) <= self.predictedRange))) and
				self:objectiveLevel(enemy) > 3 and
				self:slashIsEffective(card, enemy) and
				not (not self:isWeak(enemy) and #self.enemies > 1 and #self.friends > 1 and self.player:hasSkill("shemi")
					and self:getOverflow() > 0 and not self:isEquip("Crossbow")) then
					-- fill the card use struct
					local mi = self:searchForEcstasy(use,enemy,card)
					if mi and self:getCardsNum("Jink", enemy) > 0 and self:getCardId("Slash") then
						use.card = mi
						if use.to then use.to:append(enemy) end
						return
					end
					if not use.to or use.to:isEmpty() then
						local anal = self:searchForAnaleptic(use,enemy,card)
						if anal and self:isNoZhenshaMark() and not self:isEquip("SilverLion", enemy) and not self:isWeak() then
							use.card = anal
							return
						end
						if self.player:getGender()~=enemy:getGender() and self:getCardsNum("DoubleSword",self.player,"h") > 0 then
							self:useEquipCard(self:getCard("DoubleSword"), use)
							if use.card then return end
						end
						if enemy:isKongcheng() and self:getCardsNum("GudingBlade", self.player, "h") > 0 then
							self:useEquipCard(self:getCard("GudingBlade"), use)
							if use.card then return end
						end
						if self:getOverflow()>0 and self:getCardsNum("Axe", self.player, "h") > 0 then
							self:useEquipCard(self:getCard("Axe"), use)
							if use.card then return end
						end
						if enemy:getArmor() and self:getCardsNum("Fan", self.player, "h") > 0 and
							(enemy:getArmor():inherits("Vine") or enemy:getArmor():inherits("GaleShell")) then
							self:useEquipCard(self:getCard("Fan"), use)
							if use.card then return end
						end
						if enemy:getDefensiveHorse() and self:getCardsNum("KylinBow", self.player, "h") > 0 then
							self:useEquipCard(self:getCard("KylinBow") ,use)
							if use.card then return end
						end
					end
					use.card = card
					if use.to then use.to:append(enemy) end
					target_count = target_count+1
					if self.slash_targets <= target_count then return end
				end
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkill("baoguo") and friend:getHp() > 1 and
				not (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
				local slash_prohibit = false
				slash_prohibit = self:slashProhibit(card, friend)
				if not slash_prohibit then
					if ((self.player:canSlash(friend, not no_distance)) or
						(use.isDummy and (self.player:distanceTo(friend) <= self.predictedRange))) and
						self:slashIsEffective(card, friend) then
						use.card = card
						if use.to then
							use.to:append(friend)
							self:speak("yiji")
						end
						target_count = target_count+1
						if self.slash_targets <= target_count then return end
					end
				end
				break
			end
		end

	elseif card:inherits("Peach") and self.player:isWounded() then
		if not (self.player:hasSkill("rende") and self:getOverflow() > 1 and #self.friends_noself > 0) then
			local peaches = 0
			local cards = self.player:getHandcards()
			cards = sgs.QList2Table(cards)
			for _,card in ipairs(cards) do
				if card:inherits("Peach") then peaches = peaches+1 end
			end

			for _, friend in ipairs(self.friends_noself) do
				if (self.player:getHp()-friend:getHp() > peaches) and (friend:getHp() < 3) then
				return end
			end

			use.card = card
		end
	elseif card:inherits("Shit") then
		if self.player:hasSkill("fushang") and self.player:getMaxHP() > 3 then return end
		if (card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Club) and self.player:isChained() and
			#(self:getChainedFriends()) > #(self:getChainedEnemies()) then return end
		if self.player:getHp()>3 and (self.player:hasSkill("huanshu") or self.player:hasSkill("shenchou")) then use.card = card return end
		if card:getSuit() == sgs.Card_Heart and (self:isEquip("GaleShell") or self:isEquip("Vine")) then return end
		if not self.player:isWounded() then
			if self:hasSkills(sgs.need_kongcheng) and self.player:getHandcardNum() == 1 then
				use.card = card
				return
			end
			if sgs[self.player:getGeneralName() .. "_suit_value"] and
				(sgs[self.player:getGeneralName() .. "_suit_value"][card:getSuitString()] or 0) > 0 then return end
			local peach = self:getCard("Peach")
			if peach then
				self:sort(self.friends, "hp")
				if not self:isWeak(self.friends[1]) then
					use.card = card
					return
				end
			end
		end
	elseif card:inherits("Stink") then
		local next_player = self.player:getNextAlive()
		if self:isFriend(next_player) then return end
		use.card = card
	elseif card:inherits("Poison") then
		local players = self.room:getAllPlayers()
		players = sgs.QList2Table(players)
		for _, target in ipairs(players) do
			if self.player:distanceTo(target) <= 1 and
				((self:isFriend(target) and target:getMark("poison") > 0) or
				(self:isEnemy(target) and target:getMark("poison") == 0)) then
				use.card = card
				if use.to then
					use.to:append(target)
				end
				break
			end
		end
	end
end

function SmartAI:aoeIsEffective(card, to)
	-- the AOE starter is not effected by AOE
	if self.player == to then
		return false
	end

	-- the vine
	local armor = to:getArmor()
	if armor and armor:inherits("Vine") and not self.player:hasSkill("wuzu") then
		return false
	end

	--Baisheng's shudan
	if (to:hasSkill("shudan") and self.room:getTag("Shudan"):toString() == to:objectName()) then
		return false
	end

	--Panjinlian's shengui
	if to:hasSkill("shengui") and not to:faceUp() and self.player:getGeneral():isMale() then
		return false
	end
	
	--Wangding6's kongying
	if card:inherits("ArcheryAttack") then
		if (to:hasSkill("kongying") and self:getCardsNum("Jink", to) > 0) or (self:isEquip("EightDiagram", to) and to:getHp() > 1) then
			return false
		end
	end

	return true
end

function SmartAI:getDistanceLimit(card)
	if card:inherits("Snatch") then
		if self.player:hasSkill("shentou") then
			return 2
		else
			return 1
		end
	elseif card:inherits("SupplyShortage") then
		return 1
	end
end

function SmartAI:exclude(players, card)
	local excluded = {}
	local limit = self:getDistanceLimit(card)
	for _, player in sgs.list(players) do
		if not self.room:isProhibited(self.player, player, card) then
			local should_insert = true
			if limit then
				should_insert = self.player:distanceTo(player) <= limit
			end

			if should_insert then
				table.insert(excluded, player)
			end
		end
	end

	return excluded
end

function SmartAI:useCardDismantlement(dismantlement, use)
	if self.player:hasSkill("wuyan") then return end
	if (not self.has_wizard) and self:hasWizard(self.enemies) then
		-- find lightning
		local players = self.room:getOtherPlayers(self.player)
		players = self:exclude(players, dismantlement)
		for _, player in ipairs(players) do
			if player:containsTrick("lightning") and not player:hasSkill("wuyan") then
				use.card = dismantlement
				if use.to then use.to:append(player) end
				return
			end
		end
	end

	self:sort(self.friends_noself,"defense")
	local friends = self:exclude(self.friends_noself, dismantlement)
	local hasLion, target
	for _, friend in ipairs(friends) do
		if self:hasTrickEffective(dismantlement, friend) then
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
				use.card = dismantlement
				if use.to then use.to:append(friend) end
				return
			end
			if self:isEquip("SilverLion", friend) and friend:isWounded() and (friend:hasSkill("benghuai") or friend:getHp() < 4) then
				hasLion = true
				target = friend
			end
		end
	end

	if hasLion then
		use.card = dismantlement
		if use.to then use.to:append(target) end
		return
	end

	self:sort(self.enemies,"defense")
	if getDefense(self.enemies[1]) >= 8 then self:sort(self.enemies, "threat") end

	local enemies = self:exclude(self.enemies, dismantlement)
	for _, enemy in ipairs(enemies) do
		local equips = enemy:getEquips()
		if not enemy:isNude() and self:hasTrickEffective(dismantlement, enemy) and not enemy:hasSkill("tuntian") and
			not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getHandcardNum() == 0) and
			not (enemy:getCards("he"):length() == 1 and self:isEquip("GaleShell",enemy)) 
			and self:hasSkills("butian|yixing|qiaojiang|jishi|cuju|kongying", enemy) then
			if enemy:getHandcardNum() == 1 then
				if enemy:hasSkill("kongmen") then return end
			end
			use.card = dismantlement
			if use.to then
				use.to:append(enemy)
				self:speak("hostile", self.player:getGeneral():isFemale())
			end
			return
		end
	end	
	for _, enemy in ipairs(enemies) do
		local equips = enemy:getEquips()
		if not enemy:isNude() and self:hasTrickEffective(dismantlement, enemy) and not enemy:hasSkill("shouge") and
			not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getHandcardNum() == 0) and
			not (enemy:getCards("he"):length() == 1 and self:isEquip("GaleShell",enemy)) then
			if enemy:getHandcardNum() == 1 then
				if enemy:hasSkill("kongmen") then return end
			end
			use.card = dismantlement
			if use.to then
				use.to:append(enemy)
				self:speak("hostile", self.player:getGeneral():isFemale())
			end
			return
		end
	end
end

-- very similar with SmartAI:useCardDismantlement
function SmartAI:useCardSnatch(snatch, use)
	if self.player:hasSkill("wuyan") then return end

	if (not self.has_wizard) and self:hasWizard(self.enemies)  then
		-- find lightning
		local players = self.room:getOtherPlayers(self.player)
		players = self:exclude(players, snatch)
		for _, player in ipairs(players) do
			if player:containsTrick("lightning") and not player:hasSkill("wuyan") then
				use.card = snatch
				if use.to then use.to:append(player) end

				return
			end
		end
	end

	self:sort(self.friends_noself,"defense")
	local friends = self:exclude(self.friends_noself, snatch)
	local hasLion, target
	for _, friend in ipairs(friends) do
		if self:hasTrickEffective(snatch, friend) then
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
				use.card = snatch
				if use.to then use.to:append(friend) end
				return
			end
			if self:isEquip("SilverLion", friend) and friend:isWounded() and (friend:hasSkill("benghuai") or friend:getHp() < 4) then
				hasLion = true
				target = friend
			end
		end
	end

	if hasLion then
		use.card = snatch
		if use.to then use.to:append(target) end
		return
	end

	self:sort(self.enemies,"defense")
	if getDefense(self.enemies[1]) >= 8 then self:sort(self.enemies, "threat") end

	local enemies = self:exclude(self.enemies, snatch)
	for _, enemy in ipairs(enemies) do
		if not enemy:isNude() and self:hasTrickEffective(snatch, enemy) and
			not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getHandcardNum() == 0) and
			not (enemy:getCards("he"):length() == 1 and self:isEquip("GaleShell",enemy)) then
			if enemy:getHandcardNum() == 1 then
				if enemy:hasSkill("kongmen") then return end
			end
			use.card = snatch
			if use.to then
				use.to:append(enemy)
				self:speak("hostile", self.player:getGeneral():isFemale())
			end
			return
		end
	end
end

function SmartAI:useCardByClassName(card, use)
	local class_name = card:className()
	local use_func = self["useCard" .. class_name]

	if use_func then
		use_func(self, card, use)
	end
end

local function factorial(n)
	if n <= 0.1 then return 1 end
	return n*factorial(n-1)
end

function SmartAI:useCardDuel(duel, use)
	if self.player:hasSkill("wuyan") then return end
	self:sort(self.enemies,"handcard")
	local enemies = self:exclude(self.enemies, duel)
	for _, enemy in ipairs(enemies) do
		if self:objectiveLevel(enemy) > 3 then
			local n1 = self:getCardsNum("Slash")
			local n2 = enemy:getHandcardNum()
			if enemy:hasSkill("wushuang") then n2 = n2*2 end
			if self.player:hasSkill("wushuang") then n1 = n1*2 end
			local useduel
			if self:hasTrickEffective(duel, enemy) then
				if n1 >= n2 then
					useduel = true
				elseif n2 > n1*2 + 1 then
					useduel = false
				elseif n1 > 0 then
					local percard = 0.35
					if self:canPaoxiao(enemy) then percard = 0.2 end
					local poss = percard ^ n1 * (factorial(n1)/factorial(n2)/factorial(n1-n2))
					if math.random() > poss then useduel = true end
				end
				if useduel then
					use.card = duel
					if use.to then
						use.to:append(enemy)
						self:speak("duel", self.player:getGeneral():isFemale())
					end
					return
				end
			end
		end
	end
end

local function hp_subtract_handcard(a,b)
	local diff1 = a:getHp() - a:getHandcardNum()
	local diff2 = b:getHp() - b:getHandcardNum()

	return diff1 < diff2
end

function SmartAI:useCardIndulgence(card, use)
	table.sort(self.enemies, hp_subtract_handcard)
	
	local enemies = self:exclude(self.enemies, card)
	for _, enemy in ipairs(enemies) do
		if enemy:hasSkill("baoguo") and not enemy:containsTrick("indulgence") and not enemy:isKongcheng() and enemy:faceUp() then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if not enemy:containsTrick("indulgence") and not enemy:hasSkill("shemi") and enemy:faceUp() then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

function SmartAI:useCardCollateral(card, use)
	if self.player:hasSkill("wuyan") then return end
	self:sort(self.enemies,"threat")

	for _, friend in ipairs(self.friends_noself) do
		if friend:getWeapon() and self:hasSkills(sgs.lose_equip_skill, friend) then

			for _, enemy in ipairs(self.enemies) do
				if friend:canSlash(enemy) then
					use.card = card
				end
				if use.to then use.to:append(friend) end
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end

	local n = nil
	local final_enemy = nil
	for _, enemy in ipairs(self.enemies) do
		if not self.room:isProhibited(self.player, enemy, card)
			and self:hasTrickEffective(card, enemy)
			and not self:hasSkill(sgs.lose_equip_skill, enemy)
			and enemy:getWeapon() then

			for _, enemy2 in ipairs(self.enemies) do
				if enemy:canSlash(enemy2) then
					if enemy:getHandcardNum() == 0 then
						use.card = card
						if use.to then use.to:append(enemy) end
						if use.to then use.to:append(enemy2) end
						return
					else
						n = 1;
						final_enemy = enemy2
					end
				end
			end
			if n then use.card = card end
			if use.to then use.to:append(enemy) end
			if use.to then use.to:append(final_enemy) end
			return

		end
		n = nil
	end
end

-- the ExNihilo is always used
function SmartAI:useCardExNihilo(card, use)
		use.card = card
		if not use.isDummy then
			self:speak("lucky")
		end
end

-- when self has wizard (zhangjiao, simayi, use it)
function SmartAI:useCardLightning(card, use)
	if self.player:containsTrick("lightning") then return end
	if self.player:hasSkill("weimu") and card:isBlack() then return end

	if not self:hasWizard(self.enemies) then--and self.room:isProhibited(self.player, self.player, card) then
		if self:hasWizard(self.friends) then
			use.card = card
			return
		end
		local players = self.room:getAllPlayers()
		players = sgs.QList2Table(players)

		local friends = 0
		local enemies = 0

		for _,player in ipairs(players) do
			if self:objectiveLevel(player) >= 4 then
				enemies = enemies + 1
			elseif self:isFriend(player) then
				friends = friends + 1
			end
		end

		local ratio

		if friends == 0 then ratio = 999
		else ratio = enemies/friends
		end

		if ratio > 1.5 then
			use.card = card
			return
		end
	end
end

function SmartAI:useCardGodSalvation(card, use)
	local good, bad = 0, 0

	if self.player:hasSkill("wuyan") and self.player:isWounded() then
		use.card = card
		return
	end

	for _, friend in ipairs(self.friends) do
		if friend:isWounded() then
			good = good + 10/(friend:getHp())
			if friend:isLord() then good = good + 10/(friend:getHp()) end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() then
			bad = bad + 10/(enemy:getHp())
			if enemy:isLord() then
				bad = bad + 10/(enemy:getHp())
			end
		end
	end

	if good > bad then
		use.card = card
	end
end

function SmartAI:useCardAmazingGrace(card, use)
	if #self.friends >= #self.enemies or (self:hasSkills(sgs.need_kongcheng) and self.player:getHandcardNum() == 1)
		or self.player:hasSkill("longjiao") then
		use.card = card
	end
end

function SmartAI:getAllPeachNum(player)
	player = player or self.player
	local n = 0
	for _, friend in ipairs(self:getFriends(player)) do
		n = n + self:getCardsNum("Peach")
	end
	return n
end

function SmartAI:useTrickCard(card, use)
	if card:inherits("AOE") then
		if self.player:hasSkill("wuyan") then return end
		if self.role == "renegade" and not self:isWeak(self.room:getLord()) then use.card = card return end
		local good, bad = 0, 0
		for _, friend in ipairs(self.friends_noself) do
			if self:aoeIsEffective(card, friend) then
				bad = bad + 20/(friend:getHp())+10
				if friend:isLord() and (friend:getHp() < 3) then
					return
				end

				if (friend:getHp() < 2) and (self.player:isLord()) then
					return
				end
			end
			good = good + self:getCardsNum("Peach")
		end

		for _, enemy in ipairs(self.enemies) do
			if self:aoeIsEffective(card, enemy) then
				good = good + 20/(enemy:getHp())+10

				if enemy:isLord() then
					good = good + 20/(enemy:getHp())
				end
			end
			bad = bad + self:getCardsNum("Peach")
		end

		if good > bad or (self:hasSkills(sgs.need_kongcheng) and self.player:getHandcardNum() == 1) then
			use.card = card
		end
	else
		self:useCardByClassName(card, use)
	end
	if use.to then
		if not use.to:isEmpty() and sgs.dynamic_value.damage_card[card:className()] then
			for _, target in sgs.qlist(use.to) do
				if self:damageIsEffective(target) then return end
			end
			use.card = nil
		end
	end
end


sgs.weapon_range  =
{
	Crossbow = 1,
	Blade = 3,
	Spear = 3,
	DoubleSword  = 2,
	QinggangSword = 2,
	Axe = 3,
	KylinBow = 5,
	Halberd = 4,
	IceSword = 2,
	Fan = 4,
	MoonSpear = 3,
	GudingBlade = 2,
	YitianSword = 2,
	SPMoonSpear = 3,
	YxSword = 3,

	DoubleWhip = 2,
	MeteorSword = 3,
	SunBow = 5
}

function SmartAI:evaluateEquip(card)
	local deltaSelfThreat = 0
	local currentRange
	if not card then return -1
	else
		currentRange = sgs.weapon_range[card:className()] or 0
	end
	for _,enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= currentRange then
				deltaSelfThreat = deltaSelfThreat+6/getDefense(enemy)
		end
	end

	if card:inherits("Crossbow") and deltaSelfThreat ~= 0 then
		if self.player:hasSkill("banzhuang") then deltaSelfThreat = deltaSelfThreat*3+10 end
		deltaSelfThreat = deltaSelfThreat + self:getCardsNum("Slash")*3-2
	elseif card:inherits("Blade") then
		deltaSelfThreat = deltaSelfThreat + self:getCardsNum("Slash")
	elseif card:inherits("Spear") then
	else
		for _,enemy in ipairs(self.enemies) do
			if self.player:distanceTo(enemy) <= currentRange then
				if card:inherits("DoubleSword") and
					enemy:getGeneral():isMale() ~= self.player:getGeneral():isMale() then
						deltaSelfThreat = deltaSelfThreat+3
				elseif card:inherits("QinggangSword") and enemy:getArmor() then
					deltaSelfThreat = deltaSelfThreat+3
				elseif card:inherits("Axe") and enemy:getHp() < 3 then
					deltaSelfThreat = deltaSelfThreat+3-enemy:getHp()
				elseif card:inherits("KylinBow") and (enemy:getDefensiveHorse() or enemy:getDefensiveHorse())then
					deltaSelfThreat = deltaSelfThreat+1
					break
				elseif card:inherits("GudingBlade") and enemy:getHandcardNum() < 3 then
					deltaSelfThreat = deltaSelfThreat+2
					if enemy:getHandcardNum() < 1 then deltaSelfThreat = deltaSelfThreat+4 end
				end
			end
		end
	end
	return deltaSelfThreat
end

function SmartAI:evaluateArmor(card, player)
	player = player or self.player
	local ecard = card or player:getArmor()
	if not ecard then
		if player:hasSkill("jinjia") then return 4 end
		return 0
	end
	local armor_base_value = {
		Vine = 3,
		EightDiagram = 4,
		RenwangShield = 3,
		SilverLion = 1,
		GaleShell = -10,

		GoldArmor = 4,
	}
	if ecard:inherits("EightDiagram") and (self:hasWizard(self:getFriends(player),true) or player:hasSkill("yueli")) then return 5 end
	if ecard:inherits("EightDiagram") and self:hasWizard(self:getEnemies(player),true) then return 2 end
	if ecard:inherits("Vine") then
		for _, enemy in ipairs(self:getEnemies(player)) do
			if (enemy:canSlash(player) and self:isEquip("Fan",enemy)) or enemy:hasSkill("shenhuo") then return -1 end
			if enemy == self.player and (self:getCardId("FireSlash", enemy) or self:getCardId("FireAttack",enemy)) then return -1 end
		end
	end
	if #(self:getEnemies(player))<3 and ecard:inherits("Vine") then return 4 end
	if self:hasWizard(self:getEnemies(player), true) and ecard:inherits("SilverLion") then
		for _,player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:containsTrick("lightning") then return 5 end
		end
	end
	return armor_base_value[ecard:className()]
end

function SmartAI:useEquipCard(card, use)
	if self:hasSkill("qinlong") then
		local targets = {}
		for _, player in ipairs(self.enemies) do
			if self.player:distanceTo(player) == 1 then
				table.insert(targets, player)
			end
		end
		if #targets >= 2 then return end
	end
	if self:hasSkills(sgs.lose_equip_skill) and not card:inherits("GaleShell") then
		use.card = card
		return
	end
	if self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng) and not card:inherits("GaleShell") then
		use.card = card
		return
	end
	if self:hasSameEquip(card) and
		(self.player:hasSkill("yinlang") or self.player:hasSkill("jishi")
		or (self.player:hasSkill("sixiang") and self:getOverflow() < 3)
		or (self.player:hasSkill("shentou") and card:getSuit() == sgs.Card_Club)) then return end
	if card:inherits("Weapon") then
		if self.player:hasSkill("yinlang") then
			for _,friend in ipairs(self.friends_noself) do
				if not friend:getWeapon() then return end
			end
		end
		if self.player:getWeapon() and self.player:getWeapon():inherits("YitianSword") then use.card = card return end
		if self:evaluateEquip(card) > self:evaluateEquip(self.player:getWeapon()) then
			if (not use.to) and self.weaponUsed and (not self:hasSkills(sgs.lose_equip_skill)) then return end
			if self.player:getHandcardNum() <= self.player:getHp() then return end
			use.card = card
		end
	elseif card:inherits("Armor") then
		if card:inherits("GaleShell") then self:useGaleShell(card, use) return end
		local lion = self:getCard("SilverLion")
		if lion and self.player:isWounded() and not self:isEquip("SilverLion") and not card:inherits("SilverLion") and
			not (self:hasSkills("jinjia") and not self.player:getArmor()) then
			use.card = lion
			return
		end
		if self.player:hasSkill("yinlang") and self:evaluateArmor(card)<4 then
			for _,friend in ipairs(self.friends_noself) do
				if not friend:getArmor() then return end
			end
		end
		if self:evaluateArmor(card) > self:evaluateArmor() then use.card = card end
		return
	elseif card:inherits("OffensiveHorse") and self.player:hasSkill("yinlang") then
		for _,friend in ipairs(self.friends_noself) do
			if not friend:getOffensiveHorse() then return end
		end
	elseif card:inherits("Monkey") or self.lua_ai:useCard(card) then
		use.card = card
	end
end

function SmartAI:getTurnUse()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local turnUse = {}
	local slashAvail = 1
	self.predictedRange = self.player:getAttackRange()
	self.predictNewHorse = false
	self.retain_thresh = 5
	self.slash_targets = 1
	self.slash_distance_limit = false

	self.weaponUsed = false

	if self.player:isLord() then self.retain_thresh = 6 end
	if self.player:hasFlag("Longest") then
		self.slash_distance_limit = true
	end

	self:fillSkillCards(cards)

	self:sortByUseValue(cards)

	if self:canPaoxiao() then
		slashAvail = 100
	end

	if self.player:hasSkill("qinlong") and not self.player:hasEquip() then
		self.slash_targets = 2
		slashAvail = 100
	end

	local i = 0
	for _,card in ipairs(cards) do
		local dummy_use = {}
		dummy_use.isDummy = true
		if not self:hasSkills(sgs.need_kongcheng) then
			if (i >= (self.player:getHandcardNum()-self.player:getHp()+self.retain)) and (self:getUseValue(card) < self.retain_thresh) then
				return turnUse
			end

			if (i >= (self.player:getHandcardNum()-self.player:getHp())) and (self:getUseValue(card) < 8.5) and self.harsh_retain then
				return turnUse
			end
		end

		local type = card:getTypeId()
		if type == sgs.Card_Basic then
			self:useBasicCard(card, dummy_use, self.slash_distance_limit)
		elseif type == sgs.Card_Trick then
			self:useTrickCard(card, dummy_use)
		elseif type == sgs.Card_Equip then
			self:useEquipCard(card, dummy_use)
		elseif type == sgs.Card_Events then
			self:useEventsCard(card, dummy_use)
		elseif type == sgs.Card_Skill then
			self:useSkillCard(card, dummy_use)
		end

		if dummy_use.card then
			if (card:inherits("Slash")) then
				if slashAvail > 0 then
					slashAvail = slashAvail-1
					table.insert(turnUse,card)
				end
			else
				if card:inherits("Weapon") then
					self.predictedRange = sgs.weapon_range[card:className()]
					self.weaponUsed = true
				end
				if card:inherits("OffensiveHorse") then self.predictNewHorse = true end
				if card:objectName() == "crossbow" then slashAvail = 100 end
				if card:inherits("Snatch") then i = i-1 end
				if card:inherits("Peach") then i = i+2 end
				if card:inherits("Collateral") then i = i-1 end
				if card:inherits("AmazingGrace") then i = i-1 end
				if card:inherits("ExNihilo") then i = i-2 end
				table.insert(turnUse,card)
			end
			i = i+1
		end
	end

	return turnUse
end

function SmartAI:activate(use)
	self:updatePlayers()
	self:assignKeep(self.player:getHp(),true)
	self:printCards(self.kept)
	self.toUse  = self:getTurnUse()
	self:printCards(self.toUse)

--	self:sortByUsePriority(self.toUse)
	self:sortByDynamicUsePriority(self.toUse)
	for _, card in ipairs(self.toUse) do
		if not self.player:isJilei(card) then
			local type = card:getTypeId()

			if type == sgs.Card_Basic then
				self:useBasicCard(card, use, self.slash_distance_limit)
			elseif type == sgs.Card_Trick then
				self:useTrickCard(card, use)
			elseif type == sgs.Card_Skill then
				self:useSkillCard(card, use)
			elseif type == sgs.Card_Equip then
				self:useEquipCard(card, use)
			else
				self:useEventsCard(card, use)
			end

			if use:isValid() then
				self.toUse = nil
				return
			end
		end
	end

	self.toUse = nil
end

function SmartAI:hasEquip(card)
	return self.player:hasEquip(card)
end

function SmartAI:getKeepValue(card,kept)
	if not kept then return self.keepValue[card:getId()] or 0 end

	local class_name = card:className()
	local suit_string = card:getSuitString()
	local value, newvalue
	if sgs[self.player:getGeneralName().."_keep_value"] then
		value = sgs[self.player:getGeneralName().."_keep_value"][class_name]
		if value then return value end
	end
	if sgs[self.player:getGeneralName().."_suit_value"] then
		value = sgs[self.player:getGeneralName().."_suit_value"][suit_string]
	end
	newvalue = sgs.ai_keep_value[class_name] or 0
	for _,acard in ipairs(kept) do
		if acard:className() == card:className() then newvalue = newvalue - 1.2
		elseif acard:inherits("Slash") and card:inherits("Slash") then newvalue = newvalue - 1
		end
	end
	if not value or newvalue > value then value = newvalue end
	return value
end

function SmartAI:getUseValue(card)
	local class_name = card:className()
	local v = 0

	if card:getTypeId() == sgs.Card_Equip then
		if self:hasEquip(card) then
			if card:inherits("OffensiveHorse") and self.player:getAttackRange()>2 then return 5.5 end
			if card:inherits("DefensiveHorse") and self:isEquip("EightDiagram") then return 5.5 end
			return 9
		end
		if not self:hasSameEquip(card) then v = 6.7 end
		if self.weaponUsed and card:inherits("Weapon") then v = 2 end
		if self.player:hasSkill("feiqiang") and card:inherits("Weapon") then v = 2 end
		if self.player:hasSkill("banzhuang") and card:inherits("Crossbow") then return 9 end
		if self:hasSkill("jinjia") and card:inherits("Armor") then v = 2 end
		if self:hasSkills(sgs.lose_equip_skill) then return 10 end
	elseif card:getTypeId() == sgs.Card_Basic then
		if card:inherits("Slash") then
			if (self.player:hasFlag("drank") or self.player:hasSkill("liba") or
			(self.player:hasSkill("manli") and self.player:getWeapon() and self.player:getArmor())) then v = 8.7 end
			if self:isEquip("CrossBow") then v = v + 4 end
			v = v+self:getCardsNum("Slash")
		elseif card:inherits("Jink") then
			if self:getCardsNum("Jink") > 1 then v = v-6 end
		elseif card:inherits("Shit") and self.player:hasSkill("kuanggu") and card:getSuit()~= sgs.Card_Spade then
			v = 0.1
		end
	elseif card:getTypeId() == sgs.Card_Trick then
		if self.player:getWeapon() and not self:hasSkills(sgs.lose_equip_skill) and card:inherits("Collateral") then v = 2 end
		if self.player:hasSkill("duijue") and card:inherits("Duel") then v = 8 end
		if self.player:hasSkill("wumou") and card:isNDTrick() and not card:inherits("AOE") then
			if not (card:inherits("Duel") and self.player:hasUsed("WuqianCard")) then v = 1 end
		end
		if not self:hasTrickEffective(card) then v = 0 end
	end

	if self:hasSkills(sgs.need_kongcheng) then
		if self.player:getHandcardNum() == 1 then v = 10 end
	end
	if self:hasSkill({name = "halberd"}) and card:inherits("Slash") and self.player:getHandcardNum() == 1 then v = 10 end
	if card:getTypeId() == sgs.Card_Skill then
		if v == 0 then v = 10 end
	end

	if v == 0 then v = sgs.ai_use_value[class_name] or 0 end
	return v
end

function SmartAI:getUsePriority(card)
	local class_name = card:className()
	local v = 0
	if card:inherits("EquipCard") then
		if self:hasSkill(sgs.lose_equip_skill) then return 10 end
		if card:inherits("Armor") and not self.player:getArmor() then v = 6
		elseif card:inherits("Weapon") and not self.player:getWeapon() then v = 5.7
		elseif card:inherits("DefensiveHorse") and not self.player:getDefensiveHorse() then v = 5.8
		elseif card:inherits("OffensiveHorse") and not self.player:getOffensiveHorse() then v = 5.5
		end
		return v
	end

	if self.player:hasSkill("wuyan") then
		if card:inherits("Slash") then
			v = 4

		elseif card:inherits("Collateral") or card:inherits("Dismantlement") or card:inherits("Snatch") or card:inherits("IronChain") then v = 0
		end
		if v then return v else return sgs.ai_use_priority[class_name] end
	end
	if self.player:hasSkill("jishi") then
		if card:inherits("Dismantlement") then v = 3.8
		elseif card:inherits("Collateral") then v = 3.9
		end
		if v then return v else return sgs.ai_use_priority[class_name] end
	end
	if self.player:hasSkill("rende") then
		if card:inherits("ExNihio") then v = 5.9 end
		return v or sgs.ai_use_priority[class_name]
	end

	v = sgs.ai_use_priority[class_name] or 0

	if card:inherits("Slash") and (card:getSuit() == sgs.Card_NoSuit) then v = v-0.1 end
	return v
end

function SmartAI:getDynamicUsePriority(card)
	if not card then return 0 end

	local type = card:getTypeId()
	local dummy_use = {}
	dummy_use.isDummy = true
	if type == sgs.Card_Trick then
		self:useTrickCard(card, dummy_use)
	elseif type == sgs.Card_Basic then
		self:useBasicCard(card, dummy_use)
	elseif type == sgs.Card_Equip then
		self:useEquipCard(card, dummy_use)
	elseif type == sgs.Card_Events then
		self:useEventsCard(card, dummy_use)
	else
		self:useSkillCard(card, dummy_use)
	end

	local good_null, bad_null = 0, 0
	for _, friend in ipairs(self.friends) do
		good_null = good_null + self:getCardsNum("Nullification", friend)
	end
	for _, enemy in ipairs(self.enemies) do
		bad_null = bad_null + self:getCardsNum("Nullification", enemy)
	end

	local value = self:getUsePriority(card)
	if dummy_use.card then
		local use_card = dummy_use.card
		local card_name = use_card:className()
		local dynamic_value

		if use_card:getTypeId() == sgs.Card_Equips then
			if self:hasSkills(sgs.lose_equip_skill) then value = value + 12 end
		end

		if use_card:getSkillName() == "wusheng" and
			sgs.Sanguosha:getCard(use_card:getEffectiveId()):inherits("GaleShell") and
			self:isEquip("GaleShell") then
			value = value + 10
		end

		if sgs.dynamic_value.benefit[class_name] then
			dynamic_value = 10
			if use_card:inherits("AmazingGrace") then
				for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					dynamic_value = dynamic_value - 1
					if self:isEnemy(player) then dynamic_value = dynamic_value - ((player:getHandcardNum()+player:getHp())/player:getHp())*dynamic_value
					else dynamic_value = dynamic_value + ((player:getHandcardNum()+player:getHp())/player:getHp())*dynamic_value
					end
				end
			elseif use_card:inherits("GodSalvation") then
				local weak_mate, weak_enemy = 0, 0
				for _, player in sgs.qlist(self.room:getAllPlayers()) do
					if player:getHp() <= 1 and player:getHandcardNum() <= 1 then
						if self:isEnemy(player) then weak_enemy = weak_enemy + 1
						elseif self:isFriend(player) then weak_mate = weak_mate + 1
						end
					end
				end

				if weak_enemy > weak_mate then
					for _, card in sgs.qlist(self.player:getHandcards()) do
						if card:isAvailable(self.player) and sgs.dynamic_value.damage_card[card:className()] then
							if self:getDynamicUsePriority(card) - 0.5 > self:getUsePriority(card) then
								dynamic_value = -5
							end
						end
					end
				end
			elseif use_card:inherits("Peach") then
				dynamic_value = 7.85
			elseif use_card:inherits("QingnangCard") and self:getCardsNum("Snatch") > 0 and good_null >= bad_null then
				dynamic_value = 6.55
			elseif use_card:inherits("RendeCard") and self.player:usedTimes("RendeCard") < 2 then
				if not self.player:isWounded() then dynamic_value = 6.57
				elseif self:isWeak() then dynamic_value = 7.9
				else dynamic_value = 7.86
				end
			elseif use_card:inherits("JujianCard") then
				if not self.player:isWounded() then dynamic_value = 0
				else dynamic_value = 7.5
				end
			end
			value = value + dynamic_value
		elseif sgs.dynamic_value.damage_card[class_name] then
			local others
			if dummy_use.to then others = dummy_use.to else others = self.room:getOtherPlayers(self.player) end
			dummy_use.probably_hit = {}

			for _, enemy in sgs.qlist(others) do
				if self:isEnemy(enemy) and (enemy:getHp() <= 2 or enemy:isKongcheng())
					and self:getCardsNum("Analeptic", enemy) == 0 and self:getCardsNum("Peach", enemy) == 0 then
					table.insert(dummy_use.probably_hit, enemy)
					break
				end
			end

			if #dummy_use.probably_hit > 0 then
				self:sort(dummy_use.probably_hit, "defense")
				local probably_hit
				for _, hit in ipairs(dummy_use.probably_hit) do
					if not self:hasSkills(sgs.masochism_skill, hit) then
						probably_hit = hit
						break
					end
				end
				if not probably_hit then
					probably_hit = dummy_use.probably_hit[1]
					value = value + 1.5
				else
					value = value + 3
				end
				value = value - (probably_hit:getHp() - 1)/2.0

				if use_card:inherits("Slash") and self:getCardsNum("Jink", probably_hit) == 0 then
					value = value + 5
				elseif use_card:inherits("FireAttack") then
					value = value + 0.5 + self:getHandcardNum()
				elseif use_card:inherits("Duel") then
					value = value + 2 + (self:getHandcardNum() - self:getCardsNum("Slash", probably_hit))
				end
			end
		elseif sgs.dynamic_value.control_card[class_name] then
			if use_card:getTypeId() == sgs.Card_Trick then dynamic_value = 7 - bad_null/good_null else dynamic_value = 6.65 end
			value = value + dynamic_value
		elseif sgs.dynamic_value.control_usecard[class_name] then
			value = value + 6.6
		elseif sgs.dynamic_value.lucky_chance[class_name] then
			value = value + (#self.enemies - #self.friends)
		end
	end

	return value
end

function SmartAI:sortByKeepValue(cards,inverse,kept)
	local compare_func = function(a,b)
		local value1 = self:getKeepValue(a,kept)
		local value2 = self:getKeepValue(b,kept)

		if value1 ~= value2 then
			if inverse then return value1 > value2 end
			return value1 < value2
		else
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUseValue(cards,inverse)
	local compare_func = function(a,b)
			local value1 = self:getUseValue(a)
			local value2 = self:getUseValue(b)

			if value1 ~= value2 then
					if not inverse then return value1 > value2
					else return value1 < value2
					end
			else
					return a:getNumber() > b:getNumber()
			end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUsePriority(cards)
	local compare_func = function(a,b)
				local value1 = self:getUsePriority(a)
				local value2 = self:getUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a:getNumber() > b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByDynamicUsePriority(cards)
	local compare_func = function(a,b)
		local value1 = self:getDynamicUsePriority(a)
		local value2 = self:getDynamicUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a and a:getTypeId() ~= sgs.Card_Skill and not (b and b:getTypeId() ~= sgs.Card_Skill)
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByCardNeed(cards)
	local compare_func = function(a,b)
				local value1 = self:cardNeed(a)
				local value2 = self:cardNeed(b)

		if value1 ~= value2 then
			return value1 < value2
		else
			return a:getNumber() > b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:askForDiscard(reason, discard_num, optional, include_equip)
	if reason == "ganglie" then
		if self.player:getHp() > self.player:getHandcardNum() then return {} end

		if self.player:getHandcardNum() == 3 then
			local to_discard = {}
			local cards = self.player:getHandcards()
			local index = 0
			local all_peaches = 0
			for _, card in sgs.qlist(cards) do
				if card:inherits("Peach") then
					all_peaches = all_peaches + 1
				end
			end
			if all_peaches >= 2 then return {} end

			for _, card in sgs.qlist(cards) do
				if not card:inherits("Peach") then
					table.insert(to_discard, card:getEffectiveId())
					index = index + 1
					if index == 2 then break end
				end
			end
			return to_discard
		end

		if self.player:getHandcardNum() < 2 then return {} end
	end

	local cards = self.player:getCards("h")
	if not cards then return {} end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	local to_discard = {}

	local weapon = self.player:getWeapon()
	local armor = self.player:getArmor()
	local offensive_horse = self.player:getOffensiveHorse()
	local defensive_horse = self.player:getDefensiveHorse()

	if reason == "danshu" then
		for _, card in ipairs(cards) do
			if #to_discard >= discard_num then break end
			table.insert(to_discard, card:getId())
		end
		return to_discard
	elseif optional then
		return {}
	end

	if include_equip and weapon and weapon:inherits("YitianSword") then
		table.insert(to_discard, weapon:getId())
		weapon = nil
	end

	if include_equip and armor and armor:inherits("SilverLion") and self.player:isWounded() then
		table.insert(to_discard, armor:getId())
		armor = nil
	end

	if include_equip and self:hasSkills(sgs.lose_equip_skill) and
		not (not self.player:getCards("e"):isEmpty() and self.player:isJilei(self.player:getCards("e"):first())) then
		if #to_discard < discard_num and armor then
			if armor:inherits("GaleShell") then table.insert(to_discard, armor:getId()) armor = nil
			elseif armor:inherits("SilverLion") and self.player:isWounded() then table.insert(to_discard, armor:getId()) armor = nil end
		end
		if #to_discard < discard_num and offensive_horse then table.insert(to_discard, offensive_horse:getId()) offensive_horse = nil end
		if #to_discard < discard_num and weapon then table.insert(to_discard, weapon:getId()) weapon = nil end
		if #to_discard < discard_num and defensive_horse then table.insert(to_discard, defensive_horse:getId()) defensive_horse = nil end
		if #to_discard < discard_num and armor then table.insert(to_discard, armor:getId()) armor = nil end
	end

	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		if (not self.player:isJilei(card)) or (reason == "gongmou" and not card:inherits("Shit")) then
			table.insert(to_discard, card:getEffectiveId())
		end
	end

	if include_equip and
		not (not self.player:getCards("e"):isEmpty() and self.player:isJilei(self.player:getCards("e"):first())) then
		if #to_discard < discard_num and armor then
			if armor:inherits("GaleShell") then table.insert(to_discard, armor:getId()) armor = nil
			elseif armor:inherits("SilverLion") and self.player:isWounded() then table.insert(to_discard, armor:getId()) armor = nil end
		end
		if #to_discard < discard_num and offensive_horse then table.insert(to_discard, offensive_horse:getId()) end
		if #to_discard < discard_num and weapon then table.insert(to_discard, weapon:getId()) end
		if #to_discard < discard_num and defensive_horse then table.insert(to_discard, defensive_horse:getId()) end
		if #to_discard < discard_num and armor then table.insert(to_discard, armor:getId()) end
	end
	return to_discard
end

--- Determine that the current judge is worthy retrial
-- @param judge The JudgeStruct that contains the judge information
-- @return True if it is needed to retrial
function SmartAI:needRetrial(judge)
	local reason = judge.reason
--	if reason == "tsunami" or reason == "lightning" then return false end
	if reason == "houlue" or reason == "qimen" or reason == "huanshu1" then return false end
	if reason == "taohui" then
		if (self:isFriend(judge.who) and judge.card:inherits("BasicCard")) or
			(self:isEnemy(judge.who) and not judge.card:inherits("BasicCard")) then
			return true
		end
	end
	if reason == "yinyu" and self:getCardsNum("Slash", judge.who) > 1 then
		if (judge.card:getSuit() == sgs.Card_Spade and self:isEnemy(judge.who)) or
			(judge.card:getSuit() ~= sgs.Card_Spade and self:isFriend(judge.who)) then
			return true
		end
	end
	if self:isFriend(judge.who) then
		if not self.player:hasSkill("guidao") and judge.reason == "luoshen" and self:getOverflow(judge.who) > 1 and self.player:getHandcardNum() < 3
			and not self:isEquip("Crossbow", judge.who) then return false end
		return not judge:isGood()
	elseif self:isEnemy(judge.who) then
		return judge:isGood()
	else
		return false
	end
end

--- Get the retrial cards with the lowest keep value
-- @param cards the table that contains all cards can use in retrial skill
-- @param judge the JudgeStruct that contains the judge information
-- @return the retrial card id or -1 if not found
function SmartAI:getRetrialCardId(cards, judge)
	local can_use = {}
	for _, card in ipairs(cards) do
		if judge.reason == "yinyu" then
			if (self:isEnemy(judge.who) and card:getSuit() ~= sgs.Card_Spade) or
				(self:isFriend(judge.who) and card:getSuit() == sgs.Card_Spade) then
				table.insert(can_use, card)
			end
		elseif judge.reason == "taohui" then
			if (self:isFriend(judge.who) and not card:inherits("BasicCard")) or
				(self:isEnemy(judge.who) and card:inherits("BasicCard")) then
				table.insert(can_use, card)
			end
		elseif self:isFriend(judge.who) and judge:isGood(card) then
			table.insert(can_use, card)
		elseif self:isEnemy(judge.who) and not judge:isGood(card) then
			table.insert(can_use, card)
		end
	end

	if next(can_use) then
		self:sortByKeepValue(can_use, true)
		return can_use[1]:getEffectiveId()
	else
		return -1
	end
end

sgs.ai_skill_playerchosen = {}

function SmartAI:askForPlayerChosen(targets, reason)
	self:log("askForPlayerChosen:"..reason)
	local playerchosen = sgs.ai_skill_playerchosen[string.gsub(reason,"%-","_")]
	local target
	if type(playerchosen) == "function" then
		target = playerchosen(self,targets)
	end
	if target then
		return target
	else
		local r = math.random(0, targets:length() - 1)
		return targets:at(r)
	end
end

-- used for SmartAI:askForChoice
sgs.ai_skill_choice = {}

function SmartAI:askForChoice(skill_name, choices)
	local choice = sgs.ai_skill_choice[skill_name]
	if type(choice) == "string" then
		return choice
	elseif type(choice) == "function" then
		return choice(self, choices)
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		if skill and choices:match(skill:getDefaultChoice(self.player)) then
			return skill:getDefaultChoice(self.player)
		else
			local choice_table = choices:split("+");
			local r = math.random(1, #choice_table)
			return choice_table[r]
		end
	end
end

function SmartAI:isNoZhenshaMark()
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(player) and not player:isKongcheng() and player:getMark("@vi") > 0 then return false end
	end
	return true
end

function SmartAI:getUnuseCard()
	if self.player:isNude() then return nil end
	if self:isEquip("SilverLion") and self.player:isWounded() then
		return card
	elseif self.player:getHandcardNum() > self.player:getHp() or
		(not self.player:isKongcheng() and self.player:getHp() > 1) then
		local cards = self.player:getHandcards()
		cards=sgs.QList2Table(cards)
		for _, acard in ipairs(cards) do
			if (acard:inherits("BasicCard") or acard:inherits("EquipCard") or acard:inherits("AmazingGrace"))
				and not acard:inherits("Peach") and not acard:inherits("Analeptic") then
				return acard
			elseif acard:inherits("Disaster") or acard:inherits("EventsCard") then
				return acard
			end
		end
	elseif self.player:hasEquip() then
		local player=self.player
		if player:getWeapon() then return player:getWeapon()
		elseif player:getOffensiveHorse() then return player:getOffensiveHorse()
		elseif player:getDefensiveHorse() then return player:getDefensiveHorse()
		elseif player:getArmor() and player:getHandcardNum()<=1 then return player:getArmor()
		end
	else
		local cards = self.player:getCards("he")
		cards=sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		return cards[1]
	end
end

function SmartAI:getCardRandomly(who, flags)
	local cards = who:getCards(flags)
	if cards:isEmpty() then return end
	local r = math.random(0, cards:length()-1)
	local card = cards:at(r)
	if self:isEquip("SilverLion", who) then
		if self:isEnemy(who) and who:isWounded() and card == who:getArmor() then
			if r ~= (cards:length()-1) then
				card = cards:at(r+1)
			else
				card = cards:at(r-1)
			end
		end
	end
	if self:isEquip("GaleShell", who) then
		if self:isEnemy(who) and card == who:getArmor() then
			if r ~= (cards:length()-1) then
				card = cards:at(r+1)
			else
				card = cards:at(r-1)
			end
		end
	end
	return card:getEffectiveId()
end

sgs.ai_skill_cardchosen = {}
function SmartAI:askForCardChosen(who, flags, reason)
	self.room:output(reason)
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason,"%-","_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, who)
	end
	if card then
		return card:getId()
	end

	if reason == "yixing" and self.yixingcid then return self.yixingcid end
	if self:isFriend(who) then
		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:inherits("Lightning") then
					lightning = trick:getId()
				elseif trick:inherits("Indulgence") or trick:getSuit() == sgs.Card_Diamond then
					indulgence = trick:getId()
				else
					supply_shortage = trick:getId()
				end
			end


			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if flags:match("e") then
			local qiaodaoqing = self.room:findPlayerBySkillName("huanshu")
			if who:isWounded() and self:isEquip("SilverLion", who) and (not qiaodaoqing or self:isFriend(qiaodaoqing))
				then return who:getArmor():getId() end
			if self:isEquip("GaleShell", who) then return who:getArmor():getId() end
			if self:hasSkills(sgs.lose_equip_skill, who) then
				local equips = who:getEquips()
				if not equips:isEmpty() then
					return equips:at(0):getId()
				end
			end
		end
	else
		if flags:match("e") then
			if self:isEquip("Crossbow",who) then
				for _, friend in ipairs(self.friends) do
					if who:distanceTo(friend) <= 1 then return who:getWeapon():getId() end
				end
			end

			self:sort(self.friends, "hp")
			local friend = self.friends[1]
			if self:isWeak(friend) and who:inMyAttackRange(friend) then
				if who:getWeapon() and who:distanceTo(friend) > 1 then return who:getWeapon():getId() end
				if who:getOffensiveHorse() and who:distanceTo(friend) > 1 then return who:getOffensiveHorse():getId() end
			end

			if who:getDefensiveHorse() then
				for _,friend in ipairs(self.friends) do
					if friend:distanceTo(who) == friend:getAttackRange()+1 then
						return who:getDefensiveHorse():getId()
					end
				end
			end

			if who:getArmor() and self:evaluateArmor(who:getArmor(),who)>3 then
				return who:getArmor():getId()
			end

			if self:isEquip("Monkey", who) then
				return who:getOffensiveHorse():getId()
			end
		end

		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning
			for _, trick in sgs.qlist(tricks) do
				if trick:inherits("Lightning") then
					lightning = trick:getId()
				end
			end
			if self:hasWizard(self.enemies,true) and lightning then
				return lightning
			end
		end

		if flags:match("e") then
			if who:getArmor() and self:evaluateArmor(who:getArmor(), who)>0
				and not (who:getArmor():inherits("SilverLion") and self:isWeak(who)) then
				return who:getArmor():getId()
			end

			if who:getWeapon() then
				if not (who:hasSkill("cuihuo") and (who:getHandcardNum() >= who:getHp())) and not self:isEquip("YitianSword",who) then
					for _,friend in ipairs(self.friends) do
						if (who:distanceTo(friend) <= who:getAttackRange()) and (who:distanceTo(friend) > 1) then
							return who:getWeapon():getId()
						end
					end
				end
			end

			if who:getOffensiveHorse() then
				if who:hasSkill("cuihuo") and who:getHandcardNum() >= who:getHp() then
				else
					for _,friend in ipairs(self.friends) do
						if who:distanceTo(friend) == who:getAttackRange() and
						who:getAttackRange() > 1 then
							return who:getOffensiveHorse():getId()
						end
					end
				end
			end
		end
		if flags:match("h") then
			if not who:isKongcheng() then
				return -1
			end
		end
	end
	local new_flag = ""
	if flags:match("h") then new_flag = "h" end
	if flags:match("e") then new_flag = new_flag.."e" end
	return self:getCardRandomly(who, new_flag) or who:getCards(flags):first():getEffectiveId()
end

function SmartAI:askForCard(pattern, prompt, data)
	self.room:output(prompt)
	if sgs.ai_skill_invoke[pattern] then return sgs.ai_skill_invoke[pattern](self, prompt) end

	local target, target2
	if not prompt then return end
	local parsedPrompt = prompt:split(":")
	if parsedPrompt[2] then
		local others = self.room:getOtherPlayers(self.player)
		others = sgs.QList2Table(others)
		for _, other in ipairs(others) do
			if other:getGeneralName() == parsedPrompt[2] or other:objectName() == parsedPrompt[2] then target = other break end
		end
		if parsedPrompt[3] then
			for _, other in ipairs(others) do
				if other:getGeneralName() == parsedPrompt[3] or other:objectName() == parsedPrompt[3] then target2 = other break end
			end
		end
	end

	if parsedPrompt[1] == "@xiuluo" then
		local hand_card = self.player:getHandcards()
		for _, card in sgs.qlist(hand_card) do
			if card:getSuitString() == parsedPrompt[2] then return "$"..card:getEffectiveId() end
		end
	elseif parsedPrompt[1] == "@xiagu" then
		local damage = data:toDamage()
		if self:isFriend(damage.to) then
			if damage.to:hasSkill("fushang") and
				damage.to:getMaxHP() > 3 and damage.damage < 2 then return "." end
			local allcards = self.player:getCards("he")
			for _, card in sgs.qlist(allcards) do
				if card:inherits("EquipCard") then
					return card:getEffectiveId()
				end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@fuhu" then
		local damage = data:toDamage()
		if self:isEnemy(damage.from) then
			local cards = self.player:getHandcards()
			for _, card in sgs.qlist(cards) do
				if card:inherits("BasicCard") then
					return card:getEffectiveId()
				end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@jiachu" then
		local target = self.room:getLord()
		if self:isFriend(target) then
			local allcards = self.player:getCards("he")
			for _, card in sgs.qlist(allcards) do
				if card:getSuit() == sgs.Card_Heart then
					return card:getEffectiveId()
				end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@baoguo" then
		if self.player:hasSkill("fushang") and self.player:getHp() > 3 then return "." end 
		local damage = data:toDamage()
		if self:isFriend(damage.to) and not self.player:isKongcheng() then
			local pile = self:getCardsNum("Peach") + self:getCardsNum("Analeptic")
			local dmgnum = damage.damage
			if self.player:getHp() + pile - dmgnum > 0 then
				if self.player:getHp() + pile - dmgnum == 1 and pile > 0 then return "." end
				local card = self:getUnuseCard()
				if card then return card:getEffectiveId() end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@chiyuan" then
		local rv = data:toRecover()
		local cards = self.player:getCards("he")
		cards=sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		if self:isEnemy(rv.who) then
			return cards[1]:getEffectiveId()
		end
		return "."
	elseif parsedPrompt[1] == "@xianji" or parsedPrompt[1] == "@fuji" then
		local who = data:toPlayer()
		if self:isFriend(who) or self.player:isKongcheng() then return "." end
		return self.player:getRandomHandCard():getEffectiveId() or "."
	elseif parsedPrompt[1] == "@jishi" then
		local who = data:toPlayer()
		if self:isEnemy(who) or self.player:isKongcheng() then return "." end
		return self.player:getRandomHandCard():getEffectiveId() or "."
	elseif parsedPrompt[1] == "@zhensha" then
		local carduse = data:toCardUse()
		if self:isFriend(carduse.from) then return "." end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if fcard:getSuit() == sgs.Card_Spade then
				if carduse.from:isLord() or carduse.from:getHp() > 1 then
					return fcard:getEffectiveId()
				end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@chumai" then
		local target = data:toPlayer()
		if self:isEnemy(target) then
			local cards = self.player:getHandcards()
			for _, card in sgs.qlist(cards) do
				if card:isBlack() then
					return card:getEffectiveId()
				end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@zhangshi" then
		if not self:isFriend(sgs.zhangshisource) then return "." end
		return self:getCardId("Slash") or "."
	elseif parsedPrompt[1] == "@guizi" then
		local dy = data:toDying()
		if self:isEnemy(dy.who) then
			local cards = self.player:getCards("he")
			for _, card in sgs.qlist(cards) do
				if card:getSuit() == sgs.Card_Spade then
					return card:getEffectiveId()
				end
			end
		end
		return "."
	elseif parsedPrompt[1] == "@zhiyuan" then
		local lord = self.room:getLord()
		if self:isFriend(lord) and not self.player:isKongcheng() then
			return self.player:getRandomHandCard():getEffectiveId() or "."
		end
		return "."
	elseif parsedPrompt[1] == "@baoen" then
		local rev = data:toRecover()
		local card = self:getUnuseCard()
		if self:isEnemy(rev.who) or not card then return "." end
		return card:getEffectiveId() or "."
	elseif parsedPrompt[1] == "@hengchong" then
		local effect = data:toSlashEffect()
		if self:isFriend(effect.to) and not self:hasSkills(sgs.masochism_skill, effect.to) then
			return "."
		end
		local caninvoke = false
		for _, target in sgs.qlist(self.room:getNextandPrevious(effect.to)) do
			if self:isEnemy(target) then
				caninvoke = true
				break
			end
		end
		if caninvoke then
			local cards = self.player:getCards("he")
			cards = sgs.QList2Table(cards)
			self:sortByUseValue(cards, true)
			for _, card in ipairs(cards) do
				if card:getSuit() == effect.slash:getSuit() then
					return card:getEffectiveId()
				end
			end
		end
		return "."
	end

	if parsedPrompt[1] == "double-sword-card" then
		if target and self:isFriend(target) then return "." end
		local cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:inherits("Slash") or card:inherits("Shit") or card:inherits("Collateral") or card:inherits("GodSalvation")
			or card:inherits("Lightning") or card:inherits("EquipCard") or card:inherits("AmazingGrace") then
				return "$"..card:getEffectiveId()
			end
		end
		return "."
	elseif parsedPrompt[1] == "@axe" then
		if target and self:isFriend(target) then return "." end

		local allcards = self.player:getCards("he")
		allcards = sgs.QList2Table(allcards)
		if self.player:hasFlag("drank") or #allcards-2 >= self.player:getHp() or (self.player:hasSkill("kuanggu") and self.player:isWounded()) then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards)
			local index
			if self:hasSkills(sgs.need_kongcheng) then index = #cards end
			if self.player:getOffensiveHorse() then
				if index then
					if index < 2 then
						index = index + 1
						table.insert(cards, self.player:getOffensiveHorse())
					end
				end
				table.insert(cards, self.player:getOffensiveHorse())
			end
			if self.player:getArmor() then
				if index then
					if index < 2 then
						index = index + 1
						table.insert(cards, self.player:getArmor())
					end
				end
				table.insert(cards, self.player:getArmor())
			end
			if self.player:getDefensiveHorse() then
				if index then
					if index < 2 then
						index = index + 1
						table.insert(cards, self.player:getDefensiveHorse())
					end
				end
				table.insert(cards, self.player:getDefensiveHorse())
			end
			if #cards >= 2 then
				self:sortByUseValue(cards, true)
				return "$"..cards[1]:getEffectiveId().."+"..cards[2]:getEffectiveId()
			end
		end
	end

	if self.player:hasSkill("tianxiang") then
		local dmgStr = {damage = 1, nature = 0}
		local willTianxiang = sgs.ai_skill_use["@tianxiang"](self, dmgStr)
		if willTianxiang ~= "." then return "." end
	elseif self.player:hasSkill("longhun") and self.player:getHp() > 1 then
		return "."
	end

	if pattern == "slash" then
		if parsedPrompt[1] == "@wushuang-slash-1" and self:getCardsNum("Slash") < 2 and
			not (self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng)) then return "." end
		if parsedPrompt[1] == "collateral-slash" then
			if target and (not self:isFriend(target2) or target2:getHp() > 2 or self:getCardsNum("Jink", targets2) > 0)and not self:hasSkills(sgs.lose_equip_skill) then
				local slash = self:getCardId("Slash")
				if not self:slashProhibit(sgs.Card_Parse(slash), target2) then return slash end
			end
			self:speak("collateral", self.player:getGeneral():isFemale())
			return "."
		elseif (parsedPrompt[1] == "duel-slash") then
			if (not self:isFriend(target) and self:getCardsNum("Slash")*2 >= target:getHandcardNum())
				or (target:getHp() > 2 and self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0)
				then return self:getCardId("Slash")
			else return "." end
		elseif (parsedPrompt[1] == "@zhangshi") then
			if target and self:isFriend(target) then
				if (self.player:hasSkill("longdan") and self:getCardsNum("Jink") > 1) then
					self:speak("zhangshi", self.player:getGeneral():isFemale())
					return self:getCardId("Slash")
				end
			else return "." end
		elseif parsedPrompt[1] == "savage-assault-slash" then
			if not self:damageIsEffective(nil, nil, target) then return "." end
			local aoe = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit , 0)
			if (self.player:getHp()>1 or self:getAllPeachNum()>0 and not self.player:containsTrick("indulgence"))
				or (self.player:hasSkill("yiji")) and self.player:getHp() > 2 then return "." end
			if target and target:hasSkill("guagu") and self.player:isLord() then return "." end
			if self.player:hasSkill("jieming") and self:getJiemingChaofeng() <= -6 and self.player:getHp() >= 2 then return "." end
		end
		return self:getCardId("Slash") or "."
	elseif pattern == "jink" then
		if parsedPrompt[1] == "@assas1"	and self:getCardsNum("Jink") < 2 then return "." end
		if parsedPrompt[1] == "archery-attack-jink" then
			if not self:damageIsEffective(nil, nil, target) then return "." end
		end
		if target then
			if self:isFriend(target) then
				if parsedPrompt[1] == "archery-attack-jink"  then
					local aoe = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit , 0)
					if (self.player:getHp()>1 or self:getAllPeachNum()>0 and not self.player:containsTrick("indulgence"))
						or (self.player:hasSkill("yiji")) and self.player:getHp() > 2 then return "." end

				end
				if self.player:hasSkill("jieming") and self:getJiemingChaofeng() <= -6 then return "." end
				if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
				if target:hasSkill("huatian") then return "." end
			else
				if not target:hasFlag("drank") then
					if target:hasSkill("mengjin") and self.player:hasSkill("jijiu") then return "." end
				else
					return self:getCardId("Jink") or "."
				end
				if not self:hasSkills(sgs.need_kongcheng, player) then
					if self:isEquip("Axe", target) then
						if self:hasSkills(sgs.lose_equip_skill, target) and target:getEquips():length() > 1 then return "." end
						if target:getHandcardNum() - target:getHp() > 2 then return "." end
					elseif self:isEquip("Blade", target) then
						if self:getCardsNum("Jink") <= self:getCardsNum("Slash", target) then return "." end
					end
				end

			end
		end
		
		if self:getDamagedEffects(self) then return "." end
		return self:getCardId("Jink") or "."
	elseif pattern == "fuckgaolian" then
		local judge = data:toJudge()
		local fuck = self:getCard("FuckGaolian")
		if self:needRetrial(judge) then
			local cards = {}
			table.insert(cards, fuck)
			local card_id = self:getRetrialCardId(cards, judge)
			if card_id ~= -1 then
				return fuck:getEffectiveId()
			end
		end
		return "."
	end
end

sgs.ai_skill_askforag = {}
function SmartAI:askForAG(card_ids, refusable, reason)
	local cardchosen = sgs.ai_skill_askforag[string.gsub(reason, "%-", "_")]
	if type(cardchosen) == "function" then
		local card_id = cardchosen(self, card_ids)
		if card_id then return card_id end
	end

	if refusable and self:hasSkill("xinzhan") then
		local next_player = self.player:getNextAlive()
		if self:isFriend(next_player) and next_player:containsTrick("indulgence") then
			if #card_ids == 1 then return -1 end
		end
		for _, card_id in ipairs(card_ids) do
			if not sgs.Sanguosha:getCard(card_id):inherits("Shit") then return card_id end
		end
		return -1
	end
	local ids = card_ids
	local cards = {}
	for _, id in ipairs(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByCardNeed(cards, true)
	if #cards == 0 then return -1 end
	return cards[#cards]:getEffectiveId()
end

function SmartAI:askForNullification(trick_name, from, to, positive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local null_card
	null_card = self:getCardId("Nullification")
	if null_card then null_card = sgs.Card_Parse(null_card) else return end

	if positive then
		if from and self:isEnemy(from) then
			if trick_name:inherits("ExNihilo") and self:getOverflow(from) == 0 then return null_card end
			if trick_name:inherits("IronChain") and not self:isEquip("Vine", to) then return nil end
			if self:isFriend(to) then
				if trick_name:inherits("Dismantlement") then
					if to:getArmor() then return null_card end
				else
					if trick_name:inherits("Snatch") then return null_card end
					if self:isWeak(to) then
						if trick_name:inherits("Duel") then
							return null_card
						elseif trick_name:inherits("FireAttack") then
							if from:getHandcardNum() > 2 then return null_card end
						end
					end
				end
			elseif self:isEnemy(to) then
				if (trick_name:inherits("Snatch") or trick_name:inherits("Dismantlement")) and to:getCards("j"):length() > 0 then
					return null_card
				end
			end
		end

		if self:isFriend(to) and not null_card:objectName() == "counterplot" then
			if trick_name:inherits("Indulgence") or trick_name:inherits("SupplyShortage") then
				return null_card
			end
			if self:isWeak(to) then
				if trick_name:inherits("ArcheryAttack") then
					if self:getCardsNum("Jink", to) == 0 then return null_card end
				elseif trick_name:inherits("SavageAssault") then
					if self:getCardsNum("Slash", to) == 0 then return null_card end
				end
			end
		end
		if from and not null_card:objectName() == "counterplot" then
			if self:isEnemy(to) then
				if trick_name:inherits("GodSalvation") and self:isWeak(to) then
					return null_card
				end
			end
		end
	else
		if from then
			if from:objectName() == to:objectName() then
				if self:isFriend(from) then return null_card
				else return nil end
			end
			if not (trick_name:inherits("AmazingGrace") or trick_name:inherits("GodSalvation") or trick_name:inherits("AOE")) then
				if self:isFriend(from) then return null_card end
			end
		else
			if self:isEnemy(to) then return null_card else return end
		end
	end
end

function SmartAI:askForSinglePeach(dying)
	local card_str

	if self:isFriend(dying) then
		if (self.player:objectName() == dying:objectName()) then
			card_str = self:getCardId("Analeptic") or self:getCardId("Peach")
		else
			card_str = self:getCardId("Peach")
		end
	end

	return card_str or "."
end

function SmartAI:askForSuit()
	return math.min(math.floor(math.random(0,8)/2),3)
end

function SmartAI:askForPindian(requestor, reason)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local compare_func = function(a, b)
		return a:getNumber() < b:getNumber()
	end
	table.sort(cards, compare_func)
	local maxcard, mincard, minusecard
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then mincard = card break end
	end
	for _, card in ipairs(sgs.reverse(cards)) do
		if self.player:hasSkill("changsheng") and card:getSuit() == sgs.Card_Spade then
			maxcard = card
			break
		end
	end
	for _, card in ipairs(sgs.reverse(cards)) do
		if self:getUseValue(card) < 6 then maxcard = card break	end
	end
	self:sortByUseValue(cards, true)
	minusecard = cards[1]
	maxcard = maxcard or minusecard
	mincard = mincard or minusecard
	if self:isFriend(requestor) then return mincard end
	if ("dalei|xianzhen"):match(reason) then
		if requestor:getHandcardNum() > 2 then return maxcard else return minusecard end
	end
	return maxcard
end

function SmartAI:getChainedFriends()
	local chainedFriends = {}
	for _, friend in ipairs(self.friends) do
		if friend:isChained() then
			table.insert(chainedFriends,friend)
		end
	end
	return chainedFriends
end

function SmartAI:getChainedEnemies()
	local chainedEnemies = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:isChained() then
			table.insert(chainedEnemies,enemy)
		end
	end
	return chainedEnemies
end

function SmartAI:hasSkill(skill)
	local skill_name = skill
	if type(skill) == "table" then
		skill_name = skill.name
	end

	local real_skill = sgs.Sanguosha:getSkill(skill_name)
	if real_skill and real_skill:isLordSkill() then
		return self.player:hasLordSkill(skill_name)
	else
		return self.player:hasSkill(skill_name)
	end
end

function SmartAI:fillSkillCards(cards)
	local i = 1
	while i <= #cards do
		if prohibitUseDirectly(cards[i], self.player) then
			table.remove(cards, i)
		else
			i = i + 1
		end
	end
	for _,skill in ipairs(sgs.ai_skills) do
		if self:hasSkill(skill) then
			local skill_card = skill.getTurnUseCard(self)
			if #cards == 0 then skill_card = skill.getTurnUseCard(self,true) end
			if skill_card then table.insert(cards, skill_card) end
		end
	end
end

function SmartAI:useSkillCard(card,use)
	local name
	if card:inherits("LuaSkillCard") then
		name = "#" .. card:objectName()
	else
		name = card:className()
	end
	sgs.ai_skill_use_func[name](card, use, self)
	if use.to then
		if not use.to:isEmpty() and sgs.dynamic_value.damage_card[name] then
			for _, target in sgs.qlist(use.to) do
				if self:damageIsEffective(target) then return end
			end
			use.card = nil
		end
	end
	if not use.card then return end
	local subcards = sgs.QList2Table(use.card:getSubcards())
	local shit = 0
	if #subcards > 0 then
		for _, card in ipairs(subcards) do
			if sgs.Sanguosha:getCard(card):inherits("Shit") then shit = shit + 1 end
		end
	end
	if shit - self.player:getHp() > self:getAllPeachNum() then use.card = nil end
end

sgs.ai_skill_use_func = {}
sgs.ai_skills = {}

function SmartAI:cardNeed(card)
	local class_name = card:className()
	local suit_string = card:getSuitString()
	local value
	if card:inherits("Peach") then
		self:sort(self.friends,"hp")
		if self.friends[1]:getHp() < 2 then return 10 end
		if (self.player:getHp() < 3 or self.player:getLostHp() > 1 and not self:hasSkill("longhun")) or self:hasSkills("shouge|baoguo") then return 14 end
		return self:getUseValue(card)
	end
	if self:isWeak() and card:inherits("Jink") and self:getCardsNum("Jink") < self.player:getHp() then return 12 end
	if sgs[self.player:getGeneralName().."_keep_value"] then
		value = sgs[self.player:getGeneralName().."_keep_value"][class_name]
		if value then return value+4 end
	end
	if sgs[self.player:getGeneralName().."_suit_value"] then
		value = (sgs[self.player:getGeneralName().."_suit_value"][suit_string])
		if value then return value+4 end
	end

	if card:inherits("Jink") and self:getCardsNum("Jink") == 0 then return 5.9 end
	if card:inherits("Analeptic") then
		if self.player:getHp() < 2 then return 10 end
	end
	if card:inherits("Slash") and (self:getCardsNum("Slash") > 0) then return 4 end
	if card:inherits("Weapon") and (not self.player:getWeapon()) and (self:getCardsNum("Slash") > 1) then return 6 end
	if card:inherits("Nullification") and self:getCardsNum("Nullification") == 0 then
		if self.player:containsTrick("indulgence") or self.player:containsTrick("supply_shortage") then return 10 end
		for _,friend in ipairs(self.friends) do
			if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then return 7 end
		end
		return 6
	end
	return self:getUseValue(card)
end

sgs.ai_cardshow = {}
function SmartAI:askForCardShow(requestor, reason)
	local func = sgs.ai_cardshow[reason]
	if func then
		return func(self, requestor)
	else
		return self.player:getRandomHandCard()
	end
end

sgs.ai_cardshow.fire_attack = function(self, requestor)
	local priority  =
	{
	heart = 4,
	spade = 3,
	club = 2,
	diamond = 1
	}
	local index = 0
	local result
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if priority[card:getSuitString()] > index then
			result = card
			index = priority[card:getSuitString()]
		end
	end

	return result
end

function SmartAI:hasTrickEffective(card, player)
	if player then
		if (player:hasSkill("shudan") and self.room:getTag("Shudan"):toString() == player:objectName()) or player:hasSkill("wuyan") then
			if card and not (card:inherits("Indulgence") or card:inherits("SupplyShortage")) then return false end
		end
		if player:hasSkill("foyuan") and self.player:getGeneral():isMale() and not self.player:hasEquip() then
			return false
		end
		if player:hasSkill("fenhui") and (self.player:hasSkill("fenhui") or card:inherits("FireAttack") or card:inherits("FireSlash")) then
			return false
		end
		if player:hasSkill("jueming") and player ~= self.room:getCurrent() and card:inherits("Duel") or card:inherits("Assassinate") then
			return false
		end
	end
	return true
end

function SmartAI:hasSameEquip(card, player)
	player = player or self.player
	if not player:hasEquip() then return false end
	if card:inherits("Weapon") then
		if player:getWeapon() then return true end
	elseif card:inherits("Armor") then
		if player:getArmor() then return true end
	elseif card:inherits("DefensiveHorse") then
		if player:getDefensiveHorse() then return true end
	elseif card:inherits("OffensiveHorse") then
		if player:getOffensiveHorse() then return true end
	end
	return false
end

sgs.lose_equip_skill = "cuihuo|jiebei"
sgs.need_kongcheng = "kongmen|wanku"
sgs.masochism_skill = "baoguo|fuqin|xiaozai|huatian|heidian|cuju|huanshu"
sgs.wizard_skill = "zhaixing|butian|shenpan|yixing|yueli|houlue"
sgs.wizard_harm_skill = "zhaixing|butian|shenpan|yixing"

function SmartAI:hasSkills(skill_names, player)
	player = player or self.player
	for _, skill_name in ipairs(skill_names:split("|")) do
		if player:hasSkill(skill_name) then
			return true
		end
	end
end

function SmartAI:isEquip(equip_name, player)
	player = player or self.player
	local cards = player:getCards("e")
	for _, card in sgs.qlist(cards) do
		if card:inherits(equip_name) then return true end
	end
	if equip_name == "EightDiagram" and player:hasSkill("bazhen") and not player:getArmor() then return true end
	return false
end

function SmartAI:getCardId(class_name, player)
	player = player or self.player
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUsePriority(cards)
	local card_str = zeroCardView(class_name, player)
	if card_str then return card_str end

	for _, card in ipairs(cards) do
		local card_place = self.room:getCardPlace(card:getEffectiveId())
		if card:inherits(class_name) and not prohibitUseDirectly(card, player) then
			return card:getEffectiveId()
		elseif isCompulsoryView(card, class_name, player, card_place) then
			return isCompulsoryView(card, class_name, player, card_place)
		end
	end
	for _, card in ipairs(cards) do
		local card_place = self.room:getCardPlace(card:getEffectiveId())
		card_str = getSkillViewCard(card, class_name, player, card_place)
		if card_str then return card_str end
	end
end

function SmartAI:getJiemingChaofeng(player)
	local max_x , chaofeng = 0 , 0
	for _, friend in ipairs(self:getFriends(player)) do
		local x = math.min(friend:getMaxHP(), 5) - friend:getHandcardNum()
		if x > max_x then
			max_x = x
		end
	end
	if max_x < 2 then
		chaofeng = 5 - max_x * 2
	else
		chaofeng = (-max_x) * 2
	end
	return chaofeng
end

function SmartAI:getOverflow(player)
	player = player or self.player
	return math.max(player:getHandcardNum() - player:getHp(), 0)
end

function SmartAI:hasSuit(suit_strings, include_equip, player)
	return self:getSuitNum(suit_strings, include_equip, player) > 0
end

function SmartAI:getSuitNum(suit_strings, include_equip, player)
	player = player or self.player
	local n = 0
	local flag = "h"
	if include_equip then flag = "he" end
	local allcards = player:getCards(flag)
	for _, card in sgs.qlist(allcards) do
		for _, suit_string in ipairs(suit_strings:split("|")) do
			if card:getSuitString() == suit_string then
				n = n + 1
			end
		end
	end
	return n
end

function SmartAI:isWeak(player)
	player = player or self.player
	return ((player:getHp() <= 2 and player:getHandcardNum() <= 2) or player:getHp() <= 1)
end

function SmartAI:getAoeValue(card, player)
	player = player or self.player
	friends_noself = self:getFriendsNoself(player)
	enemies = self:getEnemies(player)
	local good, bad = 0, 0
	for _, friend in ipairs(friends_noself) do
		good = good + self:getAoeValueTo(card, friend, player)
	end

	for _, enemy in ipairs(enemies) do
		bad = bad + self:getAoeValueTo(card, enemy, player)
	end

	return good - bad
end

function SmartAI:getAoeValueTo(card, to , from)
	if not from then from = self.player end
	local value = 0
	local sj_num

	if to:hasSkill("yuanyin") then
		value = value + 5
	end

	if to:hasSkill("longjiao") then
		value = value + 5
	end

	if card:inherits("SavageAssault") then
		sj_num = self:getCardsNum("Slash", to)
		if to:hasSkill("juxiang") then
			value = value + 20
		end
	end
	if card:inherits("ArcheryAttack") then
		sj_num = self:getCardsNum("Jink", to)
	end

	if self:aoeIsEffective(card, to) then
		if to:getHp() > 1 or (self:getCardsNum("Peach", to) + self:getCardsNum("Analeptic", to) > 0) then
			if to:hasSkill("yiji") or to:hasSkill("jianxiong") then
				value = value + 20
			end
			if to:hasSkill("heidian") or to:hasSkill("huanshu") or to:hasSkill("cuju") then
				if not self:isFriend(from, to) then
					value = value + 10
				else
					value = value - 10
				end
			end
		end

		if card:inherits("ArcheryAttack") then
			sj_num = self:getCardsNum("Jink", to)
			if (to:hasSkill("kongying") and self:getCardsNum("Jink", to) > 0) or self:isEquip("EightDiagram", to) then
				value = value + 30
				if self:hasSuit("spade", true, to) then
					value = value + 20
				end
			end
			if to:hasSkill("qiaojiang") or self:isEquip("EightDiagram", to) then
				value = value + 10
			end
		end

		if to:getHp() ~= 0 then
			value = value - 24 / to:getHp() - 10
		end

		if self:isFriend(from, to) then
		if to:isLord() or from:isLord() then
				if to:getHp() <= 1 and self:getCardsNum("Peach", from) == 0 and sj_num == 0 then
					if to:getRole() == "renegade" then
						value = value - 50
					else
						value = value - 150
					end
				end
			end
			value = value + self:getCardsNum("Peach", from) * 2
		elseif to:getRole() == "rebel" or (to:isLord() and from:getRole() == "rebel") then
			if to:getHp() <= 1 and self:getCardsNum("Peach", to) == 0 and sj_num == 0 then
				value = value - 50
			end
		end
	else
		value = value + 10
	end

	return value
end

function SmartAI:getCard(class_name, player)
	player = player or self.player
	local card_id = self:getCardId(class_name, player)
	if card_id then return sgs.Card_Parse(card_id) end
end

function getCards(class_name, player, room, flag)
	flag = flag or "he"
	local cards = {}
	local card_place, card_str
	if not room then card_place = sgs.Player_Hand end

	for _, card in sgs.qlist(player:getCards(flag)) do
		card_place = card_place or room:getCardPlace(card:getEffectiveId())

		if class_name == "." then table.insert(cards, card)
		elseif isCompulsoryView(card, class_name, player, card_place) then
			cards_str = isCompulsoryView(card, class_name, player, card_place)
			card_str = sgs.Card_Parse(card_str)
			table.insert(cards, card_str)
		elseif card:inherits(class_name) and not prohibitUseDirectly(card, player) then table.insert(cards, card)
		elseif getSkillViewCard(card, class_name, player, card_place) then
			cards_str = getSkillViewCard(card, class_name, player, card_place)
			card_str = sgs.Card_Parse(card_str)
			table.insert(cards, card_str)
		end
	end
	return cards
end

function SmartAI:getCards(class_name, player, flag)
	player = player or self.player
	return getCards(class_name, player, self.room, flag)
end

function getCardsNum(class_name, player)
	return #getCards(class_name, player)
end

function SmartAI:getCardsNum(class_name, player, flag, selfonly)
	player = player or self.player
	local n = 0
	if type(class_name) == "table" then
		for _, each_class in ipairs(class_name) do
			n = n + #getCards(each_class, player, self.room, flag)
		end
		return n
	end
	n = #getCards(class_name, player, self.room, flag)

	if selfonly then return n end
	if class_name == "Jink" then
		if player:hasSkill("yuanyin") then
			for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
				local equips = target:getEquips()
				for _,equip in sgs.qlist(equips) do
					if not equip:inherits("Weapon") then
						n = n + 1
					end
				end
			end
		end
		if player:hasSkill("shunshui") then
			for _, target in sgs.qlist(self.room:getAllPlayers()) do
				local juds = target:getJudgingArea():length()
				n = n + juds
			end
		end
	elseif class_name == "Slash" then
		if player:hasSkill("wushuang") then
			n = n * 2
		end
		if player:hasSkill("yuanyin") then
			for _, target in sgs.qlist(self.room:getOtherPlayers(player)) do
				if target:getWeapon() then
					n = n + 1
				end
			end
		end
		if player:hasSkill("zhangshi") then
			local lieges = self.room:getMenorWomen("male")
			for _, liege in sgs.qlist(lieges) do
				if self:isFriend(liege, player) then
				n = n + self:getCardsNum("Slash", liege, nil, liege:hasSkill("zhangshi"))
				end
			end
		end
	end
	return n
end

function SmartAI:cardProhibit(card, to)
	if card:inherits("Slash") then return self:slashProhibit(card, to) end
	if card:getTypeId() == sgs.Card_Trick then
		if to:hasSkill("shengui") and not to:faceUp() and self.player:getGeneral():isMale() then return true end
		if card:inherits("Dismantlement") or card:inherits("Snatch") and to:hasSkill("linse") then return true end
		if card:inherits("SupplyShortage") or card:inherits("Snatch") and to:hasSkill("feiyan") then return true end
		if card:inherits("Duel") and to:hasSkill("fangzhen") and self.player:getHp() > to:getHp() then return true end
		if to ~= self.room:getCurrent() and card:inherits("Duel") or card:inherits("Assassinate") and to:hasSkill("jueming") and to:getHp() == 1 then return true end
	end
	return false
end

function SmartAI:getDamagedEffects(self, player)
	player = player or self.player
	
	if player:getHp() > 1 and self:hasSkills(sgs.masochism_skill, player) then
		local attacker = self.room:getCurrent()
		if self:isEnemy(attacker, player) and attacker:getHp() <= 1 then
			if self:hasSkills("heidian|huanshu", player) then return true end
		end
		
		if player:hasSkill("jieming") then
			for _, friend in ipairs(self:getFriends(player)) do
				if math.min(friend:getMaxHP(), 5) - friend:getHandcardNum() >= 3 then return true end
			end
		elseif player:hasSkill("qiaodou") then
			return true
		end
	end
	
	return false
end

function SmartAI:assignKeep(num,start)
	if num<=0 then return end
	if start then 
		self.keepValue={}
		self.kept={}
	end
	local cards=self.player:getHandcards()
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards,true,self.kept)
	for _,card in ipairs(cards) do
		if not self.keepValue[card:getId()] then
			self.keepValue[card:getId()]=self:getKeepValue(card,self.kept)
			table.insert(self.kept,card)
			--self:log(card:className())
			self:assignKeep(num-1)
			break
		end
	end
end

function SmartAI:log(outString)
	self.room:output(outString)
end

-- load other ai scripts
dofile "lua/ai/standard-skill-ai.lua"
dofile "lua/ai/plough-ai.lua"
dofile "lua/ai/tocheck-ai.lua"
dofile "lua/ai/qjwm-ai.lua"
dofile "lua/ai/xzdd-ai.lua"
dofile "lua/ai/ttxd-ai.lua"
dofile "lua/ai/bwqz-ai.lua"
dofile "lua/ai/qlfd-ai.lua"
dofile "lua/ai/zcyn-ai.lua"
dofile "lua/ai/cgdk-ai.lua"
dofile "lua/ai/sp-ai.lua"
--dofile "lua/ai/god-ai.lua"
dofile "lua/ai/events-ai.lua"
dofile "lua/ai/joy-ai.lua"

dofile "lua/ai/general_config.lua"
dofile "lua/ai/intention-ai.lua"
dofile "lua/ai/chat-ai.lua"
dofile "lua/ai/value_config.lua"

dofile "lua/ai/hulaoguan-ai.lua"
dofile "lua/ai/basara-ai.lua"
dofile "lua/ai/hegemony-ai.lua"

dofile "lua/ai/guanxing-ai.lua"

sgs.ai_skill_invoke["lianzang"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self.player:getMaxHP() < 4 then
		return false
	end
	return true
end

