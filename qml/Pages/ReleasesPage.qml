import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller

    width: parent ? parent.width : 0
    implicitWidth: width
    height: implicitHeight

    readonly property var personalController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.personalController !== undefined
            ? root.controller.personalController
            : null

    readonly property int cardWidth: 180
    readonly property int cardSpacing: 18

    readonly property var albums:
        root.personalController !== null
            ? root.personalController.newReleasesAlbums()
            : []

    readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode) || root.width < 540

    readonly property int columns: isMobile
        ? 2
        : Math.max(2, Math.floor((root.width + root.cardSpacing) / (root.cardWidth + root.cardSpacing)))

    readonly property int effectiveCardWidth: Math.floor(
        (root.width - (root.columns - 1) * root.cardSpacing) / root.columns)

    readonly property int rowCount: Math.ceil(
        (root.albums ? root.albums.length : 0) / root.columns)

    readonly property int cardHeight: root.effectiveCardWidth + 56

    implicitHeight:
        headerHeight +
        root.rowCount * (root.cardHeight + 22)

    readonly property int headerHeight: 70

    Component.onCompleted: {
        if (root.controller !== null && root.controller !== undefined) {
            root.controller.loadRecommendations()
        }
    }

    Column {
        id: content

        width: parent.width
        spacing: 20

        Kirigami.Heading {
            width: parent.width
            level: 2
            text: qsTr("Новые релизы")
        }

        Grid {
            width: parent.width

            columns: root.columns
            spacing: root.cardSpacing

            Repeater {
                model: root.albums

                delegate: KdeMediaCard {
                    required property var modelData

                    cardWidth: root.effectiveCardWidth
                    cardHeight: root.cardHeight
                    title: String(modelData.title || "")
                    subtitle: Number(modelData.year || 0) > 0 ? String(modelData.year) : ""
                    coverUri: modelData.coverUri ? String(modelData.coverUri) : ""

                    onActivated: {
                        const albumId = String(modelData.albumId || "")
                        if (root.controller && albumId.length > 0) {
                            root.controller.loadAlbum(albumId)
                        }
                    }
                    onPlayRequested: {
                        const albumId = String(modelData.albumId || "")
                        if (root.controller && albumId.length > 0) {
                            root.controller.playAlbum(albumId)
                        }
                    }
                }
            }
        }
    }
}