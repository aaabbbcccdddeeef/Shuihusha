#include "mustang.h"
#include "client.h"
#include "carditem.h"
#include "engine.h"
#include "maneuvering.h"
#include "plough.h"

class Qiaogong: public TriggerSkill{
public:
    Qiaogong():TriggerSkill("qiaogong"){
        events << QiaogongTrigger;
        frequency = Compulsory;
    }

    static CardStar getScreenSingleEquip(Room *room, const EquipCard *equip){
        int n = 0;
        CardStar target = equip;
        foreach(ServerPlayer *tmp, room->getAlivePlayers()){
            foreach(const Card *c, tmp->getEquips(true)){
                if(c->getSubtype() == equip->getSubtype()){
                    n ++;
                    target = c;
                }
            }
            if(n > 1)
                return NULL;
        }
        return n == 1 ? target : NULL;
    }

    static void storeEquip(ServerPlayer *taozi, QString name, QVariant data){
        QString perty = "qiaogong_" + name;
        taozi->tag[perty] = data;
        Self->tag[perty] = data;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *taozi, QVariant &data) const{
        QiaogongStruct qkgy = data.value<QiaogongStruct>();
        QList<const Card *> cards;
        if(qkgy.equip->isVirtualCard()){
            QList<int> subcards = qkgy.equip->getSubcards();
            foreach(int subcard, subcards)
                cards << Sanguosha->getCard(subcard);
        }
        else
            cards << qkgy.equip;

        foreach(const Card *card, cards){
            const EquipCard *equip = qobject_cast<const EquipCard*>(card);
            QString name = equip->getSubtype();

            if(qkgy.wear && getScreenSingleEquip(room, equip)){ //0 to 1
                if(qkgy.target == taozi)
                    continue;
                storeEquip(taozi, name.left(1), QVariant::fromValue((CardStar)equip));
                if(name == "weapon"){
                    const Weapon *weapon = qobject_cast<const Weapon*>(equip);
                    if(weapon->hasSkill())
                        room->attachSkillToPlayer(taozi, weapon->objectName());
                }
            }
            else if(!qkgy.wear && getScreenSingleEquip(room, equip)){ //2 to 1
                CardStar equ = getScreenSingleEquip(room, equip);
                storeEquip(taozi, name.left(1), QVariant::fromValue(equ));
                if(name == "weapon"){
                    const Weapon *weapon = qobject_cast<const Weapon*>(equ);
                    if(weapon->hasSkill())
                        room->attachSkillToPlayer(taozi, weapon->objectName());
                }
            }
            else{ //1 to 2, 2 to 3 ... ; 1 to 0, 3 to 2, 4 to 3 ...
                if(name == "weapon"){
                    QString proxy = QString("qiaogong_%1").arg(name.left(1));
                    CardStar myweapon = taozi->tag[proxy].value<CardStar>();
                    if(!myweapon)
                        continue;
                    const Weapon *weapon = qobject_cast<const Weapon*>(myweapon);
                    if(weapon->hasSkill())
                        room->detachSkillFromPlayer(taozi, weapon->objectName(), false);
                }
                storeEquip(taozi, name.left(1), QVariant());
            }
        }

        return false;
    }
};

class Manli: public TriggerSkill{
public:
    Manli():TriggerSkill("manli"){
        events << DamageProceed;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *turtle, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        const Card *reason = damage.card;
        if(reason == NULL)
            return false;
        if((reason->inherits("Slash") || reason->inherits("Duel"))
            && turtle->getWeapon() && turtle->getArmor()
            && turtle->askForSkillInvoke(objectName(), data)){
            room->playSkillEffect(objectName());
            LogMessage log;
            log.type = "#ManliBuff";
            log.from = turtle;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(damage.damage + 1);
            room->sendLog(log);

            damage.damage ++;
            data = QVariant::fromValue(damage);
        }
        return false;
    }
};

class Baonu:public TriggerSkill{
public:
    Baonu():TriggerSkill("baonu"){
        events << CardUsed << CardFinished << Predamage << Damage;
    }

