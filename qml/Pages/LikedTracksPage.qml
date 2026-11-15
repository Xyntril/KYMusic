import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Kirigami.ScrollablePage {
    id: root

    property var controller: null
    property string filterText: ""

    title: qsTr("Мне нравится")

    readonly property var likedModel:
        root.controller && root.controller.likedTracksModel
            ? root.controller.likedTracksModel
            : null

    readonly property int totalCount: likedModel ? likedModel.count : 0

    readonly property string firstCoverUri: {
        if (likedModel && likedModel.count > 0 && likedModel.get) {
            const first = likedModel.get(0)
            return first ? String(first.coverUri || "") : ""
        }
        return ""
    }

    AmbientGlow {
        anchors.fill: parent
        coverUri: root.firstCoverUri
        glowOpacity: 0.18
    }

    ColumnLayout {
        width: parent.width
        spacing: 20

        // =====================================================================
        // ШАПКА РАЗДЕЛА «МНЕ НРАВИТСЯ» (KDE Breeze Style)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + 32
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: 16
                spacing: 20

                // Иконка-обложка (квадратная, скругление 10)
                Rectangle {
                    Layout.preferredWidth: 128
                    Layout.preferredHeight: 128
                    radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Kirigami.Theme.highlightColor }
                        GradientStop { position: 1.0; color: Qt.darker(Kirigami.Theme.highlightColor, 1.4) }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "starred-symbolic"
                        implicitWidth: 64
                        implicitHeight: 64
                        color: Kirigami.Theme.highlightedTextColor
                    }
                }

                // Описание и действия
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    QQC2.Label {
                        text: qsTr("ПЛЕЙЛИСТ")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 1
                        text: qsTr("Мне нравится")
                        font.bold: true
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.totalCount > 0
                            ? qsTr("%1 треков").arg(root.totalCount)
                            : qsTr("Нет треков")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: 13
                    }

                    Item { Layout.preferredHeight: 4 }

                    // Кнопки управления в адаптивном Flow
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        QQC2.Button {
                            text: qsTr("Слушать")
                            icon.name: "media-playback-start"
                            highlighted: true
                            enabled: root.totalCount > 0
                            onClicked: {
                                if (root.controller) {
                                    root.controller.selectLikedTrack(0)
                                }
                            }
                        }

                        QQC2.Button {
                            text: qsTr("Моя волна")
                            icon.name: "media-playlist-shuffle"
                            enabled: root.totalCount > 0
                            onClicked: {
                                if (root.controller) {
                                    root.controller.startCollectionWave()
                                }
                            }
                        }

                        QQC2.Button {
                            text: qsTr("Скачать")
                            icon.name: "download"
                            enabled: root.totalCount > 0
                            onClicked: {
                                if (root.controller && root.controller.downloadLikedTracks) {
                                    root.controller.downloadLikedTracks()
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // ПОИСК ПО ПОНРАВИВШИМСЯ ТРЕКАМ
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Kirigami.SearchField {
                id: likedSearchField
                Layout.fillWidth: true
                placeholderText: qsTr("Поиск по понравившимся трекам…")
                onTextChanged: root.filterText = text.trim().toLowerCase()
            }
        }

        // =====================================================================
        // СПИСОК ТРЕКОВ
        // =====================================================================
        ListView {
            id: likedListView
            Layout.fillWidth: true
            implicitHeight: count * 56 + 100
            interactive: false
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4
            clip: true

            model: root.totalCount

            delegate: TrackRow {
                id: trackDel
                required property int index

                readonly property var trackData: (root.likedModel && root.likedModel.get)
                    ? root.likedModel.get(trackDel.index)
                    : null

                readonly property string itemTitle: trackData ? String(trackData.title || "") : ""
                readonly property string itemArtist: trackData ? String(trackData.artist || "") : ""

                readonly property bool matchesFilter: {
                    if (root.filterText.length === 0) return true
                    return itemTitle.toLowerCase().indexOf(root.filterText) !== -1 ||
                           itemArtist.toLowerCase().indexOf(root.filterText) !== -1
                }

                visible: matchesFilter
                height: matchesFilter ? 52 : 0

                width: likedListView.width
                controller: root.controller
                rowIndex: trackDel.index
                trackId: trackData ? String(trackData.id || "") : ""
                title: itemTitle
                artist: itemArtist
                artistId: trackData ? String(trackData.artistId || "") : ""
                album: trackData ? String(trackData.album || "") : ""
                albumId: trackData ? String(trackData.albumId || "") : ""
                coverUri: trackData ? String(trackData.coverUri || "") : ""
                durationMs: trackData ? Number(trackData.durationMs || 0) : 0

                liked: true
                showLike: true
                showDislike: true
                showAdd: true

                onActivated: {
                    if (root.controller) {
                        root.controller.selectLikedTrack(index)
                    }
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - 48
                visible: root.totalCount === 0 && (!root.controller || !root.controller.loadingLikedTracks)
                icon.name: "starred-symbolic"
                text: qsTr("Нет понравившихся треков")
                explanation: qsTr("Нажмите на сердечко или звёздочку у трека, чтобы добавить его сюда.")
            }
        }
    }

    Component.onCompleted: {
        if (root.controller && root.totalCount === 0) {
            root.controller.loadLikedTracks()
        }
    }
}
