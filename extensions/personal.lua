module("extensions.personal", package.seeall)
extension = sgs.Package("personal")

tianqi = sgs.General(extension, "tianqi", "god", 5, false)
tianyin = sgs.General(extension, "tianyin", "god", 3)
tianshuang = sgs.General(extension, "tianshuang", "god", 3)
tianlong = sgs.General(extension, "tianlong", "god", 3)

eatdeath=sgs.CreateTriggerSkill{
	name="eatdeath",
	frequency = sgs.Skill_NotFrequent,
	events={sgs.Death},

	can_trigger = function(self, player)
		return true
	end,

	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local tenkei = room:findPlayerBySkillName(self:objectName())
		if not tenkei then return false end

		local skillslist = tenkei:getTag("EatDeath"):toString()
		local eatdeath_skills = skillslist:split("+")
		if eatdeath_skills[1] == "" then table.remove(eatdeath_skills, 1) end

		if room:askForSkillInvoke(tenkei, self:objectName(), data) then
			if #eatdeath_skills > 0 and sgs.Sanguosha:getSkill(eatdeath_skills[1]) then
				local choice = room:askForChoice(tenkei, self:objectName(), table.concat(eatdeath_skills, "+"))
				room:detachSkillFromPlayer(tenkei, choice)
				for i = #eatdeath_skills, 1, -1 do
					if eatdeath_skills[i] == choice then
						table.remove(eatdeath_skills, i)
					end
				end
			end
			room:loseMaxHp(tenkei)
			local skills = player:getVisibleSkillList()
			for _, skill in sgs.qlist(skills) do
				if skill:getLocation() == sgs.Skill_Right then
					if skill:getFrequency() ~= sgs.Skill_Limited and
						skill:getFrequency() ~= sgs.Skill_Wake then
						local sk = skill:objectName()
						room:acquireSkill(tenkei, sk)
						table.insert(eatdeath_skills, sk)
					end
				end
			end
			tenkei:setTag("EatDeath", sgs.QVariant(table.concat(eatdeath_skills, "+")))
		end
		return false
	end
}

skydao=sgs.CreateTriggerSkill
{
	name="skydao",
	frequency = sgs.Skill_Compulsory,
	events={sgs.Damaged},

	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_NotActive then
			local log = sgs.LogMessage()
			log.type = "#SkydaoMAXHP"
			log.from = player
			log.arg = tonumber(player:getMaxHp())
			log.arg2 = self:objectName()
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() + 1))
			room:sendLog(log)
		end
	end
}

noqing=sgs.CreateTriggerSkill{
	name="noqing",
	frequency = sgs.Skill_Compulsory,
	events={sgs.Damaged},
	priority = -1,

	default_choice = function(player)
		if player:getMaxHp() >= player:getHp() + 2 then
			return "maxhp"
		else
			return "hp"
		end
		end,

	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		for _, tmp in sgs.qlist(room:getOtherPlayers(player)) do
			if tmp:getHp() < player:getHp() then
				return false
			end
		end
		for _, tmp in sgs.qlist(room:getAllPlayers()) do
			local choice = room:askForChoice(tmp, self:objectName(), "hp+max_hp")
			local log = sgs.LogMessage()
			log.from = player
			log.arg = self:objectName()
			log.to:append(tmp)
			if(choice == "hp") then
				log.type = "#NoqingLoseHp"
				room:sendLog(log)
				room:loseHp(tmp)
			else
				log.type = "#NoqingLoseMaxHp"
				room:sendLog(log)
				room:loseMaxHp(tmp)
			end
		end
		return false
	end
}

doubledao = sgs.CreateSlashSkill
{
	name = "doubledao",
-- 额外目标
	s_extra_func = function(self, from, to, slash) -- from：使用者；to：目标；slash：所用的杀。这三个参数除了from，其余都是可有可无的
		if from:hasSkill("doubledao") and slash and slash:getSuit() == sgs.Card_Club then --注意必须先判断from是否有这个技能，否则谁都会发动的
			return 1 -- 这张杀可以指定一个额外目标，注意加上原本的，一共两个目标
		end
	end,
-- 攻击范围
	s_range_func = function(self, from, to, slash)
		if from:hasSkill("doubledao") and slash and slash:getSuit() == sgs.Card_Heart then
			return -4 -- 注意这里因为是锁定攻击范围，所以前面要加个负号，如果不加，则累加攻击范围
		end
	end,
}

dragonfist = sgs.CreateSlashSkill
{
	name = "dragonfist",
-- 额外出杀（返回还能再使用的杀的数量）
	s_residue_func = function(self, from)
	    if from:hasSkill("dragonfist") then
                local init =  1 - from:getSlashCount() -- 还能再使用的杀的数量，若已经使用了1张杀，则init=1-1=0，不能使用杀了
                return init + from:getMark("Fist") -- 如果获得了1个Fist标记，则在可用杀的基础上+1，本例中未0+1=1，有多少Fist标记可再使用多少张杀
			-- 返回值为998，表示使用杀无次数限制（如连弩、咆哮）
			-- 返回值为-998，表示不能再使用杀（如天义拼点失败）
            else
                return 0
	    end
	end,
}

dragonfistt=sgs.CreateTriggerSkill{
	name="#dragonfist",
	events={sgs.Damage, sgs.PhaseChange},
	priority = -1,

	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.PhaseChange then
			room:setPlayerMark(player, "Fist", 0) -- 阶段转换时清除标记
		else
			local damage = data:toDamage()
			if damage.card:isKindOf("Slash") then
				room:setPlayerMark(player, "Fist", player:getMark("Fist")+1)
			end
		end
		return false
	end
}

