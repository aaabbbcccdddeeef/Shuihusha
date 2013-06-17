module("extensions.draggon",package.seeall)
extension=sgs.Package("draggon")
dofile "extensions/ai/funs.lua"

yzdisnum={3};

--ADD Generals--
--sproxiel=sgs.General(extension,"sproxiel","min",4)

splujunyi=sgs.General(extension,"splujunyi$","min",4)
splinchong=sgs.General(extension,"splinchong$","kou",4)
spluzhishen=sgs.General(extension,"spluzhishen$","jiang",4)
spwusong=sgs.General(extension,"spwusong","min",4)
spzhulei=sgs.General(extension,"spzhulei","kou",4)
spzhuwu=sgs.General(extension,"spzhuwu","min",3)
sphuyanzhuo=sgs.General(extension,"sphuyanzhuo","guan",4)
--spbird=sgs.General(extension,"spbird","god",4)
--spyuefei=sgs.General(extension,"spyuefei","god",4)
spyuefei=sgs.General(extension,"spyuefei","god",4)
spyangzhi=sgs.General(extension,"spyangzhi","guan",4)
sphuangxin=sgs.General(extension,"sphuangxin","guan",4)
g1=sgs.General(extension,"g1","min",3)
---------------
luajueding=sgs.CreateTriggerSkill{
	name="luajueding",
	events=sgs.PhaseChange,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Discard then
			local x=player:getMaxHp()*2-player:getHp()
			local y=player:getHandcardNum()
			if y>player:getHp() then SkillLog(player,self:objectName(),0,0) end
			if y>x then room:askForDiscard(player,"luajueding",y-x,y-x,false,false) end
			return true
		end
	end,
}

luajinshen=sgs.CreateTriggerSkill{
	name="luajinshen",
	events=sgs.CardEffected,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local card=data:toCardEffect().card--记录使用的卡
		if player:getArmor() then return false end
		if not (card:inherits("Slash") and card:isRed()) then return false end--卡片种类不符则不发动
		SkillLog(player,self:objectName(),0,0)
		return true--卡片无效
	end
}

luayijiucard=sgs.CreateSkillCard{--技能卡
	name="luayijiucard",
	target_fixed=true,--应该是不用选对象
	on_use=function(self,room,source,targets)
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do--循环，逐一检视其它角色
			if p:isAlive() and not p:isNude() and p:getKingdom()=="jiang" then--未死，有牌
				local card=room:askForCard(p,".|spade","@askforluayijiu")--请求弃牌
				if card then
					local card=sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
					card:setSkillName(self:objectName())
					local use=sgs.CardUseStruct()
					use.card=card
					use.from=source
					room:useCard(use)
					return
				end
			end
		end
	end,
}
luayijiu=sgs.CreateViewAsSkill{
	name="luayijiu$",
	n=0,
	view_as=function(self,cards)
		local acard=luayijiucard:clone()
		return acard
	end,
	enabled_at_play=function()
		return not sgs.Self:hasUsed("Analeptic")
	end,
	enabled_at_response=function(self,player,pattern)
		return string.find(pattern,"analeptic") or string.find(pattern,"peach")
	end
}


spluzhishen:addSkill(luajueding)
spluzhishen:addSkill(luajinshen)
spluzhishen:addSkill(luayijiu)

luaweiyan=sgs.CreateTriggerSkill{
	name="luaweiyan",
	events={sgs.SlashProceed,sgs.Predamage},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()--获取房间
		if player:getMark("@luayusui")==1 then return false end
		if event==sgs.SlashProceed then
			local effect=data:toSlashEffect()
			local to=effect.to
			local from=effect.from
			if to:getHp()<=from:getHp() and to:getHandcardNum()<=from:getHandcardNum() then
				SkillLog(player,self:objectName(),0,0)
				room:slashResult(effect,nil)--结算杀中了，然后无效原来的
				return true
			end
		end
		if event==sgs.Predamage then
			local damage=data:toDamage()
			local to=damage.to
			local from=damage.from
			local reason=damage.card
			if not reason then return false end
			if reason:inherits("Slash") then
				if to:getHp()>=from:getHp() and to:getHandcardNum()>=from:getHandcardNum() then
					SkillLog(player,self:objectName(),0,0)
					damage.damage=damage.damage+1
					data:setValue(damage)
					return false
				end
			end
			return false
		end
	end,
}

luayusui=sgs.CreateTriggerSkill{
	name="luayusui",
	events=sgs.PhaseChange,--阶段改变时发动
	frequency=sgs.Skill_Limited,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()--获取房间
		if player:getMark("@luayusui")==1 then return false end
		if player:getPhase()==sgs.Player_Finish then--出牌阶段
			if room:askForSkillInvoke(player,"luayusui") then--确认发动
				player:gainMark("@luayusui")
				player:turnOver()
				if player:isWounded() then
					local recover=sgs.RecoverStruct()
					recover.recover=1
					recover.who=player
					room:recover(player,recover)--回复
				end
				room:acquireSkill(player,"baoguo")
				room:detachSkillFromPlayer(player,"luaweiyan")
			end
			return false--不跳过阶段
		end
	end,
}

luamingwang=sgs.CreateTriggerSkill{
	name="#luamingwang$",
	events=sgs.PhaseChange,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local lord=room:getLord()
		if lord:objectName()==player:objectName() then return false end
		if not lord:hasSkill(self:objectName()) then return false end
		if player:getPhase()==sgs.Player_Start then--开始阶段
			if player:getKingdom()=="min" and player:getHp()==1 then
				if room:askForSkillInvoke(player,"luamingwangvs") then
					room:loseMaxHp(player)
					room:setPlayerProperty(lord,"maxhp",sgs.QVariant(lord:getMaxHp()+1))
				end
			end
		end
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()
	end,
}
luamingwangcard=sgs.CreateSkillCard{--技能卡
	name="luamingwangcard",
	target_fixed=true,--应该是不用选对象
	on_use=function(self,room,source,targets)
		local lord=source
		for _,theplayer in sgs.qlist(room:getOtherPlayers(lord)) do--循环，逐一检视所有角色
			if theplayer:getKingdom()=="min" and theplayer:getHp()==1 then
				if room:askForSkillInvoke(theplayer,"luamingwangvs") then
					room:loseMaxHp(theplayer)
					room:setPlayerProperty(lord,"maxhp",sgs.QVariant(lord:getMaxHp()+1))
				end
			end
		end
	end,
}
luamingwangvs=sgs.CreateViewAsSkill{
	name="luamingwangvs$",
	n=0,
	view_as=function(self,cards)
		local acard=luamingwangcard:clone()
		return acard
	end,
}

