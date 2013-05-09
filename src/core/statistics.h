#ifndef STATISTICS_H
#define STATISTICS_H
#include <QVariant>
#include <QStringList>

struct StatisticsStruct{
    StatisticsStruct();
    bool setStatistics(const QString &name, const QVariant &value);

    int kill, damage, save, recover, revive, cheat;
    QStringList designation;
};

#endif // STATISTICS_H
