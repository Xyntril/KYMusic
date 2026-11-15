#include "MediaControlsMPRIS.h"

#include <QCoreApplication>
#include <QDBusAbstractAdaptor>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QRegularExpression>
#include <QVariantMap>

namespace {
constexpr auto kServiceName = "org.mpris.MediaPlayer2.kymusic";
constexpr auto kFallbackServiceName = "org.mpris.MediaPlayer2.KYMusic";
constexpr auto kObjectPath = "/org/mpris/MediaPlayer2";

QString playbackStatusToString(SystemMediaControls::PlaybackStatus status) {
  switch (status) {
  case SystemMediaControls::PlaybackStatus::Playing:
    return QStringLiteral("Playing");
  case SystemMediaControls::PlaybackStatus::Paused:
    return QStringLiteral("Paused");
  case SystemMediaControls::PlaybackStatus::Stopped:
    return QStringLiteral("Stopped");
  }
  return QStringLiteral("Stopped");
}

} // anonymous namespace

// Импл — основной QObject на шине; адаптеры — его дочерние объекты.
class Impl : public QObject {
  Q_OBJECT

public:
  explicit Impl(MediaControlsMPRIS *owner) : QObject(owner), m_owner(owner) {}

  bool registerService();
  void unregisterService();

  SystemMediaControls::PlaybackStatus playbackStatus() const {
    return m_owner->mediaPlaybackStatus();
  }
  QString loopStatus() const { return m_owner->mediaLoopStatus(); }
  bool shuffle() const { return m_owner->mediaShuffle(); }
  const SystemMediaControls::Metadata &metadata() const { return m_owner->mediaMetadata(); }
  qint64 positionMs() const { return m_owner->mediaPositionMs(); }

  void requestPlay() { Q_EMIT m_owner->playRequested(); }
  void requestPause() { Q_EMIT m_owner->pauseRequested(); }
  void requestToggle() { Q_EMIT m_owner->togglePlayPauseRequested(); }
  void requestNext() { Q_EMIT m_owner->nextRequested(); }
  void requestPrevious() { Q_EMIT m_owner->previousRequested(); }
  void requestSeek(qint64 positionMs) { Q_EMIT m_owner->seekRequested(positionMs); }
  void requestSetLoopStatus(const QString &loopStatus) {
    Q_EMIT m_owner->setLoopStatusRequested(loopStatus);
  }
  void requestSetShuffle(bool shuffle) {
    Q_EMIT m_owner->setShuffleRequested(shuffle);
  }
  void requestRaise() { Q_EMIT m_owner->raiseRequested(); }
  void requestQuit() { Q_EMIT m_owner->quitRequested(); }

  void notifyAllChanged();
  void notifySeeked(qint64 positionMs);

private:
  MediaControlsMPRIS *m_owner = nullptr;
  qint64 m_lastSeekedMs = -1;
  QString m_registeredService;
};

// Адаптеры — по одному на D-Bus интерфейс.
namespace {
class RootAdaptor : public QDBusAbstractAdaptor {
  Q_OBJECT
  Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2")

  Q_PROPERTY(bool CanQuit READ canQuit CONSTANT)
  Q_PROPERTY(bool CanRaise READ canRaise CONSTANT)
  Q_PROPERTY(bool HasTrackList READ hasTrackList CONSTANT)
  Q_PROPERTY(QString Identity READ identity CONSTANT)
  Q_PROPERTY(QString DesktopEntry READ desktopEntry CONSTANT)
  Q_PROPERTY(QStringList SupportedUriSchemes READ supportedUriSchemes CONSTANT)
  Q_PROPERTY(QStringList SupportedMimeTypes READ supportedMimeTypes CONSTANT)

public:
  explicit RootAdaptor(Impl *parent) : QDBusAbstractAdaptor(parent), m_impl(parent) {}

public slots:
  void Raise() { m_impl->requestRaise(); }
  void Quit() { m_impl->requestQuit(); }

  bool canQuit() const { return true; }
  bool canRaise() const { return true; }
  bool hasTrackList() const { return false; }
  QString identity() const { return QStringLiteral("KYMusic"); }
  QString desktopEntry() const { return QStringLiteral("kymusic"); }
  QStringList supportedUriSchemes() const { return {QStringLiteral("https"), QStringLiteral("file")}; }
  QStringList supportedMimeTypes() const { return {QStringLiteral("audio/mpeg"), QStringLiteral("audio/flac")}; }

private:
  Impl *m_impl = nullptr;
};

class PlayerAdaptor : public QDBusAbstractAdaptor {
  Q_OBJECT
  Q_CLASSINFO("D-Bus Interface", "org.mpris.MediaPlayer2.Player")

