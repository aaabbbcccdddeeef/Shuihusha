#include "zombie.h"
#include "carditem.h"

class ZombieRule: public ScenarioRule{
public:
    ZombieRule(Scenario *scenario)
        :ScenarioRule(scenario)
    {
        events << GameStart << Death << GameOverJudge << TurnStart << CardUsed;
    }

    void zombify(ServerPlayer *player, ServerPlayer *killer = NULL) const{
        Room *room = player->getRoom();

        //room->setPlayerProperty(player, "general2", "zombie");
        //room->getThread()->addPlayerSkills(player);
        room->transfigure(player, "%zombie", false, false);

        int maxhp = killer ? (killer->getMaxHP() + 1)/2 : 5;
        room->setPlayerProperty(player, "maxhp", maxhp);
        room->setPlayerProperty(player, "hp", player->getMaxHP());
        room->setPlayerProperty(player, "role", "renegade");
        room->detachSkillFromPlayer(player, "yuanzhu", false);
        room->detachSkillFromPlayer(player, "bihu", false);

        LogMessage log;
        log.type = "#Zombify";
        log.from = player;
        room->sendLog(log);

        room->broadcastInvoke("playAudio", QString("mode/zombify-%1").arg(player->getGenderString()));
        room->updateStateItem();

        player->tag.remove("zombie");
    }

    void gameOverJudge(Room *room) const{
        bool hasZombie=false;
        foreach(ServerPlayer *p,room->getAlivePlayers()){
             if (p->getGeneral2Name()=="zombie"){
                 hasZombie=true;
                 break;
             }
        }
        int round = room->getTag("Round").toInt();
        if(round>2&&!hasZombie)
            room->gameOver("lord+loyalist");
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        switch(event){
        case GameStart:{
                room->acquireSkill(player, "yuanzhu");
                room->acquireSkill(player, "bihu");
                break;
            }

        case GameOverJudge:{
                return true;
                break;
            }
        case CardUsed: {
            CardUseStruct use = data.value<CardUseStruct>();
            if(use.card->getTypeId() == Card::Equip && use.from->hasSkill("ganran") && use.to.isEmpty()){
                room->throwCard(use.card, use.from);
                use.from->drawCards(1);
                return true;
            }
            break;
        }
        case Death:{
            bool hasHuman=false;
            if(player->isLord()){
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    if(p->getRoleEnum()==Player::Loyalist){
                        room->setPlayerProperty(player, "role", "loyalist");
                        room->setPlayerProperty(p, "role", "lord");
                        room->setPlayerProperty(p, "maxhp",  p->getMaxHP()+1);

                        room->recover(p, RecoverStruct(), false);

                        int n = player->getMark("@round")>1 ? player->getMark("@round")-1 : 1;
                        p->gainMark("@round", n);
                        hasHuman=true;
                        break;
                    }
                }
            }else
                hasHuman=true;

            DamageStar damage = data.value<DamageStar>();
            if(damage && damage->from){
                ServerPlayer *killer = damage->from;

                if(player->getGeneral2Name()=="zombie"){
                    room->recover(killer, RecoverStruct(killer, NULL, killer->getLostHp()), false);
                    if(player->getRole()=="renegade")
                        killer->drawCards(3);
                }

                else if(killer->getGeneral2Name()=="zombie" && !player->hasMark("@harb")){
                    zombify(player, killer);
                    room->setPlayerProperty(player, "role", "renegade");
                    room->revivePlayer(player);
                    room->setPlayerProperty(killer,"role","rebel");
                }
            }
            if(!hasHuman)
                room->gameOver("rebel");

            gameOverJudge(room);
            break;
        }

        case TurnStart:{
                int round = room->getTag("Round").toInt();
                if(player->isLord()){
                    room->setTag("Round", ++round);
                    player->gainMark("@round");

                    if(player->getMark("@round") > 7){
                        LogMessage log;
                        log.type = "#survive_victory";
                        log.from = player;
                        room->sendLog(log);

                        room->gameOver("lord+loyalist");
                    }
                    else if(round == 2){
                        QList<ServerPlayer *> players = room->getOtherPlayers(room->getLord());
                        qShuffle(players);
                        players.at(0)->tag["zombie"]=true;
                        players.at(1)->tag["zombie"]=true;
                    }
                }else if(player->tag.contains("zombie") && !player->hasMark("@harb")){
                    player->bury();
                    room->killPlayer(player);
                    zombify(player);
                    room->setPlayerProperty(player,"role","rebel");
                    room->revivePlayer(player);
                    player->drawCards(5);
                    room->getThread()->delay();
                }

                if(round == 1){
                    room->acquireSkill(player, "yuanzhu");
                    room->acquireSkill(player, "bihu");
                }
                gameOverJudge(room);
            }

        default:
            break;
        }

