import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Item {
    id: root

    property var controller: null

    readonly property bool fillHeight: true

    width: parent ? parent.width : 0
    height: parent ? parent.height : 700
    implicitWidth: width
    implicitHeight: height

    readonly property var genreController:
        root.controller && root.controller.genreController
            ? root.controller.genreController
            : null

    readonly property var genreModel:
        root.genreController ? root.genreController.model : null

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 600

    readonly property int columns:
        isMobile ? 2 : Math.max(2, Math.floor(availableGridWidth / 210))

    readonly property int availableGridWidth:
        Math.max(0, width - (isMobile ? 24 : 48))

    readonly property int tileWidth:
        Math.floor((availableGridWidth - (columns - 1) * 12) / columns)

    // Навигацию выполняет MainLayout
    signal genreRequested(string genreId, string title, string image, string color, var subGenres)

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    Flickable {
        id: pageFlickable
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: contentCol.implicitHeight + (root.isMobile ? 24 : 48)

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: genresScrollBar
            policy: QQC2.ScrollBar.AsNeeded
            width: root.isMobile ? 3 : 10
            opacity: root.isMobile ? (active ? 0.5 : 0) : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.isMobile ? 12 : 24
            spacing: 20

            // =================================================================
            // ЗАГОЛОВОК СТРАНИЦЫ
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
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
                    Layout.fillWidth: true
                    level: 1
                    text: qsTr("Жанры")
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            // Плейсхолдер при загрузке
            QQC2.Label {
                Layout.fillWidth: true
                visible: genreRepeater.count === 0
                text: root.genreController && root.genreController.loading
                    ? qsTr("Загрузка жанров…")
                    : qsTr("Жанры недоступны")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 40
            }

            // =================================================================
            // АДАПТИВНАЯ СЕТКА ГОРИЗОНТАЛЬНЫХ ПЛИТОК (KDE HIG, высота 80px)
            // =================================================================
            Grid {
                id: genreGrid
                Layout.fillWidth: true
                columns: root.columns
                rowSpacing: 12
                columnSpacing: 12
                visible: genreRepeater.count > 0

                Repeater {
                    id: genreRepeater
                    model: root.genreModel

                    delegate: Rectangle {
                        id: tileRoot
                        width: root.tileWidth
                        height: 80
                        radius: Kirigami.Units.cornerRadius

                        color: tileMouse.containsMouse
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
                            : Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)

                        border.width: tileMouse.containsMouse ? 1.5 : 1
                        border.color: tileMouse.containsMouse
                            ? Kirigami.Theme.highlightColor
                            : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Цветной акцент/иконка 48x48
                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 8
                                color: (model.color && String(model.color).length > 0)
                                    ? model.color
                                    : AppTheme.panelSecondary
                                clip: true

                                Image {
                                    id: genreImage
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                    source: model.image300 ? ("image://yandex/" + model.image300) : ""
                                    visible: status === Image.Ready
                                }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 26
                                    height: 26
                                    source: "audio-x-generic"
                                    color: Kirigami.Theme.highlightedTextColor
                                    visible: !model.image300 || genreImage.status !== Image.Ready
                                }
                            }

                            // Название жанра внутри карточки
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    text: String(model.title || "")
                                    font.bold: true
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                    color: tileMouse.containsMouse
                                        ? Kirigami.Theme.highlightColor
                                        : Kirigami.Theme.textColor
                                }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const id = String(model.genreId || "").trim()
                                if (id.length === 0) return
                                root.genreRequested(
                                    id,
                                    model.title || "",
                                    model.image300 || "",
                                    model.color || "",
                                    model.subGenres || []
                                )
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }

    Component.onCompleted: {
        if (root.genreController) {
            root.genreController.loadGenres()
        }
    }
}
