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

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 800

    readonly property var stats:
        root.controller !== null && root.controller !== undefined &&
        root.controller.statsController !== undefined
            ? root.controller.statsController
            : null

    Kirigami.PromptDialog {
        id: resetDialog
        title: qsTr("Сброс статистики")
        subtitle: qsTr("Вы действительно хотите обнулить всю историю прослушиваний?")
        standardButtons: Kirigami.Dialog.Yes | Kirigami.Dialog.Cancel
        onAccepted: {
            if (root.stats) {
                root.stats.reset()
            }
        }
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
        contentHeight: mainContentColumn.implicitHeight + (root.isMobile ? 24 : 48)

        QQC2.ScrollBar.vertical: QQC2.ScrollBar {
            id: statsScrollBar
            policy: QQC2.ScrollBar.AsNeeded
            width: root.isMobile ? 3 : 10
            opacity: root.isMobile ? (active ? 0.5 : 0) : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        ColumnLayout {
            id: mainContentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.isMobile ? 12 : 24
            spacing: root.isMobile ? 16 : 24

            // =================================================================
            // ЗАГОЛОВОК СТРАНИЦЫ + КНОПКА СБРОСА
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
                    text: qsTr("Статистика прослушивания")
                    font.bold: true
                    elide: Text.ElideRight
                }

                QQC2.Button {
                    text: qsTr("Сбросить")
                    icon.name: "edit-clear-all"
                    enabled: root.stats && root.stats.totalPlays > 0
                    onClicked: resetDialog.open()
                }
            }

            // =================================================================
            // 4 КАРТОЧКИ СВОДКИ (Desktop: 4 колонки, Mobile: 2x2)
            // =================================================================
            Grid {
                Layout.fillWidth: true
                columns: root.isMobile ? 2 : 4
                rowSpacing: 12
                columnSpacing: 12

                readonly property real itemWidth:
                    Math.floor((mainContentColumn.width - (columns - 1) * columnSpacing) / columns)

                // Карточка 1: Прослушиваний
                Rectangle {
                    width: parent.itemWidth
                    height: 84
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.stats ? String(root.stats.totalPlays) : "0"
                            font.pixelSize: 22
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: qsTr("Всего прослушиваний")
                            font.pixelSize: 11
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                        }
                    }
                }

                // Карточка 2: Время в музыке
                Rectangle {
                    width: parent.itemWidth
                    height: 84
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.stats ? AppTheme.formatTime(root.stats.totalPlayTimeMs) : "0:00"
                            font.pixelSize: 22
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: qsTr("Времени в музыке")
                            font.pixelSize: 11
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                        }
                    }
                }

                // Карточка 3: Треков
                Rectangle {
                    width: parent.itemWidth
                    height: 84
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.stats ? String(root.stats.trackCount) : "0"
                            font.pixelSize: 22
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: qsTr("Треков")
                            font.pixelSize: 11
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                        }
                    }
                }

                // Карточка 4: Исполнителей
                Rectangle {
                    width: parent.itemWidth
                    height: 84
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: root.stats ? String(root.stats.artistCount) : "0"
                            font.pixelSize: 22
                            font.bold: true
                            color: Kirigami.Theme.textColor
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: qsTr("Исполнителей")
                            font.pixelSize: 11
                            color: Kirigami.Theme.disabledTextColor
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // =================================================================
            // ГРАФИК «МИНУТЫ ПО ДНЯМ» (KDE Breeze Style, padding: 16)
            // =================================================================
            Rectangle {
                id: chartCard
                Layout.fillWidth: true
                implicitHeight: 220
                radius: Kirigami.Units.cornerRadius
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)

                readonly property var chartData: root.stats ? root.stats.dailyMinutes(30) : []
                readonly property int maxMinutes: {
                    let m = 0
                    for (const row of chartData) {
                        m = Math.max(m, Number(row.minutes || 0))
                    }
                    return Math.max(1, m)
                }

                readonly property int avgMinutes: {
                    if (!chartData || chartData.length === 0) return 0
                    let sum = 0
                    for (const row of chartData) sum += Number(row.minutes || 0)
                    return Math.round(sum / chartData.length)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Kirigami.Heading {
                            level: 3
                            text: qsTr("Минуты по дням")
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        QQC2.Label {
                            text: qsTr("Пик: %1 мин · В среднем: %2 мин / день").arg(chartCard.maxMinutes).arg(chartCard.avgMinutes)
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            color: Kirigami.Theme.disabledTextColor
                            horizontalAlignment: Text.AlignRight
                            Layout.maximumWidth: parent.width * 0.6
                        }
                    }

                    // Область Canvas графика
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Canvas {
                            id: chartCanvas
                            anchors.fill: parent
                            antialiasing: true

                            Connections {
                                target: chartCard
                                function onChartDataChanged() { chartCanvas.requestPaint() }
                            }

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.reset()

                                const w = width
                                const h = height
                                const data = chartCard.chartData
                                const n = data.length
                                if (n < 2) return

                                const padBottom = 20
                                const padTop = 10
                                const plotH = h - padTop - padBottom
                                const stepX = w / (n - 1)
                                const max = chartCard.maxMinutes

                                const pts = []
                                for (let i = 0; i < n; i++) {
                                    const v = Number(data[i].minutes || 0)
                                    const x = i * stepX
                                    const ratio = Math.max(0, Math.min(1, v / max))
                                    const y = h - padBottom - (plotH * ratio)
                                    pts.push({ x: x, y: y })
                                }

                                // Заливка полупрозрачным градиентом Breeze
                                ctx.beginPath()
                                ctx.moveTo(pts[0].x, pts[0].y)
                                for (let i = 1; i < n; i++) {
                                    const p0 = pts[i - 1]
                                    const p1 = pts[i]
                                    const cx = (p0.x + p1.x) / 2
                                    ctx.bezierCurveTo(cx, p0.y, cx, p1.y, p1.x, p1.y)
                                }
                                ctx.lineTo(w, h - padBottom)
                                ctx.lineTo(0, h - padBottom)
                                ctx.closePath()

                                const grad = ctx.createLinearGradient(0, padTop, 0, h - padBottom)
                                const hl = Kirigami.Theme.highlightColor
                                grad.addColorStop(0, Qt.rgba(hl.r, hl.g, hl.b, 0.35))
                                grad.addColorStop(1, Qt.rgba(hl.r, hl.g, hl.b, 0.02))
                                ctx.fillStyle = grad
                                ctx.fill()

                                // Линия
                                ctx.beginPath()
                                ctx.moveTo(pts[0].x, pts[0].y)
                                for (let i = 1; i < n; i++) {
                                    const p0 = pts[i - 1]
                                    const p1 = pts[i]
                                    const cx = (p0.x + p1.x) / 2
                                    ctx.bezierCurveTo(cx, p0.y, cx, p1.y, p1.x, p1.y)
                                }
                                ctx.strokeStyle = Kirigami.Theme.highlightColor
                                ctx.lineWidth = 2.5
                                ctx.lineCap = "round"
                                ctx.lineJoin = "round"
                                ctx.stroke()

                                // Горизонтальная базовая линия
                                ctx.beginPath()
                                ctx.moveTo(0, h - padBottom)
                                ctx.lineTo(w, h - padBottom)
                                ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                ctx.lineWidth = 1
                                ctx.stroke()
                            }
                        }
                    }
                }
            }

            // =================================================================
            // ТОП ТРЕКОВ И ТОП ИСПОЛНИТЕЛЕЙ
            // Desktop: 2 колонки рядом, Mobile: 1 колонка друг под другом
            // =================================================================
            GridLayout {
                Layout.fillWidth: true
                columns: root.isMobile ? 1 : 2
                rowSpacing: 24
                columnSpacing: 20

                // БЛОК 1: ТОП ТРЕКОВ
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Kirigami.Heading {
                        level: 3
                        text: qsTr("Топ треков")
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        implicitHeight: topTracksCol.implicitHeight + 16

                        ColumnLayout {
                            id: topTracksCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 4

                            readonly property var tracksList: root.stats ? root.stats.topTracks(20) : []

                            Repeater {
                                model: topTracksCol.tracksList

                                delegate: Rectangle {
                                    id: trackRowItem
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    height: 52
                                    radius: 6
                                    color: trackMouse.containsMouse
                                        ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
                                        : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        QQC2.Label {
                                            Layout.preferredWidth: 24
                                            text: String(trackRowItem.index + 1)
                                            font.bold: trackRowItem.index < 3
                                            font.pixelSize: 13
                                            color: trackRowItem.index < 3 ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 40
                                            radius: 6
                                            color: AppTheme.panelSecondary
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                source: trackRowItem.modelData.coverUri
                                                    ? ("image://yandex/" + String(trackRowItem.modelData.coverUri).replace(/%%/g, "400x400"))
                                                    : ""
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                cache: true
                                                visible: status === Image.Ready
                                            }

                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                width: 22
                                                height: 22
                                                source: "media-default-track"
                                                color: Kirigami.Theme.disabledTextColor
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                text: String(trackRowItem.modelData.title || qsTr("Без названия"))
                                                font.bold: true
                                                font.pixelSize: 13
                                                elide: Text.ElideRight
                                                color: trackMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                            }

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                text: String(trackRowItem.modelData.artist || qsTr("Неизвестный исполнитель"))
                                                font.pixelSize: 11
                                                color: Kirigami.Theme.disabledTextColor
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 24
                                            Layout.preferredWidth: playsLabel.implicitWidth + 14
                                            radius: 12
                                            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                            QQC2.Label {
                                                id: playsLabel
                                                anchors.centerIn: parent
                                                text: qsTr("%1×").arg(trackRowItem.modelData.plays || 0)
                                                font.bold: true
                                                font.pixelSize: 11
                                                color: Kirigami.Theme.highlightColor
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: trackMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.controller) {
                                                root.controller.playStatsTrack(trackRowItem.index)
                                            }
                                        }
                                    }
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: qsTr("История прослушиваний пуста")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                visible: topTracksCol.tracksList.length === 0
                                Layout.topMargin: 20
                                Layout.bottomMargin: 20
                            }
                        }
                    }
                }

                // БЛОК 2: ТОП ИСПОЛНИТЕЛЕЙ
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Kirigami.Heading {
                        level: 3
                        text: qsTr("Топ исполнителей")
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.65)
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        implicitHeight: topArtistsCol.implicitHeight + 16

                        ColumnLayout {
                            id: topArtistsCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 4

                            readonly property var artistsList: root.stats ? root.stats.topArtists(20) : []

                            Repeater {
                                model: topArtistsCol.artistsList

                                delegate: Rectangle {
                                    id: artistRowItem
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    height: 52
                                    radius: 6
                                    color: artistMouse.containsMouse
                                        ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.12)
                                        : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 12
                                        spacing: 10

                                        QQC2.Label {
                                            Layout.preferredWidth: 24
                                            text: String(artistRowItem.index + 1)
                                            font.bold: artistRowItem.index < 3
                                            font.pixelSize: 13
                                            color: artistRowItem.index < 3 ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                                            horizontalAlignment: Text.AlignRight
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 40
                                            radius: 20
                                            color: AppTheme.panelSecondary
                                            clip: true

                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                width: 24
                                                height: 24
                                                source: "view-media-artist"
                                                color: Kirigami.Theme.disabledTextColor
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                text: String(artistRowItem.modelData.name || qsTr("Неизвестный исполнитель"))
                                                font.bold: true
                                                font.pixelSize: 13
                                                elide: Text.ElideRight
                                                color: artistMouse.containsMouse ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                            }

                                            QQC2.Label {
                                                Layout.fillWidth: true
                                                text: qsTr("Исполнитель")
                                                font.pixelSize: 11
                                                color: Kirigami.Theme.disabledTextColor
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 24
                                            Layout.preferredWidth: artistPlaysLabel.implicitWidth + 14
                                            radius: 12
                                            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)

                                            QQC2.Label {
                                                id: artistPlaysLabel
                                                anchors.centerIn: parent
                                                text: qsTr("%1×").arg(artistRowItem.modelData.plays || 0)
                                                font.bold: true
                                                font.pixelSize: 11
                                                color: Kirigami.Theme.highlightColor
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: artistMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.controller && artistRowItem.modelData.id) {
                                                root.controller.loadArtist(artistRowItem.modelData.id)
                                            }
                                        }
                                    }
                                }
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: qsTr("История исполнителей пуста")
                                color: Kirigami.Theme.disabledTextColor
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                visible: topArtistsCol.artistsList.length === 0
                                Layout.topMargin: 20
                                Layout.bottomMargin: 20
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
