import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller: null

    width: parent ? parent.width : 0
    implicitWidth: width
    implicitHeight: contentColumn.implicitHeight + 40
    height: implicitHeight

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 680

    readonly property int effectiveCardWidth:
        isMobile ? Math.floor((contentColumn.width - 14) / 2) : 168
    readonly property int effectiveCardHeight:
        isMobile ? Math.round(effectiveCardWidth + 56) : 210

    Kirigami.PromptDialog {
        id: createPlaylistDialog
        title: qsTr("Новый плейлист")
        subtitle: qsTr("Введите название нового плейлиста")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        QQC2.TextField {
            id: newPlaylistNameField
            placeholderText: qsTr("Название плейлиста")
            focus: true
        }

        onAccepted: {
            const name = newPlaylistNameField.text.trim()
            if (name.length > 0 && root.controller) {
                root.controller.createPlaylist(name)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    Column {
        id: contentColumn

        width: parent.width
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.isMobile ? 14 : 24

        spacing: 28

        Kirigami.Heading {
            width: parent.width
            level: 1
            text: qsTr("Плейлисты")
            font.bold: true
        }

        // =====================================================================
        // СЕКЦИЯ: ВАШИ ПЛЕЙЛИСТЫ (СОЗДАННЫЕ ПОЛЬЗОВАТЕЛЕМ)
        // =====================================================================
        Column {
            width: parent.width
            spacing: 14

            RowLayout {
                width: parent.width

                Kirigami.Heading {
                    level: 2
                    text: qsTr("Ваши плейлисты")
                }

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    icon.name: "list-add"
                    text: qsTr("Создать плейлист")
                    onClicked: {
                        newPlaylistNameField.text = ""
                        createPlaylistDialog.open()
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: 14

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

                // Карточки из libraryPlaylistsModel
                Repeater {
                    model: root.controller !== null && root.controller !== undefined
                        ? root.controller.libraryPlaylistsModel
                        : null

                    delegate: PlaylistCard {
                        id: libPlaylistCard

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
        }

        // =====================================================================
        // СЕКЦИЯ: РЕКОМЕНДОВАННЫЕ ПЛЕЙЛИСТЫ
        // =====================================================================
        Repeater {
            model: root.controller !== null && root.controller !== undefined
                ? root.controller.personalPlaylistsModel
                : null

            delegate: Column {
                id: sectionItem

                required property string title
                required property string type
                required property var playlists

                width: contentColumn.width
                spacing: 12

                visible: sectionItem.playlists !== null &&
                    sectionItem.playlists !== undefined &&
                    sectionItem.playlists.length > 0

                Kirigami.Heading {
                    width: parent.width
                    level: 2
                    text: sectionItem.title
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Flow {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: sectionItem.playlists

                        delegate: PlaylistCard {
                            required property var modelData

                            cardWidth: root.effectiveCardWidth
                            cardHeight: root.effectiveCardHeight
                            controller: root.controller
                            coverUri: String(modelData.coverUri || modelData.coverUrl || "")
                            title: String(modelData.title || modelData.name || "")
                            trackCount: Number(modelData.trackCount || 0)

                            onActivated: {
                                if (root.controller === null || root.controller === undefined) {
                                    return
                                }

                                const uid = String(modelData.uid || "")
                                const kind = Number(modelData.kind || 0)

                                if (uid.length === 0 || kind <= 0) {
                                    return
                                }

                                root.controller.selectPersonalPlaylist(uid, kind)
                            }
                        }
                    }
                }
            }
        }
    }
}
