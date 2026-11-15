import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore as QC
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller
    property var authController

    signal crashReportsRequested()

    readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode) || width < 600

    width: parent ? parent.width : 0
    clip: true
    implicitWidth: width
    implicitHeight: formLayout.implicitHeight + Kirigami.Units.largeSpacing * 4
    height: implicitHeight

    QC.Settings {
        id: uiSettings
        category: "ui"
        property bool showSearch: true
        property bool showWave: true
        property bool showReleases: true
        property bool showGenres: true
        property bool showStations: true
        property bool showPodcasts: true
        property bool showPlaylists: true
        property bool showSport: true
        property bool showLiked: true
        property bool showStats: true
        property bool sidebarCompact: false
        property bool showMenuBar: false
        property bool closeToTray: true
        property bool ambientGlow: true
        property string layoutMode: "auto"
    }

    readonly property var updateController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.updateController !== undefined
            ? root.controller.updateController
            : null

    readonly property bool autoUpdateCheck:
        root.updateController !== null && root.updateController.autoCheckEnabled

    readonly property string updateBadge:
        root.updateController !== null && root.updateController.updateAvailable
            ? qsTr("Доступна версия %1").arg(root.updateController.latestVersion)
            : ""

    readonly property var preloadController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.preloadController !== undefined
            ? root.controller.preloadController
            : null

    readonly property bool preloadEnabled:
        root.preloadController !== null && root.preloadController.enabled

    readonly property string cacheUsage:
        root.preloadController !== null
            ? qsTr("%1 МБ из %2 МБ").arg(root.preloadController.usedMb.toFixed(0)).arg(root.preloadController.limitMb)
            : ""

    readonly property string preloadReady:
        root.preloadController !== null && root.preloadController.windowCount > 0
            ? qsTr("Готово %1 из %2").arg(root.preloadController.readyCount).arg(root.preloadController.windowCount)
            : ""

    readonly property var crashReporter:
        root.controller !== null && root.controller !== undefined &&
        root.controller.crashReporter !== undefined
            ? root.controller.crashReporter
            : null

    readonly property string crashReportLabel:
        root.crashReporter !== null && root.crashReporter.reportCount > 0
            ? qsTr("Отчёты о падениях: %1").arg(root.crashReporter.reportCount)
            : qsTr("Отчёты о падениях")

    readonly property var playbackSettings:
        root.controller !== null && root.controller !== undefined &&
        root.controller.playbackSettingsController !== undefined
            ? root.controller.playbackSettingsController
            : null

    readonly property int crossfadeSeconds:
        root.playbackSettings !== null ? root.playbackSettings.crossfadeSeconds : 0

    Kirigami.FormLayout {
        id: formLayout
        width: Math.min(840, parent.width - (root.isMobile ? 16 : Kirigami.Units.largeSpacing * 4))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.isMobile ? Kirigami.Units.smallSpacing : (Kirigami.Units.largeSpacing * 2)

        // Мобильная шапка с кнопкой «Назад»
        RowLayout {
            Layout.fillWidth: true
            visible: root.isMobile
            spacing: 12

            QQC2.ToolButton {
                icon.name: "go-previous"
                text: qsTr("Назад")
                display: QQC2.AbstractButton.IconOnly
                onClicked: {
                    if (typeof mainLayout !== "undefined" && mainLayout.canGoBack) {
                        mainLayout.navigationController.goBack()
                    } else if (typeof mainLayout !== "undefined") {
                        mainLayout.selectSection("home")
                    }
                }
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 2
                text: qsTr("Настройки")
            }
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("Боковая панель и интерфейс")
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Режим панели:")
            Layout.fillWidth: true
            visible: !root.isMobile
            spacing: 8

            QQC2.CheckBox {
                id: compactSidebarCb
                checked: uiSettings.sidebarCompact
                onToggled: uiSettings.sidebarCompact = checked
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Компактный режим (только иконки)")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: compactSidebarCb.toggle()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.isMobile
            spacing: 8

            QQC2.CheckBox {
                id: showMenuBarCb
                checked: (typeof window !== "undefined") ? window.showMenuBar : uiSettings.showMenuBar
                onToggled: {
                    uiSettings.showMenuBar = checked
                    if (typeof window !== "undefined") {
                        window.showMenuBar = checked
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Показывать строку меню (Ctrl+M)")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showMenuBarCb.toggle()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: closeToTrayCb
                checked: uiSettings.closeToTray
                onToggled: uiSettings.closeToTray = checked
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Сворачивать в системный трей при закрытии окна")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: closeToTrayCb.toggle()
                }
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: qsTr("Разделы каталога:")
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Выберите отображаемые элементы бокового меню:")
            opacity: 0.7
        }

        Flow {
            width: parent.width
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                text: qsTr("Поиск")
                checked: uiSettings.showSearch
                onToggled: uiSettings.showSearch = checked
            }

            QQC2.CheckBox {
                text: qsTr("Моя волна")
                checked: uiSettings.showWave
                onToggled: uiSettings.showWave = checked
            }

            QQC2.CheckBox {
                text: qsTr("Новые релизы")
                checked: uiSettings.showReleases
                onToggled: uiSettings.showReleases = checked
            }

            QQC2.CheckBox {
                text: qsTr("Жанры")
                checked: uiSettings.showGenres
                onToggled: uiSettings.showGenres = checked
            }

            QQC2.CheckBox {
                text: qsTr("Станции")
                checked: uiSettings.showStations
                onToggled: uiSettings.showStations = checked
            }

            QQC2.CheckBox {
                text: qsTr("Подкасты")
                checked: uiSettings.showPodcasts
                onToggled: uiSettings.showPodcasts = checked
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: qsTr("Разделы медиатеки:")
            text: qsTr("Личная медиатека:")
            opacity: 0.7
        }

        Flow {
            width: parent.width
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                text: qsTr("Плейлисты")
                checked: uiSettings.showPlaylists
                onToggled: uiSettings.showPlaylists = checked
            }

            QQC2.CheckBox {
                text: qsTr("Спорт")
                checked: uiSettings.showSport
                onToggled: uiSettings.showSport = checked
            }

            QQC2.CheckBox {
                text: qsTr("Мне нравится")
                checked: uiSettings.showLiked
                onToggled: uiSettings.showLiked = checked
            }

            QQC2.CheckBox {
                text: qsTr("Статистика")
                checked: uiSettings.showStats
                onToggled: uiSettings.showStats = checked
            }
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("Внешний вид и темы")
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: qsTr("Режим интерфейса:")
            model: [
                { key: "auto", text: qsTr("Автоматически (адаптивно)") },
                { key: "desktop", text: qsTr("Десктоп (KDE Plasma)") },
                { key: "mobile", text: qsTr("Мобильный (Plasma Mobile)") }
            ]
            textRole: "text"
            currentIndex: {
                for (let i = 0; i < model.length; ++i) {
                    if (model[i].key === uiSettings.layoutMode) return i
                }
                return 0
            }
            onActivated: function(index) {
                uiSettings.layoutMode = model[index].key
            }
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Атмосферная подсветка:")
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: ambientGlowCb
                checked: uiSettings.ambientGlow
                onToggled: uiSettings.ambientGlow = checked
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Атмосферная подсветка от обложки трека (Ambient Glow)")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ambientGlowCb.toggle()
                }
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: qsTr("Тема оформления:")
            text: qsTr("Используется системная тема и палитра KDE Plasma (Breeze / Oxygen). Для смены цветовой схемы или стиля элементов управления откройте Параметры системы KDE.")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            opacity: 0.8
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("Воспроизведение и звук")
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Качество аудио:")
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: [
                    { key: "low", title: qsTr("Низкое") },
                    { key: "normal", title: qsTr("Среднее") },
                    { key: "high", title: qsTr("Высокое") },
                    { key: "lossless", title: qsTr("Lossless") }
                ]

                delegate: QQC2.RadioButton {
                    id: qualityRadio
                    required property var modelData

                    text: modelData.title
                    checked: root.controller && root.controller.audioQualityController
                        ? root.controller.audioQualityController.quality === modelData.key
                        : (modelData.key === "high")

                    onClicked: {
                        if (root.controller && root.controller.audioQualityController) {
                            root.controller.audioQualityController.setQuality(modelData.key)
                        }
                    }
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Плавный переход:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.Slider {
                Layout.preferredWidth: 200
                from: 0
                to: 15
                stepSize: 1
                value: root.crossfadeSeconds
                onMoved: {
                    if (root.playbackSettings) {
                        root.playbackSettings.crossfadeSeconds = Math.round(value)
                    }
                }
            }

            QQC2.Label {
                text: root.crossfadeSeconds > 0
                    ? qsTr("%1 сек.").arg(root.crossfadeSeconds)
                    : qsTr("Выключено")
                font.bold: true
            }
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Цензура и фильтрация:")
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: censorBypassCb
                checked: root.controller &&
                    root.controller.audioQualityController &&
                    root.controller.audioQualityController.censorBypass
                onToggled: {
                    if (root.controller && root.controller.audioQualityController) {
                        root.controller.audioQualityController.setCensorBypass(checked)
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Обход цензуры (заменять цензурированные треки)")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: censorBypassCb.toggle()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: hideAiCb
                checked: root.controller ? root.controller.hideAiTracks : false
                onToggled: {
                    if (root.controller) {
                        root.controller.hideAiTracks = checked
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Скрывать AI-треки")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hideAiCb.toggle()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: autoDislikeAiCb
                checked: root.controller ? root.controller.autoDislikeAiTracks : false
                onToggled: {
                    if (root.controller) {
                        root.controller.autoDislikeAiTracks = checked
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Автодизлайк AI-треков")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: autoDislikeAiCb.toggle()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: skipAiCb
                checked: root.controller ? root.controller.skipAiTracks : false
                onToggled: {
                    if (root.controller) {
                        root.controller.skipAiTracks = checked
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Пропускать AI-треки")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: skipAiCb.toggle()
                }
            }
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("Кэш и память")
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Предзагрузка:")
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: preloadCb
                checked: root.preloadEnabled
                onToggled: {
                    if (root.preloadController) {
                        root.preloadController.enabled = checked
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Скачивать следующие треки заранее")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: preloadCb.toggle()
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Состояние кэша:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: root.preloadEnabled
                    ? [root.preloadReady, root.cacheUsage].filter(function(part) { return part.length > 0 }).join(" · ")
                    : qsTr("Кэш скачанных треков не пополняется")
                opacity: 0.8
            }

            QQC2.Button {
                text: qsTr("Очистить кэш")
                icon.name: "edit-clear"
                visible: root.preloadController !== null && root.preloadController.usedMb > 0
                onClicked: {
                    if (root.preloadController) {
                        root.preloadController.clearCache()
                    }
                }
            }
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("Обновления и обслуживание")
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Обновления:")
            Layout.fillWidth: true
            spacing: 8

            QQC2.CheckBox {
                id: autoUpdateCb
                checked: root.autoUpdateCheck
                onToggled: {
                    if (root.updateController) {
                        root.updateController.autoCheckEnabled = checked
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Проверять обновления при запуске")
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: autoUpdateCb.toggle()
                }
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Button {
                text: root.updateBadge.length > 0 ? root.updateBadge : qsTr("Проверить обновления")
                icon.name: "system-software-update"
                onClicked: {
                    if (root.updateController) {
                        root.updateController.checkForUpdates()
                        updateDialog.open()
                    }
                }
            }

            QQC2.Button {
                text: root.crashReportLabel
                icon.name: "tools-report-bug"
                onClicked: root.crashReportsRequested()
            }
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("Учётная запись")
        }

        RowLayout {
            Kirigami.FormData.label: qsTr("Пользователь:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: {
                    if (root.authController && root.authController.displayName.length > 0) {
                        return root.authController.displayName + " (" + root.authController.login + ")"
                    }
                    if (root.controller && root.controller.accountName && root.controller.accountName.length > 0) {
                        return root.controller.accountName
                    }
                    return qsTr("Авторизован")
                }
                font.bold: true
            }

            QQC2.Button {
                text: qsTr("Выйти из аккаунта")
                icon.name: "system-log-out"
                onClicked: logoutConfirmDialog.open()
            }
        }

        Kirigami.Heading {
            Kirigami.FormData.isSection: true
            text: qsTr("О программе")
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing

            QQC2.Button {
                text: qsTr("О программе KYMusic")
                icon.name: "kymusic"
                onClicked: {
                    if (root.controller) {
                        root.controller.showAboutAppDialog()
                    }
                }
            }

            QQC2.Button {
                text: qsTr("О среде KDE")
                icon.name: "kde"
                onClicked: {
                    if (root.controller) {
                        root.controller.showAboutKdeDialog()
                    }
                }
            }
        }
    }

    Kirigami.PromptDialog {
        id: logoutConfirmDialog
        title: qsTr("Выход из учётной записи")
        subtitle: qsTr("Вы действительно хотите выйти из аккаунта Яндекс Музыки?")
        standardButtons: Kirigami.Dialog.Yes | Kirigami.Dialog.Cancel
        onAccepted: {
            if (root.authController) {
                root.authController.logout()
            } else if (typeof authController !== "undefined" && authController) {
                authController.logout()
            }
            if (root.controller) {
                root.controller.logout()
            }
        }
    }

    UpdateDialog {
        id: updateDialog
        controller: root.controller
    }
}
