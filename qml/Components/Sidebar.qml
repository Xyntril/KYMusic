import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore as QC
import org.kde.kirigami as Kirigami
import YaMusic 1.0

QQC2.Page {
    id: root

    property string currentSection: "home"

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
    }

    readonly property bool compactMode: uiSettings.sidebarCompact
    property int sidebarWidth: compactMode ? 56 : 220

    signal sectionSelected(string section)

    implicitWidth: root.sidebarWidth
    width: root.sidebarWidth

    Kirigami.Theme.inherit: true
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    function buildModel() {
        let items = []
        let catItems = []
        catItems.push({ title: qsTr("Главная"), section: "home", iconName: "go-home" })
        if (uiSettings.showSearch) catItems.push({ title: qsTr("Поиск"), section: "search", iconName: "edit-find" })
        if (uiSettings.showWave) catItems.push({ title: qsTr("Моя волна"), section: "wave", iconName: "network-wireless" })
        if (uiSettings.showReleases) catItems.push({ title: qsTr("Новые релизы"), section: "releases", iconName: "view-media-recent" })
        if (uiSettings.showGenres) catItems.push({ title: qsTr("Жанры"), section: "genres", iconName: "view-media-genre" })
        if (uiSettings.showStations) catItems.push({ title: qsTr("Станции"), section: "stations", iconName: "radio" })
        if (uiSettings.showPodcasts) catItems.push({ title: qsTr("Подкасты"), section: "podcasts", iconName: "podcast-amarok" })

        if (catItems.length > 0) {
            if (!root.compactMode) items.push({ sectionHeader: qsTr("Каталог") })
            items = items.concat(catItems)
        }

        let mediaItems = []
        if (uiSettings.showPlaylists) mediaItems.push({ title: qsTr("Плейлисты"), section: "playlists", iconName: "view-media-playlist" })
        if (uiSettings.showSport) mediaItems.push({ title: qsTr("Спорт"), section: "sport", iconName: "chronometer" })
        if (uiSettings.showLiked) mediaItems.push({ title: qsTr("Мне нравится"), section: "liked", iconName: "starred-symbolic" })
        if (uiSettings.showStats) mediaItems.push({ title: qsTr("Статистика"), section: "stats", iconName: "view-statistics" })

        if (mediaItems.length > 0) {
            if (!root.compactMode) items.push({ sectionHeader: qsTr("Медиатека") })
            items = items.concat(mediaItems)
        }

        return items
    }

    readonly property var sidebarItems: {
        root.compactMode
        uiSettings.showSearch
        uiSettings.showWave
        uiSettings.showReleases
        uiSettings.showGenres
        uiSettings.showStations
        uiSettings.showPodcasts
        uiSettings.showPlaylists
        uiSettings.showSport
        uiSettings.showLiked
        uiSettings.showStats
        return root.buildModel()
    }

    QQC2.ScrollView {
        anchors.fill: parent

        ListView {
            id: listView
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model: root.sidebarItems

            delegate: Item {
                id: delegateItem
                required property var modelData

                readonly property bool isHeader: delegateItem.modelData.sectionHeader !== undefined
                width: ListView.view.width
                height: isHeader ? (root.compactMode ? 0 : sectionHeader.implicitHeight) : (root.compactMode ? 48 : itemDelegate.implicitHeight)
                visible: isHeader ? !root.compactMode : true

                Kirigami.ListSectionHeader {
                    id: sectionHeader
                    anchors.fill: parent
                    visible: delegateItem.isHeader && !root.compactMode
                    text: delegateItem.isHeader ? (delegateItem.modelData.sectionHeader || "") : ""
                }

                QQC2.ItemDelegate {
                    id: itemDelegate
                    anchors.fill: parent
                    visible: !delegateItem.isHeader
                    highlighted: !delegateItem.isHeader && root.currentSection === delegateItem.modelData.section
                    padding: root.compactMode ? 6 : 10

                    contentItem: RowLayout {
                        spacing: root.compactMode ? 0 : 12

                        Kirigami.Icon {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            Layout.alignment: root.compactMode ? Qt.AlignCenter : Qt.AlignVCenter
                            source: delegateItem.isHeader ? "" : (delegateItem.modelData.iconName || "")
                            isMask: true
                            color: itemDelegate.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }

                        QQC2.Label {
                            Layout.fillWidth: !root.compactMode
                            Layout.preferredWidth: root.compactMode ? 0 : -1
                            Layout.alignment: Qt.AlignVCenter
                            visible: !root.compactMode
                            text: (!root.compactMode && !delegateItem.isHeader) ? (delegateItem.modelData.title || "") : ""
                            color: itemDelegate.highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            elide: Text.ElideRight
                        }
                    }

                    QQC2.ToolTip.visible: root.compactMode && itemDelegate.hovered && !delegateItem.isHeader
                    QQC2.ToolTip.text: delegateItem.isHeader ? "" : (delegateItem.modelData.title || "")

                    onClicked: {
                        if (!delegateItem.isHeader) {
                            root.sectionSelected(delegateItem.modelData.section)
                        }
                    }
                }
            }
        }
    }
}
