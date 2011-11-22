#ifndef PLOUGHPACKAGE_H
#define PLOUGHPACKAGE_H

#include "package.h"
#include "standard.h"

class Drivolt:public SingleTargetTrick{
    Q_OBJECT

public:
    Q_INVOKABLE Drivolt(Card::Suit suit, int number);

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class Wiretap: public SingleTargetTrick{
    Q_OBJECT

public:
    Q_INVOKABLE Wiretap(Card::Suit suit, int number);

    virtual bool targetFilter(const QList<const ClientPlayer *> &targets, const ClientPlayer *to_select) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class Assassinate: public SingleTargetTrick{
    Q_OBJECT

public:
    Q_INVOKABLE Assassinate(Card::Suit suit, int number);

    virtual bool targetFilter(const QList<const ClientPlayer *> &targets, const ClientPlayer *to_select) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};
/*
class JuejiCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE JuejiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class YitianSword:public Weapon{
    Q_OBJECT

public:
    Q_INVOKABLE YitianSword(Card::Suit suit = Spade, int number = 6);

    virtual void onMove(const CardMoveStruct &move) const;
};

class LianliCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE LianliCard();

    virtual void onEffect(const CardEffectStruct &effect) const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class LianliSlashCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE LianliSlashCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class QiaocaiCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE QiaocaiCard();

    virtual void onEffect(const CardEffectStruct &effect) const;
};

class GuihanCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE GuihanCard();

    virtual void onEffect(const CardEffectStruct &effect) const;
};

class LexueCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE LexueCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class XunzhiCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE XunzhiCard();

    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

class YisheCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE YisheCard();

    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

class YisheAskCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE YisheAskCard();

    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

class TaichenCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE TaichenCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};
*/
class PloughPackage: public Package{
    Q_OBJECT

public:
    PloughPackage();
};

#endif // PLOUGHPACKAGE_H
