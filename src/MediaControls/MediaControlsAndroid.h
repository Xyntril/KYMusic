#pragma once

#include "SystemMediaControls.h"

class MediaControlsAndroid : public SystemMediaControls {
  Q_OBJECT

public:
  explicit MediaControlsAndroid(QObject *parent = nullptr);
  ~MediaControlsAndroid() override;

  static MediaControlsAndroid *instance();

protected:
  void platformSetEnabled(bool enabled) override;
  void platformSetMetadata(const Metadata &metadata) override;
  void platformSetPlaybackStatus(PlaybackStatus status) override;
  void platformSetPosition(qint64 positionMs) override;
  void platformSetDuration(qint64 durationMs) override;

private:
  void updateNotification();
  static MediaControlsAndroid *s_instance;
};