    virtual int getPriority(TriggerEvent event) const{
        return event == CardUsed || event == Predamage ? 1 : -1;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *pilipili, QVariant &data) const{
        if(event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if(pilipili->getPhase() == Player::Play && use.card->isKindOf("Slash") && pilipili->askForSkillInvoke(objectName(), data)){
                room->playSkillEffect(objectName());
                room->loseHp(pilipili);
                pilipili->tag["BaonuCard"] = QVariant::fromValue((CardStar)use.card);
            }
        }
        else if(event == Predamage){
            DamageStruct damage = data.value<DamageStruct>();
            CardStar slash = pilipili->tag["BaonuCard"].value<CardStar>();
            int x = qMin(3, pilipili->getLostHp());
            if(damage.card && damage.card == slash && damage.to->isAlive()){
                LogMessage log;
                log.type = "#BaonuBuff";
                log.from = pilipili;
                log.to << damage.to;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(damage.damage + x);
                room->sendLog(log);

                damage.damage += x;
                data = QVariant::fromValue(damage);
                return false;
            }
        }
        else if(event == CardFinished){
            pilipili->tag.remove("BaonuCard");
        }
        else{
            DamageStruct damage = data.value<DamageStruct>();
            int x = qMin(3, pilipili->getLostHp());
            CardStar slash = pilipili->tag["BaonuCard"].value<CardStar>();
            if(damage.card == slash){
                int all = pilipili->getCardCount(true);
                if(all < x)
                    pilipili->throwAllCards(true);
                else
                    room->askForDiscard(pilipili, objectName(), x, false, true);
            }
        }
        return false;
    }
};

class Jizhan: public TriggerSkill{
public:
    Jizhan():TriggerSkill("jizhan"){
        events << SlashMissed << CardUsed << CardFinished << Predamage;
    }

    virtual int getPriority(TriggerEvent event) const{
        return event == CardUsed || event == Predamage ? 1 : -1;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *pilipili, QVariant &data) const{
        if(event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if(use.card->isKindOf("Slash") && pilipili->askForSkillInvoke(objectName(), data)){
                room->playSkillEffect(objectName(), qrand() % 2 + 1);
                pilipili->tag["JizhanCard"] = QVariant::fromValue((CardStar)use.card);
            }
        }
        else if(event == Predamage){
            DamageStruct damage = data.value<DamageStruct>();
            CardStar slash = pilipili->tag["JizhanCard"].value<CardStar>();
            if(damage.card && damage.card == slash && damage.to->isAlive()){
                LogMessage log;
                log.type = "#JizhanBuff";
                log.from = pilipili;
                log.to << damage.to;
                log.arg = QString::number(damage.damage);
                log.arg2 = QString::number(damage.damage + 1);
                room->sendLog(log);

                damage.damage ++;
                data = QVariant::fromValue(damage);
                return false;
            }
        }
        else if(event == CardFinished){
            pilipili->tag.remove("JizhanCard");
        }
        else{
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            CardStar slash = pilipili->tag["JizhanCard"].value<CardStar>();
            if(effect.slash == slash){
                room->sendLog(LogMessage("#Jizhan", pilipili, objectName()));
                room->playSkillEffect(objectName(), qrand() % 2 + 3);
                if(!room->askForDiscard(pilipili, objectName(), 2, true))
                    room->loseHp(pilipili);
            }
        }
        return false;
    }
};

class Tianyan: public TriggerSkill{
public:
    Tianyan():TriggerSkill("tianyan"){
        events << PhaseChange << Damaged;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return true;
    }

    virtual int getPriority(TriggerEvent event) const{
        return event == Damaged ? -1 : 1;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        if(event == Damaged){
            if(player->hasSkill(objectName()) && player->hasMark("@blind"))
                player->loseAllMarks("@blind");
            return false;
        }
        if(player->getPhase() != Player::Start)
            return false;
        if(player->hasSkill(objectName()))
            player->loseAllMarks("@blind");
        QList<ServerPlayer *>tianqis = room->findPlayersBySkillName(objectName());
        foreach(ServerPlayer *tianqi, tianqis){
            if(tianqi == player)
                continue;
            if(!tianqi->hasMark("@blind") && tianqi->askForSkillInvoke(objectName())){
                room->playSkillEffect(objectName());

                QList<int> cards = room->getNCards(3);
                room->fillAG(cards, tianqi);
                int card_id = room->askForAG(tianqi, cards, false, objectName());
                cards.removeOne(card_id);
                room->takeAG(tianqi, card_id);
                tianqi->gainMark("@blind");
                room->broadcastInvoke("clearAG");

                for(int i = cards.length() - 1; i >= 0; i--){
                    //room->throwCard(cards.at(i));
                    const Card *tmp = Sanguosha->getCard(cards.at(i));
                    room->moveCardTo(tmp, NULL, Player::DrawPile);
                }
            }
        }

        return false;
    }
};

