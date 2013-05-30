#include "casket.h"
#include "standard.h"

class Stealth: public ClientSkill{
public:
    Stealth():ClientSkill("stealth_jur"){
    }

    virtual bool isProhibited(const Player *, const Player *to, const Card *card) const{
        return to->hasMark(objectName()) && !card->isKindOf("SkillCard");
    }
};

class Qingdu: public TriggerSkill{
public:
    Qingdu():TriggerSkill("qingdu"){
        events << Damage;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent, Room *, ServerPlayer *yunr, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if(damage.to->getGender() == General::Male && damage.to->isAlive()){
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = yunr;
            log.arg = objectName();
            yunr->getRoom()->sendLog(log);
            yunr->playSkillEffect(objectName());

            damage.to->gainJur("poison_jur", 5);
        }
        return false;
    }
};

TumiCard::TumiCard(){
}

bool TumiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const{
    return targets.isEmpty() && to_select->getGenderString() == "male" && !to_select->isKongcheng();
}

void TumiCard::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.from->getRoom();
    room->obtainCard(effect.from, effect.to->wholeHandCards(), false);

    QList<int> card_ids = effect.from->handCards();
    room->fillAG(card_ids);
    QList<const Card *> cards = effect.from->getHandcards();
    foreach(const Card *card, cards){
        if(card->isRed()){
            room->getThread()->delay();
            effect.to->obtainCard(card);
        }
    }
    room->broadcastInvoke("clearAG");
}

class TumiViewAsSkill: public ZeroCardViewAsSkill{
public:
    TumiViewAsSkill():ZeroCardViewAsSkill("tumi"){
    }

    virtual const Card *viewAs() const{
        return new TumiCard;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@tumi";
    }
};

class Tumi: public PhaseChangeSkill{
public:
    Tumi():PhaseChangeSkill("tumi"){
        view_as_skill = new TumiViewAsSkill;
    }

    virtual bool onPhaseChange(ServerPlayer *qiaoyun) const{
        Room *room = qiaoyun->getRoom();
        if(qiaoyun->getPhase() == Player::Start)
            room->askForUseCard(qiaoyun, "@@tumi", "@tumi", true);

        return false;
    }
};

class Jueyuan: public TriggerSkill{
public:
    Jueyuan():TriggerSkill("jueyuan"){
        events << Death;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target->hasSkill(objectName());
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const{
        DamageStar damage = data.value<DamageStar>();
        ServerPlayer *killer = damage ? damage->from : NULL;

        if(killer){
            LogMessage log;
            log.from = player;
            log.type = "#TriggerSkill";
            log.arg = objectName();
            room->sendLog(log);
            room->playSkillEffect(objectName(), 1);
            killer->throwAllCards();
            killer->loseAllMarks("poison_jur");
        }
        else
            room->playSkillEffect(objectName(), 2);
        return false;
    }
};

FanyinCard::FanyinCard(){
}

bool FanyinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.length() < subcardsLength() && to_select != Self;
}

void FanyinCard::onEffect(const CardEffectStruct &effect) const{
    effect.to->gainJur("sleep_jur", 2);
}

class Fanyin: public ViewAsSkill{
public:
    Fanyin(): ViewAsSkill("fanyin"){
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("FanyinCard");
    }

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const{
        foreach(CardItem *item, selected)
            if(to_select->getFilteredCard()->getTypeId() == item->getFilteredCard()->getTypeId())
                return false;
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        if(cards.length() < 2)
            return NULL;
        FanyinCard *card = new FanyinCard;
        card->addSubcards(cards);
        return card;
    }
};

class Lichen: public DrawCardsSkill{
public:
    Lichen():DrawCardsSkill("lichen"){
    }

    virtual int getDrawNum(ServerPlayer *tulv, int n) const{
        Room *room = tulv->getRoom();
        int x = 0;
        foreach(ServerPlayer *tmp, room->getAllPlayers()){
            if(tmp->hasMark("sleep_jur"))
                x++;
        }
        x = qMin(x, 4);
        if(x > 0 && room->askForSkillInvoke(tulv, objectName())){
            room->playSkillEffect(objectName());
            room->setPlayerMark(tulv, objectName(), x);
            return n + x;
        }else
            return n;
    }

    virtual void drawDone(ServerPlayer *heshang, int) const{
        Room *room = heshang->getRoom();
        int x = heshang->getMark(objectName());
        if(x > 2){
            ServerPlayer *target = room->askForPlayerChosen(heshang, room->getOtherPlayers(heshang), objectName());
            DamageStruct daah;
            daah.from = target;
            daah.to = heshang;
            room->damage(daah);
        }
        room->setPlayerMark(heshang, objectName(), 0);
    }
};

class Lunhui: public TriggerSkill{
public:
    Lunhui():TriggerSkill("lunhui"){
        events << Death;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target->hasSkill(objectName());
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const{
        DamageStar damage = data.value<DamageStar>();
        ServerPlayer *killer = damage ? damage->from : NULL;
        if(killer){
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            killer->playSkillEffect(objectName(), 1);
            room->loseMaxHp(killer);
            room->acquireSkill(killer, objectName());
        }
        else
            room->playSkillEffect(objectName(), 2);
        return false;
    }
};

class Kaizi: public MasochismSkill{
public:
    Kaizi():MasochismSkill("Kaizi"){
    }

    virtual bool triggerable(const ServerPlayer *) const{
        return true;
    }

