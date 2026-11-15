import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0

QQC2.ItemDelegate {
    id: root

    property string title: ""
    property string subtitle: ""
    property string coverUri: ""
    property string imageUrl: ""
    property color backgroundColor: "transparent"
    property bool roundArtwork: false
    property bool preserveAspectFit: false
    property int cardWidth: 150
    property int cardHeight: 0
    property bool showPlayButton: true

    signal activated()
    signal playRequested()

    function normalizeCover(url) {
        if (!url || url.length === 0) return ""
        var s = String(url).trim()
        if (s.startsWith("image://") || s.startsWith("file://") || s.startsWith("qrc:/")) return s
        s = s.replace(/%%/g, "400x400").replace(/%25%25/g, "400x400")
        if (s.startsWith("//")) s = "https:" + s
        return "image://yandex/" + (root.roundArtwork ? "circle/" : "") + s
    }

    width: root.cardWidth
    implicitWidth: root.cardWidth
    height: root.cardHeight > 0
        ? root.cardHeight
        : Math.round(root.cardWidth + (root.title.length > 0 ? 56 : 12))
    implicitHeight: height

    padding: 6

    onClicked: root.activated()

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: (root.hovered || root.visualFocus) && !root.roundArtwork
            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
            : "transparent"

        border.width: (root.hovered || root.visualFocus) && !root.roundArtwork ? 1 : 0
        border.color: Kirigami.Theme.highlightColor

        Behavior on border.color {
            ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
    }

    contentItem: ColumnLayout {
        spacing: 6
        Layout.alignment: Qt.AlignTop

        Item {
            id: artworkBox
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            readonly property int preferredSide: root.roundArtwork ? 136 : (root.width - 12)
            Layout.preferredWidth: preferredSide
            Layout.preferredHeight: preferredSide
            width: preferredSide
            height: preferredSide

            Rectangle {
                id: artworkContainer
                anchors.fill: parent
                radius: root.roundArtwork ? Math.round(width / 2) : Kirigami.Units.cornerRadius
                color: (root.backgroundColor !== "transparent" && root.backgroundColor !== "")
                    ? root.backgroundColor
                    : AppTheme.panelSecondary
                border.width: root.roundArtwork && (root.hovered || root.visualFocus) ? 2.5 : 0
                border.color: Kirigami.Theme.highlightColor
                clip: true

                Image {
                    id: coverImage
                    anchors.fill: parent
                    anchors.margins: root.preserveAspectFit ? 8 : 0

                    source: {
                        if (root.imageUrl.length > 0) {
                            return root.normalizeCover(root.imageUrl)
                        }
                        if (root.coverUri.length > 0) {
                            return root.normalizeCover(root.coverUri)
                        }
                        return ""
                    }

                    sourceSize: Qt.size(320, 320)
                    fillMode: root.preserveAspectFit ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true

                    visible: status === Image.Ready
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: root.roundArtwork ? 40 : 36
                    height: root.roundArtwork ? 40 : 36
                    source: root.roundArtwork ? "view-media-artist" : "view-media-playlist"
                    color: Kirigami.Theme.disabledTextColor
                    visible: coverImage.status !== Image.Ready
                }

                // Кнопка Play по центру с затемнённой подложкой Breeze
                Item {
                    id: playOverlay
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    visible: root.showPlayButton && (root.hovered || playArea.containsMouse)
                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.62)
                        border.width: 1
                        border.color: root.hovered ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.35)
                    }

                    QQC2.ToolButton {
                        anchors.fill: parent
                        icon.name: "media-playback-start"
                        highlighted: true
                        onClicked: root.playRequested()
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playRequested()
                    }
                }
            }
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop | (root.roundArtwork ? Qt.AlignHCenter : Qt.AlignLeft)
            level: 4
            text: root.title
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            visible: text.length > 0
            horizontalAlignment: root.roundArtwork ? Text.AlignHCenter : Text.AlignLeft
            color: root.hovered ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop | (root.roundArtwork ? Qt.AlignHCenter : Qt.AlignLeft)
            text: root.subtitle
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.75
            font.pixelSize: 11
            visible: text.length > 0
            horizontalAlignment: root.roundArtwork ? Text.AlignHCenter : Text.AlignLeft
            color: Kirigami.Theme.disabledTextColor
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
