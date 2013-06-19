#ifndef ZOMBIE_MODE_H
#define ZOMBIE_MODE_H

#include "scenario.h"
#include "common-skillcards.h"
#include "maneuvering.h"

class ZombieScenario : public Scenario{
    Q_OBJECT

public:
    explicit ZombieScenario();

    virtual bool exposeRoles() const;
    virtual void assign(QStringList &generals, QStringList &roles) const;
    virtual int getPlayerCount() const;
    virtual void getRoles(char *roles) const;
    virtual AI::Relation relationTo(const ServerPlayer *a, const ServerPlayer *b) const;

private:
    QStringList females;
};

class GanranEquip: public IronChain{
    Q_OBJECT

public:
    Q_INVOKABLE GanranEquip(Card::Suit suit, int number);
};

class YuanzhuCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE YuanzhuCard();
    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

#endif // ZOMBIE_MODE_H
