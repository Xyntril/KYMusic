import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Item {
    id: root

    property var controller: null
    signal closed()

    // Именованное строковое состояние: "lyrics" | "queue" | "player"
    property string activePane: "lyrics"

    // Обратная совместимость для внешних вызовов (десктоп: 0 = Очередь, 1 = Текст)
    property int currentMode: root.activePane === "queue" ? 0 : 1
    onCurrentModeChanged: {
        if (!root.isMobile) {
            root.activePane = (currentMode === 0) ? "queue" : "lyrics"
        }
    }

    // Обратная совместимость для внешних вызовов (мобильный: 0 = Плеер, 1 = Текст, 2 = Очередь)
    property int mobileTab: root.activePane === "player" ? 0 : (root.activePane === "lyrics" ? 1 : 2)
    onMobileTabChanged: {
        if (root.isMobile) {
            root.activePane = (mobileTab === 0) ? "player" : (mobileTab === 1 ? "lyrics" : "queue")
        }
    }

    onIsMobileChanged: {
        if (root.isMobile && root.activePane === "similar") {
            root.activePane = "player"
        }
    }

    property real dragYOffset: 0

    readonly property bool hasController:
        root.controller !== null && root.controller !== undefined

    readonly property bool hasTimedLines:
        root.hasController &&
        root.controller.lyricsController !== null && root.controller.lyricsController !== undefined &&
        root.controller.lyricsController.lyricsLineCount > 0

    readonly property int currentLine:
        root.hasTimedLines
            ? root.controller.lyricsController.currentLyricLine
            : -1

    readonly property string plainText:
        root.hasController &&
        root.controller.lyricsController !== null && root.controller.lyricsController !== undefined
            ? String(root.controller.lyricsController.lyricsText || "").trim()
            : ""

    readonly property string trackTitle:
        root.hasController ? String(root.controller.currentTrackTitle || "") : ""

    readonly property string trackArtist:
        root.hasController ? String(root.controller.currentTrackArtist || "") : ""

    readonly property string trackAlbum:
        root.hasController ? String(root.controller.currentTrackAlbumTitle || "") : ""

    readonly property string coverUri:
        root.hasController ? String(root.controller.currentTrackCoverUri || "") : ""

    readonly property bool playing:
        root.hasController && root.controller.playing

    readonly property int duration:
        root.hasController ? root.controller.duration : 0

    readonly property int position:
        root.hasController ? root.controller.position : 0

    readonly property bool liked:
        root.hasController && root.controller.currentTrackLiked

    readonly property bool disliked: {
        if (!root.hasController) return false
        root.controller.dislikesRevision
        return root.controller.isTrackDisliked(String(root.controller.currentTrackId || ""))
    }

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 760

    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    transform: Translate {
        y: root.dragYOffset
    }

    // Анимации выезда и закрытия мобильной шторки
    NumberAnimation {
        id: openAnim
        target: root
        property: "dragYOffset"
        from: root.height
        to: 0
        duration: 260
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "dragYOffset"
        to: root.height
        duration: 200
        easing.type: Easing.InCubic
        onFinished: {
            root.dragYOffset = 0
            root.closed()
        }
    }

    NumberAnimation {
        id: snapBackAnim
        target: root
        property: "dragYOffset"
        to: 0
        duration: 180
        easing.type: Easing.OutQuad
    }

    function requestClose() {
        if (root.isMobile) {
            closeAnim.start()
        } else {
            root.closed()
        }
    }

    // Базовый фон окна
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
    }

    // Фоновая атмосферная подсветка размытыми цветами текущей обложки (KDE Elisa style)
    AmbientGlow {
        anchors.fill: parent
        coverUri: root.coverUri
        glowOpacity: 0.28
    }

    // Тонкий градиент затемнения для идеальной читаемости текста поверх любых цветов обложки
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.30) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.60) }
        }
    }

    // Горячая клавиша закрытия
    Shortcut {
        sequence: "Escape"
        onActivated: root.requestClose()
    }

    // =========================================================================
    // 1. ДЕСКТОПНЫЙ РЕЖИМ (!root.isMobile) — СТРОГО ДВУХКОЛОНОЧНЫЙ МАКЕТ
    // =========================================================================
    RowLayout {
        id: desktopLayout
        anchors.fill: parent
        anchors.margins: 28
        anchors.topMargin: 20
        spacing: 12
        visible: !root.isMobile

        // ЛЕВАЯ КОЛОНКА (~65% ширины окна)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Сверху панель переключения: [ Список воспроизведения ] | [ Текст песни ] | [ Похожие треки ]
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    implicitHeight: 38
                    implicitWidth: desktopSegButtons.implicitWidth + 8
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.55)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                    RowLayout {
                        id: desktopSegButtons
                        anchors.centerIn: parent
                        spacing: 4

                        QQC2.ToolButton {
                            text: qsTr("Список воспроизведения")
                            icon.name: "view-media-playlist"
                            checkable: true
                            checked: root.activePane === "queue"
                            onClicked: root.activePane = "queue"
                        }

                        QQC2.ToolButton {
                            text: qsTr("Текст песни")
                            icon.name: "view-media-lyrics"
                            checkable: true
                            checked: root.activePane === "lyrics" || root.activePane === "player"
                            onClicked: root.activePane = "lyrics"
                        }

                        QQC2.ToolButton {
                            text: qsTr("Похожие треки")
                            icon.name: "view-media-similarartists-symbolic"
                            icon.color: Kirigami.Theme.textColor
                            checkable: true
                            checked: root.activePane === "similar"
                            onClicked: root.activePane = "similar"
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Контент левой колонки (Текст песни или Очередь)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Контейнер 1: Текст песни (Караоке LRC / Обычный текст / Заглушка)
                Item {
                    id: desktopLyricsContainer
                    anchors.fill: parent
                    visible: root.activePane === "lyrics" || root.activePane === "player"

                    // Синхронизированный LRC текст с выделением активной строки
                    ListView {
                        id: desktopLyricsListView
                        anchors.fill: parent
                        clip: true
                        spacing: 16
                        visible: root.hasTimedLines

                        model: root.hasTimedLines
                            ? root.controller.lyricsController.lyricsLineCount
                            : 0

                        currentIndex: root.currentLine
                        highlightFollowsCurrentItem: true
                        highlightMoveDuration: 380
                        preferredHighlightBegin: height * 0.38
                        preferredHighlightEnd: height * 0.48
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        boundsBehavior: Flickable.StopAtBounds

                        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        policy: QQC2.ScrollBar.AsNeeded
                        width: 3
                        opacity: active ? 0.5 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                        delegate: QQC2.ItemDelegate {
                            id: deskLyricDel
                            required property int index

                            width: desktopLyricsListView.width - 24
                            implicitHeight: deskLyricTxt.implicitHeight + 24
                            readonly property bool isActive: deskLyricDel.index === root.currentLine

                            background: Rectangle {
                                radius: Kirigami.Units.cornerRadius
                                color: deskLyricDel.isActive
                                    ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                    : (deskLyricDel.hovered ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06) : "transparent")
                                border.width: deskLyricDel.isActive ? 1.5 : 0
                                border.color: Kirigami.Theme.highlightColor

                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }

                            contentItem: Text {
                                id: deskLyricTxt
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.controller.lyricsController.lyricLineText(deskLyricDel.index)
                                color: deskLyricDel.isActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                font.pixelSize: deskLyricDel.isActive ? 25 : 18
                                font.weight: deskLyricDel.isActive ? Font.Bold : Font.Normal
                                opacity: deskLyricDel.isActive ? 1.0 : (deskLyricDel.hovered ? 0.85 : 0.45)
                                wrapMode: Text.WordWrap
                                scale: deskLyricDel.isActive ? 1.04 : 1.0
                                transformOrigin: Item.Left

                                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }

                            onClicked: {
                                if (root.controller && root.controller.lyricsController) {
                                    root.controller.lyricsController.seekToLine(deskLyricDel.index)
                                }
                            }
                        }

                        Connections {
                            target: root.hasController ? root.controller.lyricsController : null

                            function onCurrentLyricLineChanged() {
                                if (root.hasTimedLines && root.currentLine >= 0 && root.currentLine < desktopLyricsListView.count) {
                                    desktopLyricsListView.currentIndex = root.currentLine
                                }
                            }

                            function onLyricsChanged() {
                                if (root.hasTimedLines && desktopLyricsListView.count > 0) {
                                    desktopLyricsListView.positionViewAtIndex(0, ListView.Beginning)
                                }
                            }
                        }
                    }

                    // Обычный несинхронизированный текст
                    QQC2.ScrollView {
                        anchors.fill: parent
                        visible: !root.hasTimedLines && root.plainText.length > 0
                        clip: true

                        Text {
                            width: parent.width - 32
                            text: root.plainText
                            color: Kirigami.Theme.textColor
                            font.pixelSize: 19
                            lineHeight: 1.85
                            wrapMode: Text.WordWrap
                            opacity: 0.92
                        }
                    }

                    // Заглушка, если текста нет
                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - 48
                        visible: !root.hasTimedLines && root.plainText.length === 0
                        icon.name: "view-media-lyrics"
                        text: qsTr("Текст для этого трека не найден")
                        explanation: qsTr("Возможно, это инструментальный трек или слова ещё не добавлены в каталог.")
                    }
                }

                // Контейнер 2: Очередь воспроизведения
                Item {
                    id: desktopQueueContainer
                    anchors.fill: parent
                    visible: root.activePane === "queue"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Kirigami.Heading {
                                level: 2
                                text: qsTr("Очередь воспроизведения")
                            }

                            Item { Layout.fillWidth: true }

                            QQC2.Label {
                                text: root.hasController ? qsTr("%1 треков").arg(root.controller.queueCount) : ""
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                            }
                        }

                        ListView {
                            id: desktopQueueListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            boundsBehavior: Flickable.StopAtBounds

                            model: root.hasController ? root.controller.queueCount : 0
                            currentIndex: root.hasController ? root.controller.queueCurrentIndex : -1

                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                                id: desktopQueueScrollBar
                                policy: QQC2.ScrollBar.AsNeeded
                            }

                            delegate: TrackRow {
                                id: deskQueueDel
                                required property int index

                                readonly property var trackData: root.hasController
                                    ? root.controller.queueTrackData(deskQueueDel.index)
                                    : null

                                width: desktopQueueListView.width - (desktopQueueScrollBar.visible ? desktopQueueScrollBar.width + 16 : 16)
                                controller: root.controller
                                rowIndex: deskQueueDel.index
                                trackId: trackData ? String(trackData.id || "") : ""
                                title: trackData ? String(trackData.title || "") : ""
                                artist: trackData ? String(trackData.artist || "") : ""
                                artistId: trackData ? String(trackData.artistId || "") : ""
                                coverUri: trackData ? String(trackData.coverUri || "") : ""
                                durationMs: trackData ? Number(trackData.durationMs || 0) : 0

                                showLike: true
                                showDislike: false
                                showAdd: true

                                onActivated: {
                                    if (root.controller) {
                                        root.controller.selectQueueTrack(deskQueueDel.index)
                                    }
                                }
                            }

                            Kirigami.PlaceholderMessage {
                                anchors.centerIn: parent
                                width: parent.width - 48
                                visible: desktopQueueListView.count === 0
                                icon.name: "view-media-playlist"
                                text: qsTr("Очередь воспроизведения пуста")
                            }
                        }
                    }
                }

                // Контейнер 3: Похожие треки
                Item {
                    id: desktopSimilarContainer
                    anchors.fill: parent
                    visible: root.activePane === "similar"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Kirigami.Heading {
                                level: 2
                                text: qsTr("Похожие треки")
                            }

                            Item { Layout.fillWidth: true }

                            QQC2.Label {
                                text: (root.hasController && root.controller.similarTracksModel)
                                    ? qsTr("%1 треков").arg(root.controller.similarTracksModel.count)
                                    : ""
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                            }
                        }

                        ListView {
                            id: desktopSimilarListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            boundsBehavior: Flickable.StopAtBounds

                            model: root.hasController ? root.controller.similarTracksModel : null

                            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                                id: desktopSimilarScrollBar
                                policy: QQC2.ScrollBar.AsNeeded
                            }

                            delegate: TrackRow {
                                id: deskSimilarDel

                                width: desktopSimilarListView.width - (desktopSimilarScrollBar.visible ? desktopSimilarScrollBar.width + 16 : 16)
                                controller: root.controller
                                rowIndex: index
                                trackId: model.trackId
                                title: model.title
                                artist: model.artist
                                artistId: model.artistId
                                coverUri: model.coverUri
                                durationMs: model.durationMs

                                showLike: true
                                showDislike: false
                                showAdd: true

                                onActivated: {
                                    if (root.controller) {
                                        root.controller.selectSimilarTrack(index)
                                    }
                                }
                            }

                            Kirigami.PlaceholderMessage {
                                anchors.centerIn: parent
                                width: parent.width - 48
                                visible: desktopSimilarListView.count === 0
                                icon.name: "view-media-similarartists"
                                text: qsTr("Похожие треки не найдены")
                            }
                        }
                    }
                }
            }
        }

        // ПРАВАЯ КОЛОНКА (360px - 400px, центрирована по вертикали)
        Item {
            Layout.preferredWidth: 360
            Layout.maximumWidth: 400
            Layout.fillHeight: true

            // Кнопка закрытия ✕ вверху справа
            QQC2.ToolButton {
                anchors.top: parent.top
                anchors.right: parent.right
                icon.name: "window-close"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Закрыть (Esc)")
                onClicked: root.requestClose()
            }

            // Основной центрированный блок управления правой колонки
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 16

                // Квадратная скруглённая обложка (280x280, radius: 10, тонкая рамка Breeze)
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 280
                    Layout.preferredHeight: 280
                    radius: 10
                    color: Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20)
                    clip: true

                    Image {
                        id: desktopCoverImage
                        anchors.fill: parent
                        source: root.coverUri.length > 0 ? ("image://yandex/" + root.coverUri) : ""
                        sourceSize: Qt.size(600, 600)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    QQC2.Label {
                        anchors.centerIn: parent
                        text: "♪"
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: 64
                        visible: desktopCoverImage.status !== Image.Ready
                    }
                }

                // Название трека (жирным, по центру) и исполнитель
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 2
                        text: root.trackTitle.length > 0 ? root.trackTitle : qsTr("Нет трека")
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.Bold
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.trackArtist
                        font.pixelSize: 15
                        color: deskArtistMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        horizontalAlignment: Text.AlignHCenter
                        visible: text.length > 0

                        MouseArea {
                            id: deskArtistMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (root.controller && String(root.controller.currentTrackArtistId || "").length > 0) {
                                    root.requestClose()
                                    root.controller.loadArtist(root.controller.currentTrackArtistId)
                                }
                            }
                        }
                    }
                }

                // КОРОТКИЙ ползунок прогресса со счётчиками времени (0:16 [====o-----] 4:03),
                // строго ограниченный шириной ПРАВОЙ КОЛОНКИ
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    QQC2.Label {
                        Layout.preferredWidth: 38
                        text: AppTheme.formatTime(root.position)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        horizontalAlignment: Text.AlignRight
                    }

                    QQC2.Slider {
                        id: desktopProgressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: root.duration > 0 ? root.duration : 1
                        value: !desktopProgressSlider.pressed ? root.position : 0
                        enabled: root.duration > 0
                        onMoved: {
                            if (root.controller && root.duration > 0) {
                                root.controller.seek(Math.round(value))
                            }
                        }
                    }

                    QQC2.Label {
                        Layout.preferredWidth: 38
                        text: AppTheme.formatTime(root.duration)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.disabledTextColor
                        horizontalAlignment: Text.AlignLeft
                    }
                }

                // Ряд кнопок управления: Перемешать, Назад, Play/Pause, Вперёд, Повтор, Звёздочка, Скачать
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    QQC2.ToolButton {
                        icon.name: "media-playlist-shuffle"
                        checkable: true
                        checked: root.controller && root.controller.shuffleEnabled
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: qsTr("Перемешать")
                        onClicked: {
                            if (root.controller) root.controller.toggleShuffle()
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: "media-skip-backward"
                        icon.width: 22
                        icon.height: 22
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: qsTr("Предыдущий трек")
                        onClicked: {
                            if (root.controller) root.controller.previous()
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                        icon.width: 36
                        icon.height: 36
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: root.playing ? qsTr("Пауза") : qsTr("Воспроизвести")
                        onClicked: {
                            if (!root.controller) return
                            if (root.playing) root.controller.pause()
                            else root.controller.play()
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: "media-skip-forward"
                        icon.width: 22
                        icon.height: 22
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: qsTr("Следующий трек")
                        onClicked: {
                            if (root.controller) root.controller.next()
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: (root.controller && root.controller.repeatMode === 1)
                            ? "media-playlist-repeat-song"
                            : "media-playlist-repeat"
                        checkable: true
                        checked: root.controller && root.controller.repeatMode !== 0
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: qsTr("Повтор")
                        onClicked: {
                            if (root.controller) root.controller.cycleRepeat()
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: root.liked ? "starred-symbolic" : "non-starred-symbolic"
                        checkable: true
                        checked: root.liked
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: root.liked ? qsTr("Убрать из «Мне нравится»") : qsTr("Мне нравится")
                        onClicked: {
                            if (root.controller && String(root.controller.currentTrackId || "").length > 0) {
                                root.controller.toggleLike(String(root.controller.currentTrackId), root.liked)
                            }
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: "download"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: qsTr("Скачать текущий трек")
                        onClicked: {
                            if (root.controller) {
                                root.controller.downloadCurrentTrack()
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. МОБИЛЬНЫЙ РЕЖИМ (root.isMobile) — ОДНОКОЛОНОЧНЫЙ МАКЕТ
    // =========================================================================
    Item {
        id: mobileLayoutContainer
        anchors.fill: parent
        visible: root.isMobile

        // Верхняя мобильная плашка: полоска-ручка по центру + кнопка сворачивания ∨ в левом углу
        Item {
            id: mobileHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            z: 30

            // Кнопка сворачивания ∨ с высоким z
            QQC2.ToolButton {
                id: collapseButton
                z: 20
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                icon.name: "go-down"
                icon.width: 24
                icon.height: 24
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Свернуть плеер")
                onClicked: root.requestClose()
            }

            // Область перетаскивания: полоска-ручка Drag Pill
            Item {
                id: dragPillArea
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 160

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    width: 36
                    height: 4
                    radius: 2
                    color: Kirigami.Theme.disabledTextColor
                }

                MouseArea {
                    anchors.fill: parent
                    property real startY: 0
                    property bool isDragging: false

                    onPressed: (mouse) => {
                        startY = mouse.y
                        isDragging = true
                        snapBackAnim.stop()
                        openAnim.stop()
                        closeAnim.stop()
                    }
                    onPositionChanged: (mouse) => {
                        if (isDragging) {
                            let dy = mouse.y - startY
                            root.dragYOffset = dy > 0 ? dy : (dy * 0.2)
                        }
                    }
                    onReleased: {
                        isDragging = false
                        if (root.dragYOffset > 100) {
                            closeAnim.start()
                        } else {
                            snapBackAnim.start()
                        }
                    }
                    onCanceled: {
                        isDragging = false
                        snapBackAnim.start()
                    }
                }
            }
        }

        // Мобильные 3 вкладки сверху: [ Плеер | Текст песни | Очередь ]
        Item {
            id: mobileTabBar
            anchors.top: mobileHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            z: 20

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.55)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    QQC2.ToolButton {
                        Layout.fillWidth: true
                        text: qsTr("Плеер")
                        icon.name: "media-playback-start"
                        checkable: true
                        checked: root.activePane === "player"
                        onClicked: root.activePane = "player"
                    }

                    QQC2.ToolButton {
                        Layout.fillWidth: true
                        text: qsTr("Текст песни")
                        icon.name: "view-media-lyrics"
                        checkable: true
                        checked: root.activePane === "lyrics"
                        onClicked: root.activePane = "lyrics"
                    }

                    QQC2.ToolButton {
                        Layout.fillWidth: true
                        text: qsTr("Очередь")
                        icon.name: "view-media-playlist"
                        checkable: true
                        checked: root.activePane === "queue"
                        onClicked: root.activePane = "queue"
                    }
                }
            }
        }

        // Контент мобильного режима
        Item {
            anchors.top: mobileTabBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16

            // Вкладка: Полноэкранный мобильный плеер
            Item {
                id: mobilePlayerPane
                anchors.fill: parent
                visible: root.activePane === "player"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    Item { Layout.fillHeight: true }

                    // Крупная скруглённая обложка альбома
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        readonly property real size: Math.min(parent.width - 32, Math.max(160, parent.height * 0.44), 280)
                        Layout.preferredWidth: size
                        Layout.preferredHeight: size
                        radius: 12
                        color: Kirigami.Theme.backgroundColor
                        border.width: 2.5
                        border.color: Kirigami.Theme.highlightColor
                        clip: true

                        Image {
                            id: mobileCoverImage
                            anchors.fill: parent
                            source: root.coverUri.length > 0 ? ("image://yandex/" + root.coverUri) : ""
                            sourceSize: Qt.size(600, 600)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                            visible: status === Image.Ready
                        }

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: "♪"
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 48
                            visible: mobileCoverImage.status !== Image.Ready
                        }
                    }

                    // Название трека и артист
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 2
                            text: root.trackTitle.length > 0 ? root.trackTitle : qsTr("Нет трека")
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            horizontalAlignment: Text.AlignHCenter
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.trackArtist
                            font.pixelSize: 14
                            color: mobArtistMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            horizontalAlignment: Text.AlignHCenter
                            visible: text.length > 0

                            MouseArea {
                                id: mobArtistMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    if (root.controller && String(root.controller.currentTrackArtistId || "").length > 0) {
                                        root.requestClose()
                                        root.controller.loadArtist(root.controller.currentTrackArtistId)
                                    }
                                }
                            }
                        }
                    }

                    // Слайдер прогресса со счётчиками времени
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        QQC2.Label {
                            Layout.preferredWidth: 42
                            text: AppTheme.formatTime(root.position)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                            horizontalAlignment: Text.AlignRight
                        }

                        QQC2.Slider {
                            id: mobileSlider
                            Layout.fillWidth: true
                            from: 0
                            to: root.duration > 0 ? root.duration : 1
                            value: !mobileSlider.pressed ? root.position : 0
                            enabled: root.duration > 0
                            onMoved: {
                                if (root.controller && root.duration > 0) {
                                    root.controller.seek(Math.round(value))
                                }
                            }
                        }

                        QQC2.Label {
                            Layout.preferredWidth: 42
                            text: AppTheme.formatTime(root.duration)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            color: Kirigami.Theme.disabledTextColor
                            horizontalAlignment: Text.AlignLeft
                        }
                    }

                    // Кнопки управления воспроизведением
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        QQC2.ToolButton {
                            icon.name: "media-playlist-shuffle"
                            checkable: true
                            checked: root.controller && root.controller.shuffleEnabled
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: qsTr("Перемешать")
                            onClicked: {
                                if (root.controller) root.controller.toggleShuffle()
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: "media-skip-backward"
                            icon.width: 24
                            icon.height: 24
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: qsTr("Предыдущий трек")
                            onClicked: {
                                if (root.controller) root.controller.previous()
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                            icon.width: 36
                            icon.height: 36
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: root.playing ? qsTr("Пауза") : qsTr("Воспроизвести")
                            onClicked: {
                                if (!root.controller) return
                                if (root.playing) root.controller.pause()
                                else root.controller.play()
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: "media-skip-forward"
                            icon.width: 24
                            icon.height: 24
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: qsTr("Следующий трек")
                            onClicked: {
                                if (root.controller) root.controller.next()
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: (root.controller && root.controller.repeatMode === 1)
                                ? "media-playlist-repeat-song"
                                : "media-playlist-repeat"
                            checkable: true
                            checked: root.controller && root.controller.repeatMode !== 0
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: qsTr("Повтор")
                            onClicked: {
                                if (root.controller) root.controller.cycleRepeat()
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: root.liked ? "starred-symbolic" : "non-starred-symbolic"
                            checkable: true
                            checked: root.liked
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: root.liked ? qsTr("Убрать из «Мне нравится»") : qsTr("Мне нравится")
                            onClicked: {
                                if (root.controller && String(root.controller.currentTrackId || "").length > 0) {
                                    root.controller.toggleLike(String(root.controller.currentTrackId), root.liked)
                                }
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: "download"
                            QQC2.ToolTip.visible: hovered
                            QQC2.ToolTip.text: qsTr("Скачать текущий трек")
                            onClicked: {
                                if (root.controller) {
                                    root.controller.downloadCurrentTrack()
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Вкладка: Текст песни
            Item {
                id: mobileLyricsPane
                anchors.fill: parent
                visible: root.activePane === "lyrics"

                ListView {
                    id: mobileLyricsListView
                    anchors.fill: parent
                    clip: true
                    spacing: 16
                    visible: root.hasTimedLines

                    model: root.hasTimedLines
                        ? root.controller.lyricsController.lyricsLineCount
                        : 0

                    currentIndex: root.currentLine
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 380
                    preferredHighlightBegin: height * 0.38
                    preferredHighlightEnd: height * 0.48
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    boundsBehavior: Flickable.StopAtBounds

                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        policy: QQC2.ScrollBar.AsNeeded
                        width: 3
                        opacity: active ? 0.5 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    delegate: QQC2.ItemDelegate {
                        id: mobLyricDel
                        required property int index

                        width: mobileLyricsListView.width - 24
                        implicitHeight: mobLyricTxt.implicitHeight + 24
                        readonly property bool isActive: mobLyricDel.index === root.currentLine

                        background: Rectangle {
                            radius: Kirigami.Units.cornerRadius
                            color: mobLyricDel.isActive
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                : "transparent"
                            border.width: mobLyricDel.isActive ? 1.5 : 0
                            border.color: Kirigami.Theme.highlightColor
                        }

                        contentItem: Text {
                            id: mobLyricTxt
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.controller.lyricsController.lyricLineText(mobLyricDel.index)
                            color: mobLyricDel.isActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                            font.pixelSize: mobLyricDel.isActive ? 22 : 16
                            font.weight: mobLyricDel.isActive ? Font.Bold : Font.Normal
                            opacity: mobLyricDel.isActive ? 1.0 : 0.55
                            wrapMode: Text.WordWrap
                        }

                        onClicked: {
                            if (root.controller && root.controller.lyricsController) {
                                root.controller.lyricsController.seekToLine(mobLyricDel.index)
                            }
                        }
                    }

                    Connections {
                        target: root.hasController ? root.controller.lyricsController : null
                        function onCurrentLyricLineChanged() {
                            if (root.hasTimedLines && root.currentLine >= 0 && root.currentLine < mobileLyricsListView.count) {
                                mobileLyricsListView.currentIndex = root.currentLine
                            }
                        }
                    }
                }

                QQC2.ScrollView {
                    anchors.fill: parent
                    visible: !root.hasTimedLines && root.plainText.length > 0
                    clip: true

                    Text {
                        width: parent.width - 24
                        text: root.plainText
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 16
                        lineHeight: 1.85
                        wrapMode: Text.WordWrap
                        opacity: 0.92
                    }
                }

                Kirigami.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    visible: !root.hasTimedLines && root.plainText.length === 0
                    icon.name: "view-media-lyrics"
                    text: qsTr("Текст для этого трека не найден")
                }
            }

            // Вкладка: Очередь
            Item {
                id: mobileQueuePane
                anchors.fill: parent
                visible: root.activePane === "queue"

                ListView {
                    id: mobileQueueListView
                    anchors.fill: parent
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.hasController ? root.controller.queueCount : 0
                    currentIndex: root.hasController ? root.controller.queueCurrentIndex : -1

                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        policy: QQC2.ScrollBar.AsNeeded
                        width: 3
                        opacity: active ? 0.5 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    delegate: TrackRow {
                        id: mobQueueDel
                        required property int index

                        readonly property var trackData: root.hasController
                            ? root.controller.queueTrackData(mobQueueDel.index)
                            : null

                        width: mobileQueueListView.width - 12
                        controller: root.controller
                        rowIndex: mobQueueDel.index
                        trackId: trackData ? String(trackData.id || "") : ""
                        title: trackData ? String(trackData.title || "") : ""
                        artist: trackData ? String(trackData.artist || "") : ""
                        artistId: trackData ? String(trackData.artistId || "") : ""
                        coverUri: trackData ? String(trackData.coverUri || "") : ""
                        durationMs: trackData ? Number(trackData.durationMs || 0) : 0

                        showLike: true
                        showDislike: false
                        showAdd: true

                        onActivated: {
                            if (root.controller) {
                                root.controller.selectQueueTrack(mobQueueDel.index)
                            }
                        }
                    }

                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - 48
                        visible: mobileQueueListView.count === 0
                        icon.name: "view-media-playlist"
                        text: qsTr("Очередь воспроизведения пуста")
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.hasController && root.controller.lyricsController) {
            root.controller.lyricsController.loadLyrics()
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.dragYOffset = root.isMobile ? root.height : 0
            if (root.isMobile) {
                openAnim.start()
            }
            if (root.hasController && root.controller.lyricsController) {
                root.controller.lyricsController.loadLyrics()
            }
        } else {
            root.dragYOffset = 0
        }
    }
}
