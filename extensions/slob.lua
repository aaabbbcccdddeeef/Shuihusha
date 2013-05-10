module("extensions.slob", package.seeall)
extension = sgs.Package("slob")

chongmei = sgs.General(extension, 'chongmei', 'god', '7/10', sgs.General_Neuter, sgs.General_Hidden)

slash_ex1 = sgs.CreateTargetModSkill{
	name = "slash_ex1",
	pattern = "Slash",
	--同时杀两个玩家
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
	--杀的无距离限制
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
	--可使用两张杀，也就是额外使用一张杀
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

snatch_ex1 = sgs.CreateTargetModSkill{
	name = "snatch_ex1",
	pattern = "Snatch",
	--同时顺两个玩家
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
	--可以顺距离为2的人
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 黑色拆可同时拆2个玩家
dismantlement_ex1 = sgs.CreateTargetModSkill{
	name = "dismantlement_ex1",
	pattern = "Dismantlement|.|.|.|black",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 决斗和行刺可同时决斗两个玩家
duel_ex1 = sgs.CreateTargetModSkill{
	name = "duel_ex1",
	pattern = "Duel,Assassinate",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 红桃2~9的火攻可同时火攻2个玩家
fireattack_ex1 = sgs.CreateTargetModSkill{
	name = "fireattack_ex1",
	pattern = "FireAttack|heart|2~9",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 铁锁可同时指定三个玩家
ironchain_ex1 = sgs.CreateTargetModSkill{
	name = "ironchain_ex1",
	pattern = "IronChain",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 逼上梁山可同时逼3个玩家
driver_ex1 = sgs.CreateTargetModSkill{
	name = "driver_ex1",
	pattern = "Drivolt",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 2
		end
	end,
}

--多喝一次酒，且每次酒都能伤害+1
analeptic_ex1 = sgs.CreateTargetModSkill{
	name = "analeptic_ex1",
	pattern = "Analeptic",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

chongmei:addSkill(slash_ex1)

chongmei:addSkill(snatch_ex1)
chongmei:addSkill(dismantlement_ex1)

chongmei:addSkill(duel_ex1)
chongmei:addSkill(fireattack_ex1)
chongmei:addSkill(ironchain_ex1)
chongmei:addSkill(driver_ex1)
chongmei:addSkill(analeptic_ex1)

for var=1, 13, 1 do
	local x = var % 4
	if x == 0 then
		sgs.Sanguosha:cloneCard("shit", sgs.Card_Spade, var):setParent(extension)
	elseif x == 1 then
		sgs.Sanguosha:cloneCard("shit", sgs.Card_Heart, var):setParent(extension)
	elseif x == 2 then
		sgs.Sanguosha:cloneCard("shit", sgs.Card_Club, var):setParent(extension)
	else
		sgs.Sanguosha:cloneCard("shit", sgs.Card_Diamond, var):setParent(extension)
	end
end

sgs.LoadTranslationTable {
	["slob"] = "虫妹示例",
	['#chongmei'] ='女王受·',
	["chongmei"] = "虫",

	['slash_ex1'] ='嗜血',
	[':slash_ex1'] ='你的杀可额外指定一个目标；你的杀无距离限制；你可额外使用一张杀',

	['snatch_ex1'] ='飞贼',
	[':snatch_ex1'] ='你的顺可额外指定一个目标；你可顺与你距离为2的玩家',

	['dismantlement_ex1'] ='拆迁',
	[':dismantlement_ex1'] ='你的黑色拆可额外指定一个目标',

	['duel_ex1'] ='斗殴',
	[':duel_ex1'] ='你的决斗和行刺均可额外指定一个目标',

	['fireattack_ex1'] ='纵火',
	[':fireattack_ex1'] ='你红桃2~9的火攻可额外指定一个目标',

	['ironchain_ex1'] ='银锁',
	[':ironchain_ex1'] ='你的铁锁可额外指定一个目标',

	['driver_ex1'] ='紧逼',
	[':driver_ex1'] ='你的逼可额外指定两个目标',

	['analeptic_ex1'] ='贪杯',
	[':analeptic_ex1'] ='出牌阶段你可以多喝一杯酒，且每次酒杀都能伤害+1',
}
