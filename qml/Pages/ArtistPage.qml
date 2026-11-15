import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller

    readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode) || width < 600

    width: parent ? parent.width : 0
    implicitWidth: width
    implicitHeight: pageColumn.implicitHeight + 56

    readonly property var artistController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.artistController !== null && root.controller.artistController !== undefined
            ? root.controller.artistController
            : null

    readonly property var artistModel:
        root.artistController !== null &&
        root.artistController.artistModel !== null && root.artistController.artistModel !== undefined
            ? root.artistController.artistModel
            : null

    readonly property var albumsModel:
        root.artistController !== null &&
        root.artistController.albumsModel !== null && root.artistController.albumsModel !== undefined
            ? root.artistController.albumsModel
            : null

    readonly property bool loading:
        root.artistController !== null && root.artistController.loading === true

    readonly property bool radioLoading:
        root.artistController !== null && root.artistController.radioLoading === true

    readonly property string artistId:
        root.artistController !== null
            ? String(root.artistController.artistId || "")
            : ""

    readonly property bool artistIsAi: {
        if (root.controller === null || root.controller === undefined) {
            return false
        }
        if (root.artistId.length === 0) {
            return false
        }

        // Пересчитываем после загрузки базы Slopless.
        root.controller.aiRevision

        return root.controller.isAiArtist(root.artistId)
    }

    readonly property string artistName:
        root.artistController !== null
            ? String(root.artistController.artistName || "")
            : ""

    readonly property string artistCoverUri:
        root.artistController !== null
            ? String(root.artistController.artistCoverUri || "")
            : ""

    readonly property string artistDescription:
        root.artistController !== null
            ? String(root.artistController.artistDescription || "")
            : ""

    readonly property string artistGenres:
        root.artistController !== null
            ? String(root.artistController.artistGenres || "")
            : ""

    readonly property string newReleaseId:
        root.artistController !== null
            ? String(root.artistController.newReleaseId || "")
            : ""

    readonly property string newReleaseTitle:
        root.artistController !== null
            ? String(root.artistController.newReleaseTitle || "")
            : ""

    readonly property string newReleaseCoverUri:
        root.artistController !== null
            ? String(root.artistController.newReleaseCoverUri || "")
            : ""

    readonly property int newReleaseYear:
        root.artistController !== null
            ? Number(root.artistController.newReleaseYear || 0)
            : 0

    PlaylistPicker {
        id: addToPlaylistPopup
        controller: root.controller
    }

    // Вложенного ScrollView нет: вертикальным скроллом владеет внешний
    // ScrollView в MainLayout
    Column {
        id: pageColumn

        width: root.width
        spacing: 20

        Rectangle {
            width: parent.width
            implicitHeight: root.isMobile ? (mobileArtistHeader.implicitHeight + 32) : 260
            height: root.isMobile ? implicitHeight : 260

            radius: 14
            color: AppTheme.panel
            border.width: 1
            border.color: AppTheme.borderSubtle

            // МОБИЛЬНАЯ ШАПКА АРТИСТА
            ColumnLayout {
                id: mobileArtistHeader
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 12
                visible: root.isMobile

                // 1) 150x150 круглое фото по центру
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 150

                    Rectangle {
                        anchors.fill: parent
                        radius: 75
                        color: AppTheme.artworkPlaceholder
                        clip: true

                        Image {
                            id: mobileArtistImage
                            anchors.fill: parent
                            source: root.artistCoverUri.length > 0
                                ? "image://yandex/circle/" + root.artistCoverUri
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
                            visible: mobileArtistImage.status !== Image.Ready
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 75
                        color: "transparent"
                        border.width: 1
                        border.color: AppTheme.border
                    }
                }

                // 2) Под фото по центру: метка ИСПОЛНИТЕЛЬ, имя, жанры
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("ИСПОЛНИТЕЛЬ")
                        color: AppTheme.textMuted
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        Label {
                            text: root.artistName.length > 0 ? root.artistName : qsTr("Исполнитель")
                            color: AppTheme.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                        }

                        Badge {
                            visible: root.artistIsAi
                            text: "AI"
                            badgeColor: AppTheme.warning
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: root.artistGenres
                        color: AppTheme.textSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        visible: text.length > 0
                    }
                }

                // 3) Ниже по центру ряд кнопок (Flow): ▶ Слушать, ⬇ Скачать, ★
                Flow {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Button {
                        icon.name: "media-playback-start"
                        text: root.radioLoading ? qsTr("Загрузка...") : qsTr("Слушать")
                        highlighted: true
                        enabled: !root.loading &&
                            !root.radioLoading &&
                            root.artistController !== null &&
                            root.artistModel !== null &&
                            artistTracksView.count > 0

                        onClicked: {
                            if (root.artistController !== null) {
                                root.artistController.playArtist()
                            }
                        }
                    }

                    Button {
                        text: qsTr("Скачать")
                        icon.name: "download"
                        enabled: artistTracksView.count > 0
                        onClicked: {
                            if (root.controller && root.artistModel) {
                                for (let i = 0; i < root.artistModel.count; ++i) {
                                    const t = root.artistModel.get ? root.artistModel.get(i) : null
                                    if (t && t.id) {
                                        root.controller.downloadTrack(
                                            String(t.id), String(t.title || ""), String(t.artist || root.artistName),
                                            String(t.album || ""), String(t.coverUri || ""), Number(t.durationMs || 0)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    ToolButton {
                        visible: root.controller !== null &&
                            root.controller.artistController !== null &&
                            root.controller.artistController.artistId !== ""
                        icon.name: root.controller && root.controller.currentArtistLiked
                            ? "starred-symbolic"
                            : "non-starred-symbolic"
                        highlighted: root.controller && root.controller.currentArtistLiked
                        ToolTip.visible: hovered
                        ToolTip.text: root.controller && root.controller.currentArtistLiked
                            ? qsTr("Удалить из избранного")
                            : qsTr("В избранное")
                        onClicked: {
                            if (root.controller) {
                                root.controller.toggleArtistLike()
                            }
                        }
                    }
                }
            }

            // ДЕСКТОПНАЯ ШАПКА
            Row {
                id: desktopArtistHeader
                anchors.fill: parent
                anchors.margins: 20
                spacing: 24
                visible: !root.isMobile

                Item {
                    id: artistArtwork

                    width: 220
                    height: 220

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2

                        color: AppTheme.artworkPlaceholder
                        clip: true

                        Image {
                            id: artistImage

                            anchors.fill: parent

                            source: root.artistCoverUri.length > 0
                                ? "image://yandex/circle/" + root.artistCoverUri
                                : ""

                            sourceSize: Qt.size(220, 220)

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
                            font.pixelSize: 54

                            visible: artistImage.status !== Image.Ready
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2

                        color: "transparent"
                        border.width: 1
                        border.color: AppTheme.border
                    }
                }

                // Информация
                Column {
                    width: parent.width - artistArtwork.width - parent.spacing

                    anchors.verticalCenter: parent.verticalCenter

                    spacing: 10

                    Label {
                        text: qsTr("ИСПОЛНИТЕЛЬ")
                        color: AppTheme.textMuted
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Label {
                            width: parent.width - artistLikeButton.width - parent.spacing
                                - (artistAiBadge.visible
                                    ? artistAiBadge.implicitWidth + parent.spacing
                                    : 0)

                            text: root.artistName.length > 0 ? root.artistName : qsTr("Исполнитель")

                            color: AppTheme.textPrimary
                            font.pixelSize: 32
                            font.bold: true

                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Badge {
                            id: artistAiBadge

                            anchors.verticalCenter: parent.verticalCenter

                            visible: root.artistIsAi
                            text: "AI"
                            badgeColor: AppTheme.warning
                        }

                        ToolButton {
                            id: artistLikeButton
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.controller !== null &&
                                root.controller.artistController !== null &&
                                root.controller.artistController.artistId !== ""
                            icon.name: root.controller && root.controller.currentArtistLiked
                                ? "starred-symbolic"
                                : "non-starred-symbolic"
                            highlighted: root.controller && root.controller.currentArtistLiked
                            ToolTip.visible: hovered
                            ToolTip.text: root.controller && root.controller.currentArtistLiked
                                ? qsTr("Удалить из избранного")
                                : qsTr("В избранное")
                            onClicked: {
                                if (root.controller) {
                                    root.controller.toggleArtistLike()
                                }
                            }
                        }
                    }

                    Label {
                        width: parent.width

                        text: root.artistGenres
                        color: AppTheme.textSecondary
                        font.pixelSize: 13

                        wrapMode: Text.WordWrap
                        maximumLineCount: 2

                        visible: text.length > 0
                    }

                    Label {
                        width: parent.width

                        text: root.artistDescription
                        color: AppTheme.textSecondary
                        font.pixelSize: 12

                        wrapMode: Text.WordWrap
                        maximumLineCount: 3

                        elide: Text.ElideRight
                        visible: text.length > 0
                    }

                    Row {
                        spacing: 8

                        Button {
                            id: listenButton
                            icon.name: "media-playback-start"
                            text: root.radioLoading ? qsTr("Загрузка...") : qsTr("Слушать")
                            highlighted: true
                            enabled: !root.loading &&
                                !root.radioLoading &&
                                root.artistController !== null &&
                                root.artistModel !== null &&
                                artistTracksView.count > 0

                            onClicked: {
                                if (root.artistController !== null) {
                                    root.artistController.playArtist()
                                }
                            }
                        }

                        Button {
                            text: qsTr("Скачать популярное")
                            icon.name: "download"
                            enabled: artistTracksView.count > 0
                            onClicked: {
                                if (root.controller && root.artistModel) {
                                    for (let i = 0; i < root.artistModel.count; ++i) {
                                        const t = root.artistModel.get ? root.artistModel.get(i) : null
                                        if (t && t.id) {
                                            root.controller.downloadTrack(
                                                String(t.id), String(t.title || ""), String(t.artist || root.artistName),
                                                String(t.album || ""), String(t.coverUri || ""), Number(t.durationMs || 0)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // СЕКЦИЯ «ПОПУЛЯРНЫЕ ТРЕКИ»
        // =====================================================================
        Rectangle {
            id: tracksPanel

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

                    text: qsTr("Популярные треки")
                    color: AppTheme.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                }

                ListView {
                    id: artistTracksView

                    width: parent.width
                    implicitHeight: count * 68

                    model: root.artistModel

                    interactive: false
                    clip: true
                    spacing: 4

                    delegate: TrackRow {
                        width: artistTracksView.width

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
                        showAdd: true

                        rowHeight: 64
                        coverSize: 48
                        cornerRadius: 8

                        onActivated: {
                            if (root.controller !== null) {
                                root.controller.selectArtistTrack(index)
                            } else if (root.artistController !== null) {
                                root.artistController.selectTrack(index)
                            }
                        }

                        onAddRequested: function(trackId, albumId) {
                            addToPlaylistPopup.trackId = trackId
                            addToPlaylistPopup.albumId = albumId
                            addToPlaylistPopup.open()
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: root.loading ? qsTr("Загрузка...") : qsTr("Треки не найдены")
                        color: AppTheme.textMuted
                        font.pixelSize: 14
                        visible: artistTracksView.count === 0
                    }
                }
            }
        }

        // =====================================================================
        // СЕКЦИЯ «ПОСЛЕДНИЙ РЕЛИЗ»
        // =====================================================================
        Column {
            width: parent.width
            spacing: 12
            visible: root.newReleaseTitle.length > 0

            Label {
                text: qsTr("Последний релиз")
                color: AppTheme.textPrimary
                font.pixelSize: 22
                font.bold: true
            }

            Rectangle {
                width: Math.min(parent.width, 360)
                height: 100
                radius: 10
                color: releaseMouseArea.containsMouse ? AppTheme.panelHover : AppTheme.panel
                border.width: 1
                border.color: releaseMouseArea.containsMouse ? AppTheme.border : AppTheme.borderSubtle

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 14

                    Rectangle {
                        width: 80
                        height: 80
                        radius: 8
                        color: AppTheme.artworkPlaceholder
                        clip: true

                        Image {
                            id: newReleaseThumb
                            anchors.fill: parent
                            source: root.newReleaseCoverUri.length > 0
                                ? "image://yandex/" + root.newReleaseCoverUri
                                : ""
                            sourceSize: Qt.size(80, 80)
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
                            font.pixelSize: 28
                            visible: newReleaseThumb.status !== Image.Ready
                        }
                    }

                    Column {
                        width: parent.width - 104
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Label {
                            text: qsTr("РЕЛИЗ")
                            color: AppTheme.textMuted
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Label {
                            width: parent.width
                            text: root.newReleaseTitle
                            color: AppTheme.textPrimary
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Label {
                            text: root.newReleaseYear > 0 ? String(root.newReleaseYear) : ""
                            color: AppTheme.textSecondary
                            font.pixelSize: 12
                            visible: root.newReleaseYear > 0
                        }
                    }
                }

                MouseArea {
                    id: releaseMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.controller && root.newReleaseId.length > 0) {
                            root.controller.loadAlbum(root.newReleaseId)
                        }
                    }
                }
            }
        }

        // =====================================================================
        // СЕКЦИЯ «ВСЕ АЛЬБОМЫ»
        // =====================================================================
        Column {
            width: parent.width
            spacing: 12
            visible: root.albumsModel !== null && root.albumsModel.count > 0

            Label {
                text: qsTr("Все альбомы")
                color: AppTheme.textPrimary
                font.pixelSize: 22
                font.bold: true
            }

            Flow {
                width: parent.width
                spacing: 14

                Repeater {
                    model: root.albumsModel

                    delegate: PlaylistCard {
                        id: albumCard
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

        // =====================================================================
        // СЕКЦИЯ «ПОХОЖИЕ ИСПОЛНИТЕЛИ»
        // =====================================================================
        Column {
            width: parent.width
            spacing: 12
            visible: root.artistController && root.artistController.similarArtistsModel && root.artistController.similarArtistsModel.count > 0

            Label {
                text: qsTr("Похожие исполнители")
                color: AppTheme.textPrimary
                font.pixelSize: 22
                font.bold: true
            }

            Flow {
                width: parent.width
                spacing: 14

                Repeater {
                    model: root.artistController ? root.artistController.similarArtistsModel : null

                    delegate: KdeMediaCard {
                        id: similarArtistCard
                        cardWidth: 150
                        title: model.name || model.title || ""
                        coverUri: model.coverUri || ""
                        roundArtwork: true
                        showPlayButton: false

                        onActivated: {
                            if (root.controller && model.artistId) {
                                root.controller.loadArtist(model.artistId)
                            }
                        }
                    }
                }
            }
        }

        // Нижний отступ (внутри Column, поэтому скроллится с контентом)
        Item {
            width: 1
            height: 140
        }
    }

    BusyIndicator {
        id: loadingIndicator

        anchors.centerIn: parent

        width: 32
        height: 32

        running: root.loading && root.artistName.length === 0
        visible: running
        z: 100
    }

    Label {
        anchors.centerIn: parent

        text: qsTr("Выберите исполнителя")
        color: AppTheme.textMuted
        font.pixelSize: 14

        visible: !root.loading && root.artistName.length === 0
        z: 101
    }
}