        return false;
    }
};

bool ZombieScenario::exposeRoles() const{
    return true;
}

void ZombieScenario::assign(QStringList &generals, QStringList &roles) const{
    Q_UNUSED(generals);

    roles << "lord";
    int i;
    for(i=0; i<7; i++)
        roles << "loyalist";

    qShuffle(roles);
}

int ZombieScenario::getPlayerCount() const{
    return 8;
}

void ZombieScenario::getRoles(char *roles) const{
    strcpy(roles, "ZCCCCCCC");
}

AI::Relation ZombieScenario::relationTo(const ServerPlayer *a, const ServerPlayer *b) const{
    bool aZombie=true;
    bool bZombie = true;
    if(a->isLord() || a->getRoleEnum() == Player::Loyalist)
        aZombie = false;
    if(b->isLord() || b->getRoleEnum() == Player::Loyalist)
        bZombie = false;
    if(aZombie == bZombie)
        return AI::Friend;
    return AI::Enemy;
}

class Zaibian: public TriggerSkill{
public:
    Zaibian():TriggerSkill("zaibian"){
        events << PhaseChange ;
        frequency = Compulsory;
    }

    int getNumDiff(ServerPlayer *zombie) const{
        int human = 0, zombies = 0;
        foreach(ServerPlayer *player, zombie->getRoom()->getAlivePlayers()){
            switch(player->getRoleEnum()){
            case Player::Lord:
            case Player::Loyalist: human ++; break;
            case Player::Rebel: zombies ++; break;
                case Player::Renegade: zombies ++; break;
            default:
                break;
            }
        }

        int x = human - zombies + 1;
        if(x < 0)
            return 0;
        else
            return x;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *zombie, QVariant &) const{
        if(event == PhaseChange && zombie->getPhase() == Player::Play){
            int x = getNumDiff(zombie);
            if(x > 0){
                LogMessage log;
                log.type = "#ZaibianGood";
                log.from = zombie;
                log.arg = QString::number(x);
                log.arg2 = objectName();
                room->sendLog(log);
                zombie->drawCards(x);
                room->playSkillEffect(objectName());
            }
        }
        return false;
    }
};

class Xunmeng: public TriggerSkill{
public:
    Xunmeng():TriggerSkill("xunmeng"){
        events << Predamage;
        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent, Room* room, ServerPlayer *zombie, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();

        const Card *reason = damage.card;
        if(reason == NULL)
            return false;

        if(reason->isKindOf("Slash")){
            LogMessage log;
            log.type = "#Xunmeng";
            log.from = zombie;
            log.to << damage.to;
            log.arg = QString::number(damage.damage);
            log.arg2 = QString::number(++ damage.damage);
            room->sendLog(log);
            room->playSkillEffect(objectName());

            data = QVariant::fromValue(damage);
            if(zombie->getHp()>1)
                room->loseHp(zombie);
        }

        return false;
    }
};

class Paoxiao: public ClientSkill{
public:
    Paoxiao():ClientSkill("paoxiao"){
        frequency = NotFrequent;
    }

