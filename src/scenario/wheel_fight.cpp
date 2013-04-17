#include "wheel_fight.h"

class WheelFightScenarioRule: public ScenarioRule{
public:
    WheelFightScenarioRule(Scenario *scenario)
        :ScenarioRule(scenario){
        events << GameStarted << HpLost << PreDeath << GameOverJudge;
    }

    static void Domo(Room *room, ServerPlayer *player){
        if(!player->faceUp())
            player->turnOver();
        room->setPlayerFlag(player, "-ecst");
        room->setPlayerFlag(player, "-init_wake");
        player->clearFlags();
        player->clearHistory();
        player->throwAllCards();
        player->throwAllMarks();
        player->clearPrivatePiles();
    }

    static void Oyasumi(Room *room, ServerPlayer *player){
        //player->loseAllSkills();
        QStringList ban = room->getTag("WheelBan").toStringList();
        foreach(ServerPlayer *tmp, room->getAllPlayers()){
            if(!ban.contains(tmp->getGeneralName()))
                ban << tmp->getGeneralName();
            if(!ban.contains(tmp->getGeneral2Name()))
                ban << tmp->getGeneral2Name();
        }
        room->setTag("WheelBan", ban);
        QStringList list = Sanguosha->getRandomGenerals(qMin(5, Config.value("MaxChoice", 3).toInt()), ban.toSet());
        QString next_general = room->askForGeneral(player, list);
        room->transfigure(player, next_general, true, true);
        room->setPlayerProperty(player, "kingdom", player->getGeneral()->getKingdom());

        Domo(room, player);
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        //const WheelFightScenario *scenario = qobject_cast<const WheelFightScenario *>(parent());
        switch(event){
        case GameStarted:{
            if(player->isLord()){
                player->setRole("rebel");
                room->broadcastProperty(player, "role");
            }
            break;
        }
        case HpLost:{
            DamageStruct damage;
            damage.to = player;
            damage.from = player->getNextAlive();
            damage.damage = data.toInt();
            room->damage(damage);
            return true;
        }
        case PreDeath:{
            DamageStar damage = data.value<DamageStar>();
            ServerPlayer *killer = damage ? damage->from : NULL;
            if(killer){
                killer->addMark("wheelon");
                if(killer->getMark("wheelon") >= 3){
                    int wheel = killer->getMark("@skull");
                    LogMessage log;
                    log.type = "#KillerB";
                    log.from = killer;
                    log.arg = killer->getGeneralName();
                    room->sendLog(log);

                    Oyasumi(room, killer);
                    room->setPlayerMark(killer, "@skull", wheel);
                }
                killer->drawCards(3, false);
                room->setPlayerStatistics(killer, "kill", 1);
            }

            player->loseAllMarks("wheelon");
            player->addMark("@skull");
            if(player->getMark("@skull") >= Config.value("Scenario/WheelCount", 10).toInt())
                return false;

            int wheel = player->getMark("@skull");

            LogMessage log;
            log.type = "#VictimB";
            log.from = player;
            log.arg = QString::number(wheel);
            room->sendLog(log);
            int maxwheel = Config.value("Scenario/WheelCount", 10).toInt();
            if((float)wheel / (float)maxwheel > 0.7){
                log.type = "#VictimC";
                log.from = player;
                log.arg = QString::number(maxwheel);
                log.arg2 = QString::number(maxwheel - wheel);
                room->sendLog(log);
            }

            data = QVariant();
            Oyasumi(room, player);

            room->setPlayerMark(player, "@skull", wheel);
            player->drawCards(4, false);
            return true;
        }
        case GameOverJudge:{
            room->gameOver(room->getOtherPlayers(player).first()->objectName());
            //room->gameOver(".");
            return true;
        }
        default:
            break;
        }
        return false;
    }
};

void WheelFightScenario::assign(QStringList &generals, QStringList &roles) const{
    Q_UNUSED(generals);
    roles << "lord" << "renegade";
    qShuffle(roles);
}

int WheelFightScenario::getPlayerCount() const{
    return 2;
}

