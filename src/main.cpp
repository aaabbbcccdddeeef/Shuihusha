#include <QtGui/QApplication>

#include <QCoreApplication>
#include <QTranslator>
#include <QDir>
#include <cstring>
#include <QDateTime>

#include "mainwindow.h"
#include "settings.h"
#include "banpair.h"
#include "server.h"
#include "audio.h"
#include "crypto.h"

int main(int argc, char *argv[])
{    
    if(argc > 1 && strcmp(argv[1], "-server") == 0)
        new QCoreApplication(argc, argv);
    else
        new QApplication(argc, argv);

#ifdef Q_OS_MAC
#ifdef QT_NO_DEBUG

    QDir::setCurrent(qApp->applicationDirPath());

#endif
#endif

    // initialize random seed for later use
    qsrand(QTime(0,0,0).secsTo(QTime::currentTime()));

    QTranslator qt_translator, translator;
    qt_translator.load("qt_zh_CN.qm");
    translator.load("shuihusha.qm");
    if(Config.value("Language", "zh_cn").toString() == "zh_cn"){
        qApp->installTranslator(&qt_translator);
        qApp->installTranslator(&translator);
    }

    Sanguosha = new Engine;
    Config.init();
    BanPair::loadBanPairs();

    if(qApp->arguments().contains("-server")){
        Server *server = new Server(qApp);
        printf("Server is starting on port %u\n", Config.ServerPort);

        if(server->listen())
            printf("Starting successfully\n");
        else
            printf("Starting failed!\n");

        return qApp->exec();
    }

    QFile file("shuihusha.qss");
    if(file.open(QIODevice::ReadOnly)){
        QTextStream stream(&file);
        qApp->setStyleSheet(stream.readAll());
    }

    //Crypto::doCrypto(Crypto::Jiami, "audio/skill/ganlin1.ogg", "default");

#ifdef AUDIO_SUPPORT

    Audio::init();

#endif

    MainWindow *main_window = new MainWindow;

    Sanguosha->setParent(main_window);
    main_window->show();

    foreach(QString arg, qApp->arguments()){
        if(arg.startsWith("-connect:")){
            arg.remove("-connect:");
            Config.HostAddress = arg;
            Config.setValue("HostAddress", arg);

            main_window->startConnection();

            break;
        }
    }

    return qApp->exec();
}
