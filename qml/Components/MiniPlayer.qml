import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtCore as QC
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Window {
    id: root

    property var controller

    width: 390
    height: 120

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"
    visible: false
    modality: Qt.NonModal

    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    readonly property bool hasController:
        root.controller !== null && root.controller !== undefined

    readonly property bool hasTrack:
        root.hasController &&
        String(root.controller.currentTrackTitle || "").length > 0

    readonly property bool playing:
        root.hasController && root.controller.playing

    readonly property string currentTrackId:
        root.hasController ? String(root.controller.currentTrackId || "") : ""

    readonly property bool currentTrackLiked:
        root.hasController && root.controller.currentTrackLiked

    readonly property bool currentTrackDisliked: {
        if (!root.hasController) return false
        root.controller.dislikesRevision
        return root.controller.isTrackDisliked(root.currentTrackId)
    }

    signal expandedRequested()
    signal expandRequested()
    signal closeRequested()

    QC.Settings {
        id: miniSettings
        category: "miniplayer"
        property int posX: -1
        property int posY: -1
    }

    onXChanged: {
        if (root.visible && root.x > 0) miniSettings.posX = root.x
    }
    onYChanged: {
        if (root.visible && root.y > 0) miniSettings.posY = root.y
    }

    function showPlayer() {
        if (miniSettings.posX > 0 && miniSettings.posY > 0) {
            root.x = miniSettings.posX
            root.y = miniSettings.posY
        }
        root.show()
        root.raise()
        root.requestActivate()
    }

    function hidePlayer() {
        root.visible = false
    }

    // Корпус окна мини-плеера в стиле KDE Plasma 6
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 8
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Kirigami.Theme.highlightColor

        // Перетаскивание окна мышкой по рабочему столу (Wayland + X11 KWin)
        DragHandler {
            target: null
            onActiveChanged: {
                if (active) {
                    root.startSystemMove()
                }
            }
        }

        // Обложка трека слева
        Rectangle {
            id: coverContainer
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: progressSlider.top
            anchors.margins: 10
            anchors.bottomMargin: 4
            width: height
            radius: 6
            color: AppTheme.panelSecondary
            clip: true
            z: 5

            Image {
                id: cover
                anchors.fill: parent
                source: root.hasTrack && root.controller.currentTrackCoverUri
                    ? "image://yandex/" + root.controller.currentTrackCoverUri
                    : ""
                sourceSize: Qt.size(160, 160)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                visible: status === Image.Ready
            }

            QQC2.Label {
                anchors.centerIn: parent
                text: "♪"
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 28
                visible: cover.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expandedRequested()
                QQC2.ToolTip.visible: containsMouse
                QQC2.ToolTip.text: qsTr("Развернуть обложку")
            }
        }

        // Кнопки управления окном в правом верхнем углу (KDE Plasma)
        Row {
            id: windowButtons
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            spacing: 2
            z: 10

            QQC2.ToolButton {
                icon.name: "window-restore-symbolic"
                implicitWidth: 26
                implicitHeight: 26
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Вернуться в окно KYMusic")
                onClicked: root.expandRequested()
            }

            QQC2.ToolButton {
                icon.name: "window-close"
                implicitWidth: 26
                implicitHeight: 26
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: qsTr("Закрыть")
                onClicked: root.closeRequested()
            }
        }

        // Информация о треке и кнопки управления
        ColumnLayout {
            anchors.left: coverContainer.right
            anchors.right: windowButtons.left
            anchors.top: parent.top
            anchors.bottom: progressSlider.top
            anchors.margins: 10
            anchors.rightMargin: 4
            anchors.bottomMargin: 2
            spacing: 2
            z: 10

            QQC2.Label {
                Layout.fillWidth: true
                text: root.hasTrack ? root.controller.currentTrackTitle : qsTr("Нет трека")
                font.weight: Font.DemiBold
                font.pixelSize: 13
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: root.hasTrack ? root.controller.currentTrackArtist : ""
                font.pixelSize: 11
                opacity: 0.8
                elide: Text.ElideRight
                color: artistMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                visible: text.length > 0

                MouseArea {
                    id: artistMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.hidePlayer()
                        if (typeof window !== "undefined") {
                            window.show()
                        }
                        if (root.controller && String(root.controller.currentTrackArtistId || "").length > 0) {
                            root.controller.loadArtist(root.controller.currentTrackArtistId)
                        }
                    }
                }
            }

            // Нативные кнопки KDE Breeze
            RowLayout {
                spacing: 4

                QQC2.ToolButton {
                    icon.name: root.currentTrackLiked ? "starred-symbolic" : "non-starred-symbolic"
                    implicitWidth: 30
                    implicitHeight: 30
                    checkable: true
                    checked: root.currentTrackLiked
                    enabled: root.hasTrack && root.currentTrackId.length > 0
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: checked ? qsTr("Убрать из «Мне нравится»") : qsTr("Мне нравится")
                    onClicked: {
                        if (root.controller && root.currentTrackId.length > 0) {
                            root.controller.toggleLike(root.currentTrackId, root.currentTrackLiked)
                        }
                    }
                }

                QQC2.ToolButton {
                    icon.name: "media-skip-backward"
                    implicitWidth: 30
                    implicitHeight: 30
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Предыдущий трек")
                    onClicked: {
                        if (root.controller) root.controller.previous()
                    }
                }

                QQC2.ToolButton {
                    icon.name: root.playing ? "media-playback-pause" : "media-playback-start"
                    implicitWidth: 32
                    implicitHeight: 32
                    highlighted: true
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: root.playing ? qsTr("Пауза") : qsTr("Воспроизвести")
                    onClicked: {
                        if (!root.controller) return
                        if (root.playing) root.controller.pause(); else root.controller.play()
                    }
                }

                QQC2.ToolButton {
                    icon.name: "media-skip-forward"
                    implicitWidth: 30
                    implicitHeight: 30
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: qsTr("Следующий трек")
                    onClicked: {
                        if (root.controller) root.controller.next()
                    }
                }
            }
        }

        // Тонкий нативный ползунок Breeze Blue внизу
        QQC2.Slider {
            id: progressSlider
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 4
            height: 14
            z: 10

            from: 0
            to: (root.controller && root.controller.duration > 0)
                ? root.controller.duration
                : 1
            value: (root.controller && !progressSlider.pressed)
                ? root.controller.position
                : 0
            enabled: root.hasTrack && root.controller && root.controller.duration > 0

            onMoved: {
                if (root.controller && root.controller.duration > 0) {
                    root.controller.seek(Math.round(value))
                }
            }
        }
    }
}
