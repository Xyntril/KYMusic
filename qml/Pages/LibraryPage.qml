import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller

    signal likedRequested()
    signal playlistsRequested()

    readonly property bool fillHeight: true
    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 680

    readonly property int effectiveCardWidth:
        isMobile ? Math.floor((width - 48 - 14) / 2) : 168
    readonly property int effectiveCardHeight:
        isMobile ? Math.round(effectiveCardWidth + 56) : 210

    property int collectionTab: 0 // 0 = Вы собрали, 1 = Вам понравилось

    width: parent ? parent.width : 0
    height: parent ? parent.height : 700
    implicitWidth: width
    implicitHeight: height

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    // Единственный нативный вертикальный скроллбар всей страницы
    Flickable {
        id: pageFlickable
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: mainContentColumn.implicitHeight + (root.isMobile ? 24 : 48)

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            policy: QQC2.ScrollBar.AsNeeded
            width: root.isMobile ? 4 : undefined
        }

        ColumnLayout {
            id: mainContentColumn
            width: parent.width - (root.isMobile ? 24 : 48)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.isMobile ? 16 : 24
            spacing: root.isMobile ? 18 : 28

            // =================================================================
            // 1. ЗАГОЛОВОК СТРАНИЦЫ
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: qsTr("Медиатека")
                    font.bold: true
                }

                QQC2.ToolButton {
                    visible: (typeof window !== "undefined" && window.isMobileMode)
                    icon.name: "application-menu"
                    onClicked: {
                        if (typeof mainLayout !== "undefined") {
                            mainLayout.openMenu(this)
                        }
                    }
                }
            }

            // =================================================================
            // 2. АКЦЕНТНЫЙ БАННЕР «▶ МОЯ ВОЛНА ПО КОЛЛЕКЦИИ» (KDE Breeze Style)
            // =================================================================
            Rectangle {
                id: waveBanner
                Layout.fillWidth: true
                implicitHeight: root.isMobile ? 64 : 76
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, waveMouse.containsMouse ? 0.22 : 0.12)
                border.width: 1
                border.color: Kirigami.Theme.highlightColor

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.isMobile ? 10 : 16
                    spacing: root.isMobile ? 12 : 16

                    Rectangle {
                        Layout.preferredWidth: root.isMobile ? 40 : 46
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: Kirigami.Theme.highlightColor

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            source: "media-playback-start"
                            implicitWidth: root.isMobile ? 20 : 24
                            implicitHeight: implicitWidth
                            color: Kirigami.Theme.highlightedTextColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: qsTr("Моя волна по коллекции")
                            color: Kirigami.Theme.textColor
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: qsTr("Бесконечный поток треков на основе вашей медиатеки")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: root.isMobile ? 11 : 12
                            elide: Text.ElideRight
                        }
                    }

                    Kirigami.Icon {
                        source: "go-next"
                        implicitWidth: 18
                        implicitHeight: 18
                        color: Kirigami.Theme.disabledTextColor
                    }
                }

                MouseArea {
                    id: waveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.controller) {
                            root.controller.loadMyWave()
                        }
                    }
                }
            }

            // =================================================================
            // 3. СЕКЦИЯ «МНЕ НРАВИТСЯ >» (превью из первых 3–5 треков)
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Кликабельный заголовок секции «Мне нравится >»
                Item {
                    Layout.fillWidth: true
                    implicitHeight: likedHeaderRow.implicitHeight

                    RowLayout {
                        id: likedHeaderRow
                        anchors.left: parent.left
                        spacing: 8

                        Kirigami.Heading {
                            level: 2
                            text: qsTr("Мне нравится")
                            color: likedMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }

                        QQC2.Label {
                            text: {
                                const count = (root.controller && root.controller.likedTracksModel)
                                    ? root.controller.likedTracksModel.count
                                    : 0
                                return count > 0 ? qsTr("• %1 треков").arg(count) : ""
                            }
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: 14
                        }

                        Kirigami.Icon {
                            source: "go-next"
                            implicitWidth: 16
                            implicitHeight: 16
                            color: likedMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                        }
                    }

                    MouseArea {
                        id: likedMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.likedRequested()
                        }
                    }
                }

                // Превью-контейнер понравившихся треков (без вложенного скролла!)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: likedPreviewColumn.implicitHeight + 16
                    radius: Kirigami.Units.cornerRadius
                    color: AppTheme.panel
                    border.width: 1
                    border.color: AppTheme.borderSubtle

                    ColumnLayout {
                        id: likedPreviewColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: 12
                            text: qsTr("Загрузка понравившихся треков…")
                            color: Kirigami.Theme.disabledTextColor
                            visible: root.controller && root.controller.loadingLikedTracks
                        }

                        // Список первых 3–5 треков
                        Repeater {
                            model: (root.controller && root.controller.likedTracksModel && !root.controller.loadingLikedTracks)
                                ? Math.min(5, root.controller.likedTracksModel.count)
                                : 0

                            delegate: TrackRow {
                                id: likedRowDelegate
                                required property int index

                                readonly property var itemData: (root.controller && root.controller.likedTracksModel && root.controller.likedTracksModel.get)
                                    ? root.controller.likedTracksModel.get(likedRowDelegate.index)
                                    : null

                                Layout.fillWidth: true
                                controller: root.controller
                                rowIndex: likedRowDelegate.index
                                trackId: itemData ? String(itemData.id || "") : ""
                                title: itemData ? String(itemData.title || "") : ""
                                artist: itemData ? String(itemData.artist || "") : ""
                                artistId: itemData ? String(itemData.artistId || "") : ""
                                album: itemData ? String(itemData.album || "") : ""
                                albumId: itemData ? String(itemData.albumId || "") : ""
                                coverUri: itemData ? String(itemData.coverUri || "") : ""
                                durationMs: itemData ? Number(itemData.durationMs || 0) : 0
                                liked: true
                                showLike: true
                                showDislike: true
                                showAdd: true

                                onActivated: {
                                    if (root.controller) {
                                        root.controller.selectLikedTrack(likedRowDelegate.index)
                                    }
                                }
                            }
                        }

                        // Ссылка на полный список
                        QQC2.ItemDelegate {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            visible: root.controller && root.controller.likedTracksModel && root.controller.likedTracksModel.count > 0

                            contentItem: RowLayout {
                                spacing: 6
                                QQC2.Label {
                                    text: qsTr("Смотреть все понравившиеся треки (%1) →").arg(
                                        root.controller && root.controller.likedTracksModel ? root.controller.likedTracksModel.count : 0
                                    )
                                    color: Kirigami.Theme.highlightColor
                                    font.weight: Font.DemiBold
                                }
                            }

                            onClicked: {
                                root.likedRequested()
                            }
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.margins: 12
                            text: qsTr("Нет понравившихся треков")
                            color: Kirigami.Theme.disabledTextColor
                            visible: root.controller && !root.controller.loadingLikedTracks &&
                                (root.controller.likedTracksModel === null || root.controller.likedTracksModel.count === 0)
                        }
                    }
                }
            }

            // =================================================================
            // 4. ДЕСКТОПНЫЙ РЕЖИМ: СЕКЦИЯ «ПЛЕЙЛИСТЫ И РАЗДЕЛЫ КОЛЛЕКЦИИ»
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: !root.isMobile

                // Переключатель [ Вы собрали | Вам понравилось ]
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitHeight: 36
                        implicitWidth: segRow.implicitWidth + 8
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                        RowLayout {
                            id: segRow
                            anchors.centerIn: parent
                            spacing: 4

                            QQC2.ToolButton {
                                text: qsTr("Вы собрали")
                                checkable: true
                                checked: root.collectionTab === 0
                                onClicked: root.collectionTab = 0
                            }

                            QQC2.ToolButton {
                                text: qsTr("Вам понравилось")
                                checkable: true
                                checked: root.collectionTab === 1
                                onClicked: root.collectionTab = 1
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Вкладка «Вы собрали»: карточка создания + ваши плейлисты
                Flow {
                    Layout.fillWidth: true
                    spacing: 14
                    visible: root.collectionTab === 0

                    // Карточка «+ Новый плейлист»
                    Rectangle {
                        width: root.effectiveCardWidth
                        height: root.effectiveCardHeight
                        radius: Kirigami.Units.cornerRadius
                        color: newPlaylistMouse.containsMouse
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
                            : AppTheme.panelSecondary
                        border.width: 1
                        border.color: newPlaylistMouse.containsMouse
                            ? Kirigami.Theme.highlightColor
                            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 0
                            spacing: 4

                            Rectangle {
                                Layout.preferredWidth: root.effectiveCardWidth
                                Layout.preferredHeight: root.effectiveCardWidth
                                radius: Kirigami.Units.cornerRadius
                                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "list-add"
                                    implicitWidth: 48
                                    implicitHeight: 48
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                Layout.rightMargin: 6
                                spacing: 1

                                Kirigami.Heading {
                                    Layout.fillWidth: true
                                    level: 4
                                    text: qsTr("Новый плейлист")
                                    font.bold: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    color: newPlaylistMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Создать")
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: newPlaylistMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                newPlaylistNameField.text = ""
                                createPlaylistDialog.open()
                            }
                        }
                    }

                    // Карточки плейлистов из LibraryPlaylistsModel
                    Repeater {
                        model: root.controller !== null && root.controller !== undefined
                            ? root.controller.libraryPlaylistsModel
                            : null

                        delegate: PlaylistCard {
                            id: deskPlaylistCard

                            cardWidth: root.effectiveCardWidth
                            cardHeight: root.effectiveCardHeight
                            title: (model.title && model.title.length > 0) ? model.title : qsTr("Плейлист")
                            trackCount: model.trackCount || 0
                            coverUri: model.coverUri || model.coverUrl || ""

                            onActivated: {
                                if (root.controller) {
                                    root.controller.selectLibraryPlaylist(index)
                                }
                            }
                            onPlayRequested: {
                                if (root.controller) {
                                    root.controller.selectLibraryPlaylist(index)
                                }
                            }
                        }
                    }
                }

                // Вкладка «Вам понравилось»: Сохранённые альбомы и любимые исполнители
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 20
                    visible: root.collectionTab === 1

                    // Сохранённые альбомы
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Kirigami.Heading {
                            level: 3
                            text: qsTr("Сохранённые альбомы")
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 12

                            Repeater {
                                model: root.controller ? root.controller.likedAlbumsModel : null
                                delegate: KdeMediaCard {
                                    id: likedAlbumCard

                                    cardWidth: root.isMobile ? root.effectiveCardWidth : 140
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

                        QQC2.Label {
                            text: qsTr("Нет сохранённых альбомов")
                            color: Kirigami.Theme.disabledTextColor
                            visible: root.controller && (root.controller.likedAlbumsModel === null || root.controller.likedAlbumsModel.count === 0)
                        }
                    }

                    // Любимые исполнители
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Kirigami.Heading {
                            level: 3
                            text: qsTr("Любимые исполнители")
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 12

                            Repeater {
                                model: root.controller ? root.controller.likedArtistsModel : null
                                delegate: KdeMediaCard {
                                    id: likedArtistCard

                                    cardWidth: root.isMobile ? root.effectiveCardWidth : 130
                                    roundArtwork: true
                                    title: model.name || model.title || ""
                                    coverUri: model.coverUri || ""

                                    onActivated: {
                                        if (root.controller && model.artistId) {
                                            root.controller.loadArtist(model.artistId)
                                        }
                                    }
                                }
                            }
                        }

                        QQC2.Label {
                            text: qsTr("Нет любимых исполнителей")
                            color: Kirigami.Theme.disabledTextColor
                            visible: root.controller && (root.controller.likedArtistsModel === null || root.controller.likedArtistsModel.count === 0)
                        }
                    }
                }
            }

            // =================================================================
            // 5. МОБИЛЬНЫЙ РЕЖИМ: 2-КОЛОНОЧНАЯ СЕТКА ПЛИТОК КОЛЛЕКЦИИ
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: root.isMobile

                Kirigami.Heading {
                    level: 2
                    text: qsTr("Ещё у вас в коллекции")
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    // 1. Плитка: Плейлисты (с превью UNDERTALE / обложки первого плейлиста)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: Kirigami.Units.cornerRadius
                        color: mobPlMouse.containsMouse ? AppTheme.panelActive : AppTheme.panelSecondary
                        border.width: 1
                        border.color: AppTheme.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 8
                                color: AppTheme.artworkPlaceholder
                                clip: true

                                Image {
                                    id: mobPlCover
                                    anchors.fill: parent
                                    readonly property string firstCover: (root.controller && root.controller.libraryPlaylistsModel && root.controller.libraryPlaylistsModel.count > 0)
                                        ? String(root.controller.libraryPlaylistsModel.data(root.controller.libraryPlaylistsModel.index(0, 0), 256 + 7) || "")
                                        : ""
                                    source: firstCover.length > 0 ? ("image://yandex/" + firstCover) : ""
                                    sourceSize: Qt.size(96, 96)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    visible: status === Image.Ready
                                }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "view-media-playlist"
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    visible: mobPlCover.status !== Image.Ready
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Плейлисты")
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Всё, Мне нравится")
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: mobPlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.playlistsRequested()
                            }
                        }
                    }

                    // 2. Плитка: Скачанное
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: Kirigami.Units.cornerRadius
                        color: mobDlMouse.containsMouse ? AppTheme.panelActive : AppTheme.panelSecondary
                        border.width: 1
                        border.color: AppTheme.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 8
                                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "folder-download"
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Скачанное")
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Кэш и загрузки")
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: mobDlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof mainLayout !== "undefined" && mainLayout.selectSection) {
                                    mainLayout.selectSection("liked")
                                }
                            }
                        }
                    }

                    // 3. Плитка: Подкасты
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: Kirigami.Units.cornerRadius
                        color: mobPodMouse.containsMouse ? AppTheme.panelActive : AppTheme.panelSecondary
                        border.width: 1
                        border.color: AppTheme.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 8
                                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "audio-headset"
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Подкасты")
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Шоу и выпуски")
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: mobPodMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof mainLayout !== "undefined" && mainLayout.selectSection) {
                                    mainLayout.selectSection("podcasts")
                                }
                            }
                        }
                    }

                    // 4. Плитка: Любимые исполнители / Статистика
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: Kirigami.Units.cornerRadius
                        color: mobArtistMouse.containsMouse ? AppTheme.panelActive : AppTheme.panelSecondary
                        border.width: 1
                        border.color: AppTheme.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 8
                                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "view-media-artist"
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Исполнители")
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Статистика и любимое")
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: mobArtistMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof mainLayout !== "undefined" && mainLayout.selectSection) {
                                    mainLayout.selectSection("stats")
                                }
                            }
                        }
                    }

                    // 5. Плитка: + Новый плейлист
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: Kirigami.Units.cornerRadius
                        color: mobNewPlMouse.containsMouse ? AppTheme.panelActive : AppTheme.panelSecondary
                        border.width: 1
                        border.color: AppTheme.borderSubtle

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 8
                                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "list-add"
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    color: Kirigami.Theme.highlightColor
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("+ Новый плейлист")
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Создать")
                                    color: Kirigami.Theme.disabledTextColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: mobNewPlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                newPlaylistNameField.text = ""
                                createPlaylistDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.controller === null || root.controller === undefined) {
            return
        }

        root.controller.loadLibrary()
        root.controller.loadLikedTracks()
    }

    // Нативный диалог создания плейлиста
    Kirigami.PromptDialog {
        id: createPlaylistDialog
        title: qsTr("Новый плейлист")
        subtitle: qsTr("Введите название для нового плейлиста:")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        QQC2.TextField {
            id: newPlaylistNameField
            Layout.fillWidth: true
            placeholderText: qsTr("Название плейлиста")
            selectByMouse: true
            onAccepted: createPlaylistDialog.accept()
            Component.onCompleted: forceActiveFocus()
        }

        onAccepted: {
            const name = newPlaylistNameField.text.trim()
            if (name.length > 0 && root.controller) {
                root.controller.createPlaylist(name)
            }
        }
    }
}
