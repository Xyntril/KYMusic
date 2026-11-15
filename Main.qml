import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform as Platform
import QtCore as QC
import org.kde.kirigami as Kirigami
import YaMusic 1.0

import "Layout"
import "Home"
import "Components"
import "Pages"

Kirigami.ApplicationWindow {
    id: window

    width: 1440
    height: 900
    minimumWidth: 360
    minimumHeight: 480
    visible: true
    title: qsTr("KYMusic")
    color: AppTheme.background

    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    // int вместо двух bool, чтобы исключить противоречивые
    // комбинации (открыты оба оверлея сразу)
    readonly property int overlayNone: 0
    readonly property int overlayNowPlaying: 1
    readonly property int overlayLyrics: 2

    QC.Settings {
        id: windowSettings
        category: "ui"
        property bool showMenuBar: false
        property bool ambientGlow: true
        property string layoutMode: "auto"
    }

    readonly property string layoutModeChoice: windowSettings.layoutMode
    readonly property bool isMobileMode: (layoutModeChoice === "mobile") || (layoutModeChoice === "auto" && (Kirigami.Settings.isMobile || window.width < Kirigami.Units.gridUnit * 38))
    readonly property bool ambientGlowEnabled: windowSettings.ambientGlow

    property int activeOverlay: overlayNone
    property bool showMenuBar: windowSettings.showMenuBar
    property alias sidebarVisible: mainLayout.sidebarVisible

    Shortcut {
        sequence: "Ctrl+M"
        enabled: !window.isMobileMode
        onActivated: {
            window.showMenuBar = !window.showMenuBar
            windowSettings.showMenuBar = window.showMenuBar
        }
    }

    Shortcut {
        sequences: ["Ctrl+Shift+,", "Ctrl+,"]
        onActivated: mainLayout.selectSection("settings")
    }

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (window.visibility === Window.FullScreen) {
                window.showNormal()
            } else {
                window.showFullScreen()
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: Qt.quit()
    }

    menuBar: QQC2.MenuBar {
        id: appMenuBar
        visible: window.showMenuBar && !window.isMobileMode

        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Header

        delegate: QQC2.MenuBarItem {
            id: menuBarItem

            Kirigami.Theme.inherit: true

            leftPadding: 10
            rightPadding: 10
            topPadding: 5
            bottomPadding: 5

            font: Kirigami.Theme.defaultFont

            readonly property bool isActive: menuBarItem.highlighted || menuBarItem.down || (menuBarItem.menu && menuBarItem.menu.visible)

            contentItem: QQC2.Label {
                text: menuBarItem.text.replace(/&([^&])/g, "$1")
                font: menuBarItem.font
                opacity: menuBarItem.enabled ? 1.0 : 0.4
                color: menuBarItem.isActive ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: 4
                color: menuBarItem.isActive
                    ? Kirigami.Theme.highlightColor
                    : "transparent"
            }
        }

        QQC2.Menu {
            title: qsTr("&Файл")

            QQC2.Action {
                text: qsTr("Скачать текущий трек")
                icon.name: "download"
                enabled: String(appController.currentTrackTitle || "").length > 0
                onTriggered: appController.downloadCurrentTrack()
            }

            QQC2.MenuSeparator {}

            QQC2.Action {
                text: qsTr("Выход")
                icon.name: "application-exit"
                shortcut: "Ctrl+Q"
                onTriggered: Qt.quit()
            }
        }

        QQC2.Menu {
            title: qsTr("&Правка")

            QQC2.Action {
                text: qsTr("Копировать название трека")
                icon.name: "edit-copy"
                shortcut: "Ctrl+C"
                onTriggered: appController.copyCurrentTrackTitle()
            }

            QQC2.Action {
                text: qsTr("Найти")
                icon.name: "edit-find"
                shortcut: "Ctrl+F"
                onTriggered: mainLayout.selectSection("search")
            }
        }

        QQC2.Menu {
            title: qsTr("&Вид")

            QQC2.Action {
                text: qsTr("Показать боковую панель")
                icon.name: "view-sidetree"
                checkable: true
                checked: window.sidebarVisible
                onTriggered: window.sidebarVisible = !window.sidebarVisible
            }

            QQC2.Action {
                text: qsTr("Показать текст песни")
                icon.name: "view-media-lyrics"
                onTriggered: {
                    appController.lyricsController.loadLyrics()
                    lyricsViewOverlay.activePane = "lyrics"
                    window.activeOverlay = window.overlayLyrics
                }
            }

            QQC2.Action {
                text: qsTr("Полноэкранный режим")
                icon.name: window.visibility === Window.FullScreen ? "view-restore" : "view-fullscreen"
                shortcut: "F11"
                onTriggered: {
                    if (window.visibility === Window.FullScreen) {
                        window.showNormal()
                    } else {
                        window.showFullScreen()
                    }
                }
            }

            QQC2.Action {
                text: qsTr("Обновить страницу")
                icon.name: "view-refresh"
                shortcut: "F5"
                onTriggered: mainLayout.selectSection(mainLayout.currentSection)
            }
        }

        QQC2.Menu {
            title: qsTr("&Переход")

            QQC2.Action {
                text: qsTr("Главная")
                icon.name: "go-home"
                onTriggered: mainLayout.selectSection("home")
            }

            QQC2.Action {
                text: qsTr("Моя волна")
                icon.name: "network-wireless"
                onTriggered: mainLayout.selectSection("wave")
            }

            QQC2.Action {
                text: qsTr("Новые релизы")
                icon.name: "view-media-recent"
                onTriggered: mainLayout.selectSection("releases")
            }

            QQC2.Action {
                text: qsTr("Жанры")
                icon.name: "view-media-genre"
                onTriggered: mainLayout.selectSection("genres")
            }

            QQC2.Action {
                text: qsTr("Станции")
                icon.name: "radio"
                onTriggered: mainLayout.selectSection("stations")
            }

            QQC2.Action {
                text: qsTr("Подкасты")
                icon.name: "podcast-amarok"
                onTriggered: mainLayout.selectSection("podcasts")
            }

            QQC2.Action {
                text: qsTr("Плейлисты")
                icon.name: "view-media-playlist"
                onTriggered: mainLayout.selectSection("playlists")
            }

            QQC2.Action {
                text: qsTr("Мне нравится")
                icon.name: "starred-symbolic"
                onTriggered: mainLayout.selectSection("liked")
            }

            QQC2.Action {
                text: qsTr("Статистика")
                icon.name: "view-statistics"
                onTriggered: mainLayout.selectSection("stats")
            }
        }

        QQC2.Menu {
            title: qsTr("&Воспроизведение")

            QQC2.Action {
                text: qsTr("Воспроизвести / Пауза")
                icon.name: appController.playing ? "media-playback-pause" : "media-playback-start"
                shortcut: "Space"
                onTriggered: {
                    if (appController.playing) {
                        appController.pause()
                    } else {
                        appController.play()
                    }
                }
            }

            QQC2.Action {
                text: qsTr("Следующий трек")
                icon.name: "media-skip-forward"
                onTriggered: appController.next()
            }

            QQC2.Action {
                text: qsTr("Предыдущий трек")
                icon.name: "media-skip-backward"
                onTriggered: appController.previous()
            }

            QQC2.Action {
                text: qsTr("Перемешать")
                icon.name: "media-playlist-shuffle"
                checkable: true
                checked: appController.shuffleEnabled
                onTriggered: appController.toggleShuffle()
            }

            QQC2.Action {
                text: qsTr("Повтор")
                icon.name: "media-playlist-repeat"
                checkable: true
                checked: appController.repeatMode !== 0
                onTriggered: appController.cycleRepeat()
            }

            QQC2.MenuSeparator {}

            QQC2.Action {
                text: qsTr("Очистить кэш треков")
                icon.name: "edit-clear"
                onTriggered: appController.preloadController.clearCache()
            }
        }

        QQC2.Menu {
            title: qsTr("&Настройка")

            QQC2.Action {
                text: qsTr("Показывать строку меню")
                icon.name: "show-menu"
                shortcut: "Ctrl+M"
                checkable: true
                checked: window.showMenuBar
                enabled: !window.isMobileMode
                onTriggered: window.showMenuBar = !window.showMenuBar
            }

            QQC2.Action {
                text: qsTr("Параметры KYMusic")
                icon.name: "configure"
                shortcut: "Ctrl+Shift+,"
                onTriggered: mainLayout.selectSection("settings")
            }
        }

        QQC2.Menu {
            title: qsTr("&Справка")

            QQC2.Action {
                text: qsTr("О программе KYMusic")
                icon.name: "kymusic"
                onTriggered: appController.showAboutAppDialog()
            }

            QQC2.Action {
                text: qsTr("О среде KDE")
                icon.name: "kde"
                onTriggered: appController.showAboutKdeDialog()
            }
        }
    }

    // Экспорт нативного меню платформы для KDE Plasma (Global Menu по D-Bus)
    Platform.MenuBar {
        Platform.Menu {
            title: qsTr("Файл")

            Platform.MenuItem {
                text: qsTr("Скачать текущий трек")
                icon.name: "download"
                enabled: String(appController.currentTrackTitle || "").length > 0
                onTriggered: appController.downloadCurrentTrack()
            }

            Platform.MenuSeparator {}

            Platform.MenuItem {
                text: qsTr("Выход")
                icon.name: "application-exit"
                shortcut: "Ctrl+Q"
                onTriggered: Qt.quit()
            }
        }

        Platform.Menu {
            title: qsTr("Правка")

            Platform.MenuItem {
                text: qsTr("Копировать название трека")
                icon.name: "edit-copy"
                shortcut: "Ctrl+C"
                onTriggered: appController.copyCurrentTrackTitle()
            }

            Platform.MenuItem {
                text: qsTr("Найти")
                icon.name: "edit-find"
                shortcut: "Ctrl+F"
                onTriggered: mainLayout.selectSection("search")
            }
        }

        Platform.Menu {
            title: qsTr("Вид")

            Platform.MenuItem {
                text: qsTr("Показать боковую панель")
                checkable: true
                checked: window.sidebarVisible
                onTriggered: window.sidebarVisible = !window.sidebarVisible
            }

            Platform.MenuItem {
                text: qsTr("Показать текст песни")
                icon.name: "view-media-lyrics"
                onTriggered: {
                    appController.lyricsController.loadLyrics()
                    lyricsViewOverlay.activePane = "lyrics"
                    window.activeOverlay = window.overlayLyrics
                }
            }

            Platform.MenuItem {
                text: qsTr("Полноэкранный режим")
                shortcut: "F11"
                onTriggered: {
                    if (window.visibility === Window.FullScreen) {
                        window.showNormal()
                    } else {
                        window.showFullScreen()
                    }
                }
            }

            Platform.MenuItem {
                text: qsTr("Обновить страницу")
                shortcut: "F5"
                onTriggered: mainLayout.selectSection(mainLayout.currentSection)
            }
        }

        Platform.Menu {
            title: qsTr("Переход")

            Platform.MenuItem {
                text: qsTr("Главная")
                icon.name: "go-home"
                onTriggered: mainLayout.selectSection("home")
            }

            Platform.MenuItem {
                text: qsTr("Моя волна")
                icon.name: "network-wireless"
                onTriggered: mainLayout.selectSection("wave")
            }

            Platform.MenuItem {
                text: qsTr("Новые релизы")
                icon.name: "view-media-recent"
                onTriggered: mainLayout.selectSection("releases")
            }

            Platform.MenuItem {
                text: qsTr("Жанры")
                icon.name: "view-media-genre"
                onTriggered: mainLayout.selectSection("genres")
            }

            Platform.MenuItem {
                text: qsTr("Станции")
                icon.name: "radio"
                onTriggered: mainLayout.selectSection("stations")
            }

            Platform.MenuItem {
                text: qsTr("Подкасты")
                icon.name: "podcast-amarok"
                onTriggered: mainLayout.selectSection("podcasts")
            }

            Platform.MenuItem {
                text: qsTr("Плейлисты")
                icon.name: "view-media-playlist"
                onTriggered: mainLayout.selectSection("playlists")
            }

            Platform.MenuItem {
                text: qsTr("Мне нравится")
                icon.name: "starred-symbolic"
                onTriggered: mainLayout.selectSection("liked")
            }

            Platform.MenuItem {
                text: qsTr("Статистика")
                icon.name: "view-statistics"
                onTriggered: mainLayout.selectSection("stats")
            }
        }

        Platform.Menu {
            title: qsTr("Воспроизведение")

            Platform.MenuItem {
                text: appController.playing ? qsTr("Пауза") : qsTr("Воспроизвести")
                icon.name: appController.playing ? "media-playback-pause" : "media-playback-start"
                shortcut: "Space"
                onTriggered: {
                    if (appController.playing) {
                        appController.pause()
                    } else {
                        appController.play()
                    }
                }
            }

            Platform.MenuItem {
                text: qsTr("Следующий трек")
                icon.name: "media-skip-forward"
                onTriggered: appController.next()
            }

            Platform.MenuItem {
                text: qsTr("Предыдущий трек")
                icon.name: "media-skip-backward"
                onTriggered: appController.previous()
            }

            Platform.MenuItem {
                text: qsTr("Перемешать")
                icon.name: "media-playlist-shuffle"
                checkable: true
                checked: appController.shuffleEnabled
                onTriggered: appController.toggleShuffle()
            }

            Platform.MenuItem {
                text: qsTr("Повтор")
                icon.name: "media-playlist-repeat"
                checkable: true
                checked: appController.repeatMode !== 0
                onTriggered: appController.cycleRepeat()
            }

            Platform.MenuSeparator {}

            Platform.MenuItem {
                text: qsTr("Очистить кэш треков")
                icon.name: "edit-clear"
                onTriggered: appController.preloadController.clearCache()
            }
        }

        Platform.Menu {
            title: qsTr("Настройка")

            Platform.MenuItem {
                text: qsTr("Показывать строку меню")
                icon.name: "show-menu"
                shortcut: "Ctrl+M"
                checkable: true
                checked: window.showMenuBar
                onTriggered: window.showMenuBar = !window.showMenuBar
            }

            Platform.MenuItem {
                text: qsTr("Параметры KYMusic")
                icon.name: "configure"
                shortcut: "Ctrl+Shift+,"
                onTriggered: mainLayout.selectSection("settings")
            }
        }

        Platform.Menu {
            title: qsTr("Справка")

            Platform.MenuItem {
                text: qsTr("О программе KYMusic")
                icon.name: "kymusic"
                onTriggered: appController.showAboutAppDialog()
            }

            Platform.MenuItem {
                text: qsTr("О среде KDE")
                icon.name: "kde"
                onTriggered: appController.showAboutKdeDialog()
            }
        }
    }

    Connections {
        target: appController.themeController

        function onDarkThemeChanged() {
            AppTheme.dark = appController.themeController.darkTheme
        }

        function onPaletteChanged() {
            AppTheme.dark = appController.themeController.darkTheme
        }

        function onThemeModeChanged() {
            AppTheme.dark = appController.themeController.darkTheme
        }
    }

    Component.onCompleted: {
        AppTheme.themeController = appController.themeController
        AppTheme.dark = appController.themeController.darkTheme
    }

    Connections {
        target: appController

        function onStatusChanged(message) {
            statusBar.show(message)
        }

        function onSettingsRequested() {
            mainLayout.selectSection("settings")
        }

        function onRaiseRequested() {
            window.show()
            window.raise()
            window.requestActivate()
        }
    }

    // Только когда не авторизован
    Loader {
        anchors.fill: parent

        active: !authController.authenticated
        source: active ? "Pages/LoginPage.qml" : ""
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: (appMenuBar && appMenuBar.visible) ? appMenuBar.height : 0
        visible: authController.authenticated &&
            window.activeOverlay === window.overlayNone

        MainLayout {
            id: mainLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: window.isMobileMode ? mobileBottomArea.top : nowPlayingBar.top

            controller: appController
            authController: authController

            onCrashReportsRequested: crashReportsDialog.open()
        }

        // Десктопный плеер-бар
        NowPlayingBar {
            id: nowPlayingBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 96
            visible: !window.isMobileMode

            controller: appController

            onExpandedRequested: {
                appController.lyricsController.loadLyrics()
                if (window.isMobileMode) {
                    lyricsViewOverlay.activePane = "player"
                } else if (lyricsViewOverlay.activePane !== "queue" && lyricsViewOverlay.activePane !== "similar") {
                    lyricsViewOverlay.activePane = "lyrics"
                }
                window.activeOverlay = window.overlayLyrics
            }
            onLyricsRequested: {
                appController.lyricsController.loadLyrics()
                lyricsViewOverlay.activePane = "lyrics"
                window.activeOverlay = window.overlayLyrics
            }
            onMiniPlayerRequested: {
                window.hide()
                miniPlayer.showPlayer()
            }
        }

        // Мобильный блок управления: компактный мини-бар (56px) + NavigationTabBar
        Column {
            id: mobileBottomArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: window.isMobileMode
            spacing: 0

            // Сверхкомпактный мобильный мини-бар плеера (высота 56px)
            Item {
                id: mobilePlayerBar
                width: parent.width
                height: 56
                visible: String(appController.currentTrackTitle || "").length > 0

                Rectangle {
                    anchors.fill: parent
                    color: Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                }

                AmbientGlow {
                    anchors.fill: parent
                    coverUri: String(appController.currentTrackCoverUri || "")
                    glowOpacity: 0.16
                }

                // Тонкий индикатор прогресса воспроизведения снизу
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    height: 2.5
                    width: (appController.duration > 0) ? (parent.width * (appController.position / appController.duration)) : 0
                    color: Kirigami.Theme.highlightColor
                    z: 2
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    // Область клика по обложке и заголовкам трека для открытия мобильного плеера
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                radius: 4
                                clip: true
                                color: AppTheme.artworkPlaceholder

                                Image {
                                    anchors.fill: parent
                                    source: appController.currentTrackCoverUri ? ("image://yandex/" + appController.currentTrackCoverUri) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    cache: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: appController.currentTrackTitle.length > 0 ? appController.currentTrackTitle : qsTr("Нет трека")
                                    font.weight: Font.DemiBold
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: appController.currentTrackArtist
                                    font.pixelSize: 11
                                    color: Kirigami.Theme.disabledTextColor
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    visible: text.length > 0
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appController.lyricsController.loadLyrics()
                                lyricsViewOverlay.activePane = "player"
                                window.activeOverlay = window.overlayLyrics
                            }
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: appController.currentTrackLiked ? "starred-symbolic" : "non-starred-symbolic"
                        checkable: true
                        checked: appController.currentTrackLiked
                        onClicked: {
                            if (String(appController.currentTrackId || "").length > 0) {
                                appController.toggleLike(String(appController.currentTrackId), appController.currentTrackLiked)
                            }
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: appController.playing ? "media-playback-pause" : "media-playback-start"
                        icon.width: 28
                        icon.height: 28
                        onClicked: {
                            if (appController.playing) appController.pause()
                            else appController.play()
                        }
                    }
                }

                // Свайп вверх по бару открывает полноэкранный мобильный плеер
                DragHandler {
                    target: null
                    xAxis.enabled: false
                    yAxis.enabled: true
                    onActiveChanged: {
                        if (!active && translation.y < -20) {
                            appController.lyricsController.loadLyrics()
                            lyricsViewOverlay.activePane = "player"
                            window.activeOverlay = window.overlayLyrics
                        }
                    }
                }
            }

            // Нативная нижняя навигационная панель Kirigami для смартфонов Plasma Mobile
            Kirigami.NavigationTabBar {
                id: mobileNavTabBar
                width: parent.width

                Component.onCompleted: fixLabels()
                onWidthChanged: fixLabels()

                function fixLabels() {
                    function recurse(item) {
                        if (item.wrapMode !== undefined) {
                            item.wrapMode = Text.NoWrap
                            item.maximumLineCount = 1
                            item.elide = Text.ElideRight
                        }
                        for (let i = 0; i < item.children.length; ++i) {
                            recurse(item.children[i])
                        }
                    }
                    recurse(mobileNavTabBar)
                }

                actions: [
                    Kirigami.Action {
                        text: qsTr("Главная")
                        icon.name: "go-home"
                        checked: mainLayout.currentSection === "home"
                        onTriggered: mainLayout.selectSection("home")
                    },
                    Kirigami.Action {
                        text: qsTr("Волна")
                        icon.name: "network-wireless"
                        checked: mainLayout.currentSection === "wave"
                        onTriggered: mainLayout.selectSection("wave")
                    },
                    Kirigami.Action {
                        text: qsTr("Поиск")
                        icon.name: "search"
                        checked: mainLayout.currentSection === "search"
                        onTriggered: mainLayout.selectSection("search")
                    },
                    Kirigami.Action {
                        text: qsTr("Медиатека")
                        icon.name: "folder-music"
                        checked: mainLayout.currentSection === "library" || mainLayout.currentSection === "liked" || mainLayout.currentSection === "playlists"
                        onTriggered: mainLayout.selectSection("library")
                    }
                ]
            }
        }
    }

    // Тексты песен и полноэкранный мобильный плеер
    LyricsView {
        id: lyricsViewOverlay
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        anchors.topMargin: (appMenuBar && appMenuBar.visible) ? appMenuBar.height : 0
        z: 100
        focus: visible

        visible: authController.authenticated &&
            window.activeOverlay === window.overlayLyrics

        controller: appController

        onClosed: window.activeOverlay = window.overlayNone
    }

    // Мини-плеер как отдельное окно поверх других окон.
    MiniPlayer {
        id: miniPlayer

        controller: appController

        onExpandedRequested: {
            miniPlayer.hidePlayer()
            window.show()
            appController.lyricsController.loadLyrics()
            if (window.isMobileMode) {
                lyricsViewOverlay.activePane = "player"
            }
            window.activeOverlay = window.overlayLyrics
        }
        onExpandRequested: {
            miniPlayer.hidePlayer()
            window.show()
            appController.lyricsController.loadLyrics()
            if (window.isMobileMode) {
                lyricsViewOverlay.activePane = "player"
            }
            window.activeOverlay = window.overlayLyrics
        }
        onCloseRequested: {
            miniPlayer.hidePlayer()
            window.show()
        }
    }

    StatusBar {
        id: statusBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.isMobileMode ? (mobileBottomArea.height + 8) : (nowPlayingBar.height + 8)
        anchors.horizontalCenter: parent.horizontalCenter
        z: 99
    }

    // Отчёты о падениях: диалог живёт в окне, а не в топбаре, — тогда он
    // открывается после падения и до входа в аккаунт тоже.
    CrashReportsDialog {
        id: crashReportsDialog

        controller: appController
    }
}
