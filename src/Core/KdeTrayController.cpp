#include "KdeTrayController.h"

#include "../Playback/PlaybackController.h"

#include <KStatusNotifierItem>
#include <QAction>
#include <QCoreApplication>
#include <QIcon>
#include <QMenu>

namespace {

QIcon resolveTrayIcon() {
  QIcon icon(QStringLiteral(":/kymusic-tray-symbolic.svg"));
  if (icon.isNull()) {
    icon = QIcon(QStringLiteral(":/qt/qml/YaMusic/kymusic-tray-symbolic.svg"));
  }
  if (icon.isNull() && QIcon::hasThemeIcon(QStringLiteral("kymusic-tray-symbolic"))) {
    icon = QIcon::fromTheme(QStringLiteral("kymusic-tray-symbolic"));
  }
  if (icon.isNull()) {
    icon = QIcon(QStringLiteral(":/kymusic.svg"));
  }
  if (icon.isNull()) {
    icon = QIcon(QStringLiteral(":/qt/qml/YaMusic/kymusic.svg"));
  }
  if (icon.isNull() && QIcon::hasThemeIcon(QStringLiteral("kymusic"))) {
    icon = QIcon::fromTheme(QStringLiteral("kymusic"));
  }
  if (icon.isNull() && QIcon::hasThemeIcon(QStringLiteral("multimedia-player"))) {
    icon = QIcon::fromTheme(QStringLiteral("multimedia-player"));
  }
  if (icon.isNull()) {
    icon = QIcon::fromTheme(QStringLiteral("audio-x-generic"));
  }
  return icon;
}

QIcon resolveAppIcon() {
  QIcon icon(QStringLiteral(":/kymusic.svg"));
  if (icon.isNull()) {
    icon = QIcon(QStringLiteral(":/qt/qml/YaMusic/kymusic.svg"));
  }
  if (icon.isNull()) {
    icon = QIcon(QStringLiteral(":/YaMusic.svg"));
  }
  if (icon.isNull() && QIcon::hasThemeIcon(QStringLiteral("kymusic"))) {
    icon = QIcon::fromTheme(QStringLiteral("kymusic"));
  }
  if (icon.isNull() && QIcon::hasThemeIcon(QStringLiteral("yamusic"))) {
    icon = QIcon::fromTheme(QStringLiteral("yamusic"));
  }
  if (icon.isNull() && QIcon::hasThemeIcon(QStringLiteral("multimedia-player"))) {
    icon = QIcon::fromTheme(QStringLiteral("multimedia-player"));
  }
  if (icon.isNull()) {
    icon = QIcon::fromTheme(QStringLiteral("audio-x-generic"));
  }
  return icon;
}

} // namespace

KdeTrayController::KdeTrayController(PlaybackController *playbackController, QObject *parent)
    : QObject(parent), m_playbackController(playbackController) {
  m_trayItem = new KStatusNotifierItem(this);
  m_trayItem->setCategory(KStatusNotifierItem::ApplicationStatus);
  m_trayItem->setTitle(QStringLiteral("KYMusic"));

  // Отключаем автоматические стандартные действия KStatusNotifierItem,
  // чтобы не дублировался пункт «Выход» (в меню остаётся ровно один чистый экшен).
  m_trayItem->setStandardActionsEnabled(false);

  // Явно активируем статус, чтобы иконка не скрывалась в скрытых элементах трея Plasma
  m_trayItem->setStatus(KStatusNotifierItem::Active);

  // Загружаем символьную иконку для трея Plasma
  const QIcon trayIcon = resolveTrayIcon();
  if (!trayIcon.isNull()) {
    m_trayItem->setIconByPixmap(trayIcon);
  } else if (QIcon::hasThemeIcon(QStringLiteral("multimedia-player"))) {
    m_trayItem->setIconByName(QStringLiteral("multimedia-player"));
  } else {
    m_trayItem->setIconByName(QStringLiteral("audio-x-generic"));
  }

  setupMenu();
  updateTrayInfo();

  if (m_playbackController) {
    connect(m_playbackController, &PlaybackController::stateChanged, this,
            &KdeTrayController::onPlaybackStateChanged);
    connect(m_playbackController, &PlaybackController::currentTrackChanged, this,
            &KdeTrayController::onCurrentTrackChanged);
  }

  connect(m_trayItem, &KStatusNotifierItem::activateRequested, this,
          [this](bool /*active*/, const QPoint & /*pos*/) { toggleWindow(); });
}

