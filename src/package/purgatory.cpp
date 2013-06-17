#include "purgatory.h"
#include "maneuvering.h"

ChaosJink::ChaosJink(Suit suit, int number)
    :Jink(suit, number)
{
    setObjectName("chaos_jink");
}

ChaosSlash::ChaosSlash(Suit suit, int number)
    :Slash(suit, number)
{
    setObjectName("chaos_slash");
}

Shit::Shit(Suit suit, int number):
    BasicCard(suit, number){
    setObjectName("shit");
    target_fixed = true;
}

QString Shit::getSubtype() const{
    return "specially";
}

void Shit::onUse(Room *room, const CardUseStruct &) const{
    room->moveCardTo(this, NULL, Player::DiscardedPile);
}

void Shit::onMove(const CardMoveStruct &move) const{
    PlayerStar from = move.from;
    if(!from)
        return;
    Room *room = from->getRoom();
    if(from && move.from_place == Player::Hand &&
       room->getCurrent() == move.from
       && (move.to_place == Player::DiscardedPile || move.to_place == Player::Special)
       && move.to == NULL
       && from->isAlive()){

        LogMessage log;
        log.type = "$ShitHint";
        log.card_str = getEffectIdString();
        log.from = from;
        room->sendLog(log);

        if(getSuit() == Spade)
            room->loseHp(from);
        else{
            DamageStruct damage;
            damage.from = damage.to = from;
            damage.card = this;

            switch(getSuit()){
            case Club: damage.nature = DamageStruct::Thunder; break;
            case Heart: damage.nature = DamageStruct::Fire; break;
            default: damage.nature = DamageStruct::Normal;
            }
            room->damage(damage);
        }
    }
}

bool Shit::HasShit(const Card *card){
    if(card->isVirtualCard()){
        QList<int> card_ids = card->getSubcards();
        foreach(int card_id, card_ids){
            const Card *c = Sanguosha->getCard(card_id);
            if(c->objectName() == "shit")
                return true;
        }

        return false;
    }else
        return card->objectName() == "shit";
}

Mastermind::Mastermind(Suit suit, int number)
    :SingleTargetTrick(suit, number, false) {
    setObjectName("mastermind");
}

bool Mastermind::targetsFeasible(const QList<const Player *> &targets, const Player *) const{
    return targets.length() == 2;
}

bool Mastermind::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const{
    return targets.length() <= 1;
}

void Mastermind::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const{
    targets.last()->tag["DtoL"] = QVariant::fromValue((PlayerStar)targets.first());
    QList<ServerPlayer *> tgs;
    tgs << targets.last();
    room->setEmotion(targets, "mastermind");
    TrickCard::use(room, source, tgs);
}

void Mastermind::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.from->getRoom();
    PlayerStar death = effect.to;
    PlayerStar life = death->tag["DtoL"].value<PlayerStar>();

    foreach(ServerPlayer *t, room->getAllPlayers()){
        t->loseAllMarks("@death");
        t->loseAllMarks("@life");
    }

    death->gainMark("@death");
    life->gainMark("@life");
}

QString Mastermind::getEffectPath(bool ) const{
    return Card::getEffectPath();
}

SpinDestiny::SpinDestiny(Suit suit, int number)
    :GlobalEffect(suit, number)
{
    setObjectName("spin_destiny");
}

void SpinDestiny::onUse(Room *room, const CardUseStruct &card_use) const{
    CardUseStruct use = card_use;
    use.to = room->getAllPlayers(false);
    QList<ServerPlayer *> deads;
    foreach(ServerPlayer *dead, room->getAllPlayers(true)){
        if(dead->isDead())
            deads << dead;
    }
    TrickCard::onUse(room, use);
    foreach(ServerPlayer *dead, deads){
        if(dead->getMaxHp() <= 0)
            continue;
        room->revivePlayer(dead);
        //if(dead->getMaxHp() <= 0)
        //    room->setPlayerProperty(dead, "maxhp", 1);
        room->setPlayerProperty(dead, "hp", 1);
    }
}

void SpinDestiny::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.from->getRoom();
    room->loseHp(effect.to);
}

QString SpinDestiny::getEffectPath(bool ) const{
    return Card::getEffectPath();
}

EdoTensei::EdoTensei(Suit suit, int number)
    :SingleTargetTrick(suit, number, false){
    setObjectName("edo_tensei");
    target_fixed = true;
}

