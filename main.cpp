// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QJsonObject>
#include <QHttpServer>
#include <QTcpServer>
#include <QDebug>

#include "appconfig.h"

QJsonObject createOsmJson(QString apiKey, QString mapType) {
    QJsonObject json;
    json["UrlTemplate"] = QString("https://a.tile.thunderforest.com/%2/%z/%x/%y.png?apikey=%1").arg(apiKey).arg(mapType);
    qDebug() << "UrlTemplate" << json["UrlTemplate"];
    json["ImageFormat"] = "png";
    json["QImageFormat"] = "Indexed8";
    json["ID"] = QString("thf-%1").arg(mapType);
    json["MaximumZoomLevel"] = 20;
    json["MapCopyRight"] = "<a href='https://www.thunderforest.com/'>Thunderforest</a>";
    json["DataCopyRight"] = "<a href='https://www.openstreetmap.org/copyright'>OpenStreetMap</a> contributors";
    return json;
}

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;


#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    const QUrl url(QStringLiteral(
        "qrc:/qml/main5.qml"
        ));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);
#else

    QHttpServer httpServer;
    httpServer.route("/", []() {
        return "Hello World!";
    });

    for (auto mapType : { "cycle", "transport", "landscape", "outdoors", "transport-dark", "spinal-map", "pioneer", "mobile-atlas", "neighbourhood", "atlas" })
    {
        httpServer.route(QString("/%1").arg(mapType), [mapType]() {
            qDebug().nospace().noquote() << "Request for /" << mapType;
            return createOsmJson(AppConfig::instance()->thunderforestApiKey(), mapType);
        });
    }
    auto tcpServer = new QTcpServer();
    if(!tcpServer->listen(QHostAddress::Any, 8080) || !httpServer.bind(tcpServer)) {
        delete tcpServer;
        return -1;
    }

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("minimal_map", "Main6");
#endif

    return app.exec();
}

