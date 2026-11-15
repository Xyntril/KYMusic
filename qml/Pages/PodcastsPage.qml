import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller: null

    readonly property var podcasts:
        root.controller !== null && root.controller !== undefined
            ? root.controller.podcasts
            : []

    readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode) || contentColumn.width < 540

    readonly property int columns: isMobile
        ? 2
        : Math.max(2, Math.floor((contentColumn.width + 12) / (180 + 12)))

    width: parent ? parent.width : 0
    implicitWidth: width
    implicitHeight: contentColumn.implicitHeight + 40
    height: implicitHeight

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
        anchors.margins: 20

        spacing: 28

        Label {
            width: parent.width

            text: "Подкасты"
            color: AppTheme.textPrimary
            font.pixelSize: 28
            font.bold: true
            elide: Text.ElideRight
        }

        Label {
            width: parent.width

            visible: root.podcasts.length === 0

            text: "Подкасты пока не загрузились"
            color: AppTheme.textSecondary
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
        }

        Grid {
            width: parent.width

            columns: root.columns
            rowSpacing: 16
            columnSpacing: 12

            Repeater {
                model: root.podcasts

                delegate: KdeMediaCard {
                    required property var modelData

                    cardWidth: Math.floor((contentColumn.width - (root.columns - 1) * 12) / root.columns)
                    title: String(modelData.title || "")
                    subtitle: String(modelData.description || "")
                    coverUri: String(modelData.coverUri || "")

                    onActivated: {
                        if (root.controller && modelData.id) {
                            root.controller.playAlbum(modelData.id)
                        }
                    }
                    onPlayRequested: {
                        if (root.controller && modelData.id) {
                            root.controller.playAlbum(modelData.id)
                        }
                    }
                }
            }
        }
    }
}