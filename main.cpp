// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QJsonObject>
#include <QHttpServer>
#include <QTcpServer>
#include <QDebug>

#include "appconfig.h"

std::map<QString, QString> s_osmToThunderforestMapNames = { {"street", "atlas"}, {"satellite", ""}, { "cycle", "cycle" }, {"transit", "transport"}, {"night-transit", "transport-dark"}, {"terrain", "outdoors"}, {"hiking", "outdoors"} };

QJsonObject createOsmJson(const QString &apiKey, const QString &mapType) {
    QJsonObject json;
    json["UrlTemplate"] = QString("https://tile.thunderforest.com/%2/%z/%x/%y.png?apikey=%1").arg(apiKey, mapType);
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
        qDebug() << "Request for /";
        return "";
    });
    httpServer.setMissingHandler(&httpServer, [](const QHttpServerRequest &request, QHttpServerResponder &responder) {
        qDebug() << "Missing" << request.url();
        responder.write(QHttpServerResponder::StatusCode::NotFound);
    });


    AppConfig *appConfig = AppConfig::instance();
    for (auto &mapType : s_osmToThunderforestMapNames)
    {
        httpServer.route(QString("/%1").arg(mapType.first), [mapType, appConfig]() {
            qDebug().nospace().noquote() << "Request for /" << mapType.first;
            return createOsmJson(appConfig->thunderforestApiKey(), mapType.second);
        });
    }
    auto tcpServer = new QTcpServer();
    if(!tcpServer->listen(QHostAddress::Any, 0) || !httpServer.bind(tcpServer)) {
        delete tcpServer;
        return -1;
    }
    quint16 listenPort = tcpServer->serverPort();
    appConfig->setOsmMappingProvidersRepositoryAddress(QString("http://localhost:%1/").arg(listenPort));

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

