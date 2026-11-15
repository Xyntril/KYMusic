#include "Parsers.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

// TODO(YM-2243): парсить версии треков (version) и остальные поля альбомов.
QString parseId(const QJsonObject &object) {
  const qint64 realId = object.value("realId").toInteger();
  if (realId > 0) return QString::number(realId);

  const QJsonValue idValue = object.value("id");
  if (idValue.isString()) {
    QString id = idValue.toString().trimmed();
    if (id.contains(':')) {
      id = id.section(':', 0, 0).trimmed();
    }
    if (!id.isEmpty()) return id;
  }
  if (idValue.isDouble()) {
    const qint64 id = idValue.toInteger();
    if (id > 0) return QString::number(id);
  }
  return {};
}

static QString formatCoverUri(QString uri) {
  uri = uri.trimmed();
  if (uri.isEmpty()) return {};

  if (uri.contains(QLatin1String("%%"))) {
    uri.replace(QLatin1String("%%"), QLatin1String("400x400"));
  }
  if (!uri.startsWith(QLatin1String("http://")) &&
      !uri.startsWith(QLatin1String("https://")) &&
      !uri.startsWith(QLatin1String("qrc:/")) &&
      !uri.startsWith(QLatin1String("file:/"))) {
    if (uri.startsWith(QLatin1String("//"))) {
      uri = QStringLiteral("https:") + uri;
    } else {
      uri = QStringLiteral("https://") + uri;
    }
  }
  return uri;
}

QString parseCoverUri(const QJsonObject &object) {
  QString uri = object.value("coverUri").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  const QJsonObject cover = object.value("cover").toObject();
  uri = cover.value("uri").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  const QJsonArray itemsUri = cover.value("itemsUri").toArray();
  for (const QJsonValue &item : itemsUri) {
    const QString itemUri = item.toString().trimmed();
    if (!itemUri.isEmpty()) {
      return formatCoverUri(itemUri);
    }
  }

  const QJsonArray directItemsUri = object.value("itemsUri").toArray();
  for (const QJsonValue &item : directItemsUri) {
    const QString itemUri = item.toString().trimmed();
    if (!itemUri.isEmpty()) {
      return formatCoverUri(itemUri);
    }
  }

  uri = object.value("animatedCoverUri").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);
  uri = cover.value("animatedCoverUri").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  uri = object.value("ogImage").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);
  uri = cover.value("ogImage").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  const QJsonObject custom = cover.value("custom").toObject();
  uri = custom.value("uri").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  uri = cover.value("dir").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  uri = cover.value("prefix").toString();
  if (!uri.isEmpty()) return formatCoverUri(uri);

  const QJsonArray albums = object.value("albums").toArray();
  for (const QJsonValue &albumVal : albums) {
    if (albumVal.isObject()) {
      const QString albumUri = parseCoverUri(albumVal.toObject());
      if (!albumUri.isEmpty()) {
        return formatCoverUri(albumUri);
      }
    }
  }

  if (object.value("album").isObject()) {
    const QString albumUri = parseCoverUri(object.value("album").toObject());
    if (!albumUri.isEmpty()) {
      return formatCoverUri(albumUri);
    }
  }

  const QJsonArray tracks = object.value("tracks").toArray();
  for (const QJsonValue &tVal : tracks) {
    if (tVal.isObject()) {
      const QJsonObject tObj = tVal.toObject();
      const QJsonObject trk = (tObj.contains("track") && tObj.value("track").isObject())
                                  ? tObj.value("track").toObject()
                                  : tObj;
      const QString trkUri = parseCoverUri(trk);
      if (!trkUri.isEmpty()) {
        return formatCoverUri(trkUri);
      }
    }
  }

  return {};
}

Artist parseArtist(const QJsonObject &object) {
  QJsonObject obj = object;
  if (obj.value("artist").isObject()) {
    obj = obj.value("artist").toObject();
  }

  Artist artist;
  artist.id = parseId(obj);
  artist.name = obj.value("name").toString();
  artist.coverUri = parseCoverUri(obj);
  return artist;
}

Album parseAlbum(const QJsonObject &object) {
  QJsonObject obj = object;
  if (obj.value("album").isObject()) {
    obj = obj.value("album").toObject();
  }

  Album album;
  album.id = parseId(obj);
  album.title = obj.value("title").toString();
  album.coverUri = parseCoverUri(obj);
  album.year = obj.value("year").toInt();
  album.type = obj.value("type").toString().trimmed();
  return album;
}

Track parseTrack(const QJsonObject &object) {
  QJsonObject obj = object;
  if (obj.value("track").isObject()) {
    obj = obj.value("track").toObject();
  }

  Track track;
  track.id = parseId(obj);
  track.title = obj.value("title").toString();
  track.coverUri = parseCoverUri(obj);
  track.durationMs = obj.value("durationMs").toInt();
  // Поле отсутствует у части ответов (очередь, лайки) — считаем трек доступным.
  track.available = obj.value("available").toBool(true);

  // Состояние лайка трека: в некоторых ответах API (плейлисты, станции)
  // есть явное булево поле; иначе оно приходит строкой likeStatus
  // ("LIKE"/"DISLIKE"/"NEUTRAL").
  if (obj.contains(QStringLiteral("liked")) && !obj.value(QStringLiteral("liked")).isNull()) {
    track.liked = obj.value(QStringLiteral("liked")).toBool();
  } else {
    const QString likeStatus = obj.value(QStringLiteral("likeStatus")).toString();
    track.liked = (likeStatus == QLatin1String("LIKE"));
    track.disliked = (likeStatus == QLatin1String("DISLIKE"));
  }

  const QJsonArray artists = obj.value("artists").toArray();
  for (const QJsonValue &value : artists) {
    if (!value.isObject()) continue;
    const Artist artist = parseArtist(value.toObject());
    if (artist.name.isEmpty()) continue;
    track.artists.append(artist);
  }

  const QJsonArray albums = obj.value("albums").toArray();
  for (const QJsonValue &value : albums) {
    if (!value.isObject()) continue;
    const Album album = parseAlbum(value.toObject());
    if (album.title.isEmpty()) continue;
    track.albums.append(album);
  }
  return track;
}

QList<Track> parseTrackArray(const QJsonArray &array) {
  QList<Track> tracks;
  for (const QJsonValue &value : array) {
    if (!value.isObject()) continue;
    const Track track = parseTrack(value.toObject());
    if (track.id.isEmpty()) continue;
    tracks.append(track);
  }
  return tracks;
}

QJsonObject unwrapResult(const QJsonDocument &document) {
  if (!document.isObject()) return {};

  const QJsonObject root = document.object();
  const QJsonValue result = root.value("result");
  if (result.isObject()) {
    return result.toObject();
  }
  return root;
}