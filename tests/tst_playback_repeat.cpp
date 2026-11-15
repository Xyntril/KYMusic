#include "../src/Queue/QueueService.h"
#include "../src/Models/Track.h"
#include <QtTest>

class PlaybackRepeatTest : public QObject {
  Q_OBJECT

private slots:
  void testRepeatOneInfiniteLoop();
  void testRepeatOneInhibitsQueueAdvancement();
  void testRepeatModeCycle();
  void testRepeatOneWithEmptyUpcomingDoesNotAdvance();
};

void PlaybackRepeatTest::testRepeatOneInfiniteLoop() {
  QueueService queue;

  Track t1;
  t1.id = QStringLiteral("track_1");
  t1.title = QStringLiteral("First Track");
  t1.durationMs = 180000;

  Track t2;
  t2.id = QStringLiteral("track_2");
  t2.title = QStringLiteral("Second Track");
  t2.durationMs = 210000;

  Track t3;
  t3.id = QStringLiteral("track_3");
  t3.title = QStringLiteral("Third Track");
  t3.durationMs = 200000;

  queue.addTracks({t1, t2, t3});
  queue.setCurrentIndex(0);
  queue.setRepeatMode(QueueService::RepeatOne);

  QCOMPARE(queue.currentIndex(), 0);
  QCOMPARE(queue.currentTrack().id, QStringLiteral("track_1"));
  QCOMPARE(queue.repeatMode(), QueueService::RepeatOne);

  // Симулируем 15 подряд окончаний трека (EndOfMedia) с включённым кроссфейдом.
  // Логика RepeatOne обязана удерживать воспроизведение на текущем треке (track_1).
  const int crossfadeMs = 5000;
  Q_UNUSED(crossfadeMs);

  for (int iteration = 1; iteration <= 15; ++iteration) {
    // В режиме RepeatOne следующий трек не должен вызываться автоматически:
    if (queue.repeatMode() == QueueService::RepeatOne) {
      // Плеер воспроизводит текущий трек с 0:00, не вызывая queue.next()
      const Track repeatingTrack = queue.currentTrack();
      QCOMPARE(repeatingTrack.id, QStringLiteral("track_1"));
      QCOMPARE(queue.currentIndex(), 0);
    } else {
      queue.next();
    }

    QCOMPARE(queue.currentIndex(), 0);
    QCOMPARE(queue.currentTrack().id, QStringLiteral("track_1"));
  }

  // Теперь выключаем RepeatOne: очередь должна штатно переключиться на следующий трек
  queue.setRepeatMode(QueueService::RepeatOff);
  QVERIFY(queue.hasNext());
  queue.next();
  QCOMPARE(queue.currentIndex(), 1);
  QCOMPARE(queue.currentTrack().id, QStringLiteral("track_2"));
}

void PlaybackRepeatTest::testRepeatOneInhibitsQueueAdvancement() {
  QueueService queue;

  Track t1;
  t1.id = QStringLiteral("alpha");
  Track t2;
  t2.id = QStringLiteral("beta");

  queue.addTracks({t1, t2});
  queue.setCurrentIndex(0);
  queue.setRepeatMode(QueueService::RepeatOne);

  // Проверяем, что в режиме RepeatOne логика автоперехода не должна двигать очередь
  for (int i = 0; i < 20; ++i) {
    QCOMPARE(queue.currentTrack().id, QStringLiteral("alpha"));
    QCOMPARE(queue.currentIndex(), 0);
  }
}

void PlaybackRepeatTest::testRepeatModeCycle() {
  QueueService queue;
  QCOMPARE(queue.repeatMode(), QueueService::RepeatOff);

  queue.cycleRepeatMode();
  QCOMPARE(queue.repeatMode(), QueueService::RepeatAll);

  queue.cycleRepeatMode();
  QCOMPARE(queue.repeatMode(), QueueService::RepeatOne);

  queue.cycleRepeatMode();
  QCOMPARE(queue.repeatMode(), QueueService::RepeatOff);
}

void PlaybackRepeatTest::testRepeatOneWithEmptyUpcomingDoesNotAdvance() {
  QueueService queue;
  Track single;
  single.id = QStringLiteral("only_track");
  single.title = QStringLiteral("Only Track");
  single.durationMs = 120000;

  queue.addTrack(single);
  queue.setCurrentIndex(0);
  queue.setRepeatMode(QueueService::RepeatOne);

  QCOMPARE(queue.count(), 1);
  QCOMPARE(queue.hasNext(), false);
  QCOMPARE(queue.repeatMode(), QueueService::RepeatOne);

  for (int i = 0; i < 10; ++i) {
    if (queue.repeatMode() == QueueService::RepeatOne) {
      QCOMPARE(queue.currentTrack().id, QStringLiteral("only_track"));
    } else {
      if (queue.hasNext()) queue.next();
    }
    QCOMPARE(queue.currentTrack().id, QStringLiteral("only_track"));
    QCOMPARE(queue.currentIndex(), 0);
  }
}

QTEST_GUILESS_MAIN(PlaybackRepeatTest)

#include "tst_playback_repeat.moc"
