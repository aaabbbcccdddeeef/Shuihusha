#ifndef MUSTANGPACKAGE_H
#define MUSTANGPACKAGE_H

#include "package.h"

class MustangPackage : public GeneralPackage{
    Q_OBJECT

public:
    MustangPackage();
};

class JizhanCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE JizhanCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class BingjiCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE BingjiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class MaiyiCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE MaiyiCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

class HunjiuCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE HunjiuCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class ZishiCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE ZishiCard();

    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

class NaxianCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE NaxianCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

class QiangzhanCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE QiangzhanCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const;
};

#include <QGroupBox>
#include <QAbstractButton>
#include <QButtonGroup>
#include <QDialog>

class JingsuanCard: public SkillCard{
    Q_OBJECT

public:
    Q_INVOKABLE JingsuanCard();

    virtual bool targetFixed() const;
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;

    virtual const Card *validate(const CardUseStruct *card_use) const;
    virtual const Card *validateInResposing(ServerPlayer *player, bool *continuable) const;
};

class JingsuanDialog: public QDialog{
    Q_OBJECT

public:
    static JingsuanDialog *GetInstance();

public slots:
    void popup();
    void selectCard(QAbstractButton *button);

private:
    JingsuanDialog();

    QAbstractButton *createButton(const Card *card);
    QButtonGroup *group;
    QHash<QString, const Card *> map;
};

#endif // MUSTANGPACKAGE_H
