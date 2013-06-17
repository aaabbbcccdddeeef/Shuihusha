#ifndef PURGATORYPACKAGE_H
#define PURGATORYPACKAGE_H

#include "package.h"
#include "standard.h"
#include "client.h"

class PurgatoryPackage : public CardPackage{
    Q_OBJECT

public:
    PurgatoryPackage();
};

class ChaosJink: public Jink{
    Q_OBJECT

public:
    Q_INVOKABLE ChaosJink(Card::Suit suit, int number);
    virtual QString getEffectPath(bool is_male) const;
};

class ChaosSlash: public Slash{
    Q_OBJECT

public:
    Q_INVOKABLE ChaosSlash(Card::Suit suit, int number);
    virtual QString getEffectPath(bool is_male) const;
};

class Shit:public BasicCard{
    Q_OBJECT

public:
    Q_INVOKABLE Shit(Card::Suit suit, int number);
    virtual QString getSubtype() const;
    virtual void onMove(const CardMoveStruct &move) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    static bool HasShit(const Card *card);
};

class Mastermind: public SingleTargetTrick{
    Q_OBJECT

public:
    Q_INVOKABLE Mastermind(Card::Suit suit, int number);

    virtual QString getEffectPath(bool is_male) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class SpinDestiny: public GlobalEffect{
    Q_OBJECT

public:
    Q_INVOKABLE SpinDestiny(Card::Suit suit, int number);

    virtual QString getEffectPath(bool is_male) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class EdoTensei:public SingleTargetTrick{
    Q_OBJECT

public:
    Q_INVOKABLE EdoTensei(Card::Suit suit, int number);

    virtual QString getEffectPath(bool is_male) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
    virtual bool isAvailable(const Player *player) const;
};

class ProudBanner: public Armor{
    Q_OBJECT

public:
    Q_INVOKABLE ProudBanner(Card::Suit suit, int number);
};

class LashGun:public Weapon{
    Q_OBJECT

public:
    Q_INVOKABLE LashGun(Card::Suit suit, int number);
};

#endif // PURGATORYPACKAGE_H