    virtual void onDamaged(ServerPlayer *player, const DamageStruct &damage) const{
        Room *room = player->getRoom();
        if(player->getGender() != General::Male)
            return;
        QList<ServerPlayer *> huhuhu = room->findPlayersBySkillName(objectName());
        foreach(ServerPlayer *huhu, huhuhu){
            if(player->hasMark("lucky_jur"))
                continue;
            if(room->askForCard(huhu, "..", "@kaizi:" + player->objectName(), true, QVariant::fromValue(damage), CardDiscarded)){
                LogMessage g;
                g.type = "#InvokeSkill";
                g.from = huhu;
                g.arg = objectName();
                room->sendLog(g);
                player->gainJur("lucky_jur", 2);
            }
        }
    }
};

class Dingxin: public TriggerSkill{
public:
    Dingxin():TriggerSkill("dingxin"){
        events << PreConjuring << Death;
        frequency = Compulsory;
    }

    virtual int getPriority(TriggerEvent event) const{
        return event == Death ? 2 : -2;
    }

    virtual bool triggerable(const ServerPlayer *) const{
        return true;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        if(event == Death){
            if(player->hasSkill(objectName())){
                LogMessage log;
                log.type = "#TriggerSkill";
                log.from = player;
                log.arg = objectName();
                room->sendLog(log);
                player->playSkillEffect(objectName());
                foreach(ServerPlayer *tmp, room->getAlivePlayers()){
                    QStringList jurs = tmp->getAllMarkName(3, "_jur");
                    if(!jurs.isEmpty())
                        tmp->removeJur(jurs.first());
                }
            }
        }
        else{
            if(room->findPlayerBySkillName(objectName())){
                QStringList dataa = data.toString().split("*");
                dataa.replace(1, "100");
                data = dataa.join("*");
            }
        }
        return false;
    }
};

class Tiaonong: public TriggerSkill{
public:
    Tiaonong():TriggerSkill("tiaonong"){
        events << PhaseEnd;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return true;
    }

    virtual bool trigger(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const{
        if(player->getPhase() == Player::Play && player->getSlashCount() == 0){
            QList<ServerPlayer *> goose = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *ligu, goose){
                if(ligu == player)
                    continue;
                if(player->hasMark("chaos_jur"))
                    break;
                if(ligu->askForSkillInvoke(objectName()))
                    player->gainJur("chaos_jur", 2);
            }
        }
        return false;
    }
};

class Misaki: public TriggerSkill{
public:
    Misaki():TriggerSkill("misaki"){
        events << CardAsked;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const{
        if(room->getCurrent() == player)
            return false;
        const CardPattern *pattern = Sanguosha->getPattern(data.toString());
        if(player->askForSkillInvoke(objectName())){
            int peek = room->getDrawPile().at(0);
            room->showCard(player, peek);
            const Card *card = Sanguosha->getCard(peek);
            if(pattern->match(player, card)){
                room->showCard(player, room->getDrawPile().at(1));
                room->provide(card);
                return false;
            }
            else{
                peek = room->getDrawPile().at(1);
                room->showCard(player, peek);
                card = Sanguosha->getCard(peek);
                if(pattern->match(player, card)){
                    room->provide(card);
                    return false;
                }
            }
        }
        return false;
    }
};

class Gouxian: public TriggerSkill{
public:
    Gouxian():TriggerSkill("gouxian"){
        events << Death;
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target->hasSkill(objectName());
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const{
        DamageStar damage = data.value<DamageStar>();
        ServerPlayer *killer = damage ? damage->from : NULL;
        if(killer){
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            killer->playSkillEffect(objectName(), 1);
            room->acquireSkill(killer, "rugou");
        }
        else
            room->playSkillEffect(objectName(), 2);
        return false;
    }
};

class Rugou: public TriggerSkill{
public:
    Rugou():TriggerSkill("rugou"){
        events << Predamaged;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if(damage.damage > 0){
            LogMessage log;
            log.type = "#TriggerSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            player->playSkillEffect(objectName());
            room->loseMaxHp(player, damage.damage);
            return true;
        }
        return false;
    }
};

CasketPackage::CasketPackage()
    :GeneralPackage("casket")
{
    skills << new Stealth;
    General *moon_panqiaoyun = new General(this, "moon_panqiaoyun", "moon", 3, false);
    moon_panqiaoyun->addSkill(new Qingdu);
    moon_panqiaoyun->addSkill(new Tumi);
    moon_panqiaoyun->addSkill(new Jueyuan);

    General *sun_peiruhai = new General(this, "sun_peiruhai", "sun", 3);
    sun_peiruhai->addSkill(new Fanyin);
    sun_peiruhai->addSkill(new Lichen);
    sun_peiruhai->addSkill(new Lunhui);

    addMetaObject<TumiCard>();
    addMetaObject<FanyinCard>();

    General *moon_jiashi = new General(this, "moon_jiashi", "moon", 3, false);
    moon_jiashi->addSkill(new Kaizi);
    moon_jiashi->addSkill(new Dingxin);

    General *sun_ligu = new General(this, "sun_ligu", "sun", 3);
    sun_ligu->addSkill(new Tiaonong);
    sun_ligu->addSkill(new Misaki);
    sun_ligu->addSkill(new Gouxian);
    sun_ligu->addRelateSkill("rugou");
    skills << new Rugou;
}

ADD_PACKAGE(Casket)