    virtual int getSlashResidue(const Player *zom) const{
        if(zom->hasSkill(objectName()))
            return 998;
        else
            return 0;
    }
};

YuanzhuCard::YuanzhuCard(){
    target_fixed = true;
}

void YuanzhuCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &) const{
    foreach(ServerPlayer *tmp, room->getOtherPlayers(source)){
        if(tmp->isWounded() && source->distanceTo(tmp) == 1){
            //RecoverStruct recover;
            //recover.card = this;
            //recover.who = source;
            //room->recover(tmp, recover);
            room->recover(tmp, RecoverStruct(source, this));
        }
    }
}

class Yuanzhu: public OneCardViewAsSkill{
public:
    Yuanzhu():OneCardViewAsSkill("yuanzhu"){
    }

    virtual bool isEnabledAtPlay(const Player *z) const{
        return !z->hasUsed("YuanzhuCard");
    }

    virtual bool viewFilter(const CardItem *to_select) const{
        const Card *card = to_select->getCard();
        return card->isKindOf("Peach") || card->isKindOf("Analeptic") || card->isKindOf("Shit");
    }

    virtual const Card *viewAs(CardItem *card_item) const{
        YuanzhuCard *card = new YuanzhuCard;
        card->addSubcard(card_item->getFilteredCard());
        return card;
    }
};

class Bihu: public TriggerSkill{
public:
    Bihu():TriggerSkill("bihu$"){
        events << PhaseEnd << PhaseChange;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        if(!player->isLord() || player->getGeneral2Name() == "zombie")
            return false;

        if(event == PhaseChange){
            if(player->getPhase() == Player::RoundStart){
                foreach(ServerPlayer *p, room->getAllPlayers()){
                    if(p->hasMark("@harb"))
                        p->loseAllMarks("@harb");
                }
            }
            return false;
        }
        if(player->getPhase() != Player::Finish || player->getMark("@round") >= 4)
            return false;
        QList<ServerPlayer *> humens;
        foreach(ServerPlayer *p, room->getAllPlayers()){
            if(p->getGeneral2Name() != "zombie")
                humens << p;
        }

        if(!humens.isEmpty() && player->askForSkillInvoke(objectName())){
            ServerPlayer *target = room->askForPlayerChosen(player, humens, objectName());
            LogMessage log;
            log.type = "#Bihu";
            log.from = player;
            log.to << target;
            room->sendLog(log);

            target->gainMark("@harb");
            room->playSkillEffect(objectName());
        }

        return false;
    }
};

GanranEquip::GanranEquip(Card::Suit suit, int number)
    :IronChain(suit, number)
{
}

class Ganran: public FilterSkill{
public:
    Ganran():FilterSkill("ganran"){
    }

    virtual bool viewFilter(const CardItem *to_select) const{
        return to_select->getCard()->getTypeId() == Card::Equip;
    }

    virtual const Card *viewAs(CardItem *card_item) const{
        const Card *card = card_item->getCard();
        GanranEquip *ironchain = new GanranEquip(card->getSuit(), card->getNumber());
        ironchain->addSubcard(card_item->getFilteredCard());
        ironchain->setSkillName(objectName());

        return ironchain;
    }
};

ZombieScenario::ZombieScenario()
    :Scenario("zombie_mode")
{
    rule = new ZombieRule(this);

    skills << new Yuanzhu << new Bihu;

    General *zombie = new General(this, "zombie", "die", 3, true, true, true);
    zombie->addSkill(new Xunmeng);
    zombie->addSkill(new Ganran);
    zombie->addSkill(new Zaibian);

    zombie->addSkill(new Paoxiao);
    zombie->addSkill(new Skill("wansha", Skill::Compulsory));

    addMetaObject<YuanzhuCard>();
    addMetaObject<GanranEquip>();
}

ADD_SCENARIO(Zombie)
