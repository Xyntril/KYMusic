package org.kde.kymusic;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public class KYMusicPlaybackService extends Service {
    private static final String TAG = "KYMusicPlaybackService";
    private static KYMusicPlaybackService sInstance = null;

    public static KYMusicPlaybackService getInstance() {
        return sInstance;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        sInstance = this;
        Log.i(TAG, "KYMusicPlaybackService created");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        sInstance = null;
        super.onDestroy();
        Log.i(TAG, "KYMusicPlaybackService destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