KdeTrayController::~KdeTrayController() = default;

void KdeTrayController::setWindow(QWindow *window) {
  m_window = window;
}

void KdeTrayController::setupMenu() {
  m_menu = m_trayItem->contextMenu();
  if (!m_menu) {
    m_menu = new QMenu();
    m_trayItem->setContextMenu(m_menu);
  } else {
    m_menu->clear();
  }

  m_playPauseAction = m_menu->addAction(
      QIcon::fromTheme(QStringLiteral("media-playback-start")),
      tr("Воспроизвести"), this, &KdeTrayController::onTogglePlayPause);

  m_nextAction = m_menu->addAction(
      QIcon::fromTheme(QStringLiteral("media-skip-forward")),
      tr("Следующий трек"), this, [this]() {
        if (m_playbackController) {
          m_playbackController->next();
        }
      });

  m_prevAction = m_menu->addAction(
      QIcon::fromTheme(QStringLiteral("media-skip-backward")),
      tr("Предыдущий трек"), this, [this]() {
        if (m_playbackController) {
          m_playbackController->previous();
        }
      });

  m_menu->addSeparator();

  m_toggleWindowAction = m_menu->addAction(
      QIcon::fromTheme(QStringLiteral("window")),
      tr("Показать / Скрыть окно"), this, &KdeTrayController::toggleWindow);

  m_menu->addSeparator();

  m_menu->addAction(
      QIcon::fromTheme(QStringLiteral("application-exit")),
      tr("Выход"), qApp, &QCoreApplication::quit);
}

void KdeTrayController::toggleWindow() {
  if (!m_window) {
    return;
  }

  if (m_window->isVisible()) {
    m_window->hide();
  } else {
    m_window->show();
    m_window->raise();
    m_window->requestActivate();
  }
}

void KdeTrayController::showWindow() {
  if (m_window) {
    m_window->show();
    m_window->raise();
    m_window->requestActivate();
  }
}

void KdeTrayController::hideWindow() {
  if (m_window) {
    m_window->hide();
  }
}

void KdeTrayController::onTogglePlayPause() {
  if (!m_playbackController) {
    return;
  }

  if (m_playbackController->state() == PlaybackController::Playing) {
    m_playbackController->pause();
  } else {
    m_playbackController->resume();
  }
}

void KdeTrayController::onPlaybackStateChanged() {
  updateTrayInfo();
}

void KdeTrayController::onCurrentTrackChanged() {
  updateTrayInfo();
}

void KdeTrayController::updateTrayInfo() {
  if (!m_playbackController) {
    return;
  }

  const bool isPlaying = (m_playbackController->state() == PlaybackController::Playing);
  if (m_playPauseAction) {
    if (isPlaying) {
      m_playPauseAction->setText(tr("Пауза"));
      m_playPauseAction->setIcon(QIcon::fromTheme(QStringLiteral("media-playback-pause")));
    } else {
      m_playPauseAction->setText(tr("Воспроизвести"));
      m_playPauseAction->setIcon(QIcon::fromTheme(QStringLiteral("media-playback-start")));
    }
  }

  const Track track = m_playbackController->currentTrack();
  QString tooltipSub;
  if (!track.title.isEmpty()) {
    QStringList artistNames;
    for (const auto &artist : track.artists) {
      if (!artist.name.isEmpty()) {
        artistNames.append(artist.name);
      }
    }
    if (!artistNames.isEmpty()) {
      tooltipSub = QStringLiteral("%1 — %2").arg(track.title, artistNames.join(QStringLiteral(", ")));
    } else {
      tooltipSub = track.title;
    }
  } else {
    tooltipSub = isPlaying ? tr("Воспроизведение") : tr("Остановлено");
  }

  const QIcon appIcon = resolveAppIcon();
  if (!appIcon.isNull()) {
    m_trayItem->setToolTip(appIcon, QStringLiteral("KYMusic"), tooltipSub);
  } else {
    m_trayItem->setToolTip(QStringLiteral("multimedia-player"), QStringLiteral("KYMusic"), tooltipSub);
  }
}
