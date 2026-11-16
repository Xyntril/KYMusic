package org.kde.kymusic;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

public class MediaNotificationHelper {
    private static final String TAG = "KYMusicMediaNotify";
    private static final String CHANNEL_ID = "kymusic_playback_channel";
    private static final int NOTIFICATION_ID = 4242;

    public static native void nativeOnPlay();
    public static native void nativeOnPause();
    public static native void nativeOnToggle();
    public static native void nativeOnNext();
    public static native void nativeOnPrev();
    public static native void nativeOnStop();
    public static native void nativeOnSeek(long posMs);

    public static void onNativePlay() { nativeOnPlay(); }
    public static void onNativePause() { nativeOnPause(); }
    public static void onNativeToggle() { nativeOnToggle(); }
    public static void onNativeNext() { nativeOnNext(); }
    public static void onNativePrev() { nativeOnPrev(); }
    public static void onNativeStop() { nativeOnStop(); }

    private static void createNotificationChannel(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                NotificationChannel channel = nm.getNotificationChannel(CHANNEL_ID);
                if (channel == null) {
                    channel = new NotificationChannel(
                        CHANNEL_ID,
                        "KYMusic Playback",
                        NotificationManager.IMPORTANCE_LOW
                    );
                    channel.setDescription("KYMusic Media Playback Controls");
                    channel.setShowBadge(false);
                    channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
                    nm.createNotificationChannel(channel);
                }
            }
        }
    }

    public static void updateNotification(String title, String artist, String album, boolean isPlaying) {
        try {
            Context context = getContext();
            if (context == null) {
                Log.w(TAG, "Context is null, cannot update notification");
                return;
            }

            createNotificationChannel(context);

            NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) return;

            Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            int flags = PendingIntent.FLAG_UPDATE_CURRENT;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags |= PendingIntent.FLAG_IMMUTABLE;
            }
            PendingIntent contentIntent = null;
            if (launchIntent != null) {
                launchIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                contentIntent = PendingIntent.getActivity(context, 0, launchIntent, flags);
            }

            PendingIntent prevIntent = PendingIntent.getBroadcast(
                context, 1, new Intent(MediaNotificationReceiver.ACTION_PREV).setPackage(context.getPackageName()), flags);
            PendingIntent toggleIntent = PendingIntent.getBroadcast(
                context, 2, new Intent(MediaNotificationReceiver.ACTION_TOGGLE).setPackage(context.getPackageName()), flags);
            PendingIntent nextIntent = PendingIntent.getBroadcast(
                context, 3, new Intent(MediaNotificationReceiver.ACTION_NEXT).setPackage(context.getPackageName()), flags);

            String subtitle = artist;
            if (album != null && !album.isEmpty()) {
                if (subtitle != null && !subtitle.isEmpty()) {
                    subtitle = subtitle + " — " + album;
                } else {
                    subtitle = album;
                }
            }

            Notification.Builder builder;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder = new Notification.Builder(context, CHANNEL_ID);
            } else {
                builder = new Notification.Builder(context);
            }

            int toggleIcon = isPlaying ? android.R.drawable.ic_media_pause : android.R.drawable.ic_media_play;
            String toggleText = isPlaying ? "Пауза" : "Воспроизведение";

            builder.setContentTitle(title)
                   .setContentText(subtitle)
                   .setSmallIcon(android.R.drawable.ic_media_play)
                   .setContentIntent(contentIntent)
                   .setOngoing(isPlaying)
                   .setVisibility(Notification.VISIBILITY_PUBLIC)
                   .addAction(new Notification.Action.Builder(
                       android.R.drawable.ic_media_previous, "Назад", prevIntent).build())
                   .addAction(new Notification.Action.Builder(
                       toggleIcon, toggleText, toggleIntent).build())
                   .addAction(new Notification.Action.Builder(
                       android.R.drawable.ic_media_next, "Вперёд", nextIntent).build());

            Notification.MediaStyle mediaStyle = new Notification.MediaStyle();
            mediaStyle.setShowActionsInCompactView(0, 1, 2);
            builder.setStyle(mediaStyle);

            Notification notification = builder.build();

            KYMusicPlaybackService service = KYMusicPlaybackService.getInstance();
            if (service != null && isPlaying) {
                try {
                    service.startForeground(NOTIFICATION_ID, notification);
                } catch (Exception e) {
                    Log.w(TAG, "startForeground on service failed, falling back to notify", e);
                    nm.notify(NOTIFICATION_ID, notification);
                }
            } else {
                nm.notify(NOTIFICATION_ID, notification);
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error updating media notification", t);
        }
    }

    public static void stopNotification() {
        try {
            Context context = getContext();
            if (context == null) return;

            NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null) {
                nm.cancel(NOTIFICATION_ID);
            }

            KYMusicPlaybackService service = KYMusicPlaybackService.getInstance();
            if (service != null) {
                service.stopForeground(true);
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error stopping media notification", t);
        }
    }

    private static Context getContext() {
        KYMusicPlaybackService service = KYMusicPlaybackService.getInstance();
        if (service != null) return service;
        try {
            Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
            Object currentActivityThread = activityThreadClass.getMethod("currentActivityThread").invoke(null);
            Object app = activityThreadClass.getMethod("getApplication").invoke(currentActivityThread);
            if (app instanceof Context) {
                return (Context) app;
            }
        } catch (Throwable ignored) {}
        return null;
    }
}
