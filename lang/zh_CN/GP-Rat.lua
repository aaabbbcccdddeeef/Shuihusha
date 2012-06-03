-- translation for RatPackage

return {
	["rat"] = "子鼠",

	["#liying"] = "扑天雕", -- guan 4hp (qjwm)
	["liying"] = "李应",
	["cv:liying"] = "烨子【剪刀剧团】",
	["kong1iang"] = "控粮",
	[":kong1iang"] = "摸牌阶段，你可以摸X张牌（X为你的体力上限与你已损失的体力值之和）。若如此做，则你须展示你的所有手牌，然后弃置其中任意两种花色的所有牌（不足则全弃）。",
	["#Kongrice"] = "%from 弃置了自己 %arg 花色的所有牌",
	["$kong1iang1"] = "大军未动，粮草先行！",
	["$kong1iang2"] = "粮草器械，尽在掌控之中。",
	["~liying"] = "兵粮寸断，以何取胜？！",
	
	["#dongping"] = "双枪将", -- guan 4hp (fcdc)
	["dongping"] = "董平",
	["shuangzhan"] = "双战",
	[":shuangzhan"] = "若你攻击范围内的现存其他角色数大于2，则你使用【杀】时可以额外指定一名目标角色；当你使用【杀】指定一名其他角色为目标后，若你攻击范围内的现存其他角色数不大于2，则该角色需连续使用两张【闪】才能抵消。",
	["@shuangzhan-jink-1"] = "%src 拥有【双战】技能，您必须连续出两张【闪】",
	["@shuangzhan-jink-2"] = "%src 拥有【双战】技能，你还需出一张【闪】",

	["#zhangqing"] = "没羽箭", -- guan 4hp (ttxd)
	["zhangqing"] = "张清",
	["cv:zhangqing"] = "烨子【剪刀剧团】",
	["coder:zhangqing"] = "roxiel",
	["yinyu"] = "饮羽",
	[":yinyu"] = "回合开始时，你可以进行一次判定，然后获得一项与判定结果相应的技能，直到回合结束：♠~出牌阶段，你可以使用任意数量的【杀】；♥~你的攻击范围无限；♣~你无视其他角色的防具；♦~你使用的【杀】不能被【闪】响应。",
	["#Yinyu1"] = "%from 本回合攻击范围无限",
	["#Yinyu2"] = "%from 本回合使用的【杀】不可被闪避",
	["#Yinyu4"] = "%from 本回合可以使用任意数量的【杀】",
	["#Yinyu8"] = "%from 本回合无视其他角色的防具",
	["$yinyu1"] = "飞蝗如雨，看尔等翻成画饼！",
	["$yinyu2"] = "飞石连伤，休想逃跑！",
	["$yinyu3"] = "叫汝等饮羽沙场吧！",
	["$yinyu4"] = "此等破铜烂铁岂能挡我！",
	["$yinyu5"] = "看你马快，还是我飞石快！",
	["~zhangqing"] = "一技之长，不足傍身啊！",

	["#ruanxiaoer"] = "立地太岁", -- min 4hp (zcyn)
	["ruanxiaoer"] = "阮小二",
	["cv:ruanxiaoer"] = "烨子【剪刀剧团】",
	["fuji"] = "伏击",
	[":fuji"] = "其他角色的判定阶段开始时，若该角色的判定区里有牌，则你可以弃置一张手牌，视为对其使用一张【行刺】（不能被【将计就计】和【无懈可击】响应）。",
	["@fuji"] = "%src 即将开始判定阶段，你可以弃一张手牌【伏击】之",
	["$fuji1"]= "太岁头上也敢动土！",
	["$fuji2"]= "爷爷在此候你多时了！",
	["~ruanxiaoer"] = "不好，被包围了！",
--	["~ruanxiaoer"] = "斜阳影下空踏浪，休言村里一渔人。",

	["#zhangshun"] = "浪里白条", -- min 3hp (xzdd)
	["zhangshun"] = "张顺",
	["cv:zhangshun"] = "烨子【剪刀剧团】",
	["shunshui"] = "顺水",
	[":shunshui"] = "当任一角色判定区里的一张牌进入弃牌堆时，你可以弃置一张与该牌花色相同的牌，视为对任一其他角色使用一张【杀】（不计入每回合使用限制）。",
	["@shunshui"] = "请弃置一张 %arg 牌发动【顺水】，偷袭任一其他角色",
	["lihun"] = "离魂",
	[":lihun"] = "当你进入濒死状态时，你可以获得伤害来源的至多两张牌，然后可以交给除你与其外的任一角色。",
	["$shunshui1"] = "脚踏平浪，如行平地！",
	["$shunshui2"] = "浪里白条非浪得虚名！",
	["$lihun1"] = "涌金门外水滔滔，一点离魂何处飘？",
	["$lihun2"] = "能感龙君权作神，势杀天定血带刀！",
	["~zhangshun"] = "春风缘何起，皆因夜归神。",

	["#zhuwu"] = "神机军师", -- kou 3hp (qjwm)
	["zhuwu"] = "朱武",
	["pozhen"] = "破阵",
	["cv:zhuwu"] = "烨子【剪刀剧团】",
	[":pozhen"] = "<b>锁定技</b>，你使用的非延时类锦囊不能被【将计就计】和【无懈可击】响应。",
	["#Pozhen"] = "%from 的锁定技【%arg】被触发，使用的这张 %arg2 不能被【无懈可击】或【将计就计】抵消",
	["buzhen"] = "布阵",
	[":buzhen"] = "<font color=purple><b>限定技</b></font>，回合结束时，你可以弃置你的所有牌（至少一张），排列所有现存角色的位置。\
★排列：以任意规则交换目标角色的位置（至少两名目标角色）。",
	["@buvr"] = "布阵",
	["@buzhen"] = "你可以选择两名角色发动【布阵】（交换他们的位置）",
	["fangzhen"] = "方阵",
	[":fangzhen"] = "当你受到锦囊牌造成的伤害时，你可以弃置一张与该牌花色相同的牌，防止该伤害。",
	["@fangzhen"] = "你可以弃置一张 %arg 牌，防止本次伤害",
	["#Fangzhen"] = "%from 发动了【%arg】，防止了 %arg2 点伤害",
	["$pozhen1"] = "洞察先机，无有不破！",
	["$pozhen2"] = "意志被摧毁了吗？",
	["$buzhen"] = "汝当作先锋，汝可为接应，大军严守生门，此战可定也！",
	["$Buzhen"] = "汝当作先锋，\
汝可为接应，\
大军严守生门，\
此战可定也！",
	["~zhuwu"] = "生门已破，此战败也。",

	["#qingzhang"] = "菜园子", -- kou 3hp (bwqz)
	["qingzhang"] = "张青",
	["cv:qingzhang"] = "流岚【裔美声社】",
	["shouge"] = "收割",
	[":shouge"] = "出牌阶段，你可以将任意数量的【肉】或【酒】置于你的武将牌上，称为“菜”；你的回合外，当你失去一张手牌时，你可以将一张“菜”置入弃牌堆，然后摸三张牌。",
	["vege"] = "菜",
	["qiongtu"] = "穷途",
	[":qiongtu"] = "其他角色的回合结束时，若该角色的手牌数不大于1，则你可以获得其一张牌。",
	["$shouge1"] = "没有耕耘，哪来收获？",
	["$shouge2"] = "一粒种子，就是一个春天。",
	["$shouge3"] = "又是一年秋收时节。",
	["$shouge4"] = "好一片麦田！",
	["$qiongtu1"] = "哼，你这穷鬼，还要这些作甚？",
	["$qiongtu2"] = "这里就是张家店，客官，里边请！",
	["~qingzhang"] = "日头落了。",

	["#baisheng"] = "白日鼠", -- kou 3hp (bwqz)
	["baisheng"] = "白胜",
	["cv:baisheng"] = "明哲【剪刀剧团】",
	["coder:baisheng"] = "太阳神上",
	["xiayao"] = "下药",
	[":xiayao"] = "出牌阶段，你可以将你的任一♠手牌当【迷】使用；你使用【迷】时可以额外指定一名目标角色。",
	["shudan"] = "鼠胆",
	[":shudan"] = "<b>锁定技</b>，你的回合外，你每受到一次伤害，【杀】和非延时类锦囊对你无效，直到回合结束。",
	["#ShudanDamaged"] = "%from 受到了伤害，本回合内【杀】和非延时锦囊都将对其无效",
	["#ShudanAvoid"] = "%from 的锁定技【%arg】被触发，【杀】和非延时锦囊对其无效",
	["$menghan1"] = "睡个好觉吧～",
	["$menghan2"] = "倒～倒了！",
	["$shudan1"] = "我逃～",
	["$shudan2"] = "别～别杀我！",
	["~baisheng"] = "我招～我全招了！",

	["#shiqian"] = "鼓上蚤", -- kou 3hp (xzdd)
	["shiqian"] = "时迁",
	["cv:shiqian"] = "爪子",
	["coder:shiqian"] = "凌天翼",
	["feiyan"] = "飞檐",
	[":feiyan"] = "<b>锁定技</b>，你不能成为【顺手牵羊】和【粮尽援绝】的目标。",
	["shentou"] = "神偷",
	[":shentou"] = "出牌阶段，出牌阶段，你可以将你的任一♣手牌当【顺手牵羊】使用；你可以对距离2以内的任一其他角色使用【顺手牵羊】。",
	["$shentou1"] = "妙手空空～",
	["$shentou2"] = "探囊取物，易如反掌！",
	["~shiqian"] = "上天不公，无过于此！",

	["#shiwengong"] = "大教师", -- jiang 4hp (zcyn)
	["shiwengong"] = "史文恭",
	["cv:shiwengong"] = "佚名",
	["dujian"] = "毒箭",
	[":dujian"] = "当你对其他角色造成伤害时，若你不在其攻击范围内，则你可以防止该伤害，令该角色将其武将牌翻面。",
	["$dujian1"] = "明枪易躲，暗箭难防！",
	["$dujian2"] = "活捉晁盖！",
--	["~shiwengong"] = "非我不力，实乃毒誓害我。",
	["~shiwengong"] = "动，动不了了！呃～",

	["#yuehe"] = "铁叫子",
	["yuehe"] = "乐和",
	["cv:yuehe"] = "烨子【剪刀剧团】",
	["coder:yuehe"] = "roxiel",
	["yueli"] = "乐理",
	[":yueli"] = "若你的判定牌为基本牌，在其生效后可以获得之。",
	["yueli:yes"] = "拿屎",
	["yueli:no"] = "不拿屎",
	["taohui"] = "韬晦",
	[":taohui"] = "回合结束阶段，你可以进行一次判定：若结果不为基本牌，你可以令任一角色摸一张牌，并可以再次使用“韬晦”，如此反复，直到判定结果为基本牌为止。",
	["$yueli1"] = "呵呵～",
	["$yueli2"] = "且慢，音律有误。",
	["$taohui1"] = "白云起，郁披香；离复合，曲未央。",
	["$taohui2"] = "此曲只应天上有，人间能得几回闻。",

	["#muhong"] = "没遮拦",
	["muhong"] = "穆弘",
	["cv:muhong"] = "流岚【裔美声社】",
	["coder:muhong"] = "roxiel",
	["wuzu"] = "无阻",
	[":wuzu"] = "<b>锁定技</b>，你始终无视其他角色的防具。",
	["$IgnoreArmor"] = "%to 装备着 %card，但 %from 貌似没有看见",
	["$wuzu1"] = "谁敢拦我？",
	["$wuzu2"] = "游击部，冲！",

	["#zhoutong"] = "小霸王",
	["zhoutong"] = "周通",
	["cv:zhoutong"] = "烨子【剪刀剧团】",
	["coder:zhoutong"] = "roxiel",
	["qiangqu"] = "强娶",
	[":qiangqu"] = "当你使用【杀】对已受伤的女性角色造成伤害时，你可以防止此伤害，改为获得该角色的一张牌，然后你和她各回复1点体力。",
	["#Qiangqu"] = "%from 硬是把 %to 拉入了洞房",
	["huatian"] = "花田",
	[":huatian"] = "你每受到1点伤害，可以令任一已受伤的其他角色回复1点体力；你每回复1点体力，可以对任一其他角色造成1点伤害。",
	["$qiangqu1"] = "小娘子，春宵一刻值千金啊！",
	["$qiangqu2"] = "今夜，本大王定要做新郎！",
	["$huatian1"] = "无妨，只当为汝披嫁纱！",
	["$huatian2"] = "只要娘子开心，怎样都好！",
	["$huatian3"] = "破晓之前，忘了此错。",
	["$huatian4"] = "无心插柳，岂是花田之错？",

	["#qiaodaoqing"] = "幻魔君", -- kou 3hp (ttxd)
	["qiaodaoqing"] = "乔道清",
	["cv:qiaodaoqing"] = "烨子【剪刀剧团】",
	["coder:qiaodaoqing"] = "roxiel",
	["huanshu"] = "幻术",
	[":huanshu"] = "你每受到1点伤害，可以令任一其他角色连续进行两次判定：若结果均为红色，则你对其造成2点火焰伤害；若结果均为黑色，则你对其造成2点雷电伤害。",
	["@huanshu"] = "请指定一个目标以便于发动【幻术】",
	["huanshu1"] = "幻术·第一次判定",
	["huanshu2"] = "幻术·第二次判定",
	["mozhang"] = "魔障",
	[":mozhang"] = "<b>锁定技</b>，回合结束时，若你未处于连环状态，则你须横置你的武将牌。",
	["#Mozhang"] = "%from 的锁定技【%arg】被触发，将自己的武将牌横置",
	["$huanshu1"] = "沙石一起，真假莫辨！",
	["$huanshu2"] = "五行幻化，破！",
	["$huanshu3"] = "五雷天心，五雷天心，缘何不灵？",
	["$mozhang"] = "外道之法，也可乱心？",
	["~qiaodaoqing"] = "这，就是五雷轰顶的滋味吗？",

	["#qiongying"] = "琼矢镞", -- jiang 3hp (ybyt)
	["qiongying"] = "琼英",
	["designer:qiongying"] = "烨子&凌天翼",
	["cv:qiongying"] = "Paddy【№第④声】",
	["coder:qiongying"] = "战栗贵公子",
	["yuanpei"] = "缘配",
	[":yuanpei"] = "出牌阶段，你可以指定任一男性角色。然后若该角色交给你一张【杀】或武器牌，则你与其各摸一张牌，否则你可以将你的任一♥或♦手牌当【杀】使用或打出，直到回合结束。每阶段限一次。",
	["@yuanpei"] = "%src 对你发动了【缘配】，请给其一张【杀】或武器牌",
	["#Yuanpei"] = "%to 没有响应 %from 的【%arg】，%from 可以将任一红色手牌当【杀】使用或打出直到回合结束",
	["mengshi"] = "梦石",
	[":mengshi"] = "<font color=green><b>觉醒技</b></font>，回合开始时，若你的手牌数小于你的攻击范围，则你须摸三张牌，然后永久获得技能“饮羽”。",
	["$yuanpei1"] = "若得此缘，安保大局。",
	["$yuanpei2"] = "将军可愿一同出战？",
	["$mengshi"] = "张将军，这就是飞石手段？",
	["$yinyu6"] = "教汝等尝尝我的厉害！",
	["$yinyu7"] = "哼！不识好歹！",
	["$yinyu8"] = "看我的！",
	["$yinyu9"] = "此乃飞石绝技！",
	["$yinyu10"] = "飞石不断！",
	["~qiongying"] = "节儿，保重。",

-- last words
	["~yuehe"] = "叫子也难吹奏了。",
	["~muhong"] = "弟，兄先去矣！",
	["~zhoutong"] = "虽有霸王相，奈无霸王功啊！",
}