void WheelFightScenario::getRoles(char *roles) const{
    strcpy(roles, "ZN");
}

int WheelFightScenario::lordGeneralCount() const{
    return Config.value("MaxChoice", 5).toInt();
}

int WheelFightScenario::swapCount() const{
    return 998;
}

WheelFightScenario::WheelFightScenario()
    :Scenario("wheel_fight"){
    rule = new WheelFightScenarioRule(this);
}

#include "maneuvering.h"
class FuckGuanyuScenarioRule: public ScenarioRule{
public:
    FuckGuanyuScenarioRule(Scenario *scenario)
        :ScenarioRule(scenario){
        events << GameStart << GameOverJudge << Death;
    }

    virtual int getPriority(TriggerEvent) const{
        return 1;
    }

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const{
        switch(event){
        case GameStart:{
            if(!player->isLord()){
                QStringList all_generals = Sanguosha->getLimitedGeneralNames();
                qShuffle(all_generals);
                QStringList choices = all_generals.mid(0, Config.value("MaxChoice", 5).toInt());
                QString name = room->askForGeneral(player, choices, choices.first());
                room->transfigure(player, name);
                room->setPlayerProperty(player, "kingdom", player->getGeneral()->getKingdom());
            }
            break;
        }
        case GameOverJudge:{
            foreach(ServerPlayer *channer, room->getAllPlayers(true))
                if(channer->getState() != "robot")
                    player = channer;
            if(player->askForSkillInvoke("retry")){
                room->setTag("Retry", true);
                return true;
            }
            break;
        }
        case Death:{
            if(!room->getTag("Retry").toBool())
                return false;
            ServerPlayer *guanyu = room->getLord();
            ServerPlayer *challanger = guanyu;
            foreach(ServerPlayer *channer, room->getAllPlayers(true)){
                if(!channer->isLord())
                    challanger = channer;
            }

            room->setPlayerProperty(guanyu, "maxhp", 4);
            room->setPlayerProperty(guanyu, "hp", 4);
            guanyu->throwAllCards();
            guanyu->drawCards(4);
            challanger->throwAllCards();
            QStringList all_generals = Sanguosha->getLimitedGeneralNames();
            qShuffle(all_generals);
            QStringList choices = all_generals.mid(0, Config.value("MaxChoice", 5).toInt());
            QString name = room->askForGeneral(challanger, choices, choices.first());
            room->transfigure(challanger, name);
            room->setPlayerProperty(challanger, "kingdom", challanger->getGeneral()->getKingdom());
            challanger->drawCards(4);
            room->revivePlayer(player);
            if(room->getCurrent() != guanyu)
                challanger->setFlags("ShutUp");
            else{
                guanyu->drawCards(2);
                guanyu->clearFlags();
                guanyu->clearHistory();
                guanyu->invoke("clearHistory");
            }
            return true;
        }
        default:
            break;
        }
        return false;
    }
};

void FuckGuanyuScenario::assign(QStringList &generals, QStringList &roles) const{
    roles << "lord" << "renegade";
    qShuffle(roles);
    if(roles[0] == "lord")
        generals << "nicholas" << "anjiang";
    else
        generals << "anjiang" << "nicholas";
}

int FuckGuanyuScenario::getPlayerCount() const{
    return 2;
}

void FuckGuanyuScenario::getRoles(char *roles) const{
    strcpy(roles, "ZN");
}

bool FuckGuanyuScenario::generalSelection(Room *) const{
    return false;
}

bool FuckGuanyuScenario::setCardPiles(const Card *card) const{
    return card->getPackage() != objectName();
}

int FuckGuanyuScenario::swapCount() const{
    return 998;
}

FuckGuanyuScenario::FuckGuanyuScenario()
    :Scenario("fuck_guanyu"){
    rule = new FuckGuanyuScenarioRule(this);

    for(int i = 0; i < 26; i ++){
        Card *card = new FireAttack(Card::Diamond, i % 13 + 1);
        card->setParent(this);
    }
}

ADD_SCENARIO(WheelFight)
ADD_SCENARIO(FuckGuanyu)
