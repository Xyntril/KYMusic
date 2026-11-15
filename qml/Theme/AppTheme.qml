pragma Singleton

import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    id: theme

    // Ссылка на ThemeController из C++
    property var themeController: null

    // Режим темы — строго 100% системная тема KDE Plasma (Breeze, Oxygen и др.)
    readonly property string themeMode: "system"
    readonly property bool isSystem: true

    // false = Светлая, true = Тёмная (из системной палитры KDE Plasma)
    property bool dark:
        themeController ? themeController.darkTheme : false

    // ============================================================
    // Семантические системные цвета KDE Plasma / Breeze HIG
    // ============================================================

    readonly property color backgroundPrimary:
        themeController ? themeController.systemWindowBackground : Kirigami.Theme.backgroundColor

    readonly property color background:
        backgroundPrimary

    readonly property color backgroundSecondary:
        themeController ? themeController.systemAlternateBackground : Kirigami.Theme.alternateBackgroundColor

    readonly property color backgroundTertiary:
        themeController ? themeController.systemViewBackground : Kirigami.Theme.viewBackgroundColor

    readonly property color panel:
        themeController ? themeController.systemAlternateBackground : Kirigami.Theme.alternateBackgroundColor

    readonly property color panelSecondary:
        themeController ? themeController.systemViewBackground : Kirigami.Theme.viewBackgroundColor

    readonly property color panelHover:
        themeController ? themeController.systemHoverColor : Qt.rgba(accent.r, accent.g, accent.b, 0.15)

    readonly property color panelActive:
        Qt.rgba(accent.r, accent.g, accent.b, 0.25)

    readonly property color panelSubtle:
        themeController ? themeController.systemAlternateBackground : Kirigami.Theme.alternateBackgroundColor

    readonly property color surface:
        themeController ? themeController.systemViewBackground : Kirigami.Theme.viewBackgroundColor

    readonly property color border:
        themeController ? themeController.systemBorderColor : Kirigami.Theme.separatorColor

    readonly property color borderSubtle:
        Qt.rgba(border.r, border.g, border.b, 0.4)

    readonly property color borderStrong:
        border

    readonly property color borderWeak:
        Qt.rgba(border.r, border.g, border.b, 0.3)

    readonly property color textPrimary:
        themeController ? themeController.systemTextColor : Kirigami.Theme.textColor

    readonly property color textSecondary:
        themeController ? themeController.systemSubtextColor : Kirigami.Theme.disabledTextColor

    readonly property color textTertiary:
        textSecondary

    readonly property color textMuted:
        Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.55)

    readonly property color textDisabled:
        Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.35)

    readonly property color placeholder:
        Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.2)

    readonly property color artworkPlaceholder:
        placeholder

    readonly property color accent:
        themeController ? themeController.systemHighlightColor : Kirigami.Theme.highlightColor

    readonly property color accentHover:
        Qt.lighter(accent, 1.15)

    readonly property color accentSoft:
        Qt.rgba(accent.r, accent.g, accent.b, 0.15)

    readonly property color success:
        Kirigami.Theme.positiveTextColor

    readonly property color warning:
        Kirigami.Theme.neutralTextColor

    readonly property color error:
        Kirigami.Theme.negativeTextColor

    readonly property color info:
        accent

    readonly property color divider:
        themeController ? themeController.systemDividerColor : Kirigami.Theme.separatorColor

    readonly property color accentOn:
        themeController ? themeController.systemHighlightedTextColor : Kirigami.Theme.highlightedTextColor

    readonly property color shadowColor:
        dark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.15)

    readonly property color mauveAccent:
        accent

    function formatTime(ms) {
        return theme.formatDuration(ms)
    }

    function formatDuration(ms) {
        var value = Number(ms)

        if (!isFinite(value) || value <= 0) {
            return "0:00"
        }

        var totalSeconds = Math.floor(value / 1000)
        var minutes = Math.floor(totalSeconds / 60)
        var seconds = totalSeconds % 60

        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }
}