  Q_PROPERTY(QString PlaybackStatus READ playbackStatus NOTIFY playbackStatusChanged)
  Q_PROPERTY(QString LoopStatus READ loopStatus WRITE setLoopStatus NOTIFY loopStatusChanged)
  Q_PROPERTY(double Rate READ rate CONSTANT)
  Q_PROPERTY(bool Shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
  Q_PROPERTY(QVariantMap Metadata READ metadata NOTIFY metadataChanged)
  Q_PROPERTY(double Volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(qlonglong Position READ position)
  Q_PROPERTY(double MinimumRate READ minimumRate CONSTANT)
  Q_PROPERTY(double MaximumRate READ maximumRate CONSTANT)
  Q_PROPERTY(bool CanGoNext READ canGoNext CONSTANT)
  Q_PROPERTY(bool CanGoPrevious READ canGoPrevious CONSTANT)
  Q_PROPERTY(bool CanPlay READ canPlay CONSTANT)
  Q_PROPERTY(bool CanPause READ canPause CONSTANT)
  Q_PROPERTY(bool CanSeek READ canSeek CONSTANT)
  Q_PROPERTY(bool CanControl READ canControl CONSTANT)

public:
  explicit PlayerAdaptor(Impl *parent) : QDBusAbstractAdaptor(parent), m_impl(parent) {}

public slots:
  void Next() { m_impl->requestNext(); }
  void Previous() { m_impl->requestPrevious(); }
  void Pause() { m_impl->requestPause(); }
  void PlayPause() { m_impl->requestToggle(); }
  void Stop() { m_impl->requestPause(); }
  void Play() { m_impl->requestPlay(); }

  void Seek(qlonglong offsetMicroseconds) {
    const qint64 currentPosUs = m_impl->positionMs() * 1000;
    const qint64 targetUs = qMax<qint64>(0, currentPosUs + offsetMicroseconds);
    m_impl->requestSeek(targetUs / 1000);
  }

  void SetPosition(const QDBusObjectPath &, qlonglong posUs) {
    m_impl->requestSeek(qMax<qint64>(0, posUs) / 1000);
  }

  void OpenUri(const QString &) {}

  void setLoopStatus(const QString &loopStatus) {
    m_impl->requestSetLoopStatus(loopStatus);
  }

  void setShuffle(bool shuffle) {
    m_impl->requestSetShuffle(shuffle);
  }

  QString playbackStatus() const { return playbackStatusToString(m_impl->playbackStatus()); }
  QString loopStatus() const { return m_impl->loopStatus(); }
  double rate() const { return 1.0; }
  bool shuffle() const { return m_impl->shuffle(); }

  QVariantMap metadata() const {
    QVariantMap md;
    const auto &t = m_impl->metadata();

    QString cleanId = t.trackId;
    cleanId.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9_]")), QStringLiteral("_"));
    if (cleanId.isEmpty()) {
      cleanId = QStringLiteral("0");
    }
    md[QStringLiteral("mpris:trackid")] = QVariant::fromValue(
        QDBusObjectPath(QStringLiteral("/org/kde/kymusic/track_%1").arg(cleanId)));

    if (!t.title.isEmpty()) {
      md[QStringLiteral("xesam:title")] = t.title;
    } else {
      md[QStringLiteral("xesam:title")] = QStringLiteral("KYMusic");
    }

    if (!t.artist.isEmpty()) {
      md[QStringLiteral("xesam:artist")] = QStringList{t.artist};
    } else {
      md[QStringLiteral("xesam:artist")] = QStringList{QStringLiteral("KYMusic")};
    }

    if (!t.album.isEmpty()) {
      md[QStringLiteral("xesam:album")] = t.album;
    }

    if (t.durationMs > 0) {
      md[QStringLiteral("mpris:length")] = static_cast<qlonglong>(t.durationMs * 1000);
    }

    QString artUrl = t.coverUrl;
    if (!artUrl.isEmpty()) {
      if (!artUrl.startsWith(QLatin1String("http://")) &&
          !artUrl.startsWith(QLatin1String("https://")) &&
          !artUrl.startsWith(QLatin1String("file://"))) {
        if (artUrl.startsWith(QLatin1String("//"))) {
          artUrl = QStringLiteral("https:") + artUrl;
        } else {
          artUrl = QStringLiteral("https://") + artUrl;
        }
      }
      md[QStringLiteral("mpris:artUrl")] = artUrl;
    }

    return md;
  }

  double volume() const { return 1.0; }
  void setVolume(double) {}
  qlonglong position() const { return static_cast<qlonglong>(m_impl->positionMs() * 1000); }
  double minimumRate() const { return 1.0; }
  double maximumRate() const { return 1.0; }

  bool canGoNext() const { return true; }
  bool canGoPrevious() const { return true; }
  bool canPlay() const { return true; }
  bool canPause() const { return true; }
  bool canSeek() const { return true; }
  bool canControl() const { return true; }

  void emitAllChanged() {
    Q_EMIT playbackStatusChanged();
    Q_EMIT loopStatusChanged();
    Q_EMIT shuffleChanged();
    Q_EMIT metadataChanged();
    sendPropertiesChanged();
  }

  void emitSeeked(qint64 positionMs) {
    Q_EMIT Seeked(static_cast<qlonglong>(positionMs * 1000));
  }

  void sendPropertiesChanged() {
    QVariantMap changed;
    changed.insert(QStringLiteral("PlaybackStatus"), playbackStatus());
    changed.insert(QStringLiteral("LoopStatus"), loopStatus());
    changed.insert(QStringLiteral("Shuffle"), shuffle());
    changed.insert(QStringLiteral("Metadata"), metadata());
    changed.insert(QStringLiteral("CanControl"), canControl());
    changed.insert(QStringLiteral("CanPlay"), canPlay());
    changed.insert(QStringLiteral("CanPause"), canPause());
    changed.insert(QStringLiteral("CanGoNext"), canGoNext());
    changed.insert(QStringLiteral("CanGoPrevious"), canGoPrevious());
    changed.insert(QStringLiteral("CanSeek"), canSeek());

    QDBusMessage msg = QDBusMessage::createSignal(QStringLiteral("/org/mpris/MediaPlayer2"),
                                                  QStringLiteral("org.freedesktop.DBus.Properties"),
                                                  QStringLiteral("PropertiesChanged"));
    msg << QStringLiteral("org.mpris.MediaPlayer2.Player") << changed << QStringList();
    QDBusConnection::sessionBus().send(msg);
  }

signals:
  void playbackStatusChanged();
  void loopStatusChanged();
  void shuffleChanged();
  void metadataChanged();
  void volumeChanged();
  void Seeked(qlonglong positionMicroseconds);

private:
  Impl *m_impl = nullptr;
};

} // anonymous namespace

bool Impl::registerService() {
  QDBusConnection bus = QDBusConnection::sessionBus();

  QString chosenService = QString::fromLatin1(kServiceName);
  if (!bus.registerService(chosenService)) {
    chosenService = QString::fromLatin1(kFallbackServiceName);
    if (!bus.registerService(chosenService)) {
      chosenService = QStringLiteral("org.mpris.MediaPlayer2.kymusic.instance%1")
                          .arg(QCoreApplication::applicationPid());
      if (!bus.registerService(chosenService)) {
        qWarning("MPRIS: cannot register service %s, %s or instance PID", kServiceName, kFallbackServiceName);
        return false;
      }
    }
  }
  m_registeredService = chosenService;

  new RootAdaptor(this);
  new PlayerAdaptor(this);

  if (!bus.registerObject(kObjectPath, this, QDBusConnection::ExportAdaptors)) {
    qWarning("MPRIS: cannot register object %s", kObjectPath);
    bus.unregisterService(m_registeredService);
    m_registeredService.clear();
    return false;
  }
  return true;
}

void Impl::unregisterService() {
  if (m_registeredService.isEmpty()) return;
  QDBusConnection bus = QDBusConnection::sessionBus();
  bus.unregisterObject(kObjectPath);
  bus.unregisterService(m_registeredService);
  m_registeredService.clear();
}

void Impl::notifyAllChanged() {
  auto *pa = findChild<PlayerAdaptor *>(QString(), Qt::FindDirectChildrenOnly);
  if (pa) pa->emitAllChanged();
}

void Impl::notifySeeked(qint64 positionMs) {
  // При перемотке в 0:00 (повтор или возврат к началу) отправляем всегда!
  if (positionMs != 0 && m_lastSeekedMs >= 0 && qAbs(positionMs - m_lastSeekedMs) < 1000) return;
  auto *pa = findChild<PlayerAdaptor *>(QString(), Qt::FindDirectChildrenOnly);
  if (pa) {
    pa->emitSeeked(positionMs);
    pa->sendPropertiesChanged();
  }
  m_lastSeekedMs = positionMs;
}

MediaControlsMPRIS::MediaControlsMPRIS(QObject *parent)
    : SystemMediaControls(parent), d(new Impl(this)) {}

MediaControlsMPRIS::~MediaControlsMPRIS() {
  setEnabled(false);
  delete d;
}

void MediaControlsMPRIS::platformSetEnabled(bool enabled) {
  if (enabled)
    d->registerService();
  else
    d->unregisterService();
}

void MediaControlsMPRIS::platformSetMetadata(const Metadata &) {
  if (d) d->notifyAllChanged();
}

void MediaControlsMPRIS::platformSetPlaybackStatus(PlaybackStatus) {
  if (d) d->notifyAllChanged();
}

void MediaControlsMPRIS::platformSetPosition(qint64 positionMs) {
  if (d) d->notifySeeked(positionMs);
}

void MediaControlsMPRIS::platformSetDuration(qint64) {}

void MediaControlsMPRIS::platformSetLoopStatus(const QString &) {
  if (d) d->notifyAllChanged();
}

void MediaControlsMPRIS::platformSetShuffle(bool) {
  if (d) d->notifyAllChanged();
}

#include "MediaControlsMPRIS.moc"
