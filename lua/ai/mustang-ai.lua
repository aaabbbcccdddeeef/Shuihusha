-- AI for mustang package

-- qinming
-- baonu
sgs.ai_skill_invoke["baonu"] = function(self, data)
	local use = data:toCardUse()
	local to = sgs.QList2Table(use.to)
	if self:isFriend(to[1]) then return false end
	if self:getCardCount(true) > 2 and self:isEquip("Axe") then return true end
	if self:isWeak() then return false end
	return math.random(0, 4) == 2
end

-- pengqi
-- tianyan
sgs.ai_skill_invoke["tianyan"] = true
sgs.ai_skill_askforag["tianyan"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(card_id)
		table.insert(cards, card)
	end
	self:sortByUseValue(cards)
	return cards[1]:getEffectiveId()
end

-- xueyong
-- maiyi
maiyi_skill = {}
maiyi_skill.name = "maiyi"
table.insert(sgs.ai_skills, maiyi_skill)
maiyi_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("MaiyiCard") then
		return sgs.Card_Parse("@MaiyiCard=.")
	end
end
sgs.ai_skill_use_func["MaiyiCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	local card_ready = false
	local card_ids = {}
	for _, car in ipairs(cards) do
		if car:isKindOf("EquipCard") then
			table.insert(card_ids, car:getEffectiveId())
		end
		if #card_ids == 2 then
			use.card = sgs.Card_Parse("@MaiyiCard=" .. table.concat(card_ids, "+"))
			card_ready = true
			break
		end
	end
	if #card_ids ~= 2 then
		card_ids = {}
		for _, car in ipairs(cards) do
			if #card_ids == 0 then
				table.insert(card_ids, car:getEffectiveId())
			elseif #card_ids == 1 then
				local card1 = sgs.Sanguosha:getCard(card_ids[1])
				if card1:getSuit() ~= car:getSuit() then
					table.insert(card_ids, car:getEffectiveId())
				end
			elseif #card_ids == 2 then
				local card1 = sgs.Sanguosha:getCard(card_ids[1])
				local card2 = sgs.Sanguosha:getCard(card_ids[2])
				if card1:getSuit() ~= car:getSuit() and card2:getSuit() ~= car:getSuit() then
					table.insert(card_ids, car:getEffectiveId())
				end
			end
			if #card_ids == 3 then
				use.card = sgs.Card_Parse("@MaiyiCard=" .. table.concat(card_ids, "+"))
				card_ready = true
				break
			end
		end
	end
	if not card_ready then return end
	if #self.friends > 1 then
		self:sort(self.friends, "handcard")
		if use.to then
			use.to:append(self.friends[1])
			use.to:append(self.friends[2])
		end
	else
		if use.to then
			use.to:append(self.friends[1])
		end
	end
end

-- jiangjing
-- huazhu
sgs.ai_skill_invoke["huazhu"] = true

-- jingsuan
function SmartAI:sortByNumber(cards)
	local compare_func = function(a,b)
		local value1 = a:getNumber()
		local value2 = b:getNumber()

		return value1 < value2
	end

	table.sort(cards, compare_func)
end

local jingsuan_skill={}
jingsuan_skill.name = "jingsuan"
table.insert(sgs.ai_skills, jingsuan_skill)
jingsuan_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 2 then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local aoename = "savage_assault|archery_attack"
	local aoenames = aoename:split("|")
	local aoe
	local i
	local good, bad = 0, 0
	local jingsuantrick = "savage_assault|archery_attack|ex_nihilo|god_salvation"
	local jingsuantricks = jingsuantrick:split("|")
	for i=1, #jingsuantricks do
		local forbiden = jingsuantricks[i]
		forbid = sgs.Sanguosha:cloneCard(forbiden, sgs.Card_NoSuit, 0)
		if self.player:isLocked(forbid) then return end
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
	local card_ids = {}
	local x = self.player:getLostHp()
	self:sortByNumber(cards)
	for _, acard in ipairs(cards) do
		if #cards == 0 then
			table.insert(card_ids, acard:getEffectiveId())
		elseif #cards == 1 then
			local card1 = sgs.Sanguosha:getCard(card_ids[1])
			if acard:getNumber() - card1:getNumber() <= x then
				table.insert(card_ids, acard:getEffectiveId())
			end
		end
		if #cards == 2 then
			break
		end
	end
	if #cards ~= 2 then return end
	for i=1, #aoenames do
		local newjingsuan = aoenames[i]
		aoe = sgs.Sanguosha:cloneCard(newjingsuan, sgs.Card_NoSuit, 0)
		if self:getAoeValue(aoe) > -5 then
			local parsed_card=sgs.Card_Parse("@JingsuanCard=" .. table.concat(card_ids, "+") .. ":" .. newjingsuan)
			return parsed_card
		end
	end
	if good > bad then
		local parsed_card = sgs.Card_Parse("@JingsuanCard=" .. table.concat(card_ids, "+") .. ":" .. "god_salvation")
		return parsed_card
	end
	if self:getCardsNum("Jink") == 0 and self:getCardsNum("Peach") == 0 then
		local parsed_card = sgs.Card_Parse("@JingsuanCard=" .. table.concat(card_ids, "+") .. ":" .. "ex_nihilo")
		return parsed_card
	end
end
sgs.ai_skill_use_func["JingsuanCard"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
	local jingsuancard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	jingsuancard:setSkillName("jingsuan")
	local type = jingsuancard:getTypeId()
	if type == sgs.Card_Trick then
		self:useTrickCard(jingsuancard, use)
	elseif type == sgs.Card_Basic then
		self:useBasicCard(jingsuancard, use)
	end
	if not use.card then return end
	use.card = card
end

-- guosheng
-- bingji
local bingji_skill={}
bingji_skill.name = "bingji"
table.insert(sgs.ai_skills, bingji_skill)
bingji_skill.getTurnUseCard = function(self)
	if not self:slashIsAvailable() or not self.player:isWounded() then return end
	local first_found = false
	local second_found = false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:inherits("Peach") or fcard:inherits("ExNihilo") or fcard:inherits("AOE")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getType() == first_card:getType() and 
						not (scard:inherits("Peach") or scard:inherits("ExNihilo") or scard:inherits("AOE")) then
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		return sgs.Card_Parse("@BingjiCard=" .. first_card:getId() + second_card:getId())
	end
end
sgs.ai_skill_use_func["BingjiCard"] = function(card, use, self)
	local targetnum = self.player:getLostHp()
	self:sort(self.enemies, "defense")
	local a = 0
	for _, enemy in ipairs(self.enemies) do
		if use.to then
			use.to:append(target)
			a = a + 1
		end
		if a == 2 then
			use.card = card
			return
		end
	end
end

-- duansanniang
-- zishi
sgs.ai_skill_use["@@zishi"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	local target = self.player:getTag("ZishiSource"):toPlayer()
	local cards = self.player:getHandcards()
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards) do
		if card:isBlack() and self:getUseValue(card) < 6 then
			if (self:isFriend(target) and target:getHandcardNum() < 3) or self:isEnemy(target) then
				return "@ZishiCard=" .. card:getEffectiveId() .. "->."
			end
		end
	end
	return "."
end
sgs.ai_skill_choice["zishi"] = function(self, choice)
	local source = self.player:getTag("ZishiSource"):toPlayer()
	if self:isFriend(source) then
		return "duo"
	else
		return "shao"
	end
end

-- duqian
-- naxian
sgs.ai_skill_use["@@naxian"] = function(self, prompt)
	if #self.friends_noself == 0 then return "." end
	if self.player:getHandcardNum() >= 3 then
		self:sort(self.friends_noself, "handcard")
		return "@NaxianCard=." .. "->" .. self.friends_noself[1]:objectName()
	end
	return "."
end

naxian_skill={}
naxian_skill.name = "naxian"
table.insert(sgs.ai_skills, naxian_skill)
naxian_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("NaxianCard") and not self.player:isNude() then
		if #self.friends_noself == 0 then return end
		return sgs.Card_Parse("@NaxianCard=.")
	end
end
sgs.ai_skill_use_func["NaxianCard"] = function(card,use,self)
	self:sort(self.friends_noself, "handcard")
	use.card = card
	if use.to then use.to:append(self.friends_noself[1]) end
end

-- hancunbao
-- jizhan
sgs.ai_skill_invoke["jizhan"] = function(self, data)
	local use = data:toCardUse()
	local to = sgs.QList2Table(use.to)
	if self:isFriend(to[1]) then return false end
	if to[1]:isKongcheng() and not self:isEquip("EightDiagram") then return true end
	if self:isWeak() then return false end
	return math.random(0, 3) == 2
end

-- yintianxi
-- yiguan
sgs.ai_skill_invoke["yiguan"] = true

-- qiangzhan
sgs.ai_skill_use["@@qiangzhan"] = function(self, prompt)
	if #self.friends_noself == 0 then return "." end
	self:sort(self.friends_noself)
	if math.random(0, 3) == 2 then
		return "@QiangzhanCard=." .. "->" .. self.friends_noself[1]:objectName()
	end
end

-- yuehe
-- yueli
function sgs.ai_slash_prohibit.yueli(self, to)
	if self:isEquip("EightDiagram", to) then return true end
end

-- taohui
sgs.ai_skill_playerchosen["taohui"] = function(self, targets)
	self:sort(self.friends, "handcard")
	return self.friends[1]
end

-- zhufu
-- hunjiu-jiu
hunjiu_skill={}
hunjiu_skill.name = "hunjiu"
table.insert(sgs.ai_skills, hunjiu_skill)
hunjiu_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if (acard:inherits("Ecstasy") or
			(not self.player:isWounded() and acard:inherits("Peach"))) then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("analeptic:hunjiu[%s:%s]=%d"):format(suit, number, card_id)
	local caard = sgs.Card_Parse(card_str)
	assert(caard)
	return caard
end
-- hunjiu-mi
hunjiu2_skill={}
hunjiu2_skill.name = "hunjiu"
table.insert(sgs.ai_skills, hunjiu2_skill)
hunjiu2_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if (acard:inherits("Analeptic") or
			(not self.player:isWounded() and acard:inherits("Peach"))) then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("ecstasy:hunjiu[%s:%s]=%d"):format(suit, number, card_id)
	local caard = sgs.Card_Parse(card_str)
	assert(caard)
	return caard
end
sgs.ai_view_as["hunjiu"] = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	if card:inherits("Peach") or card:inherits("Analeptic") or card:inherits("Ecstasy") then
		if class_name == "Analeptic" then
			return ("analeptic:hunjiu[%s:%s]=%d"):format(suit, number, card_id)
		else
			return ("ecstasy:hunjiu[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

-- guitai
sgs.ai_skill_cardask["@guitai"] = function(self, data)
	local ard
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart then
			ard = card
			break
		end
	end
	if not ard then return "." end
	local effect = data:toCardEffect()
	if self:isEnemy(effect.to) or
		(self:isFriend(effect.to) and self:isWeak() and not self:isWeak(effect.to)) then
		return ard:getEffectiveId()
	else
		return "."
	end
end

-- taozongwang
-- manli
sgs.ai_skill_invoke["manli"] = sgs.ai_skill_invoke["liba"]

-- qiaogong

