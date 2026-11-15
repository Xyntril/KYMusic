#include "KdeMenuManager.h"
#include "AppController.h"
#include "AuthController.h"

#include <QApplication>
#include <QKeySequence>
#include <QWindow>

KdeMenuManager::KdeMenuManager(AppController *appController, AuthController *authController, QObject *parent)
    : QObject(parent), m_appController(appController), m_authController(authController) {
  setupMenus();
}

KdeMenuManager::~KdeMenuManager() {
  if (m_menuBar != nullptr) {
    m_menuBar->deleteLater();
  }
}

void KdeMenuManager::attachToWindow(QWindow *window) {
  if (window == nullptr || m_menuBar == nullptr) return;
  m_menuBar->winId();
}

void KdeMenuManager::setupMenus() {
  m_menuBar = new QMenuBar();

  // 1. Файл
  QMenu *fileMenu = m_menuBar->addMenu(tr("&Файл"));
  fileMenu->addAction(QIcon::fromTheme(QStringLiteral("download")), tr("Скачать текущий трек"), [this]() {
    if (m_appController != nullptr) m_appController->downloadCurrentTrack();
  });

  fileMenu->addSeparator();
  QAction *quitAct = fileMenu->addAction(QIcon::fromTheme(QStringLiteral("application-exit")), tr("Выход"), []() {
    qApp->quit();
  });
  quitAct->setShortcut(QKeySequence::Quit);

  // 2. Правка
  QMenu *editMenu = m_menuBar->addMenu(tr("&Правка"));
  QAction *copyAct = editMenu->addAction(QIcon::fromTheme(QStringLiteral("edit-copy")), tr("Копировать название трека"), [this]() {
    if (m_appController != nullptr) m_appController->copyCurrentTrackTitle();
  });
  copyAct->setShortcut(QKeySequence::Copy);

  editMenu->addAction(QIcon::fromTheme(QStringLiteral("edit-find")), tr("Найти"), [this]() {
    if (m_appController != nullptr) m_appController->search(QString());
  });

  // 3. Вид
  QMenu *viewMenu = m_menuBar->addMenu(tr("&Вид"));
  viewMenu->addAction(QIcon::fromTheme(QStringLiteral("view-media-lyrics")), tr("Текст песни"), [this]() {
    if (m_appController != nullptr) m_appController->copyCurrentTrackTitle();
  });

  // 4. Переход
  QMenu *navMenu = m_menuBar->addMenu(tr("&Переход"));
  navMenu->addAction(QIcon::fromTheme(QStringLiteral("go-home")), tr("Главная"), [this]() {
    if (m_appController != nullptr) m_appController->loadWheel();
  });
  navMenu->addAction(QIcon::fromTheme(QStringLiteral("network-wireless")), tr("Моя волна"), [this]() {
    if (m_appController != nullptr) m_appController->loadMyWave();
  });
  navMenu->addAction(QIcon::fromTheme(QStringLiteral("view-media-recent")), tr("Новые релизы"), [this]() {
    if (m_appController != nullptr) m_appController->loadRecommendations();
  });
  navMenu->addAction(QIcon::fromTheme(QStringLiteral("view-media-genre")), tr("Жанры"), [this]() {
    if (m_appController != nullptr) m_appController->loadGenres();
  });

  // 5. Воспроизведение
  QMenu *playbackMenu = m_menuBar->addMenu(tr("&Воспроизведение"));
  playbackMenu->addAction(QIcon::fromTheme(QStringLiteral("media-playback-start")), tr("Воспроизвести / Пауза"), [this]() {
    if (m_appController == nullptr) return;
    if (m_appController->isPlaying()) m_appController->pause();
    else m_appController->play();
  });

  playbackMenu->addAction(QIcon::fromTheme(QStringLiteral("media-skip-forward")), tr("Следующий трек"), [this]() {
    if (m_appController != nullptr) m_appController->next();
  });

  playbackMenu->addAction(QIcon::fromTheme(QStringLiteral("media-skip-backward")), tr("Предыдущий трек"), [this]() {
    if (m_appController != nullptr) m_appController->previous();
  });

  playbackMenu->addAction(QIcon::fromTheme(QStringLiteral("media-playlist-shuffle")), tr("Случайный порядок"), [this]() {
    if (m_appController != nullptr) m_appController->toggleShuffle();
  });

  playbackMenu->addAction(QIcon::fromTheme(QStringLiteral("media-playlist-repeat")), tr("Повтор"), [this]() {
    if (m_appController != nullptr) m_appController->cycleRepeat();
  });

  // 6. Настройка
  QMenu *settingsMenu = m_menuBar->addMenu(tr("&Настройка"));
  settingsMenu->addAction(QIcon::fromTheme(QStringLiteral("configure")), tr("Параметры KYMusic..."), [this]() {
    if (m_appController != nullptr) m_appController->openSettings();
  });

  // 7. Справка
  QMenu *helpMenu = m_menuBar->addMenu(tr("&Справка"));
  helpMenu->addAction(QIcon::fromTheme(QStringLiteral("kymusic")), tr("О программе KYMusic"), [this]() {
    if (m_appController != nullptr) m_appController->showAboutAppDialog();
  });

  helpMenu->addAction(QIcon::fromTheme(QStringLiteral("kde")), tr("О среде KDE"), [this]() {
    if (m_appController != nullptr) m_appController->showAboutKdeDialog();
  });
}
