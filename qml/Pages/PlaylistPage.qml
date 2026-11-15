import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Home"
import "../Components"

Item {
    id: root

    property var controller

    readonly property bool fillHeight: true
    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 680

    property string filterText: ""
    property bool isSearchVisible: false

    width: parent ? parent.width : 0
    height: parent ? parent.height : 700
    implicitWidth: width
    implicitHeight: height

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    AmbientGlow {
        anchors.fill: parent
        coverUri: root.controller !== null && root.controller !== undefined
            ? String(root.controller.currentPlaylistCoverUri || "")
            : ""
        glowOpacity: 0.16
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.isMobile ? 14 : 24
        spacing: root.isMobile ? 12 : 20

        // =====================================================================
        // 1. МОБИЛЬНАЯ ШАПКА ПЛЕЙЛИСТА
        // =====================================================================
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: root.isMobile

            // Верхний ряд: кнопка поиска и меню ⋯
            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                QQC2.ToolButton {
                    icon.name: "search"
                    checkable: true
                    checked: root.isSearchVisible
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Поиск по трекам")
                    onClicked: root.isSearchVisible = !root.isSearchVisible
                }

                QQC2.ToolButton {
                    id: mobileMoreBtn
                    icon.name: "overflow-menu"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Действия с плейлистом")
                    visible: root.controller && root.controller.currentPlaylistKind > 0
                    onClicked: playlistMenu.popup(mobileMoreBtn, 0, mobileMoreBtn.height)
                }
            }

            // Центр: Крупная скруглённая обложка (180x180, radius 12)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(200, Math.max(140, root.width * 0.48))
                Layout.preferredHeight: Layout.preferredWidth
                radius: 12
                color: AppTheme.panelSecondary
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20)
                clip: true

                Image {
                    id: mobileArtwork
                    anchors.fill: parent
                    source: root.controller !== null && root.controller !== undefined &&
                        root.controller.currentPlaylistCoverUri.length > 0
                        ? "image://yandex/" + root.controller.currentPlaylistCoverUri
                        : ""
                    sourceSize: Qt.size(400, 400)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    visible: status === Image.Ready
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 64
                    height: 64
                    source: "view-media-playlist"
                    color: Kirigami.Theme.disabledTextColor
                    visible: mobileArtwork.status !== Image.Ready
                }
            }

            // Название плейлиста и счётчик треков
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: root.controller !== null && root.controller !== undefined &&
                        root.controller.currentPlaylistTitle.length > 0
                        ? root.controller.currentPlaylistTitle
                        : qsTr("Плейлист")
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.controller !== null && root.controller !== undefined &&
                        root.controller.currentPlaylistTrackCount > 0
                        ? qsTr("%1 треков").arg(root.controller.currentPlaylistTrackCount)
                        : (root.controller && root.controller.loadingPlaylist ? qsTr("Загрузка…") : "")
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Плашка «▶ Моя волна по плейлисту»
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.16)
                border.width: 1
                border.color: Kirigami.Theme.highlightColor

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Kirigami.Icon {
                        source: "media-playback-start"
                        implicitWidth: 18
                        implicitHeight: 18
                        color: Kirigami.Theme.highlightColor
                    }

                    QQC2.Label {
                        text: qsTr("Моя волна по плейлисту «%1»").arg(root.controller ? root.controller.currentPlaylistTitle : "")
                        font.weight: Font.DemiBold
                        color: Kirigami.Theme.highlightColor
                        elide: Text.ElideRight
                        Layout.maximumWidth: root.width - 80
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.controller) {
                            if (typeof appController !== "undefined" && appController.startPlaylistWave) {
                                appController.startPlaylistWave(
                                    root.controller.currentPlaylistUid || "",
                                    root.controller.currentPlaylistKind || 0,
                                    root.controller.currentPlaylistTitle || ""
                                )
                            } else {
                                root.controller.selectPlaylistTrack(0)
                            }
                        }
                    }
                }
            }

            // Кнопки «Скачать» и «▶ Слушать»
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                QQC2.Button {
                    icon.name: "download"
                    text: qsTr("Скачать")
                    onClicked: {
                        if (typeof appController !== "undefined" && appController.downloadPlaylistTracks) {
                            appController.downloadPlaylistTracks()
                        }
                    }
                }

                QQC2.Button {
                    icon.name: "media-playback-start"
                    text: qsTr("Слушать")
                    highlighted: true
                    onClicked: {
                        if (root.controller) {
                            root.controller.selectPlaylistTrack(0)
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 2. ДЕСКТОПНАЯ ШАПКА ПЛЕЙЛИСТА
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            visible: !root.isMobile

            // Обложка плейлиста (180x180, radius 10, Breeze)
            Rectangle {
                Layout.preferredWidth: 180
                Layout.preferredHeight: 180
                radius: 10
                color: AppTheme.panelSecondary
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20)
                clip: true

                Image {
                    id: desktopArtwork
                    anchors.fill: parent
                    source: root.controller !== null && root.controller !== undefined &&
                        root.controller.currentPlaylistCoverUri.length > 0
                        ? "image://yandex/" + root.controller.currentPlaylistCoverUri
                        : ""
                    sourceSize: Qt.size(360, 360)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    visible: status === Image.Ready
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 64
                    height: 64
                    source: "view-media-playlist"
                    color: Kirigami.Theme.disabledTextColor
                    visible: desktopArtwork.status !== Image.Ready
                }
            }

            // Описание, заголовок и кнопки действий
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                QQC2.Label {
                    text: qsTr("ПЛЕЙЛИСТ")
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Kirigami.Theme.disabledTextColor
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 1
                    text: root.controller !== null && root.controller !== undefined &&
                        root.controller.currentPlaylistTitle.length > 0
                        ? root.controller.currentPlaylistTitle
                        : qsTr("Плейлист")
                    font.bold: true
                    elide: Text.ElideRight
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.controller !== null && root.controller !== undefined &&
                        root.controller.currentPlaylistTrackCount > 0
                        ? qsTr("%1 треков").arg(root.controller.currentPlaylistTrackCount)
                        : (root.controller && root.controller.loadingPlaylist ? qsTr("Загрузка…") : "")
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: 13
                }

                // Ряд кнопок: ▶ Слушать, ⬇ Скачать, ▶ Моя волна, ⋯
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    QQC2.Button {
                        icon.name: "media-playback-start"
                        text: qsTr("Слушать")
                        highlighted: true
                        onClicked: {
                            if (root.controller) {
                                root.controller.selectPlaylistTrack(0)
                            }
                        }
                    }

                    QQC2.Button {
                        icon.name: "download"
                        text: qsTr("Скачать")
                        onClicked: {
                            if (typeof appController !== "undefined" && appController.downloadPlaylistTracks) {
                                appController.downloadPlaylistTracks()
                            }
                        }
                    }

                    QQC2.Button {
                        icon.name: "media-playlist-shuffle"
                        text: qsTr("Моя волна по плейлисту")
                        onClicked: {
                            if (root.controller) {
                                if (typeof appController !== "undefined" && appController.startPlaylistWave) {
                                    appController.startPlaylistWave(
                                        root.controller.currentPlaylistUid || "",
                                        root.controller.currentPlaylistKind || 0,
                                        root.controller.currentPlaylistTitle || ""
                                    )
                                } else {
                                    root.controller.selectPlaylistTrack(0)
                                }
                            }
                        }
                    }

                    QQC2.ToolButton {
                        id: desktopMoreBtn
                        icon.name: "overflow-menu"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: qsTr("Действия с плейлистом")
                        visible: root.controller && root.controller.currentPlaylistKind > 0
                        onClicked: playlistMenu.popup(desktopMoreBtn, 0, desktopMoreBtn.height)
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        // =====================================================================
        // 3. ПОЛЕ ПОИСКА ПО ТРЕКАМ ПЛЕЙЛИСТА
        // =====================================================================
        Kirigami.SearchField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: qsTr("Поиск трека в плейлисте…")
            visible: !root.isMobile || root.isSearchVisible
            onTextChanged: root.filterText = text.trim()
        }

        // =====================================================================
        // 4. СПИСОК ТРЕКОВ
        // =====================================================================
        PlaylistView {
            id: playlistView
            Layout.fillWidth: true
            Layout.fillHeight: true
            controller: root.controller
            filterText: root.filterText
            visible: root.controller !== null && root.controller !== undefined &&
                !root.controller.loadingPlaylist
        }
    }

    // Выпадающее меню действий плейлиста
    QQC2.Menu {
        id: playlistMenu

        QQC2.MenuItem {
            text: qsTr("Переименовать плейлист")
            icon.name: "edit-rename"
            onTriggered: {
                renameDialog.newName = root.controller.currentPlaylistTitle
                nameField.text = root.controller.currentPlaylistTitle
                renameDialog.open()
            }
        }

        QQC2.MenuItem {
            text: qsTr("Удалить плейлист")
            icon.name: "edit-delete"
            onTriggered: deleteConfirmDialog.open()
        }
    }

    // Нативный диалог удаления плейлиста
    Kirigami.PromptDialog {
        id: deleteConfirmDialog
        title: qsTr("Удалить плейлист?")
        subtitle: qsTr("Вы действительно хотите удалить плейлист «%1»?").arg(
            root.controller ? root.controller.currentPlaylistTitle : ""
        )
        standardButtons: Kirigami.Dialog.Yes | Kirigami.Dialog.Cancel
        onAccepted: {
            if (root.controller) {
                root.controller.deleteCurrentPlaylist()
            }
            if (typeof mainLayout !== "undefined" && mainLayout.backRequested) {
                mainLayout.backRequested()
            }
        }
    }

    // Нативный диалог переименования плейлиста
    Kirigami.PromptDialog {
        id: renameDialog
        property string newName: ""
        title: qsTr("Переименовать плейлист")
        subtitle: qsTr("Введите новое название плейлиста:")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        QQC2.TextField {
            id: nameField
            Layout.fillWidth: true
            text: renameDialog.newName
            selectByMouse: true
            onAccepted: renameDialog.accept()
            Component.onCompleted: forceActiveFocus()
        }

        onAccepted: {
            if (root.controller && nameField.text.trim().length > 0) {
                root.controller.renameCurrentPlaylist(nameField.text.trim())
            }
        }
    }
}
