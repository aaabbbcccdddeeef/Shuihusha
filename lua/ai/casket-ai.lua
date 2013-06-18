-- Ai for Casket-package
sgs.ai_skill_invoke["casket_death"] = true

-- moon_panqiaoyun
sgs.ai_chaofeng.moon_panqiaoyun = 5
sgs.moon_panqiaoyun_suit_value = 
{
	spade = 4,
	club = 4,
}
-- qingdu
-- tumi
sgs.ai_card_intention.TumiCard = 80
sgs.ai_skill_use["@@tumi"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local red = 0
	for _, acard in ipairs(cards) do
		if acard:isRed() then
			red = red + 1
		end
	end
	if red > 1 then return "." end
	self:sort(self.enemies, "handcard2")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and enemy:isMale() then
			return "@TumiCard=." .. "->" .. enemy:objectName()
		end
	end
	return "."
end
-- jueyuan

-- sun_peiruhai
sgs.ai_chaofeng.sun_peiruhai = -1
-- fanyin
sgs.ai_card_intention.FanyinCard = 80
local fanyin_skill = {}
fanyin_skill.name = "fanyin"
table.insert(sgs.ai_skills, fanyin_skill)
fanyin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("FanyinCard") then return end
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	if #cards < 2 or #self.enemies < 2 then return end
	self:sortByUseValue(cards, true)
	local card1 = cards[1]
	local card2
	for _, acard in ipairs(cards) do
		if acard ~= card1 and acard:getTypeId() ~= card1:getTypeId() then
			card2 = acard
			break
		end
	end
	if card2 then
		return sgs.Card_Parse("@FanyinCard=" .. card1:getEffectiveId() .. "+" .. card2:getEffectiveId())
	end
end
sgs.ai_skill_use_func["FanyinCard"] = function(card,use,self)
	if #self.enemies > 1 then
		self:sort(self.enemies)
		local ene1, ene2
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasMark("sleep_jur") then
				if not ene1 then
					ene1 = enemy
				elseif not ene2 and ene1 ~= enemy then
					ene2 = enemy
				end
				if ene1 and ene2 then break end
			end
		end
		if ene1 and ene2 then
			use.card=card
			if use.to then
				use.to:append(ene1)
				use.to:append(ene2)
			end
		end
	end
end
-- lichen
sgs.ai_skill_invoke["lichen"] = true
sgs.ai_skill_playerchosen["lichen"] = function(self, targets)
	self:sort(self.enemies)
	if #self.enemies > 0 then
		return self.enemies[1]
	else
		return targets:first()
	end
end
-- lunhui

-- sun_ligu
sgs.ai_chaofeng.sun_ligu = -1
-- tiaonong
sgs.ai_skill_invoke["tiaonong"] = sgs.ai_skill_invoke["lihun"]
-- caimi
sgs.ai_skill_playerchosen["caimi"] = function(self, targets)
	local enemies = sgs.QList2Table(targets)
	self:sort(enemies)
	for _, e in ipairs(enemies) do
		if self:isEnemy(e) then
			return e
		end
	end
	return enemies[1]
end
-- gouxian

-- moon_jiashi
sgs.ai_chaofeng.moon_jiashi = 4
-- suqing
sgs.ai_skill_cardask["@suqing"] = function(self, data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) or damage.damage < 1 then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, false)
	return cards[1]:getEffectiveId()
end
-- xiepo
sgs.ai_skill_invoke["xiepo"] = sgs.ai_skill_invoke["lihun"]
sgs.ai_skill_use["@@xiepo"] = function(self, prompt)
--	local jiashi = self.player:getTag("XiepoSource"):toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local card_ids = {}
	for _, car in ipairs(cards) do
		if #card_ids == 0 then
			if car:isKindOf("Slash") or car:isKindOf("Jink") then
				table.insert(card_ids, car:getEffectiveId())
			end
		elseif #card_ids == 1 then
			local card1 = sgs.Sanguosha:getCard(card_ids[1])
			if card1:isKindOf("Slash") and car:isKindOf("Jink") then
				table.insert(card_ids, car:getEffectiveId())
			elseif car:isKindOf("Slash") and card1:isKindOf("Jink") then
				table.insert(card_ids, car:getEffectiveId())
			end
		end
		if #card_ids == 2 then
			return "@XiepoCard=" .. table.concat(card_ids, "+") .. "->."
		end
	end
	return "."
end
-- dingxin
