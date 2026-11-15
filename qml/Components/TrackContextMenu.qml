import QtQuick
import QtQuick.Controls
import YaMusic 1.0

// Контекстное меню трека со системными иконками KDE Breeze HIG
Menu {
    id: root

    property var controller
    property string trackId: ""
    property string trackTitle: ""
    property string artist: ""
    property string artistId: ""
    property string album: ""
    property string albumId: ""
    property string coverUri: ""
    property int durationMs: 0
    property bool liked: false
    property bool disliked: false
    property bool showAdd: false

    signal addToPlaylistRequested()

    readonly property bool hasController:
        root.controller !== null && root.controller !== undefined

    readonly property bool hasTrack: root.trackId.length > 0

    padding: 4
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    component TrackMenuItem: MenuItem {
        id: item
        implicitWidth: 260
    }

    component TrackMenuSeparator: MenuSeparator {
    }

    TrackMenuItem {
        text: qsTr("Моя волна по треку")
        icon.name: "network-wireless"

        enabled: root.hasTrack && root.hasController &&
            root.controller.stationsController !== undefined

        onTriggered: {
            if (root.hasController && root.controller.stationsController) {
                root.controller.stationsController.startTrackWave(root.trackId, root.trackTitle)
            }
        }
    }

    TrackMenuItem {
        text: root.liked
            ? qsTr("Убрать из «Мне нравится»")
            : qsTr("Мне нравится")
        icon.name: root.liked ? "starred-symbolic" : "non-starred-symbolic"

        enabled: root.hasTrack && root.hasController

        onTriggered: {
            if (root.hasController) {
                root.controller.toggleLike(root.trackId, root.liked)
            }
        }
    }

    TrackMenuItem {
        text: root.disliked
            ? qsTr("Убрать дизлайк")
            : qsTr("Не нравится")
        icon.name: "dialog-cancel"

        enabled: root.hasTrack && root.hasController

        onTriggered: {
            if (root.hasController) {
                root.controller.toggleDislike(root.trackId, root.disliked)
            }
        }
    }

    TrackMenuSeparator {}

    TrackMenuItem {
        text: qsTr("Добавить в плейлист")
        icon.name: "list-add"

        visible: root.showAdd
        enabled: root.hasTrack && root.hasController

        onTriggered: root.addToPlaylistRequested()
    }

    TrackMenuItem {
        text: qsTr("Скачать")
        icon.name: "download"

        enabled: root.hasTrack && root.hasController

        onTriggered: {
            if (!root.hasController) {
                return
            }

            root.controller.downloadTrack(
                root.trackId,
                root.trackTitle,
                root.artist,
                root.album,
                root.coverUri,
                root.durationMs
            )
        }
    }

    TrackMenuSeparator {}

    TrackMenuItem {
        text: qsTr("Перейти к исполнителю")
        icon.name: "view-media-artist"

        enabled: root.artistId.length > 0 && root.hasController

        onTriggered: {
            if (typeof window !== "undefined" && window.activeOverlay === window.overlayLyrics) {
                window.activeOverlay = window.overlayNone
            }
            if (root.hasController) {
                root.controller.loadArtist(root.artistId)
            }
        }
    }

    TrackMenuItem {
        text: qsTr("Перейти к альбому")
        icon.name: "media-optical-audio"

        enabled: root.albumId.length > 0 && root.hasController

        onTriggered: {
            if (typeof window !== "undefined" && window.activeOverlay === window.overlayLyrics) {
                window.activeOverlay = window.overlayNone
            }
            if (root.hasController) {
                root.controller.loadAlbum(root.albumId)
            }
        }
    }

    TrackMenuItem {
        text: qsTr("Скопировать «Исполнитель — Название»")
        icon.name: "edit-copy"

        enabled: root.hasController

        onTriggered: {
            if (root.hasController) {
                root.controller.copyTrack(root.trackTitle, root.artist)
            }
        }
    }
}
