#ifndef SKILL_H
#define SKILL_H

class Player;
class CardItem;
class Card;
class ServerPlayer;
class QDialog;

#include "room.h"

#include <QObject>

class Skill : public QObject
{
    Q_OBJECT
    Q_ENUMS(Frequency)
    Q_ENUMS(Location)

public:
    enum Frequency{
        Frequent,
        NotFrequent,
        Compulsory,
        Limited,
        Wake,
        NotSkill
    };

    enum Location{
        Left,
        Right
    };

    explicit Skill(const QString &name, Frequency frequent = NotFrequent);
    bool isLordSkill() const;
    QString getDescription() const;
    QString getText() const;
    bool isVisible() const;

    virtual QString getDefaultChoice(ServerPlayer *player) const;
    virtual int getEffectIndex(const ServerPlayer *player, const Card *card) const;
    virtual QDialog *getDialog() const;

    virtual Location getLocation() const;

    void initMediaSource();
    void playEffect(int index = -1) const;
    void setFlag(ServerPlayer *player) const;
    void unsetFlag(ServerPlayer *player) const;
    Frequency getFrequency() const;
    QStringList getSources() const;

protected:
    Frequency frequency;
    QString default_choice;

private:
    bool lord_skill;
    QStringList sources;
};

class ViewAsSkill:public Skill{
    Q_OBJECT

public:
    ViewAsSkill(const QString &name);

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const = 0;
    virtual const Card *viewAs(const QList<CardItem *> &cards) const = 0;

    bool isAvailable() const;
    virtual bool isEnabledAtPlay(const Player *player) const;
    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const;
};

class ZeroCardViewAsSkill: public ViewAsSkill{
    Q_OBJECT

public:
    ZeroCardViewAsSkill(const QString &name);

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const;
    virtual const Card *viewAs(const QList<CardItem *> &cards) const;

    virtual const Card *viewAs() const = 0;
};

class OneCardViewAsSkill: public ViewAsSkill{
    Q_OBJECT

public:
    OneCardViewAsSkill(const QString &name);

    virtual bool viewFilter(const QList<CardItem *> &selected, const CardItem *to_select) const;
    virtual const Card *viewAs(const QList<CardItem *> &cards) const;

    virtual bool viewFilter(const CardItem *to_select) const = 0;
    virtual const Card *viewAs(CardItem *card_item) const = 0;
};

class FilterSkill: public OneCardViewAsSkill{
    Q_OBJECT

public:
    FilterSkill(const QString &name);
};

class TriggerSkill:public Skill{
    Q_OBJECT

public:
    TriggerSkill(const QString &name);
    const ViewAsSkill *getViewAsSkill() const;
    QList<TriggerEvent> getTriggerEvents() const;

    virtual int getPriority() const;
    virtual bool triggerable(const ServerPlayer *target) const;
    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const = 0;

protected:
    const ViewAsSkill *view_as_skill;
    QList<TriggerEvent> events;
};

class Scenario;

class ScenarioRule: public TriggerSkill{
    Q_OBJECT

public:
    ScenarioRule(Scenario *scenario);

    virtual int getPriority() const;
    virtual bool triggerable(const ServerPlayer *target) const;
};

class MasochismSkill: public TriggerSkill{
    Q_OBJECT

public:
    MasochismSkill(const QString &name);

    virtual int getPriority() const;
    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const;
    virtual void onDamaged(ServerPlayer *target, const DamageStruct &damage) const = 0;
};

class PhaseChangeSkill: public TriggerSkill{
    Q_OBJECT

public:
    PhaseChangeSkill(const QString &name);

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const;
    virtual bool onPhaseChange(ServerPlayer *target) const =0;
};

class DrawCardsSkill: public TriggerSkill{
    Q_OBJECT

public:
    DrawCardsSkill(const QString &name);

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const;
    virtual int getDrawNum(ServerPlayer *player, int n) const = 0;
    virtual void drawDone(ServerPlayer *player, int n) const;
};

class SlashBuffSkill: public TriggerSkill{
    Q_OBJECT

public:
    SlashBuffSkill(const QString &name);

    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const;
    virtual bool buff(const SlashEffectStruct &effect) const = 0;
};

class GameStartSkill: public TriggerSkill{
    Q_OBJECT

public:
    GameStartSkill(const QString &name);

    virtual bool triggerable(const ServerPlayer *target) const;
    virtual bool trigger(TriggerEvent event, Room* room, ServerPlayer *player, QVariant &data) const;
    virtual void onGameStart(ServerPlayer *player) const = 0;
    virtual void onIdied(ServerPlayer *player) const;
};

class ClientSkill: public Skill{
    Q_OBJECT
    Q_ENUMS(Category)

public:
    enum Category{
        Distance,
        AttackRange,
        Prohibit,
        MaxCards,
        Mixed
    };

    ClientSkill(const QString &name, Category cate = Mixed);

    virtual Category getCategory() const;
    virtual int getExtra(const Player *target) const;
    virtual int getCorrect(const Player *from, const Player *to) const;
    virtual int getAtkrg(const Player *target) const;
    virtual bool isProhibited(const Player *from, const Player *to, const Card *card) const;

protected:
    Category cate;
};

class WeaponSkill: public TriggerSkill{
    Q_OBJECT

public:
    WeaponSkill(const QString &name);

    virtual bool triggerable(const ServerPlayer *target) const;
};

class ArmorSkill: public TriggerSkill{
    Q_OBJECT

public:
    ArmorSkill(const QString &name);

    virtual bool triggerable(const ServerPlayer *target) const;
};

class MarkAssignSkill: public GameStartSkill{
    Q_OBJECT

public:
    MarkAssignSkill(const QString &mark, int n);

    virtual int getPriority() const;
    virtual void onGameStart(ServerPlayer *player) const;

private:
    QString mark_name;
    int n;
};

class CutHpSkill: public GameStartSkill{
    Q_OBJECT

public:
    CutHpSkill(int n);

    virtual int getPriority() const;
    virtual void onGameStart(ServerPlayer *player) const;

private:
    int n;
};

#endif // SKILL_H
