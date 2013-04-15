-- Ai for Casket-package

-- moon_panqiaoyun
sgs.ai_chaofeng.moon_panqiaoyun = 5
-- qingdu
-- tumi
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

-- sun_peiruhai ->getTypeId() == item->getFilteredCard()->getTypeI
sgs.ai_chaofeng.sun_peiruhai = -1
-- fanyin
local fanyin_skill = {}
fanyin_skill.name = "fanyin"
table.insert(sgs.ai_skills, fanyin_skill)
fanyin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("FanyinCard") then return end
	local cards = self.player:getCards("he")
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
		return sgs.Card_Parse("@FanyinCard=" .. card1:getEffectiveId() + card2:getEffectiveId())
	end
end
sgs.ai_skill_use_func["FanyinCard"] = function(card,use,self)
	if #self.enemies > 1 then
		self:sort(self.enemies)
		use.card=card
		if use.to then
			use.to:append(self.enemies[1])
			use.to:append(self.enemies[2])
		end
	end
end
-- lichen
sgs.ai_skill_invoke["lichen"] = true
-- lunhui
