#ifndef SCENARIOOVERVIEW_H
#define SCENARIOOVERVIEW_H

#include <QDialog>

class QListWidget;
class QTextBrowser;

class ScenarioOverview: public QDialog{
    Q_OBJECT

public:
    ScenarioOverview(QWidget *parent);

private:
    QListWidget *list, *list2;
    QTextBrowser *content_box;

private slots:
    void loadContent(int row);
    void loadContent2(int row);
};

#endif // SCENARIOOVERVIEW_H
