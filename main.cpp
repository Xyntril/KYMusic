#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>

#if !defined(Q_OS_ANDROID)
#include <KAboutData>
#include <KIconTheme>
#include "src/Core/KdeTrayController.h"
#include "src/Core/KdeMenuManager.h"
#endif

#include "src/Core/AppController.h"
#include "src/Core/AuthController.h"

#include "src/Crash/CrashHandler.h"
#include "src/Yandex/Account/AccountService.h"
#include "src/Yandex/Auth/YandexAuth.h"
#include "src/Yandex/Catalog/CoverImageProvider.h"

// Версию подставляет CMake из project(); значение по умолчанию нужно,
// если файл собирают в обход CMake.
#ifndef YAMUSIC_VERSION
#define YAMUSIC_VERSION "0.0.0"
#endif

int main(int argc, char *argv[])
{
#if !defined(Q_OS_ANDROID)
    // 1. Инициализация темы иконок KDE Plasma
    KIconTheme::initTheme();
#endif

    // 2. Создание QApplication
    QApplication app(argc, argv);

    // 3. Настройка стиля строго ПОСЛЕ создания QApplication
#if defined(Q_OS_ANDROID)
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("Basic"));
    }
#else
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }
#endif

    QCoreApplication::setOrganizationName("KDE");
    QCoreApplication::setOrganizationDomain("kde.org");
    QCoreApplication::setApplicationName("kymusic");
    QGuiApplication::setApplicationDisplayName("KYMusic");
    QGuiApplication::setDesktopFileName("org.kde.kymusic");
    QCoreApplication::setApplicationVersion(QStringLiteral(YAMUSIC_VERSION));

#if !defined(Q_OS_ANDROID)
    // Настройка KAboutData для системных окон «О программе» и «О KDE»
    KAboutData aboutData(
        QStringLiteral("kymusic"),
        QStringLiteral("KYMusic"),
        QStringLiteral(YAMUSIC_VERSION),
        QStringLiteral("Нативный клиент Яндекс Музыки для KDE Plasma и Plasma Mobile"),
        KAboutLicense::GPL_V3,
        QStringLiteral("(C) 2024-2026 Xyntril, Anders Friden"),
        QString(),
        QStringLiteral("https://github.com/Xyntril/KYMusic")
    );
    aboutData.setDesktopFileName(QStringLiteral("org.kde.kymusic"));
    aboutData.setBugAddress("polina_leyne@proton.me");
    aboutData.addAuthor(
        QStringLiteral("Xyntril"),
        QStringLiteral("Автор и ведущий разработчик KYMusic, архитектура и интерфейс KDE Plasma"),
        QStringLiteral("polina_leyne@proton.me"),
        QStringLiteral("https://github.com/Xyntril")
    );
    aboutData.addCredit(
        QStringLiteral("Anders Friden"),
        QStringLiteral("Автор оригинального базового клиента YaMusic, на основе которого создан форк"),
        QString(),
        QStringLiteral("https://github.com/andfriden/YaMusic")
    );
#endif

    // Установка иконки приложения (Breeze HIG icon)
    QIcon appIcon(QStringLiteral(":/kymusic.svg"));
    if (appIcon.isNull()) {
        appIcon = QIcon(QStringLiteral(":/qt/qml/YaMusic/kymusic.svg"));
    }
    if (appIcon.isNull()) {
        appIcon = QIcon(QStringLiteral(":/YaMusic.svg"));
    }
    if (appIcon.isNull() && QIcon::hasThemeIcon(QStringLiteral("kymusic"))) {
        appIcon = QIcon::fromTheme(QStringLiteral("kymusic"));
    }
    if (appIcon.isNull() && QIcon::hasThemeIcon(QStringLiteral("multimedia-player"))) {
        appIcon = QIcon::fromTheme(QStringLiteral("multimedia-player"));
    }
    if (!appIcon.isNull()) {
        app.setWindowIcon(appIcon);
#if !defined(Q_OS_ANDROID)
        aboutData.setProgramLogo(QVariant::fromValue(appIcon));
#endif
    }
#if !defined(Q_OS_ANDROID)
    KAboutData::setApplicationData(aboutData);
#endif

    // Перехват падений ставится до первого окна
    Crash::install(QStringLiteral(YAMUSIC_VERSION));

    YandexAuth auth;

    AccountService accountService(
        &auth
    );

    AuthController authController(
        &auth,
        &accountService
    );

    AppController appController(
        &auth,
        &accountService
    );

#if !defined(Q_OS_ANDROID)
    // Системный трей KDE Plasma (KStatusNotifierItem) привязан к жизненному циклу app
    auto *trayController = new KdeTrayController(appController.playbackController(), &app);

    // Экспорт меню по D-Bus для Global Menu в панели KDE Plasma
    auto *menuManager = new KdeMenuManager(&appController, &authController, &app);
    Q_UNUSED(menuManager);
#endif

    // 4. И только ПОСЛЕ настройки стиля и создания контроллеров — создание QQmlApplicationEngine
    QQmlApplicationEngine engine;

    engine.addImageProvider(
        "yandex",
        new CoverImageProvider()
    );

    engine.rootContext()->setContextProperty(
        "authController",
        &authController
    );

    engine.rootContext()->setContextProperty(
        "appController",
        &appController
    );

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    engine.loadFromModule(
        "YaMusic",
        "Main"
    );

    const auto rootObjects = engine.rootObjects();
    if (!rootObjects.isEmpty()) {
        if (auto *window = qobject_cast<QQuickWindow *>(rootObjects.first())) {
            trayController->setWindow(window);
            menuManager->attachToWindow(window);
        }
    }

    return QApplication::exec();
}
