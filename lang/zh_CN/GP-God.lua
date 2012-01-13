-- translation for GodPackage

return {
	["god"] = "神",

	["#_shenwusong"] = "清忠祖师",
	["shenwusong"] = "神武松",
	["designer:shenwusong"] = "烨子&裁之刃•散",
	["coder:shenwusong"] = "皇叔",
	["shenchou"] = "深仇",
	[":shenchou"] = "<b>锁定技</b>，你每受到一次伤害，须将对你造成伤害的牌置于你的武将牌上，称为“仇”。",
	["chou"] = "仇",
	["wujie"] = "无戒",
	[":wujie"] = "<font color=green><b>觉醒技</b></font>，回合开始阶段，若“仇”达到3张或更多，你须增加1点体力上限，并永久获得技能“诛杀”（出牌阶段，你可以减1点体力上限并将一张“仇”移入弃牌堆。若如此做，本回合你使用的下一张【杀】指定所有其他角色为目标。每回合限一次）。",
	["duanbi"] = "断臂",
	[":duanbi"] = "<font color=purple><b>限定技</b></font>，出牌阶段，若你的当前体力值为1且体力上限大于1，你可将你的体力上限减至1，对任一其他角色造成2点伤害。若如此做，你失去“深仇”。",
	["@bi"] = "臂",
	["$duanbi"] = "胳臂断了，俺还有另一条胳臂！",
	["zhusha"] = "诛杀",
	[":zhusha"] = "出牌阶段，你可以减1点体力上限并将一张“仇”移入弃牌堆。若如此做，本回合你使用的下一张【杀】指定所有其他角色为目标。每回合限一次。",
	["#Zhusha"] = "受到【%arg】影响，%from 使用的【杀】指定了 %to 为目标",

	["#_shenwuyong"] = "足智多谋",
	["shenwuyong"] = "神吴用",
	["designer:shenwuyong"] = "烨子&凌天翼",
	["cv:shenwuyong"] = "烨子",
	["xianji"] = "先机",
	[":xianji"] = "其他角色的回合开始时，你可以弃置一张牌，该角色不能使用、打出或弃置与该牌同类别的牌直到回合结束。",
	["@xianji"] = "你可以弃置一张牌发动【先机】，令当前角色不能使用、打出或弃置与该牌同类别的牌直到回合结束。",
	["houlue"] = "后略",
	[":houlue"] = "其他角色的非延时类锦囊进入弃牌堆时，你可以进行一次判定：若结果不为锦囊牌，你获得该锦囊；若结果为锦囊牌，你获得该判定牌。",
	["$xianji1"] = "略施小计，鬼神俱惊！",
	["$xianji2"] = "以此先机，断汝后路。",
	["$houlue1"] = "不忙，吾有一计在此。",
	["$houlue2"] = "此计尚有后著。",
	["~shenwuyong"] = "大势已去，学究生有何用！",

	["#Xianji"] = "%from 发动了【%arg2】，%to 的 %arg 受到影响",
	["#XianjiClear"] = "%from 的先机效果消失",

	["#_shenzhangqing"] = "射石饮羽",
	["shenzhangqing"] = "神张清",
	["feihuang"] = "飞蝗",
	[":feihuang"] = "你可以跳过你的弃牌阶段，将超出你当前体力值的手牌置于你的武将牌上，称为“石”。",
	["@feihuang"] = "你可以发动【飞蝗】，将多余的手牌变成“石”。",
	["stone"] = "石",
	["meiyu"] = "没羽",
	[":meiyu"] = "出牌阶段，你可以将一张“石”移入弃牌堆，视为你对任一其他角色使用了一张【杀】，该【杀】造成的伤害为扣减体力上限（该【杀】不计入每回合的使用限制）。",

	["#_shenluzhishen"] = "义烈照暨禅师",
	["shenluzhishen"] = "神鲁智深",
	["designer:shenluzhishen"] = "烨子&凌天翼",
	["dunwu"] = "顿悟",
	[":dunwu"] = "<b>锁定技</b>，你每造成1点伤害，须亮出牌堆顶的一张牌：若为【海啸】，你立即死亡，否则你将其置于你的武将牌上，称为“偈言”；每当“偈言”达到4张时，你须将所有“偈言”移入弃牌堆并减1点体力上限。",
	["jiyan"] = "偈言",
	["#Dunwu"] = "%from 的锁定技【%arg2】被触发，需要亮出 %arg 张“偈言”牌",
	["#DunwuB"] = "%from 的 %arg 牌达到了 %arg2 张，【顿悟】效果被触发",
	["huafo"] = "花佛",
	[":huafo"] = "你可以将任一基本牌当【杀】或【酒】使用；出牌阶段，你可以使用任意数量的【杀】和【酒】。",

	["#_shenxuning"] = "虎翼上将",
	["shenxuning"] = "神徐宁",
	["coder:shenxuning"] = "皇叔",
	["jiebei"] = "戒备",
	[":jiebei"] = "任意角色防具牌进入弃牌堆时，你可以弃置一张手牌获得之，并将其置于任意角色的装备区里（不得替换原装备）；每当你失去一张装备区里的防具牌时，可以摸两张牌。",
	["@jiebei"] = "%src 弃掉了 %arg，你可以发动【戒备】，弃置一张手牌获得之",
	["jinqiang"] = "金枪",
	[":jinqiang"] = "<b>锁定技</b>，你对武将牌处于横置状态的其他角色造成的无属性伤害+1。",

	["designer:xianxi"] = "曉ャ絕對",
	["xianxi"] = "险袭",
	[":xianxi"] = "你使用的【杀】可额外指定任意个目标，其中每有一个目标使用手牌【闪】抵消【杀】时，你须弃置两张牌或失去一点体力",
}
