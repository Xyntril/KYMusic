import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0

QQC2.ToolBar {
    id: root

    property var controller

    signal expandedRequested()
    signal lyricsRequested()
    signal miniPlayerRequested()

    readonly property bool hasController:
        root.controller !== null && root.controller !== undefined

    readonly property bool hasTrack:
        root.hasController &&
        String(root.controller.currentTrackTitle || "").length > 0

    readonly property bool loading:
        root.hasController && root.controller.playbackState === 1

    readonly property bool playing:
        root.hasController && root.controller.playing

    // Дизлайк хранится в LikesService, а не в модели
    readonly property bool currentTrackDisliked: {
        if (!root.hasController) {
            return false
        }
        root.controller.dislikesRevision
        return root.controller.isTrackDisliked(String(root.controller.currentTrackId || ""))
    }

    // Бейджи текущего трека: AI и «Без цензуры»
    readonly property bool currentTrackAi: {
        if (!root.hasController) {
            return false
        }
        root.controller.currentTrackId
        root.controller.aiRevision
        return root.controller.currentTrackIsAi()
    }

    readonly property bool currentTrackUncensored: {
        if (!root.hasController) {
            return false
        }
        const id = String(root.controller.currentTrackId || "")
        if (id.length === 0) {
            return false
        }
        root.controller.censorRevision
        return root.controller.isTrackUncensored(id)
    }

    height: 96
    implicitHeight: 96

    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    AmbientGlow {
        anchors.fill: parent
        coverUri: root.hasTrack && root.controller ? String(root.controller.currentTrackCoverUri || "") : ""
        glowOpacity: 0.12
        z: -1
    }

    PlaylistPicker {
        id: addToPlaylistPopup
        controller: root.controller
    }

    TrackContextMenu {
        id: trackMenu
        controller: root.controller

        trackId: root.hasTrack ? String(root.controller.currentTrackId || "") : ""
        trackTitle: root.hasTrack ? String(root.controller.currentTrackTitle || "") : ""
        artist: root.hasTrack ? String(root.controller.currentTrackArtist || "") : ""
        artistId: root.hasTrack ? String(root.controller.currentTrackArtistId || "") : ""
        album: root.hasTrack ? String(root.controller.currentTrackAlbumTitle || "") : ""
        albumId: root.hasTrack ? String(root.controller.currentTrackAlbumId || "") : ""
        coverUri: root.hasTrack ? String(root.controller.currentTrackCoverUri || "") : ""
        durationMs: root.hasTrack ? Number(root.controller.duration || 0) : 0
        liked: root.hasTrack && root.controller.currentTrackLiked
        disliked: root.currentTrackDisliked
        showAdd: true

        onAddToPlaylistRequested: {
            if (!root.hasController) {
                return
            }
            addToPlaylistPopup.trackId = trackMenu.trackId
            addToPlaylistPopup.albumId = trackMenu.albumId
            addToPlaylistPopup.open()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing

        // ---- Левая часть: информация о треке ----
        RowLayout {
            id: trackInfo
            Layout.preferredWidth: 320
            Layout.minimumWidth: 220
            Layout.maximumWidth: 380
            spacing: Kirigami.Units.mediumSpacing

            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: root.hasTrack
                onTapped: trackMenu.popup()
            }

            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: 6
                color: AppTheme.artworkPlaceholder
                clip: true
                border.width: 1
                border.color: AppTheme.borderSubtle

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.hasTrack && root.controller.currentTrackCoverUri
                        ? "image://yandex/" + root.controller.currentTrackCoverUri
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: root.hasTrack ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.hasTrack
                    onClicked: root.expandedRequested()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                QQC2.Label {
                    id: titleLabel
                    Layout.fillWidth: true
                    text: root.hasTrack
                        ? root.controller.currentTrackTitle
                        : qsTr("Нет воспроизводимого трека")
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.hasTrack ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: root.hasTrack
                        onClicked: root.expandedRequested()
                    }
                }

                ArtistLinks {
                    Layout.fillWidth: true
                    clip: true
                    artists: root.hasTrack && root.controller
                        ? root.controller.currentTrackArtists
                        : []
                    controller: root.controller
                    pixelSize: 12
                    baseColor: Kirigami.Theme.disabledTextColor
                }

                Row {
                    Layout.fillWidth: true
                    visible: root.hasTrack && (root.currentTrackAi || root.currentTrackUncensored)
                    spacing: 4

                    Badge {
                        visible: root.currentTrackAi
                        text: "AI"
                        badgeColor: AppTheme.warning
                    }

                    Badge {
                        visible: root.currentTrackUncensored
                        text: qsTr("Без цензуры")
                        badgeColor: AppTheme.info
                    }
                }
            }

            QQC2.ToolButton {
                id: likeButton
                visible: root.hasTrack
                icon.name: (root.controller && root.controller.currentTrackLiked)
                    ? "starred-symbolic"
                    : "non-starred-symbolic"
                checkable: true
                checked: root.controller && root.controller.currentTrackLiked
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: checked
                    ? qsTr("Убрать из «Мне нравится»")
                    : qsTr("Мне нравится")
                onClicked: {
                    if (root.controller && String(root.controller.currentTrackId || "").length > 0) {
                        root.controller.toggleLike(
                            String(root.controller.currentTrackId),
                            root.controller.currentTrackLiked
                        )
                    }
                }
            }

            QQC2.ToolButton {
                id: dislikeButton
                visible: root.hasTrack
                icon.name: "dialog-cancel"
                checkable: true
                checked: root.currentTrackDisliked
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: checked
                    ? qsTr("Убрать дизлайк")
                    : qsTr("Не нравится")
                onClicked: {
                    if (root.controller && String(root.controller.currentTrackId || "").length > 0) {
                        root.controller.toggleDislike(
                            String(root.controller.currentTrackId),
                            root.currentTrackDisliked
                        )
                    }
                }
            }
        }

        // ---- Центральная часть: кнопки управления и прогресс ----
        ColumnLayout {
            id: centerControls
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing

                QQC2.ToolButton {
                    icon.name: "media-playlist-shuffle"
                    checkable: true
                    checked: root.controller && root.controller.shuffleEnabled
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Перемешать")
                    onClicked: {
                        if (root.controller) {
                            root.controller.toggleShuffle()
                        }
                    }
                }

                QQC2.ToolButton {
                    icon.name: "media-skip-backward"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Предыдущий трек")
                    onClicked: {
                        if (root.controller) {
                            root.controller.previous()
                        }
                    }
                }

                QQC2.ToolButton {
                    id: playPauseBtn
                    icon.name: root.loading
                        ? "media-seek-forward"
                        : (root.playing ? "media-playback-pause" : "media-playback-start")
                    icon.width: 28
                    icon.height: 28
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: root.loading
                        ? qsTr("Загрузка…")
                        : (root.playing ? qsTr("Пауза") : qsTr("Воспроизвести"))
                    onClicked: {
                        if (!root.controller || root.loading) {
                            return
                        }
                        if (root.playing) {
                            root.controller.pause()
                        } else {
                            root.controller.play()
                        }
                    }
                }

                QQC2.ToolButton {
                    icon.name: "media-skip-forward"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Следующий трек")
                    onClicked: {
                        if (root.controller) {
                            root.controller.next()
                        }
                    }
                }

                QQC2.ToolButton {
                    icon.name: (root.controller && root.controller.repeatMode === 1)
                        ? "media-playlist-repeat-song"
                        : "media-playlist-repeat"
                    checkable: true
                    checked: root.controller && root.controller.repeatMode !== 0
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: {
                        const mode = root.controller ? root.controller.repeatMode : 0
                        if (mode === 1) {
                            return qsTr("Повтор трека")
                        }
                        if (mode === 2) {
                            return qsTr("Повтор списка")
                        }
                        return qsTr("Повтор выключен")
                    }
                    onClicked: {
                        if (root.controller) {
                            root.controller.cycleRepeat()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.preferredWidth: 42
                    text: AppTheme.formatTime(root.controller ? root.controller.position : 0)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                    horizontalAlignment: Text.AlignRight
                }

                QQC2.Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: (root.controller && root.controller.duration > 0)
                        ? root.controller.duration
                        : 1
                    value: (root.controller && !progressSlider.pressed)
                        ? root.controller.position
                        : 0
                    enabled: root.hasTrack && root.controller && root.controller.duration > 0
                    onMoved: {
                        if (root.controller && root.controller.duration > 0) {
                            root.controller.seek(Math.round(value))
                        }
                    }
                }

                QQC2.Label {
                    Layout.preferredWidth: 42
                    text: AppTheme.formatTime(root.controller ? root.controller.duration : 0)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.disabledTextColor
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        // ---- Правая часть: Скачивание, Текст, Громкость, Мини-плеер, Развернуть ----
        RowLayout {
            id: rightTools
            Layout.preferredWidth: 320
            Layout.minimumWidth: 240
            Layout.maximumWidth: 380
            spacing: Kirigami.Units.smallSpacing

            Item {
                Layout.fillWidth: true
            }

            QQC2.ToolButton {
                id: downloadBtn
                visible: root.hasTrack
                icon.name: "download"
                readonly property int dlState:
                    root.hasController && root.controller.downloadService
                        ? root.controller.downloadService.state
                        : 0

                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: {
                    if (dlState === 1) {
                        return qsTr("Скачивание…")
                    }
                    if (dlState === 2) {
                        return qsTr("Скачано")
                    }
                    if (dlState === 3) {
                        return qsTr("Ошибка скачивания (нажмите для повтора)")
                    }
                    return qsTr("Скачать трек")
                }
                onClicked: {
                    if (root.controller) {
                        root.controller.downloadCurrentTrack()
                    }
                }
            }

            QQC2.ToolButton {
                visible: root.hasTrack
                icon.name: "view-media-lyrics"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Текст песни")
                onClicked: root.lyricsRequested()
            }

            QQC2.ToolButton {
                icon.name: (root.controller && root.controller.volume > 0)
                    ? (root.controller.volume > 0.5 ? "audio-volume-high" : "audio-volume-medium")
                    : "audio-volume-muted"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: (root.controller && root.controller.volume > 0)
                    ? qsTr("Выключить звук")
                    : qsTr("Включить звук")
                onClicked: {
                    if (!root.controller) {
                        return
                    }
                    if (root.controller.volume > 0) {
                        root.controller.setVolume(0)
                    } else {
                        root.controller.setVolume(1)
                    }
                }
            }

            QQC2.Slider {
                id: volumeSlider
                Layout.preferredWidth: 90
                from: 0
                to: 1
                value: root.controller ? root.controller.volume : 0
                onMoved: {
                    if (root.controller) {
                        root.controller.setVolume(value)
                    }
                }
            }

            QQC2.ToolButton {
                icon.name: "window-minimize"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Мини-плеер")
                onClicked: root.miniPlayerRequested()
            }
        }
    }
}