luabaoguo=sgs.CreateTriggerSkill{--触发技
	name="luabaoguo",
	events={sgs.Damaged,sgs.Predamaged},--受到伤害时
	on_trigger=function(self,event,player,data)--要执行的动作
		local room=player:getRoom()--获取房间
		if event==sgs.Damaged then
			if player:hasSkill(self:objectName()) then
				SkillLog(player,self:objectName(),0,0)
				player:drawCards(player:getLostHp())
			end
			return false
		end
		if event==sgs.Predamaged then
			local pattern=".a,BasicCard"--基本牌，锦囊牌，对应花色，加上.a可以让系统不播放牌的音效
	--		player:speak("111")
			for _,theplayer in sgs.qlist(room:getOtherPlayers(player)) do--循环，逐一检视所有角色
				if theplayer:hasSkill("luabaoguo") then--有这个技能，不是使用中（否则两张杀换来换去死循环）
	--		theplayer:speak("111")
					local card=room:askForCard(theplayer,pattern,"askforluabaoguo",data)--请求弃牌
					if card then
						SkillLog(theplayer,self:objectName(),2,0)
						local damage=data:toDamage()
						damage.to=theplayer
						room:damage(damage)
						return true
					end
				end
			end
		end
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()--重载cantrigger，不是自己也能用（相当于略去hasskill）
	end,
}


splujunyi:addSkill(luaweiyan)
splujunyi:addSkill(luayusui)
splujunyi:addSkill(luamingwang)
splujunyi:addSkill(luamingwangvs)
--splujunyi:addSkill(luabaoguo)
local skill=sgs.Sanguosha:getSkill("luabaoguo")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(luabaoguo)
	sgs.Sanguosha:addSkills(skillList)
end