class Huazhu: public DrawCardsSkill{
public:
    Huazhu():DrawCardsSkill("huazhu"){
        frequency = Frequent;
    }

    virtual int getDrawNum(ServerPlayer *player, int n) const{
        int x = player->getHandcardNum();
        foreach(ServerPlayer *tmp, player->getRoom()->getOtherPlayers(player))
            if(tmp->getHandcardNum() > x)
                x = tmp->getHandcardNum();
        x = qMin(2, qAbs(x - player->getHandcardNum()));
        if(x > 0 && player->askForSkillInvoke(objectName())){
            player->playSkillEffect(objectName());
            return n + x;
        }
        return n;
    }
};

BingjiCard::BingjiCard(){
    mute = true;
    will_throw = false;
}

bool BingjiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    int x = qMax(1, Self->getLostHp());
    return targets.length() < x;
}

bool BingjiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    int x = qMax(1, Self->getLostHp());
    return targets.length() <= x && !targets.isEmpty();
}

void BingjiCard::onUse(Room *room, const CardUseStruct &card_use) const{
    Slash *slash = new Slash(Card::NoSuit, 0);
    slash->setSkillName(skill_name);
    foreach(int x, getSubcards())
        slash->addSubcard(Sanguosha->getCard(x));
    CardUseStruct use;
    use.card = slash;
    use.from = card_use.from;
    use.to = card_use.to;
    room->useCard(use);
}

class Bingji: public ViewAsSkill{
public:
    Bingji():ViewAsSkill("bingji"){
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return Slash::IsAvailable(player);
    }

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const{
        if(selected.isEmpty())
            return true;
        else if(selected.length() == 1){
            QString type1 = selected.first()->getFilteredCard()->getType();
            return to_select->getFilteredCard()->getType() == type1;
        }else
            return false;
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        if(cards.length() == 2){
            BingjiCard *card = new BingjiCard();
            card->addSubcards(cards);
            return card;
        }else
            return NULL;
    }
};

class Yueli:public TriggerSkill{
public:
    Yueli():TriggerSkill("yueli"){
        frequency = Frequent;
        events << FinishJudge;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *yuehe, QVariant &data) const{
        JudgeStar judge = data.value<JudgeStar>();
        CardStar card = judge->card;

        QVariant data_card = QVariant::fromValue(card);
        if(judge->card->isKindOf("BasicCard") && yuehe->askForSkillInvoke(objectName(), data_card)){
            if(card->objectName() == "shit"){
                QString result = room->askForChoice(yuehe, objectName(), "yes+no");
                if(result == "no"){
                    room->playSkillEffect(objectName(), 2);
                    return false;
                }
            }
            yuehe->obtainCard(judge->card);
            if(judge->reason != "taohui")
                room->playSkillEffect(objectName(), 1);
            return true;
        }
        if(judge->reason != "taohui")
            room->playSkillEffect(objectName(), 2);
        return false;
    }
};

class Taohui:public TriggerSkill{
public:
    Taohui():TriggerSkill("taohui"){
        events << PhaseChange << FinishJudge;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *yuehe, QVariant &data) const{
        if(event == PhaseChange && yuehe->getPhase() == Player::Finish){
            while(yuehe->askForSkillInvoke(objectName())){
                room->playSkillEffect(objectName());

                JudgeStruct judge;
                judge.reason = objectName();
                judge.who = yuehe;
                judge.time_consuming = true;

                room->judge(judge);
                if(judge.card->isKindOf("BasicCard") || judge.card->isKindOf("EventsCard"))
                    break;
            }
        }
        else if(event == FinishJudge){
            JudgeStar judge = data.value<JudgeStar>();
            if(judge->reason == objectName()){
                if(!judge->card->isKindOf("BasicCard") && !judge->card->isKindOf("EventsCard")){
                    Room *room = yuehe->getRoom();
                    room->throwCard(judge->card->getId());
                    ServerPlayer *target = room->askForPlayerChosen(yuehe, room->getAllPlayers(), objectName());
                    target->drawCards(1);
                    return true;
                }
            }
        }
        return false;
    }
};

