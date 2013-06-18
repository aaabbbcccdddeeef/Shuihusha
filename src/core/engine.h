#ifndef ENGINE_H
#define ENGINE_H

#include "card.h"
#include "general.h"
#include "skill.h"
#include "package.h"
#include "exppattern.h"
#include "protocol.h"
#include "util.h"

#include <QHash>
#include <QStringList>
#include <QMetaObject>

class AI;
class Scenario;

struct lua_State;

class Engine: public QObject
{
    Q_OBJECT

public:
    explicit Engine();
    ~Engine();

    void addTranslationEntry(const char *key, const char *value);
    QString translate(const QString &to_translate, bool return_null = false) const;
    lua_State *getLuaState() const;

    void addPackage(Package *package);
    void addBanPackage(const QString &package_name);
    QStringList getBanPackages() const;
    Card *cloneCard(const QString &name, Card::Suit suit, int number) const;
    Card *cloneCard(const QString &name, const QString &suit_string, int number) const;
    SkillCard *cloneSkillCard(const QString &name) const;
    QString getVersionNumber() const;
    QString getVersion() const;
    QString getVersionName() const;
    QString getMODName() const;
    QStringList getExtensions(bool getall = false) const;
    QStringList getLuaExtensions() const;
    QStringList getKingdoms() const;
    QColor getKingdomColor(const QString &kingdom) const;
    QString getSetupString() const;

    QMap<QString, QString> getAvailableModes() const;
    QString getModeName(const QString &mode) const;
    int getPlayerCount(const QString &mode) const;
    void getRoles(const QString &mode, char *roles) const;
    QStringList getRoleList(const QString &mode) const;
    int getRoleIndex() const;

    const CardPattern *getPattern(const QString &name) const;
    QList<const Skill *> getRelatedSkills(const QString &skill_name) const;

    QStringList getScenarioNames() const;
    void addScenario(Scenario *scenario);
    const Scenario *getScenario(const QString &name) const;
    bool getScenarioLordSkill(const QString &mode) const;

    void addPackage(const QString &name);
    void addScenario(const QString &name);

    const Card *getCard(const QString &name) const;
    const General *getGeneral(const QString &name) const;
    int getGeneralCount(bool include_banned = false) const;
    QList<const Skill *> getSkills(const QString &package_name) const;
    const Skill *getSkill(const QString &skill_name) const;
    QStringList getSkillNames() const;
    const TriggerSkill *getTriggerSkill(const QString &skill_name) const;
    const ViewAsSkill *getViewAsSkill(const QString &skill_name) const;
    QList<const ClientSkill *> getClientSkills() const;
    QList<const TargetModSkill *> getTargetModSkills() const;
    void addSkills(const QList<const Skill *> &skills);

    bool isDuplicated(const QString &name, bool is_skill = true);
    bool isExist(const QString &str);

    int getCardCount() const;
    const Card *getCard(int index) const;
    QList<Card*> getCards() const;

    QStringList getLords(bool contain_banned = false) const;
    QStringList getRandomLords() const;
    QStringList getRandomGenerals(int count, const QSet<QString> &ban_set = QSet<QString>()) const;
    QList<int> getRandomCards() const;
    QString getRandomGeneralName() const;
    QStringList getLimitedGeneralNames(bool getall = false) const;
    QString getPackageInformation(const Package *package) const;

    void playAudio(const QString &name) const;
    void playEffect(const QString &filename) const;
    void playSkillEffect(const QString &skill_name, int index) const;
    void playCardEffect(const QString &card_name, bool is_male) const;

    const ClientSkill *isProhibited(const Player *from, const Player *to, const Card *card) const;
    const ClientSkill *isPenetrate(const Player *from, const Player *to, const Card *card) const;
    int correctClient(const ClientSkill::ClientType type, const Player *from, const Player *to = NULL, const Card *slash = NULL) const;
    int correctCardTarget(const TargetModSkill::ModType type, const Player *from, const Card *card) const;

    bool useNew3v3();
    bool is3v3Friend(const ServerPlayer *a, const ServerPlayer *b);

    QStringList getConjurs() const;
    int getConjurDelay(const QString &conjur) const;
    int getConjurPAdditional(const QString &conjur) const;
    int getConjurPEffective(const QString &conjur) const;

private:
    QHash<QString, QString> translations;
    QHash<QString, const General *> generals, hidden_generals;
    QHash<QString, const QMetaObject *> metaobjects;
    QHash<QString, const Skill *> skills;
    QMap<QString, QString> modes;
    QMap<QString, QString> conjurs;
    QMap<QString, const CardPattern *> patterns;
    QMultiMap<QString, QString> related_skills;

    // special skills
    QList<const ClientSkill *> client_skills;
    QList<const TargetModSkill *> targetmod_skills;

    QHash<QString, const Scenario *> scenarios;

    QList<Card*> cards;
    QStringList lord_list, nonlord_list;
    QSet<QString> ban_package;

    lua_State *lua;
};

extern Engine *Sanguosha;

static inline QVariant GetConfigFromLuaState(lua_State *L, const char *key, const char *parent = "config"){
    return GetValueFromLuaState(L, parent, key);
}

#endif // ENGINE_H
