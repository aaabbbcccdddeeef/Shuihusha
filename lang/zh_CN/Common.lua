-- The common
return {
	["Shuihusha"] = "水浒杀",
	["DefaultDesigner"] = "烨子",
	["DefaultCV"] = "佚名",
	["DefaultCoder"] = "宇文天启",
	["UnknowNick"] = "",
	["DefaultIllustrator"] = "",

	["lord"] = "主公",
	["loyalist"] = "忠臣",
	["rebel"] = "反贼",
	["renegade"] = "内奸",
	["spade_char"] = "♠",
	["club_char"] = "♣",
	["heart_char"] = "♥",
	["diamond_char"] = "♦",
	["no_suit_char"] = "无色",
	["start"] = "开始",
	["judge"] = "判定",
	["draw"] = "摸牌",
	["play"] = "出牌",
	["discard"] = "弃牌",
	["finish"] = "结束",
	["online"] = "在线",
	["offline"] = "离线",
	["robot"] = "电脑",
	["trust"] = "托管",
	["yes"] = "是",
	["no"] = "否",
	["male"] = "男性",
	["female"] = "女性",

	["Pairs"] = "双将",
	["spade"] = "黑桃",
	["club"] = "梅花",
	["heart"] = "红桃",
	["diamond"] = "方块",
	["no_suit"] = "无色",
	["basic"] = "基本牌",
	["trick"] = "锦囊牌",
	["equip"] = "装备牌",
	["ndtrick"] = "非延时锦囊",
	["attack_card"] = "进攻牌",
	["defense_card"] = "防御牌",
	["recover_card"] = "恢复牌",
	["global_effect"] = "全局效果",
	["aoe"] = "范围效果",
	["single_target_trick"] = "单体锦囊",
	["delayed_trick"] = "延时锦囊",
	["buff_card"] = "辅助伤害卡",
	["damage_spread"] = "伤害传导",
	["weapon"] = "武器",
	["armor"] = "防具",
	["defensive_horse"] = "防御马",
	["offensive_horse"] = "进攻马",
	["disgusting_card"] = "恶心牌",

	["guan"] = "官",
	["jiang"] = "将",
	["min"] = "民",
	["kou"] = "寇",
	["god"] = "神",

	["[Limited]"] = " [限]",
	["[Compulsory]"] = " [锁]",
	["[Wake]"] = " [醒]",

	["#Murder"] = "%to【%arg】 挂了，凶手是 %from",
	["#Suicide"] = "%to【%arg】 自杀身亡",
	["#InvokeSkill"] = "%from 使用了技能【%arg】",
	["#TriggerSkill"] = "%from 的锁定技【%arg】被触发",
	["#UseSkill"] = "%from 发动了技能【%arg】，目标是 %to",
	["#WakeUp"] = "已满足触发条件，%from 的觉醒技【%arg】被触发",
	["#Pindian"] = "%from 向 %to 发起了拼点",
	["#PindianSuccess"] = "%from (对 %to) 拼点成功！\\(^o^)/",
	["#PindianFailure"] = "%from (对 %to) 拼点失败！-_-！",
	["#Damage"] = "%from 对 %to 造成了 %arg 点伤害[%arg2]",
	["#DamageNoSource"] = "%to 受到了 %arg 点伤害[%arg2]",
	["#Recover"] = "%from 恢复了 %arg 点体力",
	["#AskForPeaches"] = "%from 向 %to 求【肉】，一共需要 %arg 块【肉】",
	["#ChooseKingdom"] = "%from 选择了 %arg 作为他的势力",
	["#NullificationDetails"] = "%from 对 %to 的锦囊【%arg】被抵消",
	["#SkillAvoid"] = "%from 的 %arg 技能被触发，这张 %arg2 不能指定其作为目标",
	["#Transfigure"] = "%from 变身为 %arg",
	["#AcquireSkill"] = "%from 获得了技能 【%arg】",
	["#LoseSkill"] = "%from 失去了技能 【%arg】",
	["$InitialJudge"] = "%from 最初的判定结果为 %card",
	["$ChangedJudge"] = "%from 把 %to 的判定结果改判成了 %card",
	["$MoveCard"] = "%to 从 %from 处得到了 %card",
	["$PasteCard"] = "%from 给 %to 贴了张 %card",
	["$LightningMove"] = "%card 从 %from 移动到 %to",
	["$DiscardCard"] = "%from 弃置了 %card",
	["$DiscardCardByOther"] = "%from 弃置了 %to 的卡牌 %card",
	["$EnterDiscardPile"] = "%card 被置入弃牌堆",
	["$RecycleCard"] = "%from 从弃牌堆回收了 %card",
	["$Dismantlement"] = "%from 被拆掉了 %card",
	["$ShowCard"] = "%from 展示了 %card",
	["$PutCard"] = "%from 的 %card 被放置在了摸牌堆",
	["normal_nature"] = "无属性",
	["fire_nature"] = "火焰属性",
	["thunder_nature"] = "雷电属性",
	["#Contingency"] = "%to【%arg】 挂了，死于天灾",
	["#DelayedTrick"] = "%from 的延时锦囊【%arg】开始判定",
	["#SkillNullify"] = "%from 的技能【%arg】被触发，【%arg2】对其无效",
	["#ComskillNullify"] = "%to 的锁定技【%arg2】被触发，%from 对 %to 的 %arg 无效",
	["#ArmorNullify"] = "%from 的防具【%arg】技能被触发，【%arg2】对其无效",
	["#DrawNCards"] = "%from 摸了 %arg 张牌",
	["#MoveNCards"] = "%to 从 %from 处得到 %arg 张牌",
	["$TakeAG"] = "%from 拿走了 %card",
	["$Install"] = "%from 装备了 %card",
	["$Uninstall"] = "%from 卸载了 %card",
	["$JudgeResult"] = "%from 最终判定结果为 %card",
	["$PindianResult"] = "%from 的拼点结果为 %card",
	["#ChooseSuit"] = "%from 选择了花色 %arg",
	["#DeclareSuit"] = "%from 声明的花色是 %arg",
	["#TurnOver"] = "%from 将自己的武将牌翻面，现在是 %arg",
	["face_up"] = "面朝上",
	["face_down"] = "面朝下",
	["#SkipPhase"] = "%from 跳过了 %arg 阶段",
	["#SkipAllPhase"] = "%from 中止了当前回合",
	["#IronChainDamage"] = "%from 处于铁锁连环状态，将受到铁锁的传导伤害",
	["#LoseHp"] = "%from 流失了 %arg 点体力",
	["#LoseMaxHp"] = "%from 流失了 %arg 点体力上限",
	["#LostMaxHpPlus"] = "%from 流失了 %arg 点体力上限，并同时流失了 %arg2 点体力",
	["#ChangeKingdom"] = "%from 把 %to 的国籍由原来的 %arg 改成了 %arg2",
	["#AnalepticBuff"] = "%from 喝了【%arg】，对 %to 造成的杀伤害 +1",
	["#GetMark"] = "%from 得到了 %arg2 枚 %arg 标记",
	["#LoseMark"] = "%from 失去了 %arg2 枚 %arg 标记",
	["#GuanxingUpOnly"] = "%from 将 %arg 张牌放到了牌堆顶",
	["#GuanxingResult"] = "%from 将 %arg 张牌放到了牌堆顶，将 %arg2 张牌放到了牌堆底",
	["$CheatCard"] = "%from 使用了作弊，获得了 %card",
	["#ShowRole"] = "%from 的身份是【%arg】",
	["#RemoveHidden"] = "恭喜 %from 达成了隐藏技获得的条件！",

	-- askForChoice相关
	["draw1card"] = "摸1张牌",
	["draw2card"] = "摸2张牌",
	["recover1hp"] = "回复1点体力",
	["cancel"] = "不发动",

}