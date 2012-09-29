#include "changban-scenario.h"
#include "skill.h"
#include "maneuvering.h"
#include "clientplayer.h"
#include "carditem.h"
#include "engine.h"
#include "general.h"
#include "standard.h"
#include "client.h"
#include "serverplayer.h"
#include "room.h"
#include "settings.h"

static int TransfigurationCB = 1;

class CBQingGang: public TriggerSkill{
public:
    CBQingGang():TriggerSkill("cbqinggang"){
        events << Damage;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if(damage.to->getCards("he").length() <= 0)
            return false;
        if(!player->askForSkillInvoke(objectName(), data))
            return false;
        int i;
        for(i=0; i<damage.damage; i++){
            if(damage.to->isNude())
                break;
            if(damage.to->getCards("e").length() == 0)
                room->askForDiscard(damage.to, objectName(), 1, false, false);
            else
                if(!room->askForDiscard(damage.to, objectName(), 1, true, false))
                    room->moveCardTo(Sanguosha->getCard(room->askForCardChosen(player, damage.to, "e", objectName())), player, Player::Hand, true);
        }
        return false;
    }
};

CBLongNuCard::CBLongNuCard(){
    target_fixed = true;
}

void CBLongNuCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    QList<int> angers = source->getPile("Angers");

    room->fillAG(angers, source);
    int card_id = room->askForAG(source, angers, true, "cblongnu");
    source->invoke("clearAG");
    if(card_id != -1){
        const Card *anger1 = Sanguosha->getCard(card_id);
        const Card *anger2 = anger1;
        foreach(int id, source->getPile("Angers")){
            const Card *card = Sanguosha->getCard(id);
            if(card->getEffectiveId() == anger1->getEffectiveId())
                continue;
            else if(card->sameColorWith(anger1))
                anger2 = card;
        }
        if(anger2->getEffectiveId() != anger1->getEffectiveId()){
            room->throwCard(anger1);
            room->throwCard(anger2);
            source->addMark("CBLongNu");
        }
    }else{
        LogMessage log;
        log.type = "#CBLongNuLog";
        log.from = source;
        room->sendLog(log);
    }
}

class CBLongNuViewAsSkill: public ZeroCardViewAsSkill{
public:
    CBLongNuViewAsSkill():ZeroCardViewAsSkill("cblongnu"){
    }

    virtual const Card *viewAs() const{
        return new CBLongNuCard;
    }

protected:
    virtual bool isEnabledAtPlay(const Player *player) const{
        bool has_sameColor = false;
        QList<int> angers = Self->getPile("Angers"), temp;

        foreach(int id, angers){
            temp = angers;
            temp.removeOne(id);
            const Card *card = Sanguosha->getCard(id);
            foreach(int tmp, temp){
                const Card *cardtmp = Sanguosha->getCard(tmp);
                if(card->sameColorWith(cardtmp)){
                    has_sameColor = true;
                    break;
                }
            }
        }

        return has_sameColor;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return false;
    }
};

class CBLongNu: public TriggerSkill{
public:
    CBLongNu():TriggerSkill("cblongnu"){
        events << SlashProceed ;
        view_as_skill = new CBLongNuViewAsSkill;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if(event == SlashProceed){
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            if(player->getMark("CBLongNu")){
                room->slashResult(effect, NULL);
                player->removeMark("CBLongNu");
                return true;
            }
        }
        return false;
    }
};

CBYuXueCard::CBYuXueCard(){
    target_fixed = true;
}

void CBYuXueCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    QList<int> angers = source->getPile("Angers"), redAngers;
    foreach(int anger, angers){
        if(Sanguosha->getCard(anger)->isRed())
            redAngers << anger;
    }

    ServerPlayer *target = source;
    foreach(ServerPlayer *p, room->getAllPlayers()){
        if(p->hasFlag("dying")){
            target = p;
            break;
        }
    }

    room->fillAG(redAngers, source);
    int card_id = room->askForAG(source, redAngers, true, "cbyuxue");
    source->invoke("clearAG");
    if(card_id != -1){
        const Card *redAnger = Sanguosha->getCard(card_id);

        room->throwCard(redAnger);
        Peach *peach = new Peach(Card::NoSuit, 0);
        peach->setSkillName("cbyuxue");
        CardUseStruct usepeach;
        usepeach.card = peach;
        usepeach.from = source;
        usepeach.to << target;
        room->useCard(usepeach);
    }else{
        LogMessage log;
        log.type = "#CBYuXueLog";
        log.from = source;
        room->sendLog(log);
    }
}

class CBYuXue: public ZeroCardViewAsSkill{
public:
    CBYuXue():ZeroCardViewAsSkill("cbyuxue"){
    }

    virtual const Card *viewAs() const{
        return new CBYuXueCard;
    }

protected:
    virtual bool isEnabledAtPlay(const Player *player) const{
        bool has_redAnger = false;
        QList<int> angers = Self->getPile("Angers");

        foreach(int id, angers){
            const Card *card = Sanguosha->getCard(id);
            if(card->isRed()){
                has_redAnger = true;
                break;
            }
        }

        return has_redAnger && player->isWounded();
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        bool has_redAnger = false;
        QList<int> angers = Self->getPile("Angers");

        foreach(int id, angers){
            const Card *card = Sanguosha->getCard(id);
            if(card->isRed()){
                has_redAnger = true;
                break;
            }
        }

        return has_redAnger && pattern.contains("peach");
    }
};

class CBLongYin: public TriggerSkill{
public:
    CBLongYin():TriggerSkill("cblongyin"){
        events << PhaseChange ;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if(event == PhaseChange && player->getPhase() == Player::Start){
            if(player->getPile("Angers").length() >= 5)
                return false;
            bool cbzhangfeiIsDead = room->findPlayer("cbzhangfei2") == NULL ? true : false;
            if(!cbzhangfeiIsDead)
                return false;
            data = QVariant::fromValue(player);
            if(!player->askForSkillInvoke(objectName(), data))
                return false;
            QList<int> cards = room->getNCards(3);
            room->fillAG(cards, player);
            int card_id = room->askForAG(player, cards, false, objectName());
            player->invoke("clearAG");
            cards.removeOne(card_id);
            player->addToPile("Angers", card_id, true);
            foreach(int id, cards){
                const Card *card = Sanguosha->getCard(id);
                room->moveCardTo(card, player, Player::Hand, true);
            }
            return true;

        }
        return false;
    }
};

class CBZhengJun: public TriggerSkill{
public:
    CBZhengJun():TriggerSkill("cbzhengjun"){
        events << PhaseChange;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        if(event == PhaseChange){
            int x = player->getAttackRange();
            if(player->getPhase() == Player::Start){
                if(player->getCards("he").length() <= x)
                    player->throwAllCards();
                else
                    room->askForDiscard(player, objectName(), x, false, true);
            }else if(player->getPhase() == Player::Finish){
                player->drawCards(x + 1);
                player->turnOver();
            }
        }
        return false;
    }
};

class CBBeiLiang: public DrawCardsSkill{
public:
    CBBeiLiang():DrawCardsSkill("cbbeiliang"){

    }

    virtual int getDrawNum(ServerPlayer *player, int n) const{
        Room *room = player->getRoom();
        if(player->getHandcardNum() >= 5)
            return n;
        if(room->askForSkillInvoke(player, objectName())){
            room->playSkillEffect(objectName());
            int x = player->getMaxHP() - player->getHandcardNum();
            return x;
        }else
            return n;
    }
};

CBJuWuCard::CBJuWuCard(){
    will_throw = false;
}

bool CBJuWuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return to_select->getGeneralName() == "cbzhaoyun1" || to_select->getGeneralName() == "cbzhaoyun2";
}

void CBJuWuCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    ServerPlayer *target = targets.first();
    room->moveCardTo(this, target, Player::Hand, false);

    int old_value = source->getMark("cbjuwu");
    int new_value = old_value + subcards.length();
    room->setPlayerMark(source, "cbjuwu", new_value);
}

