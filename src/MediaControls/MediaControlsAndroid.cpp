#include "MediaControlsAndroid.h"

#include <QCoreApplication>
#include <QDebug>

#if defined(Q_OS_ANDROID)
#include <QJniEnvironment>
#include <QJniObject>
#include <jni.h>
#endif

MediaControlsAndroid *MediaControlsAndroid::s_instance = nullptr;

MediaControlsAndroid::MediaControlsAndroid(QObject *parent)
    : SystemMediaControls(parent) {
  s_instance = this;
}

MediaControlsAndroid::~MediaControlsAndroid() {
  if (s_instance == this) {
    s_instance = nullptr;
  }
}

MediaControlsAndroid *MediaControlsAndroid::instance() {
  return s_instance;
}

void MediaControlsAndroid::platformSetEnabled(bool enabled) {
#if defined(Q_OS_ANDROID)
  if (!enabled) {
    QJniObject::callStaticMethod<void>(
        "org/kde/kymusic/MediaNotificationHelper",
        "stopNotification",
        "()V");
  } else {
    updateNotification();
  }
#else
  Q_UNUSED(enabled);
#endif
}

void MediaControlsAndroid::platformSetMetadata(const Metadata &metadata) {
  Q_UNUSED(metadata);
  updateNotification();
}

void MediaControlsAndroid::platformSetPlaybackStatus(PlaybackStatus status) {
  Q_UNUSED(status);
  updateNotification();
}

void MediaControlsAndroid::platformSetPosition(qint64 positionMs) {
  Q_UNUSED(positionMs);
}

void MediaControlsAndroid::platformSetDuration(qint64 durationMs) {
  Q_UNUSED(durationMs);
}

void MediaControlsAndroid::updateNotification() {
#if defined(Q_OS_ANDROID)
  if (!isEnabled()) {
    return;
  }

  const bool isPlaying = (m_status == PlaybackStatus::Playing);
  const QString title = m_metadata.title.isEmpty() ? QStringLiteral("KYMusic") : m_metadata.title;
  const QString artist = m_metadata.artist;
  const QString album = m_metadata.album;

  QJniObject jTitle = QJniObject::fromString(title);
  QJniObject jArtist = QJniObject::fromString(artist);
  QJniObject jAlbum = QJniObject::fromString(album);

  QJniObject::callStaticMethod<void>(
      "org/kde/kymusic/MediaNotificationHelper",
      "updateNotification",
      "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V",
      jTitle.object<jstring>(),
      jArtist.object<jstring>(),
      jAlbum.object<jstring>(),
      static_cast<jboolean>(isPlaying));
#endif
}

#if defined(Q_OS_ANDROID)
extern "C" {

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnPlay(JNIEnv * /*env*/, jclass /*clazz*/) {
  QMetaObject::invokeMethod(qApp, []() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->playRequested();
    }
  }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnPause(JNIEnv * /*env*/, jclass /*clazz*/) {
  QMetaObject::invokeMethod(qApp, []() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->pauseRequested();
    }
  }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnToggle(JNIEnv * /*env*/, jclass /*clazz*/) {
  QMetaObject::invokeMethod(qApp, []() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->togglePlayPauseRequested();
    }
  }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnNext(JNIEnv * /*env*/, jclass /*clazz*/) {
  QMetaObject::invokeMethod(qApp, []() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->nextRequested();
    }
  }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnPrev(JNIEnv * /*env*/, jclass /*clazz*/) {
  QMetaObject::invokeMethod(qApp, []() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->previousRequested();
    }
  }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnStop(JNIEnv * /*env*/, jclass /*clazz*/) {
  QMetaObject::invokeMethod(qApp, []() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->pauseRequested();
    }
  }, Qt::QueuedConnection);
}

JNIEXPORT void JNICALL
Java_org_kde_kymusic_MediaNotificationHelper_nativeOnSeek(JNIEnv * /*env*/, jclass /*clazz*/, jlong posMs) {
  QMetaObject::invokeMethod(qApp, [posMs]() {
    if (auto *ctrl = MediaControlsAndroid::instance()) {
      emit ctrl->seekRequested(static_cast<qint64>(posMs));
    }
  }, Qt::QueuedConnection);
}

} // extern "C"
#endif