MaiyiCard::MaiyiCard(){

}

bool MaiyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    if(targets.length() >= 2)
        return false;
    return true;
}

bool MaiyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return targets.length() == 2 || targets.isEmpty();
}

void MaiyiCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    room->playSkillEffect(objectName());
    if(targets.isEmpty())
        room->setPlayerFlag(source, "maiyi");
    else{
        foreach(ServerPlayer *target, targets)
            target->drawCards(2);
    }
}

class MaiyiViewAsSkill: public ViewAsSkill{
public:
    MaiyiViewAsSkill(): ViewAsSkill("maiyi"){

    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return ! player->hasUsed("MaiyiCard");
    }

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const{
        if(selected.length() >= 3)
            return false;

        foreach(CardItem *item, selected){
            if(selected.length() == 1 && item->getCard()->inherits("EquipCard") && to_select->getCard()->inherits("EquipCard"))
                return true;
            if(to_select->getFilteredCard()->getSuit() == item->getFilteredCard()->getSuit())
                return false;
        }
        return true;
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        bool can = false;
        if(cards.length() == 3)
            can = true;
        if(cards.length() == 2){
            if(cards.first()->getCard()->inherits("EquipCard") &&
               cards.last()->getCard()->inherits("EquipCard"))
                can = true;
        }
        if(!can)
            return NULL;
        MaiyiCard *card = new MaiyiCard;
        card->addSubcards(cards);
        return card;
    }
};

class Maiyi: public PhaseChangeSkill{
public:
    Maiyi():PhaseChangeSkill("maiyi"){
        view_as_skill = new MaiyiViewAsSkill;
    }

    virtual int getPriority(TriggerEvent) const{
        return -1;
    }

    virtual bool onPhaseChange(ServerPlayer *xueyong) const{
        if(xueyong->getPhase() != Player::NotActive || !xueyong->hasFlag("maiyi"))
            return false;
        Room *room = xueyong->getRoom();

        ServerPlayer *maiyier = room->askForPlayerChosen(xueyong, room->getAllPlayers(), objectName());
        LogMessage log;
        log.type = "#MaiyiCanInvoke";
        log.to << maiyier;
        log.from = xueyong;
        log.arg = objectName();
        room->sendLog(log);

        maiyier->gainAnExtraTurn(xueyong);
        return false;
    }
};

HunjiuCard::HunjiuCard(){
    will_throw = false;
}

bool HunjiuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && Self->inMyAttackRange(to_select);
}

bool HunjiuCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    return (targets.isEmpty() && Analeptic::IsAvailable(Self)) ||
            (targets.length() == 1 && Ecstasy::IsAvailable(Self));
}

void HunjiuCard::onUse(Room *room, const CardUseStruct &card_use) const{
    int card_id = getSubcards().first();
    Card::Suit suit = Sanguosha->getCard(card_id)->getSuit();
    int num = Sanguosha->getCard(card_id)->getNumber();
    CardUseStruct use;
    use.from = card_use.from;
    if(card_use.to.isEmpty()){
        Analeptic *a = new Analeptic(suit, num);
        a->setSkillName("hunjiu");
        a->addSubcard(card_id);
        use.card = a;
    }
    else{
        Ecstasy *e = new Ecstasy(suit, num);
        e->setSkillName("hunjiu");
        e->addSubcard(card_id);
        use.card = e;
        use.to << card_use.to.first();
    }
    room->useCard(use);
}

class Hunjiu:public OneCardViewAsSkill{
public:
    Hunjiu():OneCardViewAsSkill("hunjiu"){

    }

    virtual bool viewFilter(const CardItem *to_select) const{
        const Card *card = to_select->getFilteredCard();

        switch(ClientInstance->getStatus()){
        case Client::Playing:{
                return card->inherits("Peach") || card->inherits("Analeptic") || card->inherits("Ecstasy");
            }

        case Client::Responsing:{
                QString pattern = ClientInstance->getPattern();
                if(pattern.contains("analeptic"))
                    return card->inherits("Ecstasy") || card->inherits("Peach");
            }
        default:
            return false;
        }
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern.contains("analeptic");
    }

    virtual const Card *viewAs(CardItem *card_item) const{
        HunjiuCard *card = new HunjiuCard;
        card->addSubcard(card_item->getFilteredCard());
        return card;
    }
};

