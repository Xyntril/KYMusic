import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import YaMusic 1.0

Item {
    id: root

    property var controller
    property var authController
    property string currentSection: "home"
    property bool canGoBack: false

    signal backRequested()
    signal crashReportsRequested()

    readonly property int barHeight: 68

    // Состояние апдейтера для пункта настроек: контроллер может быть не
    // создан, поэтому все обращения к нему идут через эту проверку.
    readonly property var updateController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.updateController !== undefined
            ? root.controller.updateController
            : null

    readonly property bool autoUpdateCheck:
        root.updateController !== null && root.updateController.autoCheckEnabled

    readonly property string updateBadge:
        root.updateController !== null && root.updateController.updateAvailable
            ? "Доступна версия " + root.updateController.latestVersion
            : ""

    // Состояние предзагрузки: сколько треков уже готово и сколько места
    // занял кэш.
    readonly property var preloadController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.preloadController !== undefined
            ? root.controller.preloadController
            : null

    readonly property bool preloadEnabled:
        root.preloadController !== null && root.preloadController.enabled

    readonly property string cacheUsage:
        root.preloadController !== null
            ? root.preloadController.usedMb.toFixed(0) + " МБ из " +
              root.preloadController.limitMb + " МБ"
            : ""

    readonly property string preloadReady:
        root.preloadController !== null && root.preloadController.windowCount > 0
            ? "Готово " + root.preloadController.readyCount + " из " +
              root.preloadController.windowCount
            : ""

    // Отчёты о падениях: сколько их накопилось, видно сразу.
    readonly property var crashReporter:
        root.controller !== null && root.controller !== undefined &&
        root.controller.crashReporter !== undefined
            ? root.controller.crashReporter
            : null

    readonly property string crashReportLabel:
        root.crashReporter !== null && root.crashReporter.reportCount > 0
            ? "Отчёты о падениях: " + root.crashReporter.reportCount
            : "Отчёты о падениях"

    // Настройки воспроизведения: сейчас это перекрёстное затухание.
    readonly property var playbackSettings:
        root.controller !== null && root.controller !== undefined &&
        root.controller.playbackSettingsController !== undefined
            ? root.controller.playbackSettingsController
            : null

    readonly property int crossfadeSeconds:
        root.playbackSettings !== null ? root.playbackSettings.crossfadeSeconds : 0

    implicitHeight: root.barHeight
    visible: height > 0

    function openMenu(targetItem) {
        if (targetItem) {
            hamburgerMenu.popup(targetItem, 0, targetItem.height)
        } else {
            hamburgerMenu.popup()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: (typeof window !== "undefined" && window.isMobileMode) ? 12 : 28
        anchors.rightMargin: (typeof window !== "undefined" && window.isMobileMode) ? 12 : 28

        spacing: 8

        ToolButton {
            id: backButton

            visible: root.canGoBack
            icon.name: "go-previous"
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Назад")

            onClicked: root.backRequested()
        }

        Item {
            Layout.fillWidth: true
        }

        ToolButton {
            id: menuButton
            visible: (typeof window !== "undefined") ? !window.showMenuBar : true
            icon.name: "application-menu"
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Меню приложения (☰)")
            onClicked: hamburgerMenu.popup()

            Menu {
                id: hamburgerMenu
                y: menuButton.height

                // Быстрые разделы в мобильном режиме в один тап
                MenuItem {
                    text: qsTr("Новые релизы")
                    icon.name: "view-media-recent"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("releases")
                }

                MenuItem {
                    text: qsTr("Жанры")
                    icon.name: "view-media-genre"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("genres")
                }

                MenuItem {
                    text: qsTr("Станции")
                    icon.name: "radio"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("stations")
                }

                MenuItem {
                    text: qsTr("Подкасты")
                    icon.name: "podcast-amarok"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("podcasts")
                }

                MenuItem {
                    text: qsTr("Спорт")
                    icon.name: "media-playback-start"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("sport")
                }

                MenuItem {
                    text: qsTr("Статистика")
                    icon.name: "view-statistics"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("stats")
                }

                MenuSeparator {
                    visible: (typeof window !== "undefined") && window.isMobileMode
                }

                MenuItem {
                    text: qsTr("Параметры KYMusic…")
                    icon.name: "configure"
                    onTriggered: {
                        if (typeof mainLayout !== "undefined" && mainLayout.selectSection) {
                            mainLayout.selectSection("settings")
                        }
                    }
                }

                MenuItem {
                    text: qsTr("О программе KYMusic")
                    icon.name: "kymusic"
                    visible: (typeof window !== "undefined") && window.isMobileMode
                    onTriggered: if (root.controller) root.controller.showAboutAppDialog()
                }

                MenuSeparator {
                    visible: (typeof window !== "undefined") && !window.isMobileMode
                }

                Menu {
                    title: qsTr("Дополнительно")
                    icon.name: "view-more-symbolic"
                    visible: (typeof window !== "undefined") && !window.isMobileMode

                    Action {
                        text: qsTr("Показывать строку меню")
                        icon.name: "show-menu"
                        shortcut: "Ctrl+M"
                        checkable: true
                        checked: (typeof window !== "undefined") ? window.showMenuBar : false
                        onTriggered: {
                            if (typeof window !== "undefined") {
                                window.showMenuBar = !window.showMenuBar
                            }
                        }
                    }

                    MenuSeparator {}

                    Menu {
                        title: qsTr("Файл")
                        icon.name: "document-open"

                        Action {
                            text: qsTr("Скачать текущий трек")
                            icon.name: "download"
                            enabled: root.controller && String(root.controller.currentTrackTitle || "").length > 0
                            onTriggered: if (root.controller) root.controller.downloadCurrentTrack()
                        }
                    }

                    Menu {
                        title: qsTr("Правка")
                        icon.name: "edit-rename"

                        Action {
                            text: qsTr("Копировать название трека")
                            icon.name: "edit-copy"
                            shortcut: "Ctrl+C"
                            enabled: root.controller && String(root.controller.currentTrackTitle || "").length > 0
                            onTriggered: if (root.controller) root.controller.copyCurrentTrackTitle()
                        }

                        Action {
                            text: qsTr("Найти")
                            icon.name: "edit-find"
                            shortcut: "Ctrl+F"
                            onTriggered: if (typeof mainLayout !== "undefined") mainLayout.selectSection("search")
                        }
                    }

                    Menu {
                        title: qsTr("Вид")
                        icon.name: "view-media-lyrics"

                        Action {
                            text: qsTr("Показать / скрыть боковую панель")
                            icon.name: "view-sidetree"
                            onTriggered: if (typeof window !== "undefined") window.sidebarVisible = !window.sidebarVisible
                        }

                        Action {
                            text: qsTr("Полноэкранный режим")
                            icon.name: "view-fullscreen"
                            shortcut: "F11"
                            onTriggered: {
                                if (typeof window !== "undefined") {
                                    if (window.visibility === Window.FullScreen) window.showNormal(); else window.showFullScreen();
                                }
                            }
                        }
                    }

                    Menu {
                        title: qsTr("Воспроизведение")
                        icon.name: "media-playback-start"

                        Action {
                            text: qsTr("Воспроизвести / Пауза")
                            icon.name: (root.controller && root.controller.playing) ? "media-playback-pause" : "media-playback-start"
                            shortcut: "Space"
                            onTriggered: {
                                if (!root.controller) return
                                if (root.controller.playing) root.controller.pause(); else root.controller.play()
                            }
                        }

                        Action {
                            text: qsTr("Следующий трек")
                            icon.name: "media-skip-forward"
                            onTriggered: if (root.controller) root.controller.next()
                        }

                        Action {
                            text: qsTr("Предыдущий трек")
                            icon.name: "media-skip-backward"
                            onTriggered: if (root.controller) root.controller.previous()
                        }
                    }

                    MenuSeparator {}

                    Menu {
                        title: qsTr("Справка")
                        icon.name: "help-about"

                        Action {
                            text: qsTr("О программе KYMusic")
                            icon.name: "kymusic"
                            onTriggered: if (root.controller) root.controller.showAboutAppDialog()
                        }

                        Action {
                            text: qsTr("О среде KDE")
                            icon.name: "kde"
                            onTriggered: if (root.controller) root.controller.showAboutKdeDialog()
                        }
                    }
                }

                MenuSeparator {}

                Action {
                    text: qsTr("Выход")
                    icon.name: "application-exit"
                    shortcut: "Ctrl+Q"
                    onTriggered: Qt.quit()
                }
            }
        }
    }
}