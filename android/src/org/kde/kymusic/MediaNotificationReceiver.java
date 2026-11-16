package org.kde.kymusic;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class MediaNotificationReceiver extends BroadcastReceiver {
    private static final String TAG = "KYMusicMediaReceiver";

    public static final String ACTION_PLAY = "org.kde.kymusic.ACTION_PLAY";
    public static final String ACTION_PAUSE = "org.kde.kymusic.ACTION_PAUSE";
    public static final String ACTION_TOGGLE = "org.kde.kymusic.ACTION_TOGGLE";
    public static final String ACTION_NEXT = "org.kde.kymusic.ACTION_NEXT";
    public static final String ACTION_PREV = "org.kde.kymusic.ACTION_PREV";
    public static final String ACTION_STOP = "org.kde.kymusic.ACTION_STOP";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) {
            return;
        }

        String action = intent.getAction();
        Log.d(TAG, "Received action: " + action);

        switch (action) {
            case ACTION_PLAY:
                MediaNotificationHelper.onNativePlay();
                break;
            case ACTION_PAUSE:
                MediaNotificationHelper.onNativePause();
                break;
            case ACTION_TOGGLE:
                MediaNotificationHelper.onNativeToggle();
                break;
            case ACTION_NEXT:
                MediaNotificationHelper.onNativeNext();
                break;
            case ACTION_PREV:
                MediaNotificationHelper.onNativePrev();
                break;
            case ACTION_STOP:
                MediaNotificationHelper.onNativeStop();
                break;
            default:
                break;
        }
    }
}
