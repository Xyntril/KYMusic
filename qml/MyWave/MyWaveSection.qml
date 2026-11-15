import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller: null
    property bool compactMode: false

    readonly property bool hasController:
        root.controller !== null && root.controller !== undefined

    readonly property var waveModel:
        root.hasController ? root.controller.myWaveModel : null

    readonly property int trackCount:
        root.waveModel !== null && root.waveModel !== undefined
            ? Number(root.waveModel.count)
            : 0

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 600

    readonly property bool hasTracks: root.trackCount > 0

    readonly property int horizontalMargin: root.compactMode ? 12 : (isMobile ? 10 : 24)
    readonly property int verticalMargin: root.compactMode ? 12 : (isMobile ? 10 : 20)

    implicitWidth: parent ? parent.width : 400
    implicitHeight: root.compactMode ? 320 : (parent ? parent.height : 600)

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    // Верхний заголовок раздела
    Item {
        id: headerArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: root.verticalMargin
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        height: 38

        RowLayout {
            anchors.fill: parent
            spacing: 12

            QQC2.ToolButton {
                visible: root.isMobile && typeof mainLayout !== "undefined" && !mainLayout.canGoBack
                icon.name: "application-menu"
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Меню")
                onClicked: {
                    if (typeof mainLayout !== "undefined" && mainLayout.openMenu) {
                        mainLayout.openMenu(this)
                    }
                }
            }

            Kirigami.Heading {
                level: 2
                text: qsTr("Моя волна")
                elide: Text.ElideRight
            }

            Item { Layout.fillWidth: true }

            QQC2.Label {
                text: root.hasTracks ? qsTr("%1 треков").arg(root.trackCount) : ""
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 13
                visible: !root.isMobile && text.length > 0
            }
        }
    }

    // Полноценный рабочий список треков с прокруткой мышкой и скроллбаром
    ListView {
        id: trackList
        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 12
        anchors.leftMargin: root.horizontalMargin
        anchors.rightMargin: root.horizontalMargin
        anchors.bottomMargin: 16

        model: root.waveModel

        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 6
        cacheBuffer: 600

        onMovementEnded: {
            if (atYEnd && root.controller) {
                root.controller.loadMoreMyWave()
            }
        }

        onContentYChanged: {
            if (contentY > 0 && (contentHeight - contentY - height) < 300) {
                if (root.controller) {
                    root.controller.loadMoreMyWave()
                }
            }
        }

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: waveScrollBar
            policy: QQC2.ScrollBar.AsNeeded
            width: root.isMobile ? 3 : 10
            opacity: root.isMobile ? (active ? 0.5 : 0) : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        delegate: TrackRow {
            id: trackDelegate

            required property var modelData
            required property int index

            coverSize: root.isMobile ? 48 : 52
            rowHeight: root.isMobile ? 56 : 64

            width: trackList.width - (waveScrollBar.visible ? waveScrollBar.width + 16 : 16)

            controller: root.controller
            rowIndex: index
            trackId: modelData.id ? String(modelData.id) : ""
            title: String(modelData.title || "")
            artist: String(modelData.artist || "")
            artistId: modelData.artistId ? String(modelData.artistId) : ""
            artists: modelData.artists || []
            album: String(modelData.album || "")
            albumId: modelData.albumId ? String(modelData.albumId) : ""
            coverUri: modelData.coverUri ? String(modelData.coverUri) : ""
            durationMs: Number(modelData.durationMs || 0)

            liked: modelData.liked || false
            showLike: true
            showDislike: true
            showAdd: true

            onActivated: {
                if (root.controller) {
                    root.controller.selectMyWaveTrack(index)
                }
            }
            onAddRequested: function(trackId, albumId) {
                if (root.controller && root.controller.playlistPicker) {
                    root.controller.playlistPicker.trackId = trackId
                    root.controller.playlistPicker.albumId = albumId
                    root.controller.playlistPicker.open()
                }
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - 48
            visible: !root.hasTracks
            icon.name: "network-wireless"
            text: qsTr("Загрузка «Моей волны»...")
        }
    }
}
