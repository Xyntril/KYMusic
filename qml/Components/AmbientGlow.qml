import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Item {
    id: root

    property string coverUri: ""
    property real glowOpacity: 0.26
    property bool active: (typeof window !== "undefined") ? window.ambientGlowEnabled : true

    anchors.fill: parent
    clip: true

    property string currentCover: ""
    property string previousCover: ""
    property bool flip: false

    onCoverUriChanged: {
        if (coverUri === currentCover) return
        previousCover = currentCover
        currentCover = coverUri
        flip = !flip
    }

    Item {
        id: layerA
        anchors.fill: parent
        opacity: (root.flip ? 0 : 1) * ((coverA.status === Image.Ready && root.active && root.coverUri.length > 0) ? root.glowOpacity : 0)

        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
        }

        Image {
            id: coverA
            anchors.fill: parent
            source: (!root.flip && root.currentCover.length > 0) ? ("image://yandex/" + root.currentCover) : ((root.previousCover.length > 0) ? ("image://yandex/" + root.previousCover) : "")
            sourceSize: Qt.size(160, 160)
            fillMode: Image.PreserveAspectCrop
            visible: false
            cache: true
            asynchronous: true
        }

        MultiEffect {
            anchors.fill: parent
            source: coverA
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 1.3
        }
    }

    Item {
        id: layerB
        anchors.fill: parent
        opacity: (root.flip ? 1 : 0) * ((coverB.status === Image.Ready && root.active && root.coverUri.length > 0) ? root.glowOpacity : 0)

        Behavior on opacity {
            NumberAnimation { duration: 600; easing.type: Easing.InOutQuad }
        }

        Image {
            id: coverB
            anchors.fill: parent
            source: (root.flip && root.currentCover.length > 0) ? ("image://yandex/" + root.currentCover) : ((root.previousCover.length > 0) ? ("image://yandex/" + root.previousCover) : "")
            sourceSize: Qt.size(160, 160)
            fillMode: Image.PreserveAspectCrop
            visible: false
            cache: true
            asynchronous: true
        }

        MultiEffect {
            anchors.fill: parent
            source: coverB
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 1.3
        }
    }
}