class Guitai: public TriggerSkill{
public:
    Guitai():TriggerSkill("guitai"){
        events << CardEffected;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return true;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *player, QVariant &data) const{
        ServerPlayer *zhufu = room->findPlayerBySkillName(objectName());
        CardEffectStruct effect = data.value<CardEffectStruct>();
        if(effect.to == zhufu)
            return false;

        if(!zhufu || zhufu->getPhase() != Player::NotActive)
            return false;

        if(!effect.card->inherits("Peach"))
            return false;

        if(!zhufu->isNude() && zhufu->isWounded()){
            const Card *card = room->askForCard(zhufu, ".|heart", "@guitai:" + effect.to->objectName(), true, data, CardDiscarded);
            if(card){
                room->playSkillEffect(objectName());
                LogMessage log;
                log.type = "#Guitai";
                log.from = zhufu;
                log.to << effect.to;
                log.arg = objectName();
                log.arg2 = effect.card->objectName();
                room->sendLog(log);

                effect.from = effect.from;
                effect.to = zhufu;
                data = QVariant::fromValue(effect);
            }
        }
        return false;
    }
};

ZishiCard::ZishiCard(){
    target_fixed = true;
}

void ZishiCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    int num = this->getSubcards().length();
    source->tag["ZiShi"] = num;
}

class ZishiViewAsSkill: public ViewAsSkill{
public:
    ZishiViewAsSkill():ViewAsSkill("zishi"){
    }

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const{
        return selected.length() < 3 && to_select->getCard()->isBlack();
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@zishi";
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        if(cards.length() > 2 && !cards.isEmpty())
            return NULL;
        ZishiCard *card = new ZishiCard;
        card->addSubcards(cards);
        return card;
    }
};

class Zishi:public DrawCardsSkill{
public:
    Zishi():DrawCardsSkill("zishi"){
        view_as_skill = new ZishiViewAsSkill;
    }

    virtual int getPriority(TriggerEvent) const{
        return -2;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual int getDrawNum(ServerPlayer *player, int n) const{
        if(player->getGender() != General::Male)
            return n;
        Room *room = player->getRoom();
        QList<ServerPlayer *> duan3iang = room->findPlayersBySkillName(objectName());
        if(duan3iang.isEmpty())
            return n;
        foreach(ServerPlayer *duan3niang, duan3iang){
            if(duan3niang->isNude())
                continue;
            duan3niang->tag["ZishiSource"] = QVariant::fromValue((PlayerStar)player);
            if(room->askForUseCard(duan3niang, "@@zishi", "@zishi:" + player->objectName(), true)){
                int delta = duan3niang->tag.value("ZiShi", 0).toInt();
                if(delta > 0){
                    QString choice = room->askForChoice(duan3niang, objectName(), "duo+shao", QVariant::fromValue((PlayerStar)player));
                    LogMessage log;
                    log.type = "#Zishi";
                    log.from = duan3niang;
                    log.to << player;
                    log.arg = QString::number(delta);
                    log.arg2 = choice == "duo" ? "duo" : "shao";
                    n = choice == "duo" ? n + delta : n - delta;
                    room->sendLog(log);
                }
                duan3niang->tag.remove("ZiShi");
            }
            duan3niang->tag.remove("ZishiSource");
        }
        return qMax(n, 0);
    }
};

NaxianCard::NaxianCard(){
    mute = true;
}

bool NaxianCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const{
    if(Self->getPhase() == Player::Draw)
        return to_select != Self;
    else
        return to_select != Self && !to_select->isKongcheng();
}

void NaxianCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    ServerPlayer *target = targets.first();
    if(source->getPhase() == Player::Draw){
        room->playSkillEffect(skill_name, qrand() % 2 + 1);
        target->drawCards(2);
        target->clearHistory("NaxianCard");
    }else{
        int l = qMin(qMax(1, source->getLostHp()), target->getHandcardNum());
        if(l < 1)
            return;
        QList<int> cards = target->handCards();
        qShuffle(cards);
        cards = cards.mid(0, l);
        DummyCard *dummy = new DummyCard;
        foreach(int id, cards)
            dummy->addSubcard(id);
        room->playSkillEffect(skill_name, qrand() % 2 + 3);
        source->obtainCard(dummy);
        delete dummy;
        target->drawCards(l);
    }
}

