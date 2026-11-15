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

    readonly property var stationsController:
        root.controller && root.controller.stationsController
            ? root.controller.stationsController
            : null

    readonly property var groups:
        root.stationsController ? root.stationsController.groups : []

    readonly property bool loading:
        root.stationsController ? root.stationsController.loading : false

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 600

    property string selectedCategory: "all"
    property string filterText: ""

    readonly property int availableGridWidth:
        Math.max(0, width - (isMobile ? 24 : 48))

    readonly property int columns:
        isMobile ? 2 : Math.max(2, Math.floor(availableGridWidth / 155))

    readonly property int cardWidth:
        Math.floor((availableGridWidth - (columns - 1) * 14) / columns)

    // Список категорий для кнопок Flow
    readonly property var categoryList: {
        const list = [{ id: "all", label: qsTr("Все") }]
        if (root.groups) {
            for (const g of root.groups) {
                if (g.type && g.label) {
                    list.push({ id: String(g.type), label: String(g.label) })
                }
            }
        }
        return list
    }

    // Отфильтрованные станции: категория + поиск
    readonly property var displayedStations: {
        if (!root.groups || root.groups.length === 0) return []
        const out = []
        const q = root.filterText.toLowerCase().trim()
        for (const g of root.groups) {
            if (root.selectedCategory !== "all" && g.type !== root.selectedCategory) {
                continue
            }
            if (!g.items) continue
            for (const item of g.items) {
                if (q.length > 0) {
                    const title = String(item.title || "").toLowerCase()
                    if (title.indexOf(q) === -1) continue
                }
                out.push(item)
            }
        }
        return out
    }

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
            id: stationsScrollBar
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
            spacing: 16

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
                    text: qsTr("Радио и станции")
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            // =================================================================
            // ПОИСК + КАТЕГОРИИ В FLOW (KDE HIG)
            // =================================================================
            Kirigami.SearchField {
                id: stationSearchField
                Layout.fillWidth: true
                placeholderText: qsTr("Найти станцию…")
                onTextChanged: root.filterText = text
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.categoryList

                    delegate: QQC2.Button {
                        required property var modelData

                        text: modelData.label
                        checkable: true
                        checked: root.selectedCategory === modelData.id
                        highlighted: checked

                        onClicked: {
                            root.selectedCategory = modelData.id
                        }
                    }
                }
            }

            // Плейсхолдер загрузки / пустого результата
            QQC2.Label {
                Layout.fillWidth: true
                visible: root.displayedStations.length === 0
                text: root.loading
                    ? qsTr("Загрузка станций…")
                    : (root.filterText.length > 0 ? qsTr("Станции не найдены") : qsTr("Станции недоступны"))
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 40
            }

            // =================================================================
            // ЕДИНАЯ АДАПТИВНАЯ СЕТКА КАРТОЧЕК СТАНЦИЙ
            // =================================================================
            Grid {
                id: stationsGrid
                Layout.fillWidth: true
                columns: root.columns
                rowSpacing: 16
                columnSpacing: 14
                visible: root.displayedStations.length > 0

                Repeater {
                    model: root.displayedStations

                    delegate: Item {
                        id: cardItem
                        required property var modelData

                        width: root.cardWidth
                        height: root.cardWidth + 52

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            // Квадратная плашка станции
                            Rectangle {
                                Layout.preferredWidth: root.cardWidth
                                Layout.preferredHeight: root.cardWidth
                                radius: Kirigami.Units.cornerRadius
                                color: (cardItem.modelData.backgroundColor && String(cardItem.modelData.backgroundColor).length > 0)
                                    ? cardItem.modelData.backgroundColor
                                    : AppTheme.panelSecondary
                                clip: true

                                border.width: stationMouse.containsMouse ? 2 : 1
                                border.color: stationMouse.containsMouse
                                    ? Kirigami.Theme.highlightColor
                                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Image {
                                    id: stationIcon
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                    source: cardItem.modelData.imageUrl ? ("image://yandex/" + cardItem.modelData.imageUrl) : ""
                                    visible: status === Image.Ready
                                }

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    source: "media-default-track"
                                    color: Kirigami.Theme.highlightedTextColor
                                    visible: !cardItem.modelData.imageUrl || stationIcon.status !== Image.Ready
                                }

                                // Полупрозрачная кнопка ▶ при наведении
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 46
                                    height: 46
                                    radius: 23
                                    color: Qt.rgba(0, 0, 0, 0.65)
                                    visible: stationMouse.containsMouse
                                    opacity: visible ? 1 : 0

                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: 26
                                        height: 26
                                        source: "media-playback-start"
                                        color: "white"
                                    }
                                }
                            }

                            // 2-строчное читаемое название под иконкой
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                text: String(cardItem.modelData.title || "")
                                font.bold: true
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignTop
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                color: stationMouse.containsMouse
                                    ? Kirigami.Theme.highlightColor
                                    : Kirigami.Theme.textColor
                            }
                        }

                        MouseArea {
                            id: stationMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.stationsController) {
                                    root.stationsController.selectStation(
                                        cardItem.modelData.type,
                                        cardItem.modelData.tag,
                                        cardItem.modelData.title
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }

    Component.onCompleted: {
        if (root.stationsController) {
            root.stationsController.loadStations()
        }
    }
}
