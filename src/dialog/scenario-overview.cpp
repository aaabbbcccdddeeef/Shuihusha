#include "scenario-overview.h"
#include "engine.h"
#include "scenario.h"

#include <QListWidget>
#include <QTextBrowser>
#include <QHBoxLayout>
#include <QFile>
#include <QTextStream>

ScenarioOverview::ScenarioOverview(QWidget *parent)
    :QDialog(parent)
{
    setWindowTitle(tr("Scenario overview"));
    resize(800, 600);

    list = new QListWidget;
    list->setMaximumWidth(100);
    list2 = new QListWidget;
    list2->setMaximumWidth(100);

    content_box = new QTextBrowser;
    content_box->setReadOnly(true);
    //content_box->setProperty("type", "description");

    QHBoxLayout *layout = new QHBoxLayout;
    QVBoxLayout *layout2 = new QVBoxLayout;
    layout2->addWidget(list);
    layout2->addWidget(list2);

    layout->addLayout(layout2);
    layout->addWidget(content_box);

    setLayout(layout);

    QStringList modes = Sanguosha->getScenarioNames();
    foreach(QString name, modes){
        QString text = Sanguosha->translate(name);
        QListWidgetItem *item = new QListWidgetItem(text, list);
        item->setData(Qt::UserRole, name);
    }
    connect(list, SIGNAL(currentRowChanged(int)), this, SLOT(loadContent(int)));

    QStringList rules;
    rules << "casket" << "conjur_sys" << "other_rules" << "MiniScene";
    foreach(QString name, rules){
        QString text = Sanguosha->translate(name);
        QListWidgetItem *item = new QListWidgetItem(text, list2);
        item->setData(Qt::UserRole, name);
    }
    connect(list2, SIGNAL(currentRowChanged(int)), this, SLOT(loadContent2(int)));

    if(!modes.isEmpty())
        loadContent(0);
}

void ScenarioOverview::loadContent(int row){
    QString name = list->item(row)->data(Qt::UserRole).toString();
    QString filename = QString("scenarios/%1.html").arg(name);
    QFile file(filename);
    if(file.open(QIODevice::ReadOnly)){
        QTextStream stream(&file);
        stream.setCodec("UTF-8");
        QString content = stream.readAll();

        content_box->setHtml(content);
    }
}

void ScenarioOverview::loadContent2(int row){
    QString name = list2->item(row)->data(Qt::UserRole).toString();
    QString filename = QString("scenarios/%1.html").arg(name);
    QFile file(filename);
    if(file.open(QIODevice::ReadOnly)){
        QTextStream stream(&file);
        stream.setCodec("UTF-8");
        QString content = stream.readAll();

        content_box->setHtml(content);
    }
}