class NaxianViewAsSkill: public ZeroCardViewAsSkill{
public:
    NaxianViewAsSkill(): ZeroCardViewAsSkill("naxian"){
    }

    virtual const Card *viewAs() const{
        return new NaxianCard;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "@@naxian";
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return ! player->hasUsed("NaxianCard");
    }
};

class Naxian:public PhaseChangeSkill{
public:
    Naxian():PhaseChangeSkill("naxian"){
        view_as_skill = new NaxianViewAsSkill;
    }

    virtual bool onPhaseChange(ServerPlayer *duqian) const{
        Room *room = duqian->getRoom();
        return duqian->getPhase() == Player::Draw &&
           room->askForUseCard(duqian, "@@naxian", "@naxian", true);
    }
};

class Yiguan:public TriggerSkill{
public:
    Yiguan():TriggerSkill("yiguan"){
        events << CardUsed;
        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *tianxi, QVariant &data) const{
        CardUseStruct use = data.value<CardUseStruct>();
        if(use.card->isKindOf("Slash") && use.card->isBlack() && tianxi->askForSkillInvoke(objectName())){
            room->playSkillEffect(objectName());
            int x = qMin(room->getLieges("guan", NULL).count(), 2);
            tianxi->drawCards(x);
        }
        return false;
    }
};

QiangzhanCard::QiangzhanCard(){
    mute = true;
}

bool QiangzhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return Self != to_select && !to_select->isKongcheng();
}

void QiangzhanCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    PlayerStar target = targets.first();
    int l = qMin(3, target->getHandcardNum());
    QList<int> cards = target->handCards();
    qShuffle(cards);
    cards = cards.mid(0, l);
    room->playSkillEffect(skill_name, qrand() % 2 + 1);
    DummyCard *dummy = new DummyCard;
    foreach(int id, cards)
        dummy->addSubcard(id);
    source->obtainCard(dummy, false);
    target->gainMark("@grabs");
    delete dummy;
}

class QiangzhanViewAsSkill:public ZeroCardViewAsSkill{
public:
    QiangzhanViewAsSkill():ZeroCardViewAsSkill("qiangzhan"){
    }