class CBJuWuViewAsSkill: public ViewAsSkill{
public:
    CBJuWuViewAsSkill():ViewAsSkill("cbjuwu"){
    }

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const{
        if(selected.length() + Self->getMark("cbjuwu") >= Self->getHp())
            return false;
        else
            return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        if(cards.length() == 0 || cards.length() > Self->getHp())
            return NULL;

        CBJuWuCard *card = new CBJuWuCard;
        card->setSkillName(objectName());
        card->addSubcards(cards);
        return card;
    }
};

class CBJuWu: public PhaseChangeSkill{
public:
    CBJuWu():PhaseChangeSkill("cbjuwu"){
        view_as_skill = new CBJuWuViewAsSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return PhaseChangeSkill::triggerable(target)
                && target->getPhase() == Player::NotActive
                && target->hasUsed("CBJuWuCard");
    }

    virtual bool onPhaseChange(ServerPlayer *target) const{
        target->getRoom()->setPlayerMark(target, "cbjuwu", 0);

        return false;
    }
};

CBChanSheCard::CBChanSheCard(){

}

bool CBChanSheCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    bool canuse = true;

    foreach(const Card *cd, to_select->getJudgingArea()){
        if(cd->isRed() && !cd->inherits("DelayedTrick"))
            canuse = false;
    }

    if(!targets.isEmpty())
        canuse = false;

    if(to_select->containsTrick("indulgence"))
        canuse = false;

    if(to_select == Self)
        canuse = false;

    return canuse;
}

void CBChanSheCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    ServerPlayer *target = targets.first();
    QList<int> redangers;
    foreach(int id, source->getPile("Angers")){
        if(Sanguosha->getCard(id)->isRed())
            redangers << id;
    }

    room->fillAG(redangers, source);
    int card_id = room->askForAG(source, redangers, true, "cbchanshe");
    source->invoke("clearAG");
    if(card_id != -1){
        const Card *redAnger = Sanguosha->getCard(card_id);
        room->moveCardTo(redAnger, target, Player::Judging, true);
    }else{
        LogMessage log;
        log.type = "#CBChanSheLog";
        log.from = source;
        room->sendLog(log);
    }
}

class CBChanShe: public ZeroCardViewAsSkill{
public:
    CBChanShe():ZeroCardViewAsSkill("cbchanshe"){
    }

    virtual const Card *viewAs() const{
        return new CBChanSheCard;
    }

protected:
    virtual bool isEnabledAtPlay(const Player *player) const{
        bool has_redAnger = false;
        QList<int> angers = Self->getPile("Angers");

        foreach(int id, angers){
            const Card *card = Sanguosha->getCard(id);
            if(card->isRed()){
                has_redAnger = true;
                break;
            }
        }

        return has_redAnger;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return false;
    }
};

CBShiShenCard::CBShiShenCard(){

}

bool CBShiShenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty();
}

void CBShiShenCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    ServerPlayer *target = targets.first();
    QList<int> angers = source->getPile("Angers");

    room->fillAG(angers, source);
    int card_id = room->askForAG(source, angers, true, "cbshishen");
    source->invoke("clearAG");
    if(card_id != -1){
        const Card *anger1 = Sanguosha->getCard(card_id);
        const Card *anger2 = anger1;
        foreach(int id, source->getPile("Angers")){
            const Card *card = Sanguosha->getCard(id);
            if(card->getEffectiveId() == anger1->getEffectiveId())
                continue;
            else if(card->sameColorWith(anger1))
                anger2 = card;
        }
        if(anger2->getEffectiveId() != anger1->getEffectiveId()){
            room->throwCard(anger1);
            room->throwCard(anger2);
            room->loseHp(target, 1);
        }
    }else{
        LogMessage log;
        log.type = "#CBShiShenLog";
        log.from = source;
        room->sendLog(log);
    }
}