tianqi:addSkill(eatdeath)
tianyin:addSkill(skydao)
tianyin:addSkill(noqing)
tianshuang:addSkill(doubledao)
tianshuang:addSkill(dragonfist)
tianshuang:addSkill(dragonfistt)

luamaichong=sgs.CreateTriggerSkill{
	name="luamaichong",
	frequency = sgs.Skill_Compulsory,
	events={sgs.Damaged, sgs.ConjuringProbability},
	priority = -1,

	can_trigger = function(self, player)
		return true
		-- 本技能涉及到两个事件，其中伤害事件不需要return true，但是概率事件的触发者并不一定拥有maichong技能，所以需要return true
	end,

	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.ConjuringProbability then
		-- 本事件用于设置咒术的附加概率
			if player:hasFlag("iswoman") then
				-- 传递的data为字符串类型，形似dizzy_jur*75，星号前面为咒术名，后面为概率（默认为100）
				local dataa = data:toString():split("*")
				local conjur = dataa[1]
				local percent = dataa[2]:toInt()
				-- 将data传递的字符串拆成两部分
				if string.find(conjur, "dizzy") then
					percent = percent + 5
					-- 如果此咒术是晕眩，则概率+5
				end
				data:setValue(conjur .. "*" .. percent)
				-- 写入data传回
			end
			return false
		else
			if not player:hasSkill(self:objectName()) then return false end
			local damage = data:toDamage()
			if damage.from then
				if damage.from:getGeneral():isFemale() then
					damage.from:setFlags("iswoman")
					-- 设置触发标记，有iswoman的角色才能执行概率的增加
				end
				damage.from:gainJur("dizzy_jur", 2)
				-- 设置咒术状态主函数，第二个参数是持续回合数，请遵守咒术的描述规则进行设置，否则须在技能中说明。第三个参数（可选）为布尔类型，设置是否叠加。程序中并未使用过
				damage.from:setFlags("-iswoman")
				-- 清除触发标记
			end
		end
		return false
	end
}

luashepin=sgs.CreateTriggerSkill{
	name="luashepin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if(room:askForSkillInvoke(player, self:objectName())) then
			local x = data:toInt()
			room:playSkillEffect(self:objectName())
			player:gainJur("shensu_jur", 1)
			data:setValue(x-1)
		end
		return false
	end
}

-- 设置自定义咒术。自定义咒术其实就是写了一些新的技能效果，在咒术名的约束下进行执行而已
luashepin_shensu = sgs.CreateSlashSkill
{
	name = "#luashepin_shensu",

	s_extra_func = function(self, from, to, slash)
		if from:hasJur("shensu_jur") then
		-- 判断from是否有你自定义的神速咒术状态
			return 1
		end
	end,
}

tianlong:addSkill(luamaichong)
tianlong:addSkill(luashepin)
tianlong:addSkill(luashepin_shensu)

sgs.LoadTranslationTable{
	["personal"] = "Pesonal",

	["#tianyin"] = "天道之化身",
	["tianyin"] = "天音",
	["designer:tianyin"] = "鎏铄天音",
	["cv:tianyin"] = "",
	["illustrator:tianyin"] = "帕秋丽同人",
	["skydao"] = "天道",
	[":skydao"] = "锁定技，你的回合外，你每受到一次伤害，增加1点体力上限",
	["#SkydaoMAXHP"] = "%from 的锁定技【%arg2】被触发，增加了一点体力上限，目前体力上限是 %arg",
	["noqing"] = "无情",
	[":noqing"] = "锁定技，你受到伤害时，若你的体力是全场最少或同时为最少，则所有人必须减少1点体力或1点体力上限",
	["noqing:hp"] = "体力",
	["noqing:max_hp"] = "体力上限",
	["#NoqingLoseHp"] = "受到 %from 【%arg】锁定技的影响，%to 流失了一点体力",
	["#NoqingLoseMaxHp"] = "受到 %from 【%arg】锁定技的影响，%to 流失了一点体力上限",

	["#tianqi"] = "食死徒",
	["tianqi"] = "天启",
	["designer:tianqi"] = "宇文天启",
	["cv:tianqi"] = "",
	["illustrator:tianqi"] = "火影忍者",
	["eatdeath"] = "拾尸",
	[":eatdeath"] = "当有角色死亡时，你可以失去一个因“拾尸”获得的技能(如果有的话)，然后失去一点体力上限并获得该角色当前的所有武将技(限定技、觉醒技除外)",

	["#tianshuang"] = "静流",
	["tianshuang"] = "天霜",
	["doubledao"] = "双刀",
	[":doubledao"] = "LUA演示：你的草花杀可额外指定一个目标；你使用红桃杀的攻击范围锁定为4.",
	["dragonfist"] = "龙拳",
	[":dragonfist"] = "LUA演示：出牌阶段，当你的【杀】造成伤害时，可额外出一次【杀】",

	["#tianlong"] = "八部",
	["tianlong"] = "天龍",
	["luamaichong"] = "脉衝",
	[":luamaichong"] = "LUA演示：锁定技，对你造成伤害的角色附加“晕眩”状态，若其为女性角色，附加“晕眩”状态的概率增加5%.",
	["luashepin"] = "射頻",
	[":luashepin"] = "LUA演示：摸牌阶段，你可以少摸一张牌，然后附加“神速”状态（使用【杀】可额外指定一个目标。附加概率100%，共持续1个回合）。",
	["shensu_jur"] = "神速",
	[":shensu_jur"] = "目标角色使用【杀】可额外指定一个目标。附加概率100%，共持续1个回合。",
}
