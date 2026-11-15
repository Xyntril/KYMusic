import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Item {
    id: root

    property var controller

    readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode) || width < 600

    width: parent ? parent.width : 0
    implicitHeight: pageColumn.implicitHeight + 56

    readonly property var albumController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.albumController !== null && root.controller.albumController !== undefined
            ? root.controller.albumController
            : null

    readonly property var albumModel:
        root.albumController !== null &&
        root.albumController.albumModel !== null && root.albumController.albumModel !== undefined
            ? root.albumController.albumModel
            : null

    readonly property bool loading:
        root.albumController !== null && root.albumController.loading === true

    readonly property bool hasAlbum:
        root.albumController !== null && root.albumController.albumId !== ""

    readonly property int trackCount:
        root.albumModel !== null ? root.albumModel.count : 0

    readonly property string albumTitle:
        root.albumController !== null
            ? String(root.albumController.currentAlbumTitle || "")
            : ""

    readonly property string albumArtworkUri:
        root.albumController !== null
            ? String(root.albumController.currentAlbumCoverUri || "")
            : ""

    // Есть ли в альбоме треки, которые Яндекс отдаёт в Music API:
    // у книг и части подкастов звук доступен только во внешнем сервисе.
    readonly property bool hasPlayableTracks:
        root.albumController !== null &&
        root.albumController.currentAlbumPlayable === true

    readonly property string externalText:
        root.albumController !== null
            ? String(root.albumController.currentAlbumExternalText || "")
            : ""

    readonly property string externalUrl:
        root.albumController !== null
            ? String(root.albumController.currentAlbumExternalUrl || "")
            : ""

    PlaylistPicker {
        id: addToPlaylistPopup
        controller: root.controller
    }

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    AmbientGlow {
        anchors.fill: parent
        coverUri: root.albumArtworkUri
        glowOpacity: 0.12
    }

    // Контент скроллит внешний ScrollView в MainLayout
    Column {
        id: pageColumn

        width: root.width
        spacing: 20

        Rectangle {
            width: parent.width
            implicitHeight: root.isMobile ? (mobileHeaderColumn.implicitHeight + 32) : (desktopHeaderRow.implicitHeight + 36)

            radius: 12
            color: AppTheme.panel
            border.width: 1
            border.color: AppTheme.borderSubtle

            // МОБИЛЬНАЯ ШАПКА
            ColumnLayout {
                id: mobileHeaderColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12
                visible: root.isMobile

                // 1) Сверху по центру обложка альбома 150x150
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150
                    radius: 8
                    color: AppTheme.artworkPlaceholder
                    clip: true

                    Image {
                        id: mobileAlbumImage
                        anchors.fill: parent
                        source: root.albumArtworkUri.length > 0
                            ? "image://yandex/" + root.albumArtworkUri
                            : ""
                        sourceSize: Qt.size(300, 300)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "♪"
                        color: AppTheme.textMuted
                        font.pixelSize: 40
                        visible: mobileAlbumImage.status !== Image.Ready
                    }
                }

                // 2) Под фото по центру: метка АЛЬБОМ, крупное полное название, подзаголовок
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("АЛЬБОМ")
                        color: AppTheme.textMuted
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        text: root.albumTitle.length > 0 ? root.albumTitle : qsTr("Альбом")
                        color: AppTheme.textPrimary
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                    }

                    Label {
                        Layout.fillWidth: true
                        text: root.trackCount > 0
                            ? root.trackCount + (root.trackCount === 1 ? qsTr(" трек") : qsTr(" трека"))
                            : qsTr("Нет треков")
                        color: AppTheme.textSecondary
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // 3) Ниже по центру переносящийся ряд кнопок (Flow): ▶ Слушать, ⬇ Скачать, ★
                Flow {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Button {
                        text: qsTr("Слушать")
                        icon.name: "media-playback-start"
                        highlighted: true
                        enabled: root.trackCount > 0
                        onClicked: {
                            if (root.controller) {
                                root.controller.selectAlbumTrack(0)
                            } else if (root.albumController) {
                                root.albumController.selectAlbumTrack(0)
                            }
                        }
                    }

                    Button {
                        text: qsTr("Скачать")
                        icon.name: "download"
                        enabled: root.trackCount > 0
                        onClicked: {
                            if (root.controller && root.controller.downloadAlbumTracks) {
                                root.controller.downloadAlbumTracks()
                            }
                        }
                    }

                    ToolButton {
                        visible: root.albumController !== null && root.albumController.albumId !== ""
                        icon.name: root.controller && root.controller.currentAlbumLiked
                            ? "starred-symbolic"
                            : "non-starred-symbolic"
                        highlighted: root.controller && root.controller.currentAlbumLiked
                        ToolTip.visible: hovered
                        ToolTip.text: root.controller && root.controller.currentAlbumLiked
                            ? qsTr("Удалить из избранного")
                            : qsTr("В избранное")
                        onClicked: {
                            if (root.controller) {
                                root.controller.toggleAlbumLike()
                            }
                        }
                    }
                }
            }

            // ДЕСКТОПНАЯ ШАПКА
            Row {
                id: desktopHeaderRow
                anchors.fill: parent
                anchors.margins: 18
                spacing: 20
                visible: !root.isMobile

                Rectangle {
                    width: 180
                    height: 180
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 8
                    color: AppTheme.artworkPlaceholder
                    clip: true

                    Image {
                        id: albumImage
                        anchors.fill: parent
                        source: root.albumArtworkUri.length > 0
                            ? "image://yandex/" + root.albumArtworkUri
                            : ""
                        sourceSize: Qt.size(180, 180)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "♪"
                        color: AppTheme.textMuted
                        font.pixelSize: 40
                        visible: albumImage.status !== Image.Ready
                    }
                }

                Column {
                    width: parent.width - 200
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Label {
                        text: qsTr("АЛЬБОМ")
                        color: AppTheme.textMuted
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Label {
                        width: parent.width
                        text: root.albumTitle.length > 0 ? root.albumTitle : qsTr("Альбом")
                        color: AppTheme.textPrimary
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 2
                    }

                    Label {
                        text: root.trackCount > 0
                            ? root.trackCount + (root.trackCount === 1 ? qsTr(" трек") : qsTr(" трека"))
                            : qsTr("Нет треков")
                        color: AppTheme.textSecondary
                        font.pixelSize: 13
                    }

                    Row {
                        spacing: 8

                        Button {
                            text: qsTr("Слушать")
                            icon.name: "media-playback-start"
                            highlighted: true
                            enabled: root.trackCount > 0
                            onClicked: {
                                if (root.controller) {
                                    root.controller.selectAlbumTrack(0)
                                } else if (root.albumController) {
                                    root.albumController.selectAlbumTrack(0)
                                }
                            }
                        }

                        Button {
                            text: qsTr("Скачать")
                            icon.name: "download"
                            enabled: root.trackCount > 0
                            onClicked: {
                                if (root.controller && root.controller.downloadAlbumTracks) {
                                    root.controller.downloadAlbumTracks()
                                }
                            }
                        }

                        ToolButton {
                            id: albumLikeButton
                            visible: root.albumController !== null && root.albumController.albumId !== ""
                            icon.name: root.controller && root.controller.currentAlbumLiked
                                ? "starred-symbolic"
                                : "non-starred-symbolic"
                            highlighted: root.controller && root.controller.currentAlbumLiked
                            ToolTip.visible: hovered
                            ToolTip.text: root.controller && root.controller.currentAlbumLiked
                                ? qsTr("Удалить из избранного")
                                : qsTr("В избранное")
                            onClicked: {
                                if (root.controller) {
                                    root.controller.toggleAlbumLike()
                                }
                            }
                        }
                    }
                }
            }
        }

        // У книг и части подкастов звука в Music API нет: API кладёт
        // в альбом готовую ссылку-переход во внешний сервис.
        Item {
            width: parent.width
            height: root.externalUrl.length > 0
                ? root.hasPlayableTracks ? 52 : 74
                : 0

            visible: height > 0

            Rectangle {
                id: externalButton

                width: Math.min(260, parent.width)
                height: 44

                anchors.top: parent.top

                radius: 10

                color: externalMouseArea.containsMouse
                    ? AppTheme.accent
                    : AppTheme.panelActive

                border.width: 1
                border.color: AppTheme.borderSubtle

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Label {
                    anchors.centerIn: parent

                    text: root.externalText.length > 0
                        ? root.externalText
                        : qsTr("Слушать в Яндекс Книгах")

                    color: externalMouseArea.containsMouse
                        ? AppTheme.accentOn
                        : AppTheme.textPrimary

                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: externalMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Qt.openUrlExternally(root.externalUrl)
                }
            }

            Label {
                anchors.top: externalButton.bottom
                anchors.topMargin: 6

                width: parent.width

                visible: !root.hasPlayableTracks

                text: qsTr("Прослушивание доступно только в Яндекс Книгах")

                color: AppTheme.textMuted
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Rectangle {
            width: parent.width
            implicitHeight: tracksColumn.implicitHeight + 28
            radius: 12
            color: AppTheme.panel
            border.width: 1
            border.color: AppTheme.borderSubtle

            Column {
                id: tracksColumn
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 10

                Label {
                    width: parent.width
                    height: 26
                    text: qsTr("Треки")
                    color: AppTheme.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                ListView {
                    id: tracksView
                    width: parent.width
                    implicitHeight: count * 68
                    model: root.albumModel
                    clip: true
                    spacing: 4
                    interactive: false
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: TrackRow {
                        width: tracksView.width
                        opacity: model.available === false ? 0.45 : 1.0
                        controller: root.controller
                        rowIndex: index
                        trackId: model.trackId
                        title: model.title
                        artist: model.artist
                        artistId: model.artistId
                        artists: model.artists
                        albumId: model.albumId
                        coverUri: model.coverUri
                        durationMs: model.durationMs
                        liked: model.liked
                        showLike: true
                        showDislike: true
                        showAdd: true
                        titleLinkToAlbum: false

                        rowHeight: 64
                        coverSize: 48
                        cornerRadius: 8

                        onActivated: {
                            if (root.controller !== null) {
                                root.controller.selectAlbumTrack(index)
                            } else if (root.albumController !== null) {
                                root.albumController.selectAlbumTrack(index)
                            }
                        }

                        onAddRequested: function(trackId, albumId) {
                            addToPlaylistPopup.trackId = trackId
                            addToPlaylistPopup.albumId = albumId
                            addToPlaylistPopup.open()
                        }
                    }

                    // Пустое состояние
                    Rectangle {
                        width: parent.width
                        height: 72
                        radius: 8
                        color: AppTheme.panelSecondary
                        border.width: 1
                        border.color: AppTheme.borderSubtle
                        visible: root.trackCount === 0 && !root.loading

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("Треки не найдены")
                            color: AppTheme.textMuted
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        // =====================================================================
        // СЕКЦИЯ «ДРУГИЕ АЛЬБОМЫ» (сетка скруглённых карточек KDE Breeze)
        // =====================================================================
        Column {
            width: parent.width
            spacing: 12
            visible: root.albumController && root.albumController.otherAlbumsModel && root.albumController.otherAlbumsModel.count > 0

            Label {
                text: qsTr("Другие альбомы исполнителя")
                color: AppTheme.textPrimary
                font.pixelSize: 22
                font.bold: true
            }

            Flow {
                width: parent.width
                spacing: 14

                Repeater {
                    model: root.albumController ? root.albumController.otherAlbumsModel : null

                    delegate: PlaylistCard {
                        id: otherAlbumCard

                        cardWidth: 168
                        cardHeight: 210
                        title: model.title || ""
                        subtitle: (model.year && model.year > 0) ? String(model.year) : ""
                        coverUri: model.coverUri || ""

                        onActivated: {
                            if (root.controller && model.albumId) {
                                root.controller.loadAlbum(model.albumId)
                            }
                        }
                    }
                }
            }
        }

        // Нижний отступ
        Item {
            width: 1
            height: 100
        }
    }

    BusyIndicator {
        id: loadingIndicator

        anchors.centerIn: parent

        width: 32
        height: 32

        running: root.loading
        visible: running
        z: 100
    }
}