luashenqiangcard=sgs.CreateSkillCard{
	name="luashenqiangcard",
	filter=function(self,targets,to_select,player)
		if #targets==0 then--未选定借刀杀人的第一个对象
			local pl=sgs.PlayerList()
			local card=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			return card:targetFilter(pl,to_select,player)
		else
			return false
		end
	end,
	on_use=function(self,room,source,targets)
		room:throwCard(self)
		room:setPlayerFlag(source,"luashenqiangUsed")
		if #targets<1 then return false end--未选够两个人
		local victim=targets[1]--被杀的人
		local card=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		card:setSkillName(self:objectName())
		local use=sgs.CardUseStruct()
		use.card=card
		use.from=source
		use.to:append(victim)
		room:useCard(use,false)
	end,
}
luashenqiang=sgs.CreateViewAsSkill{
	name="luashenqiang",
	n=2,
	view_filter=function(self,selected,to_select)
		return to_select:inherits("BasicCard")--要求是杀
	end,
	view_as=function(self,cards)
		if #cards==2 then--选了一张牌
			local acard=luashenqiangcard:clone()--复制技能卡
			acard:addSubcard(cards[1]:getId())
			acard:addSubcard(cards[2]:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("luashenqiangUsed")
	end,
}
luashenqiangTR=sgs.CreateTriggerSkill{
	name="#luashenqiangTR",
	events=sgs.Predamage,
	on_trigger=function(self,event,player,data)
		local damage=data:toDamage()
		local room=player:getRoom()
		local reason=damage.card
		if not reason then return false end
		if reason:inherits("Slash") and reason:getSkillName()=="luashenqiangcard" then
			SkillLog(player,"luashenqiang",0,0)
			damage.damage=damage.damage+1
			data:setValue(damage)
			return false
		end
	end
}

luahuopin=sgs.CreateTriggerSkill{
	name="luahuopin$",
	events=sgs.PhaseChange,--阶段改变时发动
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()--获取房间
		if player:getPhase()==sgs.Player_Start then--出牌阶段
			if player:getMark("@luahuopin")==0 then return false end
			SkillLog(player,self:objectName(),0,0)
			local bool=room:askForDiscard(player,"luahuopin",3,true,true)
			if bool then
				if player:isWounded() then
					local recover=sgs.RecoverStruct()
					recover.recover=1
					recover.who=player
					room:recover(player,recover)--回复
				end
			else
				room:loseHp(player)
				player:drawCards(3)
			end
			return false--不跳过阶段
		end
	end,
}
luahuopinTR=sgs.CreateTriggerSkill{
	name="#luahuopinTR",
	events=sgs.Death,--阶段改变时发动
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()--获取房间
		local lord=room:getLord()
		if not lord:hasSkill(self:objectName()) or lord:getMark("@luahuopin")==1 then return false end
		lord:gainMark("@luahuopin")
	end,
	can_trigger=function(self,player)
		return player and player:getKingdom()=="kou"
	end,
}


splinchong:addSkill(luashenqiang)
splinchong:addSkill(luashenqiangTR)
splinchong:addSkill(luahuopin)
splinchong:addSkill(luahuopinTR)

luashenchou=sgs.CreateTriggerSkill{--奸雄 by hypercross
	name="luashenchou",
	events=sgs.Damaged,
	frequency=sgs.Skill_Compulsory,--锁定技，
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local card=data:toDamage().card
		SkillLog(player,self:objectName(),0,0)
		if card then room:obtainCard(player,card) end
		local card2=room:askForCard(player,".|.|.|.","~luashenchou")
		room:playSkillEffect("luashenchou",math.random(1,2))
		if card2 then player:addToPile("luashenchou",card2) end
	end
}
luaduanbi=sgs.CreateTriggerSkill{
	name="luaduanbi",
	events=sgs.PhaseChange,
	frequency=sgs.Skill_Limited,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()~=sgs.Player_Start or player:getHp()~=1 or player:getMark("luaduanbi")==1 then return false end
		if not room:askForSkillInvoke(player,"luaduanbi",data) then return false end
		room:setPlayerMark(player,"luaduanbi",1)
		room:loseMaxHp(player,player:getMaxHp()-1)
		local pls=room:getOtherPlayers(player)
		local target=room:askForPlayerChosen(player,pls,"luaduanbi")
		if room:askForChoice(player,"luaduanbi","recover+damage")=="recover" then
			room:playSkillEffect("luaduanbi")
			local recover=sgs.RecoverStruct()
			recover.recover=2
			recover.who=player
			room:recover(target,recover)--回复
		else
			room:playSkillEffect("luaduanbi")
			local damage = sgs.DamageStruct()
			damage.from = player
			damage.to = target
			damage.damage=2
			room:damage(damage)
		end
	end,
}
luawujie=sgs.CreateTriggerSkill{
	name="luawujie",
	events=sgs.PhaseChange,
	frequency=sgs.Skill_Wake,
	priority=3,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()~=sgs.Player_Start or player:getPile("luashenchou"):length()<3 or player:getMark("luazhusha")==1 then return false end
		room:setPlayerMark(player,"luazhusha",1)
		SkillLog(player,self:objectName(),0,0)
		room:playSkillEffect("luawujie")
		room:loseMaxHp(player)
		room:acquireSkill(player,"luazhusha")
	end,
}
luazhusha_card=sgs.CreateSkillCard{--技能卡
	name="luazhusha_card",
	filter=function(self,targets,to_select,player)
		if #targets>1 then return false end
		local slash=CreateCard("slash")
		local pl=sgs.PlayerList()
		return player:canSlash(to_select,false)--slash:targetFilter(pl,to_select,player)
	end,
	on_use=function(self,room,source,targets)
		local parts=source:getPile("luashenchou")--获取圣谕牌
 		room:fillAG(parts,source)--填充ag界面
		local cdid=room:askForAG(source,parts,false,"luazhusha")
		local cd=sgs.Sanguosha:getCard(cdid)
		if cd:inherits("Weapon") or cd:inherits("EventsCard") then room:setPlayerFlag(source,"luazhusha") end
		room:throwCard(cdid,source)--弃掉
		source:invoke("clearAG")
		room:playSkillEffect("luazhusha",math.random(1,2))
		local use=sgs.CardUseStruct()--卡牌使用结构体
		use.card=CreateCard("slash",nil,"luazhusha")
		use.from=source
		local targetnum=#targets
		for var=1,targetnum,1 do
			use.to:append(targets[var])
		end
		room:useCard(use,false)
		room:setPlayerFlag(source,"-luazhusha")
	end,
}
luazhusha_vs=sgs.CreateViewAsSkill{
	name="luazhusha_vs",
	view_as=function(self,cards)
		return CreateCard(luazhusha_card)
	end,
	enabled_at_play=function(self,player)
	--	local slash=CreateCard("slash")
		return --[[slash:isAvailable(sgs.Self) and]] sgs.Self:getPile("luashenchou"):length()>0--牌堆有牌
	end,
}
luazhusha=sgs.CreateTriggerSkill{
	name="luazhusha",
	events=sgs.Predamage,
	view_as_skill=luazhusha_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()--获取房间
		local damage=data:toDamage()
		local from=damage.from
		if from:hasFlag("luazhusha") then
			SkillLog(player,self:objectName(),0,0)
			damage.damage=damage.damage+1
			data:setValue(damage)
			return false
		end
	end,
}

spwusong:addSkill(luawujie)
spwusong:addSkill(luaduanbi)
TempSkill(luazhusha)
spwusong:addSkill(luashenchou)

sgs.LoadTranslationTable{
	["draggon"]="群龙逆天",

	["spluzhishen"]="鲁智深",
	["#spluzhishen"]="聚义逆天",
	["luajueding"]="绝顶",
	[":luajueding"]="锁定技,你的手牌上限等于你的体力上限加上你的已损失体力值.",
	["luajinshen"]="金身",
	[":luajinshen"]="锁定技,若你没有装备防具,红色【杀】对你无效",
	["luayijiu"]="义酒",
	["luayijiucard"]="义酒",
	[":luayijiu"]="主公技,当你需要一张【酒】时,其他将势力角色弃置一张黑桃牌，若如此做,视为你使用一张【酒】",
	["@askforluayijiu"]="你可以弃置一张黑桃牌，若如此做,视为主公使用一张【酒】",

	["splujunyi"]="卢俊义",
	["#splujunyi"]="无双无对",
	["luaweiyan"]="威严",
	[":luaweiyan"]="锁定技,你使用【杀】指定的目标的当前体力值和手牌数均不大于你的,则该【杀】不可被【闪】响应;若目标角色的当前体力值和手牌数均不少于你的.则该【杀】造成的伤害+1.",
	["luayusui"]="玉碎",
	["@luayusui"]="玉碎",
	[":luayusui"]="限定技,回合结束阶段,你可以将你的武将牌翻面并且回复一点体力,然后你失去技能【威严】,获得技能【报国】",
	["luamingwangvs"]="名望",
	["luamingwangcard"]="名望",
	[":luamingwangvs"]="主公技,其他体力为1的民势力角色在其回合开始阶段可减1点体力上限，然后令你加1点体力上限.",
	["luabaoguo"]="报国",
	["askforluabaoguo"]="你可以弃置一张基本牌，将该伤害转移给你",
	[":luabaoguo"]="当其他角色受到伤害时，你可以弃置一张基本牌，将该伤害转移给你；你每受到一次伤害，可以摸X张牌（X为你已损失的体力值）。",

	["splinchong"]="林冲",
	["#splinchong"]="火拼夺位",
	["luashenqiang"]="神枪",
	["luashenqiangcard"]="神枪",
	[":luashenqiang"]="限制技,出牌阶段,你可以弃掉两张基本牌,若如此做,则视为你对你攻击范围内的任意一名角色使用了一张【杀】.该【杀】造成的伤害+1.",
	["luahuopin"]="火拼",
	["@luahuopin"]="火拼",
	[":luahuopin"]="主公技.锁定技,回合开始阶段,若场上存在已死亡的寇势力角色,你须执行下列两项中的一项：1.摸取3张牌，然后失去1点体力；2.弃置3张牌，然后回复1点体力。",
	["spwusong"]="武松",
	["#spwusong"]="杀人者打虎",
	["cv:spwusong"]="猎狐",
	["luashenchou"]="深仇",
	[":luashenchou"]="你始终获得对你造成伤害的牌;你每受到一次伤害你可以将一张牌置于你的武将牌上称为“仇”。",
	["~luashenchou"]="你始终获得对你造成伤害的牌;你每受到一次伤害你可以将一张牌置于你的武将牌上称为“仇”。",
	["luawujie"]="无戒",
	[":luawujie"]="觉醒技,回合开始阶段,你的“仇”为3张或更多时,你须减少一点体力上限,然后获得技能【诛杀】(出牌阶段,你可弃置一张“仇”视为对至多两名角色使用一张【杀】,额外的,“仇”为武器牌或事件牌,此【杀】造成伤害+1)",
	["luazhusha"]="诛杀",
	recover="回复2",
	damage="伤害2",
	["luazhusha_card"]="诛杀",
	[":luazhusha"]="出牌阶段,你可弃置一张“仇”视为对至多两名角色使用一张【杀】,额外的,“仇”为武器牌或事件牌,此【杀】造成伤害+1",
	["luaduanbi"]="断臂",
	[":luaduanbi"]="限定技,回合开始阶段,若你的体力为1,你可以将体力上限减至1,然后让任一角色回复或失去2点体力.",

	["$luawujie"]="冤各有头，债各有主！",
	["$luaduanbi"]="自断一臂，力擒此贼！",
	["$luashenchou1"] = "人无刚骨，安身不牢。",
	["$luashenchou2"] = "杀兄之仇，不共戴天！",
}

luaqiankun=sgs.CreateProhibitSkill{
	name="luaqiankun",
	is_prohibited=function(self,from,to,card)
		return to:hasSkill(self:objectName()) and from:getHp()>to:getHp() and (card:inherits("Duel") or card:inherits("Slash"))--有喝酒标记的人的杀无效
	end,
}

function getLeftAlive(player)
	local i=player
	while i:getNextAlive():objectName()~=player:objectName() do
		i=i:getNextAlive()
	end
	return i
end
luanizhuan=sgs.CreateTriggerSkill{
	name="luanizhuan",
	events={sgs.AskForRetrial,sgs.PhaseChange},
	frequency=sgs.Skill_Limited,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local source=player
		if player:getPhase()~=sgs.Player_Finish then return false end
		if player:getMark("@luanizhuan")==1 then return false end
		if room:askForCard(player,".a,DelayedTrick","askforluanizhuan") then
			source:gainMark("@luanizhuan",1)
			local right=source:getNextAlive()
			local left=getLeftAlive(source)
			while right:objectName()~=left:objectName() do
				left:speak("left")
				right:speak("right")
				room:swapSeat(right,left)
				local t=left
				left=right
				right=t
				if right:getNextAlive():objectName()==left:objectName() then break end
				right=right:getNextAlive()
				left=getLeftAlive(left)
			end
		end
		return false
	end,
}
--[[luanizhuan=sgs.CreateViewAsSkill{
	name="luanizhuan",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:inherits("DelayedTrick")--要求是杀
	end,
	view_as=function(self,cards)
		if #cards==0 then return nil end
		acard=luanizhuanCard:clone()--复制一张卡的效果
		acard:addSubcard(cards[1])
		return acard--返回一张新卡
	end,
	enabled_at_play=function()
		return sgs.Self:getMark("@luanizhuan")==0
	end,
}]]

luaqianlv=sgs.CreateTriggerSkill{
	name="luaqianlv",
	events={sgs.AskForRetrial,sgs.PhaseChange},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.AskForRetrial then
			local judge=data:toJudge()
			if judge.who:objectName()~=player:objectName() then return false end
			if not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			local id=room:getNCards(1):at(0)
			local card=sgs.Sanguosha:getCard(id)
			room:throwCard(judge.card)
			judge.card=card
			room:throwCard(card)
			local log=sgs.LogMessage()
			log.type="$ChangedJudge"
			log.from=player
			log.to:append(judge.who)
			log.card_str=card:getEffectIdString()
			room:sendLog(log)
			room:sendJudgeResult(judge)
			return false
		end
		if player:getPhase()~=sgs.Player_Draw then return false end
		if not room:askForSkillInvoke(player,self:objectName()) then return false end
		local idlist=room:getNCards(2)
		room:askForGuanxing(player,idlist,false)
		local newlist=sgs.IntList()
		local pile=room:getDrawPile()
		local n=pile:length()
		newlist:append(pile:at(0))
		newlist:append(pile:at(1))
	--	local newlist=room:getNCards(2)
		local uplist=sgs.IntList()
		for _,id in sgs.qlist(idlist) do
			local up=false
			for _,id2 in sgs.qlist(newlist) do
				if id==id2 then up=true end
			end
			if not up then
				room:throwCard(id)
			else
				uplist:append(id)
			end
		end
--		if uplist:length()>0 then room:askForGuanxing(player,uplist,true) end
	end,
}

spzhuwu:addSkill(luaqianlv)
spzhuwu:addSkill(luaqiankun)
spzhuwu:addSkill(luanizhuan)
sgs.LoadTranslationTable{
	["spzhuwu"]="朱武",
	["#spzhuwu"]="千虑之师",
	["luaqianlv"]="千虑",
	[":luaqianlv"]="在你的判定牌生效前，你可以亮出牌堆顶的一张牌代替之；摸牌阶段开始时，你可以观看牌堆顶的两张牌并可以将其置入弃牌堆。",
	["luaqiankun"]="乾坤",
	[":luaqiankun"]="锁定技，你不能成为体力比你多的角色使用【杀】和【决斗】的目标。",
	["luanizhuan"]="逆转",
	["@luanizhuan"]="逆转",
	["askforluanizhuan"]="回合结束阶段开始时，你可以弃置一张延时类锦囊牌，若如此做，所有角色行动和响应群体性锦囊的方向均反转。",
	[":luanizhuan"]="限定技，回合结束阶段开始时，你可以弃置一张延时类锦囊牌，若如此做，所有角色行动和响应群体性锦囊的方向均反转。",
}

luachongfeng=sgs.CreateViewAsSkill{--基本就是“武圣”，没啥必要注释了吧。。。
	name="luachongfeng",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:inherits("DefensiveHorse") or to_select:inherits("OffensiveHorse")
	end,
	view_as=function(self,cards)
		if #cards==1 then return CreateCard("iron_chain",cards,"luachongfeng") end
	end,
}
luamahuan=sgs.CreateDistanceSkill{
	name="luamahuan",
	correct_func=function(self,from,to)
		local t=0
		if from:isChained() then t=t+1 end
		for _,ap in sgs.qlist(from:getSiblings()) do
			if ap:isChained() then t=t+1 end
		end
		if from:hasSkill(self:objectName()) then return 0-t end
		if to:hasSkill(self:objectName()) then return 0+t end
		return 0
	end,
}


sphuyanzhuo:addSkill(luachongfeng)
sphuyanzhuo:addSkill(luamahuan)
sgs.LoadTranslationTable{
	["sphuyanzhuo"]="呼延灼",
	["#sphuyanzhuo"]="来去如风",
	["luachongfeng"]="马环",
	[":luachongfeng"]="出牌阶段,你可以将你的坐骑牌当成【铁索连环】使用或重铸",
	["luamahuan"]="冲锋",
	[":luamahuan"]="锁定技,你与其他角色计算距离-X,其他角色计算与你计算距离+X,X为场上横置角色数.",
}

--Skills--
luasaodangcard=sgs.CreateSkillCard{
name="luasaodangcard",
filter=function(self,targets,to_select,player)
if (#targets>=3) then return false end
if to_select:hasSkill("luasaodang") then return false end
return true
end,
on_effect=function(self,effect)
	local room=effect.from:getRoom()
	local judge=sgs.JudgeStruct()
    judge.pattern=sgs.QRegExp("(.*):(heart|diamond):(.*)")
    judge.good=true
    judge.reason=self:objectName()
    judge.who=effect.to
    room:judge(judge)
	if judge:isGood() then
		if effect.to:getHandcardNum()<2 or not room:askForDiscard(effect.to, self:objectName(),2,2,true,true) then
			local damage=sgs.DamageStruct()
			damage.damage=1
			damage.from=effect.from
			damage.to=effect.to
			room:damage(damage)
		end
	end
end
}
luasaodangvs=sgs.CreateViewAsSkill{
name="luasaodangvs",
n=0,
view_filter=function(self, selected, to_select)
	return false
end,
view_as=function(self, cards)
	if #cards==0 then
	local acard=luasaodangcard:clone()
	acard:setSkillName("luasaodangcard")
	return acard end
end,
enabled_at_play=function()
	return false
end,
enabled_at_response=function(self,player,pattern)
	return pattern == "@@luasaodangcard"
end,
}

luasaodang=sgs.CreateTriggerSkill{
name="luasaodang",
frequency=sgs.Skill_NotFrequent,
view_as_skill=luasaodangvs,
events={sgs.Damage},
on_trigger=function(self,event,player,data)
		if not player:getPhase()==sgs.Player_play then return end
        local room=player:getRoom()
		local damage=data:toDamage()
        local card = damage.card
		if not card then return end
		--if not player:getPhase()==sgs.Player_play then return end
		if not card:inherits("Slash") then return end
        if not room:askForSkillInvoke(player,self:objectName(),data) then return end
		room:loseHp(player)
        room:askForUseCard(player, "@@luasaodangcard", "@luasaodang")
end
}
--ADD Skill--
sphuangxin:addSkill(luasaodang)
--LANG--
sgs.LoadTranslationTable{
	["sphuangxin"]="黄信",
	["#sphuangxin"]="三山之岳",
	["luasaodangvs"]="扫荡",
	["luasaodangcard"]="扫荡",
	["luasaodang"]="扫荡",
	[":luasaodang"]="出牌阶段,你的【杀】造成伤害后，你可以自减1点体力，然后指定最多3名角色进行一次判定，\
	若判定结果为红色,该角色须弃两张牌或受到1点伤害。",
	["@luasaodang"]="请指定1-3名其它角色",
	["~luasaodang"]="除你以外",
	["@luasaodangdiscard"]="请弃2张牌 否则将受到1点伤害",
}

luayizongcard=sgs.CreateSkillCard{
name="luayizongcard",
target_fixed=true,
will_throw=true,
on_use=function(self,room,source,targets)
	local x=self:getSubcards():length()
	for i=1,x,1 do
		local card_id = room:drawCard()
		local card=sgs.Sanguosha:getCard(card_id)
		source:addToPile("spyz",card)
	end
	room:throwCard(self)
end
}

luayizongvs=sgs.CreateViewAsSkill{
name="luayizongvs",
n=999,
view_filter=function(self, selected, to_select)
	return not to_select:isEquipped()
end,
view_as=function(self, cards)
	if #cards==0 then return end
	local acard=luayizongcard:clone()
	for var=1,#cards,1 do
        acard:addSubcard(cards[var])
    end
	acard:setSkillName("luayizong")
	return acard
end,
enabled_at_play=function()
	return false
end,
enabled_at_response=function(self,player,pattern)
	return pattern == "@@luayizongcard"
end,
}
luayizong=sgs.CreateTriggerSkill{
name="luayizong",
events={sgs.CardDiscarded,sgs.PhaseChange},
priority=3,
view_as_skill=luayizongvs,
default_choice = "dis",
can_trigger=function(self,target)
	return (not target:hasSkill(self:objectName())) and target:isWounded()
end,
frequency=sgs.Skill_NotFrequent,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local owner=room:findPlayerBySkillName(self:objectName())
	local yzcardids=sgs.IntList()
	if owner:isKongcheng() then return end
if event == sgs.CardDiscarded and player:getPhase()==sgs.Player_Discard then
	local owner=room:findPlayerBySkillName(self:objectName())
    if player:objectName()~=owner:objectName() then
		local card = data:toCard()
		if not card:isVirtualCard() then
			yzcardids:append(card:getId())
		else
			for _, cid in sgs.qlist(card:getSubcards()) do
				yzcardids:append(cid)
			end
		end
	end
	table.insert(yztargetdiscarded,yzcardids:length())--AiNeed 弃牌量
	table.insert(yztarget,player)--AiNeed 目标角色
	if (room:askForSkillInvoke(owner,self:objectName(),sgs.QVariant(player:objectName()))~=true) then return end
	room:askForUseCard(owner, "@@luayizongcard", "@luayizong")
	local x=owner:getPile("spyz"):length()
	for i=1,owner:getPile("spyz"):length(),1 do
		room:throwCard(owner:getPile("spyz"):first())
	end
	if x>yzcardids:length() then x=yzcardids:length() end
	local get=0
	for i=1,x,1 do
		room:fillAG(yzcardids, owner)
		local card_id = room:askForAG(owner, yzcardids, true, "luayizong")
		if card_id then
			yzcardids:removeOne(card_id)
			player:obtainCard(sgs.Sanguosha:getCard(card_id))
			get=get+1
			owner:invoke("clearAG")
		end
		if(card_id == -1) then break end
	end
	if owner and room:askForChoice(owner, self:objectName(), "dis+draw") == "dis" then
		room:playSkillEffect("guzong",math.random(1,3))
		if player:isAllNude() or get==0 then return end
		for i=1,get,1 do
			local card_id = room:askForCardChosen(owner,player,"hej",self:objectName())
			room:throwCard(card_id)
		end
	else
		room:playSkillEffect("yixian",math.random(1,2))
		owner:drawCards(1)
	end


end
end,
}
--============20130514===========
luakunshoucard=sgs.CreateSkillCard{
name="luakunshoucard",
filter=function(self,targets,to_select,player)
if (#targets>=2) then return false end
if not to_select:faceUp() then return false end
return true
end,
on_effect=function(self,effect)
	local room=effect.from:getRoom()
	effect.to:turnOver()
end
}
luakunshouvs=sgs.CreateViewAsSkill{
name="luakunshouvs",
n=0,
view_filter=function(self, selected, to_select)
	return false
end,
view_as=function(self, cards)
	if #cards==0 then
	local acard=luakunshoucard:clone()
	acard:setSkillName("luakunshoucard")
	return acard end
end,
enabled_at_play=function()
	return false
end,
enabled_at_response=function(self,player,pattern)
	return pattern == "@@luakunshoucard"
end,
}

luakunshou=sgs.CreateTriggerSkill{
name="luakunshou",
events={sgs.PhaseEnd,sgs.Predamage,sgs.CardDiscarded},
priority=3,
view_as_skill=luakunshouvs,
frequency=sgs.Skill_NotFrequent,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if event==sgs.PhaseEnd and player:getPhase()==sgs.Player_Finish then
	local facedownCounter=1
	for _,theplayer in sgs.qlist(room:getAlivePlayers()) do
		if not theplayer:faceUp() then facedownCounter=facedownCounter+1 end
	end
	--facedownCounter=facedownCounter+1
	if facedownCounter>(player:getHandcardNum()+player:getEquips():length()) then return end
	if (room:askForSkillInvoke(player,"luakunshou",data)~=true) then return end
	player:turnOver()
	player:drawCards(facedownCounter+1)
	room:askForDiscard(player,"luakunshou",facedownCounter,facedownCounter,false,true)
elseif event == sgs.CardDiscarded and player:getPhase()==sgs.Player_Finish then
	local card = data:toCard()
	local kscardids=sgs.IntList()
		if not card:isVirtualCard() then
			kscardids:append(card:getId())
		else
			for _, cid in sgs.qlist(card:getSubcards()) do
				kscardids:append(cid)
			end
		end
	for _,cid in sgs.qlist(kscardids) do
		player:addToPile("spDou",cid)
	end
	--table.insert(kstargetdiscarded,kscardids:length())--AiNeed 弃牌量
	--table.insert(kstarget,player)--AiNeed 目标角色
elseif event==sgs.Predamage then
	if player:getPile("spDou"):length()==0 then return end
	local damage=data:toDamage()
	if not damage.card:inherits("Slash") then return end
	if (room:askForSkillInvoke(player,"luakunshou2",data)~=true) then return end
		local parts=player:getPile("spDou")--获取
 		room:fillAG(parts,player)--填充ag界面
		local cdid=room:askForAG(player,parts,false,"luakunshou")
		local cd=sgs.Sanguosha:getCard(cdid)
		if cd:inherits("EventsCard") then
			if room:askForUseCard(player, "@@luakunshoucard", "@luakunshou") then
				room:throwCard(cdid,player)--弃掉
				player:invoke("clearAG")
				return
			end
		end
		room:throwCard(cdid,player)--弃掉
		player:invoke("clearAG")
	damage.damage=damage.damage+1
	data:setValue(damage)
	return false
end
end,
}

guonanTarget={}
luaguonan=sgs.CreateTriggerSkill{
name="luaguonan",
events={sgs.CardFinished,sgs.Damage,sgs.SlashMissed,sgs.CardDiscarded,sgs.PhaseEnd},
priority=3,
can_trigger=function(self,player)
	return true
end,
frequency=sgs.Skill_NotFrequent,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local owner=room:findPlayerBySkillName(self:objectName())
	if not owner then return end
	if not owner:isAlive() then
		for _,theplayer in sgs.qlist(room:getAlivePlayers()) do
			if theplayer:hasMark("@bgMarkEffect") then room:setPlayerMark(theplayer,"@bgMarkEffect",0)	end
		end
	return end
if event==sgs.CardFinished and player:objectName()==owner:objectName() then
	local cd=data:toCardUse().card
	if not cd:inherits("Slash") then return end
	if owner:isKongcheng() then return end
	if owner:getPhase()~=sgs.Player_Play then return end
	if (room:askForSkillInvoke(owner,"luaguonan",data)~=true) then
		if owner:hasMark("guonanMissed") then
			room:setPlayerMark(owner,"guonanMissed",0)
		end
		return
	end
	room:setPlayerMark(owner,"bgStart",1)
	local x=owner:getHandcardNum()
	room:askForDiscard(owner,"luaguonan",x,x,false,false)
		local x=owner:getMark("baoguoPlus")
		owner:gainMark("@bgMark",x)
		--room:setPlayerMark(owner,"@bgMark",x+y)
		room:setPlayerMark(owner,"baoguoPlus",0)
	if owner:hasMark("guonanMissed") then
		local z=owner:getMark("jingzhongPlus")
		owner:gainMark("@jingzhong",z)
		room:setPlayerMark(owner,"jingzhongPlus",0)
		room:setPlayerMark(owner,"guonanMissed",0)
	elseif owner:hasMark("guonanHasEquip")	then
		local d=owner:getMark("damagePlus")
		local damage = sgs.DamageStruct()
			damage.from = owner
			damage.to = guonanTarget[1]
			damage.damage=d
			room:damage(damage)
		owner:drawCards(d)
		table.remove(guonanTarget)
		room:setPlayerMark(owner,"guonanHasEquip",0)
	end
elseif event == sgs.CardDiscarded and owner:getPhase()~=sgs.Player_Discard then
	if player:objectName()~=owner:objectName() then return end
	if not owner:hasMark("bgStart") then return end
	local card = data:toCard()
	local kscardids=sgs.IntList()
		if not card:isVirtualCard() then
			kscardids:append(card:getId())
		else
			for _, cid in sgs.qlist(card:getSubcards()) do
				kscardids:append(cid)
			end
		end
	for _,cid in sgs.qlist(kscardids) do
		local cd=sgs.Sanguosha:getCard(cid)
		if	cd:inherits("EquipCard") then
			room:setPlayerMark(owner,"damagePlus",owner:getMark("damagePlus")+1)
			owner:speak("DamageUpgraded:"..tostring(owner:getMark("damagePlus")))
		elseif	cd:inherits("TrickCard") then
			room:setPlayerMark(owner,"baoguoPlus",owner:getMark("baoguoPlus")+1)
		elseif cd:inherits("BasicCard") then

			room:setPlayerMark(owner,"jingzhongPlus",owner:getMark("jingzhongPlus")+1)
		end
		owner:speak("精忠Plus:"..tostring(owner:getMark("jingzhongPlus")))
	end
elseif event==sgs.Damage and player:objectName()==owner:objectName() then
	local damage=data:toDamage()
	if not damage.card or not damage.card:inherits("Slash") then return end
	room:setPlayerMark(owner,"guonanHasEquip",1)
	table.insert(guonanTarget,damage.to)
	owner:speak("Damage Upgrading...")
	return false
elseif event==sgs.SlashMissed and player:objectName()==owner:objectName() then
		owner:speak("Target Missed")
		room:setPlayerMark(owner,"guonanMissed",1)
elseif event==sgs.PhaseEnd and 	player:objectName()==owner:objectName() and owner:getPhase()==sgs.Player_Finish then
	room:setPlayerMark(owner,"damagePlus",0)
	room:setPlayerMark(owner,"baoguoPlus",0)
	room:setPlayerMark(owner,"jingzhongPlus",0)
	room:setPlayerMark(owner,"bgStart",0)
end
end,
}



luaciyincard=sgs.CreateSkillCard{
name="luaciyincard",
filter=function(self,targets,to_select,player)
if (#targets>=player:getMark("@bgMark")) then return false end
return true--not to_select:hasMark("@bgMarkEffect")
end,
on_effect=function(self,effect)
		if not effect.from:hasMark("@bgMark") then return end
		local room=effect.from:getRoom()
		effect.to:gainMark("@bgMarkEffect")
		effect.from:loseMark("@bgMark")
end
}
luaciyinvs=sgs.CreateViewAsSkill{
name="luaciyinvs",
n=0,
view_filter=function(self, selected, to_select)
	return false
end,
view_as=function(self, cards)
	if #cards==0 then
	local acard=luaciyincard:clone()
	acard:setSkillName("luaciyincard")
	return acard end
end,
enabled_at_play=function(self,player)
	return false
end,
enabled_at_response=function(self,player,pattern)
	return pattern=="@@luaciyincard"
end,
}


luaciyin=sgs.CreateTriggerSkill{
name="luaciyin",
events={sgs.SlashProceed,sgs.DamageComplete,sgs.PhaseEnd},
view_as_skill=luaciyinvs,
--priority=3,
can_trigger=function(self,player)
	return true
end,
frequency=sgs.Skill_NotFrequent,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local owner=room:findPlayerBySkillName(self:objectName())
	if not owner then return end
	if not owner:isAlive() then	return end
if event==sgs.SlashProceed then
	if owner:getMark("@jingzhong")<4 then return end
	local effect=data:toSlashEffect()
	if effect.from:objectName()~=owner:objectName() then return end
	if (room:askForSkillInvoke(owner,"luaciyin",data)~=true) then return end
	owner:loseMark("@jingzhong",4)
	room:slashResult(effect,nil)--结算杀中了，然后无效原来的
	return true
elseif event==sgs.DamageComplete then
	local who=data:toDamage().to
	if not who:hasMark("@bgMarkEffect") then return end
	--if (room:askForSkillInvoke(player,"luaciyinbaoguo",data)~=true) then return end
	owner:drawCards(who:getLostHp())
	--room:setPlayerMark(player,"@bgMarkEffect",0)
	who:loseMark("@bgMarkEffect")
	return false
elseif event==sgs.PhaseEnd and owner:getPhase()==sgs.Player_Finish then
	if not owner:hasMark("@bgMark") then return end
	if room:askForUseCard(owner, "@@luaciyincard", "@luaciyin")~=nil then
		owner:gainMark("@jingzhong")
	end
end
end,
}
spyangzhi:addSkill(luakunshou)
spyuefei:addSkill(luaguonan)
spyuefei:addSkill(luaciyin)
--spbird:addSkill(luazhuanshi)
--spbird:addSkill(luazhuoxie)
spzhulei:addSkill(luayizong)

sgs.LoadTranslationTable{
	["#sproxiel"]="叫兽",
	["sproxiel"]="李云",
	["luaPoisonBody"]="毒体",
	[":luaPoisonBody"]="对你造成伤害的角色，都将中毒，持续5个回合",
	["luaDeathMagic"]="即死",
	["luaDeathMagicCard"]="即死魔法",
	[":luaDeathMagic"]="<font color=deeppink><b>咒术技</b></font>,出牌阶段，你可以用一张锦囊牌，对任意一名角色施加【即死魔法】祖咒。每阶段限1次\
	<font color=green><b>目标角色若未受伤，则附加概率为38%，默认概率20%，持续2个回合</b></font>",
	["luadeathmagic_jur"] = "即死",
	[":luadeathmagic_jur"] = "目标角色回合开始时，进行一次判定，若判定结果为【黑桃】，目标角色流失其当前体力值；\
	若判定结果为梅花，除施放者外的其它角色均将被即死魔法诅咒，持续1个回合。",
	["#luaDeathMagicFailed"]="%from 对%arg的即死魔法失效了",
	["#luaDeathMagicOK"]="%from 中了%arg的即死魔法",
	["#luaDeathMagicDoom"]="%from的变异即死诅咒使得其它所有人均被诅咒",


	["#spzhulei"]="义不容辞",
	["spzhulei"]="朱仝雷横",
	["luayizong"] = "义纵",
	["luayizongvs"] = "义纵",
	["luayizongcard"] = "义纵",
	["@luayizong"]="请选择任意张牌用以发动【义纵】",
	["spyz"]="【义】",
	["#yztest"] = "%arg now",
	[":luayizong"] = "其他角色弃牌阶段结束时,若其已受伤,你可以弃置X张手牌,	将其弃牌中X张弃牌返回其手牌,然后你可以选择弃置其等量的牌或摸1张牌。",
	["luayizong:dis"] = "弃他牌",
    ["luayizong:draw"] = "摸1张",
	["#spyangzhi"]="青面禽兽",
	["spyangzhi"]="杨志",
	["~spyangzhi"]="杨志",
	["luakunshou"]="困兽",
	["luakunshoucard"]="困兽",
	["luakunshou2"]="困兽",
	[":luakunshou"]="回合结束阶段，你可以将你的武将牌翻面，然后摸X+1张并将X张牌置于你的武将牌上，称为“斗”，\	X为场上背面朝上的武将数；出牌阶段，你使用的【杀】造成伤害时，可以弃置一张“斗”，此伤害+1。\
	额外的，你弃置的“斗”为事件牌，则可以改为指定2名角色武将牌翻面。",
	["@luakunshou"]="困兽额外效果：请指定至多两名角色",
	["#spyuefei"]="金翅雏鹰",
	["spyuefei"]="少年岳飞",
	["luaguonan"]="国难",
	["luaciyincard"]="刺印",
	[":luaguonan"]="出牌阶段，你使用【杀】结算后，可弃掉所有手牌；其中每有一张锦囊牌，你+1【报国】；若被【闪】避，其中每有1张基本牌，你+1点【精忠】；若造成伤害，你再对目标角色造成x点伤害，并摸X张牌，x为你弃置的装备牌数",
	["luaciyin"]="刺印",
	[":luaciyin"]=" 回合结束阶段，你可以弃置任意点【报国】并指定等量角色进入【报国】状态，若如此做，你+1【精忠】 ，出牌阶段，可弃4点【精忠】，则你下一张【杀】不可【闪】避。",
	["spDou"]="【斗】",
	["@jingzhong"]="精忠",
	["@bgMark"]="报国",
	["@bgMarkEffect"]="报国状态",
	["@luaciyin"]="你可以至多指定X名角色进入【报国】状态，X为你的报国点数",
	["#g1"]="青眼虎",
	["g1"]="李云",
	["luaBlackParty"]="黑手",
	[":luaBlackParty"]="<font color=blue><b>锁定技</b></font>,你造成伤害之前，须进行一次判定，若结果为红桃，伤害将改为目标角色流失1点最大体力值; \
回合外，每当你失去牌时，若你的当前体力值与手牌数相等，视为你使用了一张猛虎下山。",
	["#bp1"]="%from的锁定技【黑手】被触发",
	["#bp2"]="%from 下了黑手，敌人不死也残废",
	["#bp2failed"]="%from 手下留情，没有下死手",
	["bpAOE"]="亡命徒之血战八方",

	["luaFresh"]="生猛",
	[":luaFresh"]="每当你受到一次伤害，你可以进行X次判定，X为你的已损体力值+1，若判定结果为黑色,视为你对伤害来源使用了一张杀",
	["#luaFresh"]="%from 受够了%arg 的折磨",

}



luaBlackParty=sgs.CreateTriggerSkill{
name="luaBlackParty",
events={sgs.CardLost,sgs.Predamage},--sgs.CardFinished},
frequency=sgs.Skill_Compulsory,
priority=3,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	local trigger=false
	local log=sgs.LogMessage()
	log.from =player
	if player:getHp()==player:getHandcardNum() then trigger=true end
	if event==sgs.CardLost and player:getPhase()==sgs.Player_NotActive and trigger then
			local aoe=sgs.Sanguosha:cloneCard("savage_assault",sgs.Card_NoSuit,0)
            aoe:setSkillName("bpAOE")
			local use=sgs.CardUseStruct()
			use.card = aoe
			use.from = player
			room:useCard(use,false)
			log.type="#bp1"
			room:sendLog(log)
	elseif event==sgs.Predamage then
		local enemy=data:toDamage().to
		local judge=sgs.JudgeStruct()
        judge.pattern=sgs.QRegExp("(.*):(heart):(.*)")
        judge.good=true
        judge.reason=self:objectName()
        judge.who=player
        room:judge(judge)
		if judge:isGood() then
			log.type="#bp2"
			room:sendLog(log)
			room:loseMaxHp(enemy)
			--room:setPlayerProperty(enemy,"maxhp",sgs.QVariant(player:getMaxHp()-1))
			return true
		end
		local log=sgs.LogMessage()
		log.from =player
		log.type="#bp2failed"
		room:sendLog(log)
	--[[elseif event==sgs.CardFinished  then
		local card=data:toCardUse().card
		if card:inherits("Analeptic") then return end
		if not card:inherits("Peach") then return end
		local log=sgs.LogMessage()
		log.from =player
		log.type="#bp3"
		room:sendLog(log)
		player:drawCards(2)	]]
	end
end,
}

luaFresh=sgs.CreateTriggerSkill{
name="luaFresh",
frequency=sgs.Skill_NotFrequent,
events={sgs.Damaged},
on_trigger=function(self,event,player,data)
    local room=player:getRoom()
	local damage=data:toDamage()
	if not damage.from then return end
	if not damage.from:isAlive() then return end
	if player:isProhibited(damage.from,sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)) then return end
    if room:askForSkillInvoke(player,"luaFresh",data)~=true then return end
	for i=1,(player:getLostHp()+1),1 do
		local judge=sgs.JudgeStruct()
        judge.pattern=sgs.QRegExp("(.*):(spade|club):(.*)")
        judge.good=true
        judge.reason=self:objectName()
        judge.who=player
        room:judge(judge)
		if judge.card:isBlack() then
			local log=sgs.LogMessage()
			log.type ="#luaFresh"
			log.from=player
			log.arg=damage.from:getGeneralName()
			room:sendLog(log)
			local acard=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			acard:setSkillName("luaFresh")
			local use=sgs.CardUseStruct()
			use.card = acard
			use.from = player
			use.to:append(damage.from)
			room:useCard(use,true)
		end
	end
end
}
g1:addSkill(luaBlackParty)
g1:addSkill(luaFresh)

--[[GeneralNameTable]]--
mygname={
"splujunyi",
"splinchong",
"spluzhishen",
"spwusong",
"spzhulei",
"spzhuwu",
"sphuyanzhuo",
"spyangzhi",
"spyuefei",
"sphuangxin",
}
gnum={
"001",
"002",
"003",
"004",
"005",
"006",
"007",
"008",
"009",
"0012",
}
--[[AutoFillDesigner]]--
for j=1,#mygname,1 do
	sgs.LoadTranslationTable
	{
		["designer:"..mygname[j]]="群龙令&烨子",
		["illustrator:"..mygname[j]] = "江某",
		["$"..mygname[j]] =gnum[j],
	}
	if j>=7 or j==5 then
		sgs.LoadTranslationTable{["coder:"..mygname[j]]="roxiel",}
	else
		sgs.LoadTranslationTable{["coder:"..mygname[j]]="群龙令",}
	end
end