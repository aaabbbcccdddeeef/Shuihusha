-- ZhechongYannan Shuihusha part 8.

local tt = {
	["YBYT"] = "义薄云天",
	["coder:YBYT"] = "战栗贵公子",

	["#_qiongying"] = "琼矢镞",
	["qiongying"] = "琼英",
	["designer:qiongying"] = "烨子&凌天翼",
	["cv:qiongying"] = "蒲小猫",
	["coder:qiongying"] = "宇文天启",
	["yuanpei"] = "缘配",
	[":yuanpei"] = "出牌阶段，你可以指定任一男性角色。若该角色交给你一张【杀】或武器牌，你和该角色各摸一张牌，否则你可以将你的任一手牌当【杀】使用或打出直到回合结束。每回合限一次。",
	["@yuanpei"] = "%src 对你发动了【缘配】，请给其一张【杀】或武器牌",
	["mengshi"] = "梦石",
	[":mengshi"] = "<font color=green><b>觉醒技</b></font>，回合开始阶段，若你的手牌数小于你的攻击范围，你须摸三张牌，并永久获得技能“饮羽”。",
	["yuanpei_slash"] = "缘配·杀",
	[":yuanpei_slash"] = "你可以将你的任一手牌当【杀】使用或打出直到本回合结束",
	["$yuanpei1"] = "若得此缘，安保大局。",
	["$yuanpei2"] = "将军可愿一同出战？",
	["$mengshi"] = "张将军，这就是飞石手段？",
	["~qiongying"] = "节儿，保重。",

	["#_xuning"] = "金枪手",
	["xuning"] = "徐宁",
	["goulian"] = "钩镰",
	[":goulian"] = "每当你对武将牌处于横置状态的其他角色造成无属性伤害时，可以重置该角色的武将牌并弃掉其装备区里的所有马匹。",
	["jinjia"] = "金甲",
	[":jinjia"] = "<b>锁定技</b>，当你没装备防具时，始终视为你装备着【雁翎圈金甲】。",

	["#_baoxu"] = "丧门神",
	["baoxu"] = "鲍旭",
	["sinue"] = "肆虐",
	[":sinue"] = "出牌阶段，每当你杀死一名其他角色，可以弃置一张手牌，对一名距离为1的其他角色造成2点伤害。每回合限用一次。\
	★此时机为执行奖惩以后",
	["@sinue"] = "你可以发动【肆虐】，弃置一张手牌，对一名距离为1的其他角色造成2点伤害",

	["#_xiangchong"] = "八臂哪吒",
	["xiangchong"] = "项充",
	["xuandao"] = "旋刀",
	[":xuandao"] = "<b>锁定技</b>，当你使用的【杀】被【闪】抵消时，你不能发动武器技能，视为你对目标角色的下家使用了同一张【杀】。\
	★同一张【杀】即同来源、同程度、同属性、同花色、同点数。",
	["#Xuandao"] = "%from 的锁定技【%arg】被触发，视为对 %to 使用了同一张【杀】",

	["#_jindajian"] = "玉臂匠",
	["jindajian"] = "金大坚",
	["weizao"] = "伪造",
	[":weizao"] = "出牌阶段，你可以展示任一其他角色的一张手牌，若该牌为基本牌或非延时类锦囊，则你可以将你的任一手牌当该牌使用。每回合限一次。",
	["jiangxin"] = "匠心",
	[":jiangxin"] = "在任意角色的判定牌生效后，若其为基本牌，你可以摸一张牌。",

	["#_yangchun"] = "白花蛇",
	["yangchun"] = "杨春",
	["shexin"] = "蛇信",
	[":shexin"] = "出牌阶段，你可以弃置一张非延时类锦囊或装备牌，展示任一其他角色的手牌并弃掉其中除基本牌外的所有牌。每回合限一次。",

	["#_songqing"] = "铁扇子",
	["songqing"] = "宋清",
	["sheyan"] = "设宴",
	[":sheyan"] = "出牌阶段，你可以将你的任一红桃手牌当【五谷丰登】使用。每回合限一次。",
	["jiayao"] = "佳肴",
	[":jiayao"] = "任意角色使用【五谷丰登】从牌堆顶亮出牌时，你可摸一张牌并回复X点体力，X为亮出的牌中【桃】和【酒】的张数。",

	["#_xueyong"] = "病大虫",
	["xueyong"] = "薛永",
	["maiyi"] = "卖艺",
	[":maiyi"] = "出牌阶段，你可以弃置两张装备牌或三张不同花色的牌，执行下列两项中的一项：1.令任意两名角色各摸两张牌；2.回合结束时令任一角色进行一个额外的回合。每回合限一次。",
	["#MaiyiCanInvoke"] = "受到【%arg】技能影响，%from 进行一个额外的回合",

	["#_tanglong"] = "金钱豹子",
	["tanglong"] = "汤隆",
	["cuihuo"] = "淬火",
	[":cuihuo"] = "当你失去装备区里的一张牌时，可以摸两张牌",
	["jintang"] = "金汤",
	[":jintang"] = "当你受到装备有武器的角色造成的伤害时，有四分之一的反伤几率",

	["#_zouyuan"] = "出林龙",
	["zouyuan"] = "邹渊",
	["longao"] = "龙傲",
	[":longao"] = "当其他角色使用非延时类锦囊指定了唯一的目标角色时，你可以弃置一张牌，执行下列两项中的一项：1.将该锦囊转移给除该角色和目标角色外的任一角色；2.弃掉该角色的一张牌",
	["longao:zhuan"] = "转移锦囊目标",
	["longao:qi"] = "弃掉使用者的一张牌",

	["#_zhufu"] = "笑面虎",
	["zhufu"] = "朱富",
	["hunjiu"] = "浑酒",--
	[":hunjiu"] = "你可以将你的一张【肉】、【酒】或【迷】当【酒】或【迷】使用",
	["guitai"] = "鬼胎",
	[":guitai"] = "你的回合外，每当其他角色成为【肉】的目标时，若你已受伤，你可以弃置一张红桃牌，将该【肉】转移给你",
	["@guitai"] = "%src 吃了【肉】，你可以弃掉一张红桃牌发动【鬼胎】，将【肉】抢走并吃掉",

	["#_gaolian"] = "高唐魔君",
	["gaolian"] = "高廉",
	["guibing"] = "鬼兵",
	[":guibing"] = "每当你需要使用或打出一张【杀】时，你可以进行一次判定：若结果为黑色，则视为你使用或打出了一张【杀】。\
	★若判定结果为红色，则你仍可以从手牌中使用或打出一张【杀】。\
	★发动【鬼兵】使用或打出的【杀】，并非从你的手牌中使用或打出。",
	["heiwu"] = "黑雾",
	[":heiwu"] = "出牌阶段，你可以将任意数量的手牌以任意顺序置于牌堆顶或牌堆底。",
	["#GuanxingResult"] = "%from 将 %arg 张牌放到了牌堆顶，将 %arg2 张牌放到了牌堆底",
}

local gongzi = {"xuning", "baoxu", "xiangchong", "jindajian", "yangchun",
		"songqing", "xueyong", "zouyuan", "zhufu", "gaolian"}

for _, player in ipairs(gongzi) do
	tt["coder:" .. player] = tt["coder:YBYT"]
end

return tt