    virtual const Card *viewAs() const{
        return new QiangzhanCard;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const{
        return pattern == "@@qiangzhan";
    }

    virtual bool isEnabledAtPlay(const Player *) const{
        return false;
    }
};

class Qiangzhan: public PhaseChangeSkill{
public:
    Qiangzhan():PhaseChangeSkill("qiangzhan"){
        view_as_skill = new QiangzhanViewAsSkill;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target != NULL;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const{
        Room *room = player->getRoom();
        if(player->getPhase() == Player::Finish && player->hasSkill(objectName()))
            room->askForUseCard(player, "@@qiangzhan", "@qiangzhan", true);
        else if(player->getPhase() == Player::RoundStart && player->hasMark("@grabs")){
            ServerPlayer *yin = room->findPlayerBySkillName(objectName());
            if(yin){
                DummyCard *card = yin->wholeHandCards();
                if(card){
                    LogMessage log;
                    log.type = "#Qiangzhan";
                    log.from = yin;
                    log.to << player;
                    log.arg = objectName();
                    room->sendLog(log);
                    room->playSkillEffect(objectName(), qrand() % 2 + 3);

                    room->obtainCard(player, card, false);
                    player->loseMark("@grabs");
                    delete card;
                }
            }
        }
        return false;
    }
};

JingsuanCard::JingsuanCard(){
}

#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QCommandLinkButton>

JingsuanDialog *JingsuanDialog::GetInstance(){
    static JingsuanDialog *instance;
    if(instance == NULL)
        instance = new JingsuanDialog;

    return instance;
}

JingsuanDialog::JingsuanDialog()
{
    setWindowTitle(Sanguosha->translate("jingsuan"));
    group = new QButtonGroup(this);

    QHBoxLayout *layout = new QHBoxLayout;
    layout->addWidget(createLeft());
    layout->addWidget(createRight());

    setLayout(layout);

    connect(group, SIGNAL(buttonClicked(QAbstractButton*)), this, SLOT(selectCard(QAbstractButton*)));
}

QGroupBox *JingsuanDialog::createLeft(){
    QGroupBox *box = new QGroupBox;
    box->setTitle(Sanguosha->translate("basic"));

    QVBoxLayout *layout = new QVBoxLayout;

    QList<const Card *> cards = Sanguosha->findChildren<const Card *>();
    foreach(const Card *card, cards){
        if(card->getPackage() == "gift")
            continue;
        if(card->getPackage() == "purgatory")
            continue;
        //const Package *package = Sanguosha->findChild<const Package *>(card->getPackage());
        //if(package->getGenre() == Package::LUA)
        //    continue;
        if(card->getTypeId() == Card::Basic && !map.contains(card->objectName())){
            Card *c = Sanguosha->cloneCard(card->objectName(), Card::NoSuit, 0);
            c->setSkillName("jingsuan");
            c->setParent(this);

            layout->addWidget(createButton(c));
        }
    }

    layout->addStretch();

    box->setLayout(layout);
    return box;
}

QGroupBox *JingsuanDialog::createRight(){
    QGroupBox *box = new QGroupBox(Sanguosha->translate("ndtrick"));
    QHBoxLayout *layout = new QHBoxLayout;

    QGroupBox *box1 = new QGroupBox(Sanguosha->translate("stt"));
    QVBoxLayout *layout1 = new QVBoxLayout;

    QGroupBox *box2 = new QGroupBox(Sanguosha->translate("mtt"));
    QVBoxLayout *layout2 = new QVBoxLayout;

    QList<const Card *> cards = Sanguosha->findChildren<const Card *>();
    foreach(const Card *card, cards){
        if(card->getPackage() == "gift")
            continue;
        if(card->getPackage() == "purgatory")
            continue;
        if(card->getPackage() == "ex_cards")
            continue;
        if(card->isNDTrick() && !map.contains(card->objectName())){
            Card *c = Sanguosha->cloneCard(card->objectName(), Card::NoSuit, 0);
            c->setSkillName("jingsuan");
            c->setParent(this);

            QVBoxLayout *layout = c->isKindOf("SingleTargetTrick") ? layout1 : layout2;
            layout->addWidget(createButton(c));
        }
    }

    box->setLayout(layout);
    box1->setLayout(layout1);
    box2->setLayout(layout2);

    layout1->addStretch();
    layout2->addStretch();

    layout->addWidget(box1);
    layout->addWidget(box2);
    return box;
}

void JingsuanDialog::popup(){
    if(ClientInstance->getStatus() != Client::Playing)
        return;

    foreach(QAbstractButton *button, group->buttons()){
        const Card *card = map[button->objectName()];
        bool enable = false;
        if(card->isKindOf("Slash"))
            enable = Slash::IsAvailable(Self);
        else if(card->isKindOf("Peach"))
            enable = Peach::IsAvailable(Self);
        else if(card->isKindOf("Analeptic"))
            enable = Analeptic::IsAvailable(Self);
        else if(card->isKindOf("Ecstasy"))
            enable = Ecstasy::IsAvailable(Self);
        else
            enable = card->isAvailable(Self);
        button->setEnabled(enable);
    }

    Self->tag.remove("Jingsuan");
    exec();
}

void JingsuanDialog::selectCard(QAbstractButton *button){
    CardStar card = map.value(button->objectName());
    Self->tag["Jingsuan"] = QVariant::fromValue(card);
    accept();
}

QAbstractButton *JingsuanDialog::createButton(const Card *card){
    QCommandLinkButton *button = new QCommandLinkButton(Sanguosha->translate(card->objectName()));
    button->setObjectName(card->objectName());
    button->setToolTip(card->getDescription());

    map.insert(card->objectName(), card);
    group->addButton(button);

    return button;
}

bool JingsuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    CardStar card = Self->tag["Jingsuan"].value<CardStar>();
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card);
}

bool JingsuanCard::targetFixed() const{
    if(ClientInstance->getStatus() == Client::Responsing)
        return true;

    CardStar card = Self->tag["Jingsuan"].value<CardStar>();
    return card && card->targetFixed();
}

bool JingsuanCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const{
    CardStar card = Self->tag["Jingsuan"].value<CardStar>();
    return card && card->targetsFeasible(targets, Self);
}

const Card *JingsuanCard::validate(const CardUseStruct *card_use) const{
    Room *room = card_use->from->getRoom();
    //room->playSkillEffect("jingsuan");
    const Card *card = Sanguosha->getCard(subcards.first());
    Card *use_card = Sanguosha->cloneCard(user_string, card->getSuit(), card->getNumber());
    use_card->setSkillName("jingsuan");
    use_card->addSubcard(subcards.first());
    use_card->addSubcard(subcards.last());
    room->throwCard(this);

    return use_card;
}

