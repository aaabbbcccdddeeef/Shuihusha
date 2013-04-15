#include "pixmapanimation.h"
#include "settings.h"
#include <QPainter>
#include <QPixmapCache>
#include <QDir>

#ifdef USE_RCC
#include <QResource>
#endif

PixmapAnimation::PixmapAnimation(QGraphicsScene *scene) :
    QGraphicsItem(0,scene)
{
}

void PixmapAnimation::advance(int phase){
    if(phase)current++;
    if(current>=frames.size()){
        current = 0;
        emit finished();
    }
    update();
}

void PixmapAnimation::setPath(const QString &path){
    frames.clear();

    int i = 0;
    QString pic_path = QString("%1%2%3").arg(path).arg(i++).arg(".png");
    do{
        frames << GetFrameFromCache(pic_path);
        pic_path = QString("%1%2%3").arg(path).arg(i++).arg(".png");
    }while(!GetFrameFromCache(pic_path).isNull());

    current = 0;
}

void PixmapAnimation::paint(QPainter *painter, const QStyleOptionGraphicsItem *, QWidget *){
    painter->drawPixmap(0,0,frames.at(current));
}

QRectF PixmapAnimation::boundingRect() const{
    return frames.at(current).rect();
}

bool PixmapAnimation::valid(){
    return !frames.isEmpty();
}

void PixmapAnimation::timerEvent(QTimerEvent *){
    advance(1);
}

void PixmapAnimation::start(bool permanent,int interval){
    startTimer(interval);
    if(!permanent)connect(this,SIGNAL(finished()),this,SLOT(deleteLater()));
}

PixmapAnimation* PixmapAnimation::GetPixmapAnimation(QGraphicsObject *parent, const QString &emotion){
    PixmapAnimation *pma = new PixmapAnimation();
    if(emotion.contains("skill"))
        pma->setPath(QString("image/system/emotion/%1/").arg(emotion));
    else{
#ifdef USE_RCC
        QResource::registerResource(QString("image/system/emotion/%1.rcc").arg(emotion));
        pma->setPath(QString(":/%1/").arg(emotion));
#else
        pma->setPath(QString("image/system/emotion-real/%1/").arg(emotion));
#endif
    }
    bool returnpma = false;
    if(pma->valid()){
        pma->setZValue(8.0);
        pma->moveBy((parent->boundingRect().width() - pma->boundingRect().width())/2,
                (parent->boundingRect().height() - pma->boundingRect().height())/2);

        pma->setParentItem(parent);

        qreal data1 = 0, data2 = 0;
        if(emotion.contains("skill")){
            QString spec_name = QString("image/system/emotion/%1/revise.ini").arg(emotion);
            QSettings emo_sets(spec_name, QSettings::IniFormat);

            if(emo_sets.contains("x") && emo_sets.contains("y")){
                data1 = emo_sets.value("x", 0).toReal();
                data2 = emo_sets.value("y", 0).toReal();
                pma->moveBy(data1, data2);
            }
            if(emo_sets.contains("z")){
                data1 = emo_sets.value("z", 1).toReal();
                pma->setZValue(data1);
            }
            if(emo_sets.contains("s")){
                data1 = emo_sets.value("s", 1).toReal();
                pma->setScale(data1);
            }
            if(emo_sets.contains("o")){
                data1 = emo_sets.value("o", 1).toReal();
                pma->setOpacity(data1);
            }
            emo_sets.deleteLater();
        }
        else{
            QString spec_name = "image/system/emotion/revise.ini";
            QSettings emo_sets(spec_name, QSettings::IniFormat);

            emo_sets.beginGroup(emotion);
            if(emo_sets.contains("x") && emo_sets.contains("y")){
                data1 = emo_sets.value("x", 0).toReal();
                data2 = emo_sets.value("y", 0).toReal();
                pma->moveBy(data1, data2);
            }
            if(emo_sets.contains("z")){
                data1 = emo_sets.value("z", 1).toReal();
                pma->setZValue(data1);
            }
            if(emo_sets.contains("s")){
                data1 = emo_sets.value("s", 1).toReal();
                pma->setScale(data1);
            }
            if(emo_sets.contains("o")){
                data1 = emo_sets.value("o", 1).toReal();
                pma->setOpacity(data1);
            }
            emo_sets.endGroup();

            emo_sets.deleteLater();
        }

        pma->startTimer(70);
        connect(pma,SIGNAL(finished()),pma,SLOT(deleteLater()));
        returnpma = true;
    }
#ifdef USE_RCC
    QResource::unregisterResource(QString("image/system/emotion/%1.rcc").arg(emotion));
#endif
    if(returnpma)
        return pma;
    else{
        delete pma;
        return NULL;
    }
}

QPixmap PixmapAnimation::GetFrameFromCache(const QString &filename){
    QPixmap pixmap;
    if(!QPixmapCache::find(filename, &pixmap)){
        pixmap.load(filename);
        if(!pixmap.isNull())
            QPixmapCache::insert(filename, pixmap);
    }

    return pixmap;
}

int PixmapAnimation::GetFrameCount(const QString &emotion){
    QString path = QString("image/system/emotion/%1/").arg(emotion);
    QDir dir(path);
    return dir.entryList(QDir::Files | QDir::NoDotAndDotDot).count();
}
