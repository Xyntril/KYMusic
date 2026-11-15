import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Item {
    id: root

    property var controller
    property int rowIndex: -1
    property string trackId: ""
    property string title: ""
    property string artist: ""
    property string artistId: ""
    property var artists: []
    property string album: ""
    property string albumId: ""
    property string coverUri: ""
    property int durationMs: 0

    // Подсветка текущего трека: по trackId (обычно) или по паре title+artist
    property string currentMatch: "id"

    readonly property bool highlighted: root.currentMatch === "titleArtist"
        ? root.hasController
            && String(root.controller.currentTrackTitle || "") === root.title
            && String(root.controller.currentTrackArtist || "") === root.artist
        : root.hasController
            && root.trackId.length > 0
            && String(root.controller.currentTrackId || "") === root.trackId

    property bool liked: false
    property bool showLike: false
    property bool showDislike: false
    property bool showAdd: false
    property bool showRemove: false
    property bool showAlbum: true
    property bool titleLinkToAlbum: true

    property bool alwaysBorder: false
    property int scrollbarOffset: 0

    property color aiBadgeColor: AppTheme.warning
    property color uncensoredBadgeColor: AppTheme.info

    readonly property bool showAiBadge: {
        if (!root.hasController || root.trackId.length === 0) return false
        root.controller.aiRevision
        if (root.artists && root.artists.length > 0) {
            for (let i = 0; i < root.artists.length; ++i) {
                const id = String(root.artists[i].id || "")
                if (id.length > 0 && root.controller.isAiArtist(id)) return true
            }
            return false
        }
        const id = String(root.artistId || "")
        return id.length > 0 && root.controller.isAiArtist(id)
    }

    readonly property bool showUncensoredBadge: {
        if (!root.hasController || root.trackId.length === 0) return false
        root.controller.censorRevision
        return root.controller.isTrackUncensored(root.trackId)
    }

    property int rowHeight: 62
    property int coverSize: 44
    property int cornerRadius: 8

    readonly property bool hasController:
        root.controller !== null && root.controller !== undefined

    readonly property bool isCached:
        root.hasController && root.trackId.length > 0 && root.controller.isTrackCached(root.trackId)

    readonly property var linkArtists: {
        if (root.artists && root.artists.length > 0) return root.artists
        if (root.artist.length > 0) return [{ id: root.artistId, name: root.artist }]
        return [{ id: "", name: qsTr("Неизвестный исполнитель") }]
    }

    readonly property bool disliked: {
        if (!root.hasController || root.trackId.length === 0) return false
        root.controller.dislikesRevision
        return root.controller.isTrackDisliked(root.trackId)
    }

    width: ListView.view
        ? Math.max(0, ListView.view.width - (ListView.view.ScrollBar && ListView.view.ScrollBar.vertical && ListView.view.ScrollBar.vertical.visible ? ListView.view.ScrollBar.vertical.width + 16 : 16))
        : (parent ? Math.max(0, parent.width - root.scrollbarOffset) : 0)
    height: root.rowHeight

    signal activated()
    signal addRequested(string trackId, string albumId)
    signal removeRequested(int index)

    TrackContextMenu {
        id: contextMenu

        controller: root.controller
        trackId: root.trackId
        trackTitle: root.title
        artist: root.artist
        artistId: root.artistId
        album: root.album
        albumId: root.albumId
        coverUri: root.coverUri
        durationMs: root.durationMs
        liked: root.liked
        disliked: root.disliked
        showAdd: root.showAdd

        onAddToPlaylistRequested: root.addRequested(root.trackId, root.albumId)
    }

    Rectangle {
        id: rowBackground
        anchors.fill: parent
        radius: root.cornerRadius

        color: root.highlighted
            ? AppTheme.panelActive
            : rowMouseArea.containsMouse
                ? AppTheme.panelHover
                : AppTheme.panelSecondary

        border.width: root.highlighted || root.alwaysBorder ? 1 : 0
        border.color: root.highlighted ? AppTheme.accent : AppTheme.borderSubtle

        // Акцентная боковая полоска слева — маркер текущего трека
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: root.highlighted ? parent.height - 16 : 0
            radius: 1.5
            color: AppTheme.accent
            opacity: root.highlighted ? 1 : 0

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }

        // Строгий RowLayout: обложка, тексты, длительность, кнопки
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            // 1. Скруглённая обложка 44x44
            Rectangle {
                Layout.preferredWidth: root.coverSize
                Layout.preferredHeight: root.coverSize
                Layout.alignment: Qt.AlignVCenter
                radius: 6
                color: AppTheme.artworkPlaceholder
                clip: true

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.coverUri.length > 0 ? ("image://yandex/" + root.coverUri) : ""
                    sourceSize: Qt.size(root.coverSize * 2, root.coverSize * 2)
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
                    font.pixelSize: 18
                    visible: coverImage.status !== Image.Ready
                }
            }

            // 2. Текстовый ColumnLayout со сжатием при нехватке места
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 80
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                // Название трека
                QQC2.Label {
                    id: titleLabel
                    Layout.fillWidth: true
                    text: root.title.length > 0 ? root.title : qsTr("Без названия")
                    color: titleMouseArea.containsMouse && titleMouseArea.enabled
                        ? AppTheme.accent
                        : AppTheme.textPrimary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    MouseArea {
                        id: titleMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.titleLinkToAlbum && root.albumId.length > 0 && root.hasController
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        z: 10
                        onClicked: {
                            if (root.hasController && root.albumId.length > 0) {
                                root.controller.loadAlbum(root.albumId)
                            }
                        }
                    }
                }

                // Исполнители трека
                ArtistLinks {
                    id: artistLinks
                    Layout.fillWidth: true
                    clip: true
                    artists: root.linkArtists
                    controller: root.controller
                    pixelSize: 11
                    baseColor: AppTheme.textSecondary
                }

                // Альбом (если включено отображение)
                QQC2.Label {
                    id: albumLabel
                    Layout.fillWidth: true
                    visible: root.showAlbum && root.album.length > 0
                    text: root.album
                    color: albumMouseArea.containsMouse ? AppTheme.accent : AppTheme.textMuted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    maximumLineCount: 1

                    MouseArea {
                        id: albumMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.albumId.length > 0 && root.hasController
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        z: 10
                        onClicked: {
                            if (root.hasController && root.albumId.length > 0) {
                                root.controller.loadAlbum(root.albumId)
                            }
                        }
                    }
                }
            }

            // 3. Бейджи контента (AI / Без цензуры)
            Row {
                Layout.alignment: Qt.AlignVCenter
                visible: root.showAiBadge || root.showUncensoredBadge
                spacing: 4

                Badge {
                    visible: root.showAiBadge
                    text: "AI"
                    badgeColor: root.aiBadgeColor
                }

                Badge {
                    visible: root.showUncensoredBadge
                    text: "Без цензуры"
                    badgeColor: root.uncensoredBadgeColor
                }
            }

            // 4. Отдельный Label длительности (никогда не наезжает на кнопки)
            QQC2.Label {
                Layout.preferredWidth: 44
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                rightPadding: 4
                text: AppTheme.formatDuration(root.durationMs)
                color: AppTheme.textSecondary
                font.pixelSize: 11
            }

            // 5. Блок кнопок действий справа с кнопкой «Три точки»
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                readonly property bool compactButtons: root.width < 480

                QQC2.ToolButton {
                    visible: !parent.compactButtons && root.hasController && root.trackId.length > 0
                    icon.name: root.isCached ? "object-select-symbolic" : "download"
                    icon.color: root.isCached ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    implicitWidth: 30
                    implicitHeight: 30
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: root.isCached ? qsTr("Сохранено в кэше") : qsTr("Скачать в кэш")
                    onClicked: {
                        if (root.hasController && root.trackId.length > 0) {
                            if (!root.isCached) {
                                root.controller.downloadTrack(
                                    root.trackId, root.title, root.artist, root.album, root.coverUri, root.durationMs
                                )
                            }
                        }
                    }
                }

                QQC2.ToolButton {
                    visible: !parent.compactButtons && root.showAdd
                    icon.name: "list-add"
                    implicitWidth: 30
                    implicitHeight: 30
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Добавить в плейлист")
                    onClicked: root.addRequested(root.trackId, root.albumId)
                }

                QQC2.ToolButton {
                    visible: !parent.compactButtons && root.showLike
                    icon.name: root.liked ? "starred-symbolic" : "non-starred-symbolic"
                    implicitWidth: 30
                    implicitHeight: 30
                    checkable: true
                    checked: root.liked
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: root.liked ? qsTr("Убрать из «Мне нравится»") : qsTr("Мне нравится")
                    onClicked: {
                        if (root.hasController && root.trackId.length > 0) {
                            root.controller.toggleLike(root.trackId, root.liked)
                        }
                    }
                }

                QQC2.ToolButton {
                    visible: !parent.compactButtons && root.showDislike
                    icon.name: "dialog-cancel"
                    implicitWidth: 30
                    implicitHeight: 30
                    checkable: true
                    checked: root.disliked
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: root.disliked ? qsTr("Убрать дизлайк") : qsTr("Не нравится")
                    onClicked: {
                        if (root.hasController && root.trackId.length > 0) {
                            root.controller.toggleDislike(root.trackId, root.disliked)
                        }
                    }
                }

                QQC2.ToolButton {
                    visible: root.showRemove
                    icon.name: "edit-delete"
                    implicitWidth: 30
                    implicitHeight: 30
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Удалить из списка")
                    onClicked: root.removeRequested(root.rowIndex)
                }

                // Кнопка «Три точки» (overflow-menu) для доступа ко всем действиям трека
                QQC2.ToolButton {
                    id: moreButton
                    icon.name: "overflow-menu"
                    implicitWidth: 30
                    implicitHeight: 30
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Действия с треком")
                    onClicked: contextMenu.popup(moreButton, 0, moreButton.height)
                }
            }
        }

        MouseArea {
            id: rowMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            z: -1

            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    root.activated()
                }
            }

            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton && root.hasController) {
                    contextMenu.popup()
                }
            }
        }
    }
}