const Card *JingsuanCard::validateInResposing(ServerPlayer *player, bool *continuable) const{
    *continuable = true;
    Room *room = player->getRoom();
    QString string;
    if(user_string == "nulliplot")
        string = room->askForChoice(player, "jingsuan-nullchoice", "nullification+counterplot");
    else
        string = "nullification";
    const Card *card = Sanguosha->getCard(subcards.first());
    Card *use_card = Sanguosha->cloneCard(string, card->getSuit(), card->getNumber());
    use_card->setSkillName("jingsuan");
    use_card->addSubcard(card);
    room->throwCard(this);

    return use_card;
}

class Jingsuan:public ViewAsSkill{
public:
    Jingsuan():ViewAsSkill("jingsuan"){
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return (pattern == "nullification" || pattern == "nulliplot") &&
                !player->isKongcheng() &&
                player->getPhase() == Player::Play;
    }

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const{
        int x = Self->getLostHp();
        if(selected.isEmpty())
            return true;
        else if(selected.length() == 1){
            const Card *first = selected.first()->getCard();
            const Card *second = to_select->getCard();
            if(qAbs(first->getNumber() - second->getNumber()) <= x)
                return !to_select->isEquipped();
        }
        return false;
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        if(cards.length() != 2)
            return NULL;

        if(ClientInstance->getStatus() == Client::Responsing){
            JingsuanCard *card = new JingsuanCard;
            card->setUserString(ClientInstance->getPattern());
            card->addSubcards(cards);
            return card;
        }

        CardStar c = Self->tag["Jingsuan"].value<CardStar>();
        if(c){
            JingsuanCard *card = new JingsuanCard;
            card->setUserString(c->objectName());
            card->addSubcards(cards);
            return card;
        }else
            return NULL;
    }

    virtual bool isEnabledAtNullification(const ServerPlayer *player, bool) const{
        return player->getPhase() == Player::Play && player->getHandcardNum() > 1;
    }

    virtual QDialog *getDialog() const{
        return JingsuanDialog::GetInstance();
    }
};

MustangPackage::MustangPackage()
    :GeneralPackage("mustang")
{
    General *qinming = new General(this, "qinming", "jiang");
    qinming->addSkill(new Baonu);

    General *pengqi = new General(this, "pengqi", "guan");
    pengqi->addSkill(new Tianyan);

    General *xueyong = new General(this, "xueyong", "min", "3/4");
    xueyong->addSkill(new Maiyi);
    addMetaObject<MaiyiCard>();

    General *jiangjing = new General(this, "jiangjing", "kou", 3);
    jiangjing->addSkill(new Huazhu);
    jiangjing->addSkill(new Jingsuan);
    addMetaObject<JingsuanCard>();

    General *guosheng = new General(this, "guosheng", "jiang");
    guosheng->addSkill(new Bingji);
    addMetaObject<BingjiCard>();

    General *duansanniang = new General(this, "duansanniang", "min", 4, false);
    duansanniang->addSkill(new Zishi);
    addMetaObject<ZishiCard>();

    General *duqian = new General(this, "duqian", "kou");
    duqian->addSkill(new Naxian);
    addMetaObject<NaxianCard>();

    General *hancunbao = new General(this, "hancunbao", "guan");
    hancunbao->addSkill(new Jizhan);

    General *yintianxi = new General(this, "yintianxi", "guan", 3);
    yintianxi->addSkill(new Yiguan);
    yintianxi->addSkill(new Qiangzhan);
    addMetaObject<QiangzhanCard>();

    General *yuehe = new General(this, "yuehe", "jiang", 3);
    yuehe->addSkill(new Yueli);
    yuehe->addSkill(new Taohui);

    General *zhufu = new General(this, "zhufu", "min", 3);
    zhufu->addSkill(new Hunjiu);
    zhufu->addSkill(new Guitai);
    addMetaObject<HunjiuCard>();

    General *taozongwang = new General(this, "taozongwang", "kou", 3);
    taozongwang->addSkill(new Qiaogong);
    taozongwang->addSkill(new Manli);
}

ADD_PACKAGE(Mustang)
