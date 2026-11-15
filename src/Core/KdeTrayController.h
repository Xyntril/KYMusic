#pragma once

#include <QObject>
#include <QPointer>
#include <QWindow>
#include <memory>

class KStatusNotifierItem;
class PlaybackController;
class QAction;
class QMenu;

class KdeTrayController : public QObject {
  Q_OBJECT

public:
  explicit KdeTrayController(PlaybackController *playbackController, QObject *parent = nullptr);
  ~KdeTrayController() override;

  void setWindow(QWindow *window);

public slots:
  void toggleWindow();
  void showWindow();
  void hideWindow();

private slots:
  void onPlaybackStateChanged();
  void onCurrentTrackChanged();
  void onTogglePlayPause();

private:
  void setupMenu();
  void updateTrayInfo();

  PlaybackController *m_playbackController = nullptr;
  QPointer<QWindow> m_window;
  KStatusNotifierItem *m_trayItem = nullptr;
  QMenu *m_menu = nullptr;
  QAction *m_playPauseAction = nullptr;
  QAction *m_nextAction = nullptr;
  QAction *m_prevAction = nullptr;
  QAction *m_toggleWindowAction = nullptr;
};
