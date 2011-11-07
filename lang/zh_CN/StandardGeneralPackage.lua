-- translation for StandardGeneralPackage

return {
	["standard"] = "标准版",

	["DefaultDesigner"] = "Ailue",
	["designer:otagiritoshirou"] = "Ailue、尉迟泱",
	["designer:kobayashisumiko"] = "Ailue、尉迟泱",

	["kudoushinichi"] = "工藤新一",
	["zhenxiang"] = "真相",
	[":zhenxiang"] = "以下情况，你可以观看A的手牌：\
1、回合外当A对你使用非延时锦囊（不含五谷丰登）时\
2、出牌阶段主动指定一名角色为目标A，直到此回合结束A的手牌始终对你处于可见状态",
	["$Zhenxiangissingle"] = "%from 观看了 %to 的手牌",
	["wuwei"] = "无畏",
	[":wuwei"] = "主公技，在你的回合之外，当你受到一次伤害时，可以要求其他角色轮流对伤害来源使用一张【杀】（视为你使用）",
	[":wuwei:"] = "%from 想让你帮其出一张【杀】:",
	["wuwei:accept"] = "响应无畏",
	["wuwei:ignore"] = "不响应",
	["@wuwei-slash"] = "请打出一张【杀】以响应主公的【无畏】",

	["hattoriheiji"] = "服部平次",
	["rexue"] = "热血",
	[":rexue"] = "你每受到一点伤害，可摸一张牌置于一名其他角色的武将牌上，该角色在濒死时可以弃掉一张热血牌，回复一点体力",
	["rexue_get"] = "热血·救援",
	["jiaojin"] = "较劲",
	[":jiaojin"] = "单发技，你可以向一名有手牌的角色展示一张手牌，对方必须弃掉一张相同花色的手牌，否则需弃掉三张牌\
★单发技的定义：每回合出牌阶段可以发动且只能发动一次的技能",
	["@jiaojinask"] = "%src 发动了【较劲】，如果你不能弃掉和 %arg 相同花色的牌，你的装备或手牌将不保",

	["mourikogorou"] = "毛利小五郎",
	["chenshui"] = "沉睡",
	[":chenshui"] = "回合开始阶段，你可以选择跳过判定阶段、摸牌阶段和出牌阶段，若如此做，从主公开始所有角色必须打出一张【杀】，否则受到你造成的一点伤害，你可以指定一名角色不受技能影响",
	["chenshuiprotect"] = "请选择一名角色，该角色不受【沉睡】的影响",
	["chenshui-slash"] = "%src 陷入了沉睡，请打出一张【杀】来证明自己的清白",
	["jingxing"] = "惊醒",
	[":jingxing"] = "你每受到一点伤害，可立即摸两张牌或指定一名角色弃一张牌",
--	["zuoxi"] = "做戏",
--	[":zuoxi"] = "单发技，出牌阶段，当你发起的某个事件结算完毕后，未造成任何濒死或死亡，你可以反悔一次\
--★结算后反悔举例：当你用过河拆桥拆A，B出了无懈可击，你反无懈，A被拆。执行反悔操作，A从弃牌堆里收回被拆的牌，你回收无懈可击，B回收无懈可击，你回收过河拆桥，完毕",

	["edogawaconan"] = "江户川柯南",
	["zhinang"] = "智囊",
	[":zhinang"] = "回合外，每失去一张手牌，可以立即摸一张牌",
	["mazui"] = "麻醉",
	[":mazui"] = "单发技，你可以指定一名角色然后判定，若为红桃，该角色将其武将牌翻面",
	["fuyuan"] = "复原",
	[":fuyuan"] = "主公技，若你在弃牌阶段弃掉两张或两张以上的手牌，你可以获得工藤新一的武将技，有效期至你下个回合的弃牌阶段",
	["$Fuyuanrb"] = "%from 又变成了小屁孩的样子……",

	["haibaraai"] = "灰原哀",
	["pantao"] = "叛逃",
	[":pantao"] = "任意其他角色的回合开始前，若你已受伤且武将牌正面朝上，可以立即插入你的一个回合并将自己的武将牌翻面，此回合结束后，进入该角色的回合",
	["shiyan"] = "实验",
	[":shiyan"] = "单发技，出牌阶段，你可以对自己的一张手牌进行判定，若判定牌和此牌花色相同，可摸两张牌。无论结果，你都获得此判定牌",
	["$Shiyan"] = "%from 对 %card 进行实验",
	["$Shiyansuc"] = "%from 判定牌的花色和 %card 的花色相同 ，实验成功！",
	["$Shiyanfail"] = "%from 判定牌的花色和 %card 的花色不同 ，实验失败……",
	["qianfu"] = "潜伏",
	[":qianfu"] = "锁定技，当你的武将牌背面朝上时，黑色的【杀】对你无效",

	["yoshidaayumi"] = "吉田步美",
	["tianzhen"] = "天真",
	[":tianzhen"] = "锁定技，任意锦囊对你造成的伤害无效；你使用锦囊对其他角色造成的伤害无效",
	["#TianzhenPrevent"] = "%from 的锁定技【%arg】被触发，防止了当前锦囊对 %to 造成的 %arg2 点伤害",
	["lanman"] = "烂漫",
	[":lanman"] = "当你的手牌数小于4时，可以将方块手牌当【无中生有】使用",
	["dontcry"] = "不哭",
	[":dontcry"] = "觉醒技，首次行动跳过弃牌阶段，若第二次行动之后依然存活，增加1点体力上限并回复全部体力",
	["#BukuWake"] = "阳光总在风雨后，%from 触发了觉醒技【%arg】，增加了1点体力上限",

	["mouriran"] = "毛利兰",
	["duoren"] = "夺刃",
	[":duoren"] = "你可以将红色手牌当【闪】打出。当你打出一张【闪】时，可获得当前行动角色的武器",
	["shouhou"] = "守候",
	[":shouhou"] = "回合开始阶段，你可以选择跳过判定和摸牌阶段，为任一角色回复一点体力",

	["touyamakazuha"] = "远山和叶",
	["heqi"] = "合气",
	[":heqi"] = "当你成为【杀】的目标时，若你的手牌没有【杀】的使用者的所有牌多，你可以立即获得其一张手牌或一张判定区里的牌",
	["shouqiu"] = "手球",
	[":shouqiu"] = "当任意角色的判定牌生效前，你可以打出一张牌代替之",
	["@shouqiu-card"] = "请使用【手球】技能来修改 %src 的 %arg 判定",

	["kyougokumakoto"] = "京极真",
	["shenyong"] = "神勇",
	[":shenyong"] = "出牌阶段，当你使用的【杀】造成伤害时，可视为对原目标攻击范围内的另一目标使用了一张【杀】。神勇可连锁发动但每名角色只能被指定一次目标\
★神勇连锁举例：A对B出杀(黑桃8)，B没闪掉血，继续指定B攻击范围内的C，C没闪掉血，再指定C攻击范围内的D，D出闪，结束",

	["kaitoukid"] = "怪盗基德",
	["shentou"] = "神偷",
	[":shentou"] = "你可以将任意锦囊当【顺手牵羊】使用；若出牌阶段你使用【顺手牵羊】超过两次，可以跳过弃牌阶段",
	["baiyi"] = "白衣",
	[":baiyi"] = "单发技，你可以卸下自己的一件装备并让一名其他角色观看自己的手牌",
	["feixing"] = "飞行",
	[":feixing"] = "锁定技，当你装备区没牌时，视为你装备着一辆+1车",

	["sharon"] = "莎朗·温亚德",
	["wuyu"] = "物语",
	[":wuyu"] = "锁定技，每失去装备区里的一张牌，立即摸两张牌",
	["yirong"] = "易容",
	[":yirong"] = "限定技，当你死亡时，可重新选择一次武将，并恢复体力至3点",
	["@yaiba"] = "面膜",
	["$yirong"] = "A secret makes a woman woman.",

	["megurejyuuzou"] = "目暮十三",
	["quzheng"] = "取证",
	[":quzheng"] = "你可以获得其他角色弃牌阶段弃掉的所有牌。摸牌阶段摸牌前，若你的手牌数大于体力值，必须放弃摸牌",
	["ranglu"] = "让路",
	[":ranglu"] = "主公技，你可以将“取证”的机会交给其他侦势力角色",

	["shiratorininzaburou"] = "白鸟任三郎",
	["guilin"] = "归林",
	[":guilin"] = "任意角色判定阶段判定前，你可以和其交换判定区的所有牌",

	["matsumotokiyonaka"] = "松本清长",
	["shangchi"] = "伤饬",
	[":shangchi"] = "摸牌阶段，若你已受伤，可以额外摸X张牌，或者让另一名角色摸X-1张牌，X为你失去的体力",
	["shangchi:me"] = "自己摸牌",
	["shangchi:him"] = "其他人摸牌",
	["diaobing"] = "调兵",
	[":diaobing"] = "主公技，单发技，出牌阶段，你可以指定一个目标，让其他警势力角色轮流攻击一次\
★发动调兵时，警势力角色可以打出【杀】、【决斗】和【火攻】来响应",
	[":diaobing:"] = "%from 命令你攻击目标:",
	["diaobing:accept"] = "攻击",
	["diaobing:ignore"] = "弹药不足",
	["@diaobing-slash"] = "请打出一张【杀】【决斗】或【火攻】以响应主公的【调兵】",

	["otagiritoshirou"] = "小田切敏郎",
	["qinjian"] = "勤俭",
	[":qinjian"] = "当你的【杀】被抵消时，可做一次判定，若为红色，则收回那张【杀】，并立即使用一次",
	["@qinjian-slash"] = "你可以再使用一次【杀】",

	["kurobakaitou"] = "黑羽快斗",
--	["bjvh"] = "变装",
--	[":bjvh"] = "回合开始阶段，你可以弃一张牌，改变自己的性别",
	["tishen"] = "替身",
	[":tishen"] = "限定技，当你濒死时，可做一次判定，若为梅花，解除濒死状态并恢复体力至3点",
	["$tishen"] = "私に対してとてもキッドにとってできないことはない!",
	["@fake"] = "假人",
	["moshu"] = "魔术",
	[":moshu"] = "在任意角色摸牌阶段前，你可以获得堆顶的一张或两张牌，然后用等量手牌替换之，每轮限一次",
	["moshu:zero"] = "不发动",
	["moshu:one"] = "换1张",
	["moshu:two"] = "换2张",
	["#Moshu"] = "%from 发动了【%arg2】技能，替换了牌堆顶的 %arg 张牌",
	["moshu-only"] = "请选择一张手牌放到牌堆顶",
	["moshu-first"] = "请先选择一张手牌放到当前牌堆顶",
	["moshu-second"] = "请再选择一张手牌放到当前牌堆顶",

	["nakamoriaoko"] = "中森青子",
	["renxing"] = "任性",
	[":renxing"] = "单发技，你可以和一名体力不比你少的角色拼点，如果获胜，可获得对方的一张牌，否则失去一点体力",
	["qingmei"] = "青梅",
	[":qingmei"] = "锁定技，你参与拼点时，除你之外其他角色的基本牌点数均为1",
	["#Qingmeieff"] = "%from 的锁定技【%arg】生效，某张拼点牌的点数可能发生了改变",

	["gin"] = "琴酒",
	["ansha"] = "暗杀",
	[":ansha"] = "限定技，出牌阶段，弃掉四张不同花色的手牌，让一名角色获得暗杀标记（不明示）。该角色在其回合结束阶段受到你对其造成的3点伤害，发动后体力上限-1",
	["@ansha"] = "杀气",
	["$ansha"] = "安息吧，永远地安息吧……",
	["#Ansha"] = "%from 的技能【%arg】生效，目标是 %to",
	["juelu"] = "绝戮",
	[":juelu"] = "当你的【杀】造成伤害时，可以对受到伤害的角色再使用一次【杀】",
	["juelu-slash"] = "你可以继续对目标使用【杀】",
	["heiyi"] = "黑衣",
	[":heiyi"] = "主公技，其他黑势力角色可以跳过自己的摸牌阶段，令你下个摸牌阶段额外摸两张牌",
	["@heiyi"] = "黑衣",

	["vodka"] = "伏特加",
	["maixiong"] = "买凶",
	[":maixiong"] = "出牌阶段，你可以将自己的基本牌以每人一张的形式分给其他角色，每分出去两张，你回复一点体力",
	["dashou"] = "打手",
	[":dashou"] = "回合结束阶段，你可以向每名其他角色要一张牌，若你获得的牌大于两张，将武将牌翻面",
	["@dashou-get"] = "%src 向你求一张牌，想给就给，不想给就别给",

	["akaishuichi"] = "赤井秀一",
	["jushen"] = "狙神",
	[":jushen"] = "锁定技，你的【杀】不可闪避",
	["#Jushenslash"] = "%from 的锁定技【%arg】生效，目标不可闪避",
	["xunzhi"] = "殉职",
	[":xunzhi"] = "锁定技，当你死亡时，令包括杀死你的角色在内的一共两名角色获得以下技能直到游戏结束：摸牌阶段，少摸一张牌",
	["#Xunzhieffect"] = "%from 受到【%arg】效果的影响，少摸了1张牌",
	["@aka"] = "红色",

	["agasahiroshi"] = "阿笠博士",
	["gaizao"] = "改造",
	[":gaizao"] = "摸牌阶段摸牌前，弃掉一名角色装备区内的一张牌，自己和对方同时摸一张牌",
	["suyuan"] = "溯源",
	[":suyuan"] = "在你参与的伤害事件结算前，你可以更改伤害来源",
	["#SuyuanChange"] = "%from 发动了技能【%arg】，将本次伤害来源更改为 %to",
	["baomu"] = "保姆",
	[":baomu"] = "主公技，在少势力角色濒死时，你可以弃一张黑桃手牌，为其回复1点体力",

	["kobayashisumiko"] = "小林澄子",
	["yuanding"] = "园丁",
	[":yuanding"] = "出牌阶段，你可以亮出一张手牌并指定一名有手牌的角色，该角色需给你一张手牌，然后获得你亮出的这张牌",
	["@yuandingask"] = "%src 发动了【园丁】，你可以用一张手牌替换亮出的园丁牌",
	["qiniao"] = "栖鸟",
	[":qiniao"] = "弃牌阶段，若你的弃牌数小于2，可以指定一名角色，其下回合的判定阶段自动跳过",
	["@bird"] = "鸟",

	["yamamuramisae"] = "山村美砂绘",
	["biaoche"] = "飙车",
	[":biaoche"] = "锁定技，当与体力比你多的角色计算距离时，始终-1；当体力比你多的角色计算和你的距离时，始终+1",
	["jingshen"] = "敬神",
	[":jingshen"] = "单发技，每回合你可以将一张手牌移出游戏作为“祭品”，当祭品数和场上人数相等时，全部取出来并交给一名角色",
	["jipin"] = "祭品",

	["aoyamagoushou"] = "青山刚昌",
	["long"] = "龙颿",
	[":long"] = "你每造成一次伤害时，可做一次判定，若判定牌点数为合数，你摸一张牌并抵消此伤害；为质数，对方立即摸两张牌且伤害+1；既不是质数也不是合数，伤害+2\
★关于质数和合数的概念请查阅四年级小学数学课本",

	["uzumaki"] = "漩涡鸣人",
	["haruno"] = "春野樱",
}

