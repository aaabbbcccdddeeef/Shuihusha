module("extensions.chongmei", package.seeall)
extension = sgs.Package("chongmei")

chongmei = sgs.General(extension, 'chongmei', 'god', 3)

--[[
要修改杀或者锦囊的目标个数， 
直接修改下面这些函数的return值即可
以下开牌不适用： 
无中，延时锦囊，借刀，AOE, 桃园，五谷，技能卡(比如突袭:TuxuCard)
]]

--同时杀两个玩家
slash_ex1 = sgs.CreateTargetModSkill{
	name = "slash_ex1",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--杀的无距离限制,  
--[[
	对于【杀】来说有个bug，目前0224版本的return值小于1000的话是没有效果的, 
	所以暂且无法实现“攻击范围为3”这样的效果，只能实现无距离限制的效果
	这个bug在最新的git开发代码上已经修复
]]
slash_ex2 = sgs.CreateTargetModSkill{
	name = "slash_ex2",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}


--可使用两张杀，也就是额外使用一张杀
slash_ex3 = sgs.CreateTargetModSkill{
	name = "slash_ex3",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}


--同时顺两个玩家
snatch_ex1 = sgs.CreateTargetModSkill{
	name = "snatch_ex1",
	pattern = "Snatch",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--可以顺距离为2的人
snatch_ex2 = sgs.CreateTargetModSkill{
	name = "snatch_ex2",
	pattern = "Snatch",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--可同时拆2个玩家
dismantlement_ex1 = sgs.CreateTargetModSkill{
	name = "dismantlement_ex1",
	pattern = "Dismantlement",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}


-- 决斗可同时决斗两个玩家
duel_ex1 = sgs.CreateTargetModSkill{
	name = "duel_ex1",
	pattern = "Duel",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 火攻可同时火攻2个玩家
fireattack_ex1 = sgs.CreateTargetModSkill{
	name = "fireattack_ex1",
	pattern = "FireAttack",
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
chongmei:addSkill(slash_ex2)
chongmei:addSkill(slash_ex3)

chongmei:addSkill(snatch_ex1)
chongmei:addSkill(snatch_ex2)
chongmei:addSkill(dismantlement_ex1)

chongmei:addSkill(duel_ex1)
chongmei:addSkill(fireattack_ex1)
chongmei:addSkill(ironchain_ex1)
chongmei:addSkill(analeptic_ex1)



sgs.LoadTranslationTable {
	["chongmei"] = "虫妹",
	['#chongmei'] ='女王受*虫',

	['slash_ex1'] ='双杀',
	[':slash_ex1'] ='你的杀可额外指定一个目标',

	['slash_ex2'] ='强击',
	[':slash_ex2'] ='你的杀无距离限制',

	['slash_ex3'] ='突击',
	[':slash_ex3'] ='你可额外使用一张杀',

	['snatch_ex1'] ='偷梁',
	[':snatch_ex1'] ='你的顺可额外指定一个目标',

	['snatch_ex2'] ='飞贼',
	[':snatch_ex2'] ='你可顺与你距离为2的玩家',

	['dismantlement_ex1'] ='拆迁',
	[':dismantlement_ex1'] ='你的拆可额外指定一个目标',

	['duel_ex1'] ='领导',
	[':duel_ex1'] ='你的决斗可额外指定一目标',

	['fireattack_ex1'] ='火烧',
	[':fireattack_ex1'] ='你的火攻可额外指定一目标',

	['ironchain_ex1'] ='银锁',
	[':ironchain_ex1'] ='你的铁锁可额外指定一目标',

	['analeptic_ex1'] ='贪杯',
	[':analeptic_ex1'] ='出牌阶段你可以多喝一杯酒，且每次酒杀都能伤害+1',
}