void EdoTensei::onEffect(const CardEffectStruct &effect) const{
    Room *room = effect.from->getRoom();
    QStringList targets, targets_object;
    foreach(ServerPlayer *target, room->getAllPlayers(true)){
        if(target->isDead()){
            targets << target->getGeneralName();
            targets_object << target->objectName();
        }
    }
    if(targets.isEmpty())
        return;
    QString hcoi = targets.count() == 1 ? targets.first() :
                   room->askForChoice(effect.from, "edo_tensei", targets.join("+"));
    int index = targets.indexOf(hcoi);
    room->setEmotion(effect.from, "edo_tensei");
    PlayerStar revivd = room->findPlayer(targets_object.at(index), true);
    if(revivd->getMaxHp() <= 0)
        return;
    room->revivePlayer(revivd);
    room->setPlayerProperty(revivd, "hp", 1);
    revivd->drawCards(3);
}

QString EdoTensei::getEffectPath(bool ) const{
    return Card::getEffectPath();
}

bool EdoTensei::isAvailable(const Player *) const{
    return false;
}

class ProudBannerChain: public ProhibitSkill{
public:
    ProudBannerChain():ProhibitSkill("#proud_chain"){
    }

    virtual bool prohibitable(const Player *) const{
        return true;
    }

    virtual bool isProhibited(const Player *, const Player *to, const Card *card) const{
        return to->hasEquip("proud_banner") &&
                !to->isChained() && card->isKindOf("IronChain");
    }
};

class ProudBannerSkill: public ArmorSkill{
public:
    ProudBannerSkill():ArmorSkill("proud_banner"){
        events << TurnedOver << PreConjuring/* << ChainStateChange*/;
    }

    virtual bool trigger(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const{
        LogMessage log;
        log.from = player;
        log.arg = objectName();
        if(event == TurnedOver && player->faceUp()){
            log.type = "#ProudBanner1";
            room->sendLog(log);
            if(player->getGeneral()->isMale())
                player->playCardEffect("Eproud_banner1", "armor");
            else
                player->playCardEffect("Eproud_banner2", "armor");
            return true;
        }/*
        else if(event == ChainStateChange && !player->isChained()){
            log.type = "#ProudBanner2";
            room->sendLog(log);
            player->playCardEffect("Eproud_banner2");
            return true;
        }*/
        else if(event == PreConjuring && qrand() % 2 == 0){
            log.type = "#ProudBanner3";
            log.arg2 = data.toString();
            room->sendLog(log);
            if(player->getGeneral()->isMale())
                player->playCardEffect("Eproud_banner3", "armor");
            else
                player->playCardEffect("Eproud_banner4", "armor");
            return true;
        }
        return false;
    }
};

ProudBanner::ProudBanner(Suit suit, int number)
    :Armor(suit, number)
{
    setObjectName("proud_banner");
    skill = new ProudBannerSkill;
}

class LashGunSkill : public WeaponSkill{
public:
    LashGunSkill():WeaponSkill("lash_gun"){
        events << Damage;
    }

    virtual int getPriority(TriggerEvent) const{
        return -1;
    }

    static QList<ServerPlayer *> getNextandPrevious(ServerPlayer *target){
        QList<ServerPlayer *> targets;
        targets << target->getNextAlive();
        if(target->getRoom()->getAlivePlayers().count() > 2){
            foreach(ServerPlayer *tmp, target->getRoom()->getOtherPlayers(target)){
                if(tmp->getNext() == target){
                    targets << tmp;
                    break;
                }
            }
        }
        return targets;
    }

    virtual bool trigger(TriggerEvent, Room*, ServerPlayer *player, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();
        if(damage.card->isKindOf("Slash") && damage.nature != DamageStruct::Normal){
            player->playCardEffect("Elash_gun", "weapon");
            LogMessage log;
            log.type = "#LashGun";
            log.from = player;
            log.arg = objectName();
            player->getRoom()->sendLog(log);

            foreach(ServerPlayer *tmp, getNextandPrevious(damage.to))
                tmp->gainJur("dizzy_jur", 2);
        }
        return false;
    }
};

LashGun::LashGun(Suit suit, int number)
    :Weapon(suit, number, 6)
{
    setObjectName("lash_gun");
    skill = new LashGunSkill;
}

PurgatoryPackage::PurgatoryPackage()
    :CardPackage("purgatory")
{
    skills << new ProudBannerChain;
    QList<Card *> cards;

    cards
            << new ChaosJink(Card::Heart, 11)
            << new ChaosSlash(Card::Diamond, 10)
            << new Shit(Card::Heart, 10)
            << new Mastermind(Card::Spade, 4)
            << new Mastermind(Card::Diamond, 9)
            << new SpinDestiny(Card::Spade, 13)
            << new Shit(Card::Club, 10)
            << new EdoTensei(Card::Diamond, 2)
            << new EdoTensei(Card::Heart, 11)
            << new Shit(Card::Diamond, 10)
            << new LashGun(Card::Club, 4)
            << new ProudBanner(Card::Heart, 1)
            << new Shit(Card::Spade, 10)
            ;

    foreach(Card *card, cards)
        card->setParent(this);
}

ADD_PACKAGE(Purgatory)