class CBShiShen: public ZeroCardViewAsSkill{
public:
    CBShiShen():ZeroCardViewAsSkill("cbshishen"){
    }

    virtual const Card *viewAs() const{
        return new CBShiShenCard;
    }

protected:
    virtual bool isEnabledAtPlay(const Player *player) const{
        bool has_sameColor = false;
        QList<int> angers = Self->getPile("Angers"), temp;

        foreach(int id, angers){
            temp = angers;
            temp.removeOne(id);
            const Card *card = Sanguosha->getCard(id);
            foreach(int tmp, temp){
                if(card->sameColorWith(Sanguosha->getCard(tmp))){
                    has_sameColor = true;
                    break;
                }
            }
        }

        return has_sameColor;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return false;
    }
};

class ChangbanRule: public ScenarioRule{
public:
    ChangbanRule(Scenario *scenario)
        :ScenarioRule(scenario)
    {
        events << GameStart << TurnStart << GameOverJudge << HpChanged << Death;
    }

    void changeGeneral(ServerPlayer *player) const{
        Room *room = player->getRoom();
        QStringList generals = room->getTag(player->objectName()).toStringList();
        QString new_general = generals.takeFirst();
        room->setTag(player->objectName(), QVariant(generals));
        room->transfigure(player, new_general, true, true);
        room->revivePlayer(player);

        if(player->getKingdom() != player->getGeneral()->getKingdom())
            room->setPlayerProperty(player, "kingdom", player->getGeneral()->getKingdom());

        room->broadcastInvoke("revealGeneral",
                              QString("%1:%2").arg(player->objectName()).arg(new_general),
                              player);

        if(!player->faceUp())
            player->turnOver();

        if(player->isChained())
            room->setPlayerProperty(player, "chained", false);

        player->drawCards(4);
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        switch(event){
        case GameStart:{
                room->setTag("SkipNormalDeathProcess", true);
                if(player->isLord()){
                    if(setjmp(env) == TransfigurationCB){
                        player = room->getLord();
                        room->transfigure(player, "cbzhaoyun2", true, true);
                        ServerPlayer *cbzhangfei = player;
                        foreach(ServerPlayer *p, room->getAlivePlayers()){
                            if(p->getRole() == "loyalist")
                                cbzhangfei = p;
                        }
                        if(cbzhangfei == player){
                            cbzhangfei = room->findPlayer("cbzhangfei2", true);
                            if(cbzhangfei == NULL)
                                cbzhangfei = room->findPlayer("cbzhangfei1", true);
                            room->revivePlayer(cbzhangfei);
                        }
                        room->transfigure(cbzhangfei, "cbzhangfei2", true, true);
                        QList<ServerPlayer *> cbgod;
                        cbgod << player << cbzhangfei;
                        foreach(ServerPlayer *p, cbgod){
                            QList<const Card *> tricks = p->getJudgingArea();
                            foreach(const Card *trick, tricks)
                                room->throwCard(trick);

                            if(!p->faceUp())
                                p->turnOver();

                            if(p->isChained())
                                room->setPlayerProperty(p, "chained", false);
                        }
                    }else{
                        player->drawCards(4, false);
                    }
                }else
                    player->drawCards(4, false);

                return true;
            }

        case HpChanged:{
                if(player->getGeneralName() == "cbzhaoyun1" && player->getHp() <= 4){
                    longjmp(env, TransfigurationCB);
                }

                if(player->getGeneralName() == "cbzhangfei1" && player->getHp() <= 5){
                    room->transfigure(player, "cbzhangfei2", true, true);
                }
                return false;
            }

        case TurnStart:{
                if(player->isLord()){
                    if(!player->faceUp())
                        player->turnOver();
                    else
                        player->play();
                }else{
                    if(player->isDead()){
                        QStringList generals = room->getTag(player->objectName()).toStringList();
                        if(!generals.isEmpty()){
                            changeGeneral(player);
                            player->play();
                        }
                    }
                    else if(!player->faceUp())
                        player->turnOver();
                    else
                        player->play();
                }

                return true;
            }

        case Death:{
                player->bury();

                if(player->getRoleEnum() == Player::Rebel){
                    QStringList generals = room->getTag(player->objectName()).toStringList();
                    if(generals.isEmpty()){
                        QStringList alive_roles = room->aliveRoles(player);
                        if(!alive_roles.contains("rebel"))
                            room->gameOver("lord+loyalist");
                    }
                }

                if(player->isDead()){
                    DamageStar damage = data.value<DamageStar>();
                    ServerPlayer *killer = damage ? damage->from : NULL;
                    if(killer && killer->isAlive()){
                        if(player->getRole() == "rebel" && killer != player){
                            killer->drawCards(2);
                        }else if(player->getRole() == "loyalist" && killer->getRole() == "lord"){
                            killer->throwAllEquips();
                            killer->throwAllHandCards();
                        }
                    }
                }

                if(player->isLord()){
                    room->gameOver("rebel");
                }

                if(player->getGeneralName() == "cbzhangfei2"){
                    ServerPlayer *cbzhaoyun = room->getLord();
                    if(cbzhaoyun->getHp() < 4)
                        room->setPlayerProperty(cbzhaoyun, "hp", 4);
                }

                return false;
            }

        case GameOverJudge:{
                if(player->getRole() == "rebel"){
                    QStringList list = room->getTag(player->objectName()).toStringList();

                    if(!list.isEmpty())
                        return false;
                }

                break;
            }

        default:
            break;
        }

        return false;
    }

private:
    mutable jmp_buf env;
};

