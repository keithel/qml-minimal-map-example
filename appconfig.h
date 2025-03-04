#pragma once

#include <QObject>
#include <QQmlEngine>

class AppConfig : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

    Q_PROPERTY(QString thunderforestApiKey READ thunderforestApiKey WRITE setThunderforestApiKey NOTIFY thunderforestApiKeyChanged)

public:
    explicit AppConfig(QObject *parent);
    ~AppConfig() = default;

    static AppConfig *instance();
    static AppConfig *create(QQmlEngine *, QJSEngine *engine);

    QString thunderforestApiKey() const;
    void setThunderforestApiKey(const QString &key);

signals:
    void thunderforestApiKeyChanged();

private:
    QString m_thunderforestApiKey;

    inline static AppConfig * s_singletonInstance = nullptr;
    inline static QJSEngine *s_engine = nullptr;
};
