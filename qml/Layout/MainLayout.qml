import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import YaMusic 1.0

Item {
    id: root

    property var controller
    property var authController
    property bool sidebarVisible: true
    readonly property bool effectiveSidebarVisible: (typeof window !== "undefined" && window.isMobileMode) ? false : root.sidebarVisible

    readonly property int topBarHeight: ((typeof window !== "undefined" && window.isMobileMode) && !root.canGoBack) ? 0 : ((typeof window !== "undefined" && window.isMobileMode) ? 48 : 68)
    readonly property int sidebarWidth: sidebar.implicitWidth
    readonly property int contextPanelWidth: 0

    readonly property string currentSection:
        navigationController.currentSection

    signal crashReportsRequested()
    signal settingsRequested()

    readonly property string currentPageType:
        navigationController.currentPageType

    readonly property bool canGoBack:
        navigationController.navigationStack.length > 0 &&
        navigationController.currentPageType !== "section"

    readonly property bool contextPanelVisible: false

    readonly property string contextType:
        navigationController.contextTypeForCurrentPage()

    NavigationController {
        id: navigationController
        controller: root.controller
        authController: root.authController
    }

    function selectSection(section) {
        navigationController.selectSection(section)
    }

    function openMenu(targetItem) {
        topBar.openMenu(targetItem)
    }

    Rectangle {
        anchors.fill: parent
        color: AppTheme.backgroundPrimary
    }

    // ---- Боковой сайдбар (как в mashiro) ----
    Sidebar {
        id: sidebar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        visible: root.effectiveSidebarVisible
        width: root.effectiveSidebarVisible ? sidebar.implicitWidth : 0

        currentSection: root.currentSection

        onSectionSelected: function(section) {
            navigationController.selectSection(section)
        }
    }

    TopBar {
        id: topBar

        anchors.top: parent.top
        anchors.left: root.effectiveSidebarVisible ? sidebar.right : parent.left
        anchors.right: parent.right

        height: root.topBarHeight

        controller: root.controller
        authController: root.authController
        currentSection: root.currentSection
        canGoBack: root.canGoBack

        onBackRequested: navigationController.goBack()
        onCrashReportsRequested: root.crashReportsRequested()
    }

    Row {
        anchors.top: topBar.bottom
        anchors.left: root.effectiveSidebarVisible ? sidebar.right : parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        spacing: 0

        Item {
            id: mainArea

            width: parent.width
            height: parent.height
            clip: true

            Flickable {
                id: contentScrollView

                anchors.fill: parent
                anchors.topMargin: (typeof window !== "undefined" && window.isMobileMode) ? 0 : Kirigami.Units.largeSpacing
                anchors.leftMargin: (typeof window !== "undefined" && window.isMobileMode) ? 10 : (Kirigami.Units.largeSpacing * 2)
                anchors.rightMargin: (typeof window !== "undefined" && window.isMobileMode) ? 10 : Kirigami.Units.smallSpacing

                clip: true
                boundsBehavior: Flickable.StopAtBounds

                readonly property bool pageIsFillHeight:
                    pageLoader.item !== null && pageLoader.item !== undefined &&
                    pageLoader.item.fillHeight === true

                ScrollBar.vertical: ScrollBar {
                    id: contentScrollBar
                    readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode)
                    policy: contentScrollView.pageIsFillHeight
                        ? ScrollBar.AlwaysOff
                        : ScrollBar.AsNeeded
                    width: isMobile ? 3 : 10
                    interactive: !isMobile
                    opacity: isMobile ? (active ? 0.5 : 0) : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                contentWidth: width
                contentHeight: contentScrollView.pageIsFillHeight
                    ? height
                    : Math.max(pageLoader.height + bottomContentSpacer.height, height)

                Loader {
                    id: pageLoader

                    width: contentScrollView.width - (!contentScrollView.pageIsFillHeight && contentScrollBar.visible && !contentScrollBar.isMobile
                        ? (contentScrollBar.width + Kirigami.Units.largeSpacing)
                        : (contentScrollBar.isMobile ? 0 : Kirigami.Units.largeSpacing))

                    // Страницы, которым нужна вся высота области просмотра,
                    // берут её отсюда: считать её из item.implicitHeight нельзя —
                    // страница сама тянется за родителем и получается цикл,
                    // из-за которого высота схлопывается в ноль.
                    height: item && item.fillHeight !== true
                        ? item.implicitHeight
                        : contentScrollView.height

                    // Ширина именно биндингом: при разворачивании окна
                    // страница должна переехать вместе с ней.
                    onLoaded: {
                        if (item) {
                            item.width = Qt.binding(function() {
                                return pageLoader.width
                            })
                        }
                    }
                }

                Item {
                    id: bottomContentSpacer

                    width: pageLoader.width
                    height: contentScrollView.pageIsFillHeight ? 0 : 40
                    y: pageLoader.height
                }
            }
        }
    }

    Connections {
        target: navigationController

        function onPageLoadRequested(source, properties) {
            pageLoader.setSource(source, properties)
        }
    }

    // Страницы разделов не знают про NavigationController, поэтому сообщают о навигации сигналами
    Connections {
        target: root.currentPageType === "section" &&
                (root.currentSection === "home" || root.currentSection === "genres" || root.currentSection === "library")
            ? pageLoader.item
            : null

        ignoreUnknownSignals: true

        function onGenresRequested() {
            navigationController.selectSection("genres")
        }

        function onPlaylistsRequested() {
            navigationController.selectSection("playlists")
        }

        function onSportRequested() {
            navigationController.selectSection("sport")
        }

        function onMyPlaylistsRequested() {
            navigationController.selectSection("library")
        }

        function onWaveRequested() {
            navigationController.selectSection("wave")
        }

        function onReleasesRequested() {
            navigationController.selectSection("releases")
        }

        function onLikedRequested() {
            navigationController.selectSection("liked")
        }

        function onSearchRequested() {
            navigationController.selectSection("search")
        }

        function onStationPageRequested(stationType, stationTag, title) {
            navigationController.openStationPage(stationType, stationTag, title)
        }

        function onGenreRequested(genreId, title, image, color, subGenres) {
            navigationController.openGenrePage(genreId, title, image, color)
        }
    }
}