#include "../src/Yandex/Parsers.h"
#include "../src/Yandex/Personal/LibraryPlaylistsModel.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSignalSpy>
#include <QTest>

class PlaylistCoverTest : public QObject {
  Q_OBJECT

private slots:
  void testTrackAlbumCoverParsing();
  void testPlaylistTracksCoverFallback();
  void testLibraryPlaylistsModelCoverUpdate();
};

void PlaylistCoverTest::testTrackAlbumCoverParsing() {
  // Имитация JSON трека ASGORE с обложкой внутри albums
  const QString jsonStr = R"({
    "id": 123456,
    "title": "ASGORE",
    "albums": [
      {
        "id": 789,
        "title": "UNDERTALE Soundtrack",
        "coverUri": "avatars.yandex.net/get-music-content/12345/67890/%%"
      }
    ]
  })";

  const QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
  QVERIFY(doc.isObject());

  const QString coverUri = parseCoverUri(doc.object());
  QVERIFY(!coverUri.isEmpty());
  QCOMPARE(coverUri, QString("https://avatars.yandex.net/get-music-content/12345/67890/400x400"));

  const Track track = parseTrack(doc.object());
  QCOMPARE(track.title, QString("ASGORE"));
  QCOMPARE(track.coverUri, QString("https://avatars.yandex.net/get-music-content/12345/67890/400x400"));
}

void PlaylistCoverTest::testPlaylistTracksCoverFallback() {
  // Имитация плейлиста «Всё» с 10 треками, где у самого плейлиста coverUri пустой,
  // но у первого трека в tracks есть обложка в albums
  const QString jsonStr = R"({
    "uid": 424242,
    "kind": 3,
    "title": "Всё",
    "trackCount": 10,
    "tracks": [
      {
        "id": 1001,
        "track": {
          "id": 1001,
          "title": "ASGORE",
          "albums": [
            {
              "id": 789,
              "title": "UNDERTALE Soundtrack",
              "coverUri": "avatars.yandex.net/get-music-content/999/888/%%"
            }
          ]
        }
      }
    ]
  })";

  const QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
  QVERIFY(doc.isObject());

  const QString coverUri = parseCoverUri(doc.object());
  QVERIFY(!coverUri.isEmpty());
  QCOMPARE(coverUri, QString("https://avatars.yandex.net/get-music-content/999/888/400x400"));
}

void PlaylistCoverTest::testLibraryPlaylistsModelCoverUpdate() {
  LibraryPlaylistsModel model;

  PersonalPlaylist p1;
  p1.uid = "424242";
  p1.kind = 3;
  p1.title = "Всё";
  p1.trackCount = 10;
  p1.coverUri = "";

  model.setPlaylists({p1});
  QCOMPARE(model.rowCount(), 1);

  // Проверяем начальные роли
  const QModelIndex idx = model.index(0, 0);
  QCOMPARE(model.data(idx, LibraryPlaylistsModel::TitleRole).toString(), QString("Всё"));
  QCOMPARE(model.data(idx, LibraryPlaylistsModel::TrackCountRole).toInt(), 10);
  QCOMPARE(model.data(idx, LibraryPlaylistsModel::CoverUriRole).toString(), QString(""));
  QCOMPARE(model.data(idx, LibraryPlaylistsModel::CoverUrlRole).toString(), QString(""));

  // Подключаем шпион за dataChanged
  QSignalSpy spy(&model, &QAbstractItemModel::dataChanged);

  // Обновляем обложку
  const QString newCover = "https://avatars.yandex.net/get-music-content/999/888/400x400";
  const bool updated = model.updateCoverUri(3, newCover);
  QVERIFY(updated);
  QCOMPARE(spy.count(), 1);

  // Проверяем, что и coverUri, и coverUrl возвращают правильный URL
  QCOMPARE(model.data(idx, LibraryPlaylistsModel::CoverUriRole).toString(), newCover);
  QCOMPARE(model.data(idx, LibraryPlaylistsModel::CoverUrlRole).toString(), newCover);

  // Проверяем roleNames
  const auto roles = model.roleNames();
  QVERIFY(roles.contains(LibraryPlaylistsModel::CoverUriRole));
  QVERIFY(roles.contains(LibraryPlaylistsModel::CoverUrlRole));
  QCOMPARE(roles.value(LibraryPlaylistsModel::CoverUriRole), QByteArray("coverUri"));
  QCOMPARE(roles.value(LibraryPlaylistsModel::CoverUrlRole), QByteArray("coverUrl"));
}

QTEST_MAIN(PlaylistCoverTest)
#include "tst_playlist_cover.moc"