bool ChangbanScenario::exposeRoles() const{
    return true;
}

void ChangbanScenario::assign(QStringList &generals, QStringList &roles) const{
    Q_UNUSED(generals);

    roles << "lord" << "loyalist";
    int i;
    for(i=0; i<3; i++)
        roles << "rebel";

    qShuffle(roles);
}

int ChangbanScenario::getPlayerCount() const{
    return 5;
}

void ChangbanScenario::getRoles(char *roles) const{
    strcpy(roles, "ZCFFF");
}

void ChangbanScenario::onTagSet(Room *room, const QString &key) const{
    // dummy
}

bool ChangbanScenario::lordWelfare(const ServerPlayer *) const{
    return false;
}

bool ChangbanScenario::generalSelection() const{
    return true;
}

ChangbanScenario::ChangbanScenario()
    :Scenario("changban")
{
    //lord = "zhang1dong";
    rule = new ChangbanRule(this);

    General *cbzhaoyun1 = new General(this, "cbzhaoyun1", "god", 8, true, true);
    cbzhaoyun1->addSkill("linse");
    cbzhaoyun1->addSkill(new CBQingGang);

    General *cbzhaoyun2 = new General(this, "cbzhaoyun2", "god", 4, true, true);
    cbzhaoyun2->addSkill("linse");
    cbzhaoyun2->addSkill("cbqinggang");
    cbzhaoyun2->addSkill(new CBLongNu);
    cbzhaoyun2->addSkill(new CBYuXue);
    cbzhaoyun2->addSkill(new CBLongYin);

    General *cbzhangfei1 = new General(this, "cbzhangfei1", "god", 10, true, true);
    cbzhangfei1->addSkill(new CBZhengJun);
    cbzhangfei1->addSkill(new Skill("CBZhangBa", Skill::Compulsory));

    General *cbzhangfei2 = new General(this, "cbzhangfei2", "god", 5, true, true);
    cbzhangfei2->addSkill("CBZhangBa");
    cbzhangfei2->addSkill(new CBBeiLiang);
    cbzhangfei2->addSkill(new CBJuWu);
    cbzhangfei2->addSkill(new CBChanShe);
    cbzhangfei2->addSkill(new CBShiShen);

    addMetaObject<CBLongNuCard>();
    addMetaObject<CBYuXueCard>();
    addMetaObject<CBJuWuCard>();
    addMetaObject<CBChanSheCard>();
    addMetaObject<CBShiShenCard>();
}

ADD_SCENARIO(Changban)
