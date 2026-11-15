import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller

    width: parent ? parent.width : 0
    implicitWidth: width
    implicitHeight: content.implicitHeight
    height: implicitHeight

    signal waveRequested()
    signal likedRequested()
    signal searchRequested()
    signal releasesRequested()
    signal playlistsRequested()
    signal stationPageRequested(string stationType, string stationTag, string title)

    readonly property var personalController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.personalController !== undefined
            ? root.controller.personalController
            : null

    readonly property var stationsController:
        root.controller !== null && root.controller !== undefined &&
        root.controller.stationsController !== undefined
            ? root.controller.stationsController
            : null

    readonly property var wheelItems:
        root.personalController !== null && root.personalController.wheelItems
            ? root.personalController.wheelItems
            : []

    // «Новое для тебя»: альбомы, подборки, артисты из Колеса.
    readonly property var picks:
        root.wheelItems.filter((item) => item.type !== "wave")

    // «Волны по настроению»: элементы Колеса типа "wave".
    readonly property var waves:
        root.wheelItems.filter((item) => item.type === "wave")

    readonly property int cardWidth: 150
    readonly property int cardSpacing: 18

    Component.onCompleted: {
        if (root.controller !== null && root.controller !== undefined) {
            // «Мою волну» не трогаем: она загружается своей страницей,
            // иначе возврат на главную сбрасывал бы очередь плеера.
            root.controller.loadRecommendations()
            root.controller.loadWheel()
        }
    }

    readonly property string accountName:
        root.controller !== null && root.controller !== undefined
            ? String(root.controller.accountName || "")
            : ""

    function greeting() {
        const hour = new Date().getHours()
        let text = ""

        if (hour < 6) text = "Доброй ночи"
        else if (hour < 12) text = "Доброе утро"
        else if (hour < 18) text = "Добрый день"
        else text = "Добрый вечер"

        const name = root.accountName.trim()

        return name.length > 0 ? text + ", " + name : text
    }

    function startWheelWave(item) {
        if (root.stationsController === null) {
            return
        }

        // Сид станции вида "type:tag" — разбираем на составные части.
        const station = String(item.station || "")
        const separator = station.indexOf(":")
        const type = separator > 0 ? station.substring(0, separator) : ""
        const tag = separator > 0 ? station.substring(separator + 1) : station

        if (type.length > 0 && tag.length > 0) {
            root.stationsController.selectStation(type, tag, item.title || "Волна")
            return
        }

        // Нет сида — просто открываем страницу волны.
        root.waveRequested()
    }

    function openPick(item) {
        if (root.controller === null) {
            return
        }

        if (item.type === "album") {
            root.controller.loadAlbum(item.id)
        } else if (item.type === "artist") {
            root.controller.loadArtist(item.id)
        }
    }

    function playPick(item) {
        if (root.controller === null) {
            return
        }

        if (item.type === "album") {
            root.controller.playAlbum(item.id)
            return
        }

        // Для артиста и подборок запускаем волну по сиду.
        startWheelWave(item)
    }

    Column {
        id: content

        width: parent.width
        spacing: 26

        // ---- Приветствие ----
        RowLayout {
            width: parent.width
            Label {
                Layout.fillWidth: true
                text: root.greeting()
                color: AppTheme.textPrimary
                font.pixelSize: (typeof window !== "undefined" && window.isMobileMode) ? 22 : 28
                font.bold: true
                elide: Text.ElideRight
            }

            ToolButton {
                visible: (typeof window !== "undefined" && window.isMobileMode)
                icon.name: "application-menu"
                onClicked: {
                    if (typeof mainLayout !== "undefined") {
                        mainLayout.openMenu(this)
                    }
                }
            }
        }

        // ---- Кнопки-действия ----
        Flow {
            width: content.width
            spacing: 10

            ActionButton {
                text: "Моя волна"
                glyph: "play"
                emphasized: true

                onClicked: root.waveRequested()
            }

            ActionButton {
                text: "Новые релизы"
                glyph: "chart"

                onClicked: root.releasesRequested()
            }

            ActionButton {
                text: "Новые плейлисты"
                glyph: "playlist"

                onClicked: root.playlistsRequested()
            }

            ActionButton {
                text: "Мне нравится"
                glyph: "heartFilled"

                onClicked: root.likedRequested()
            }

            ActionButton {
                text: "Поиск"
                glyph: "search"

                onClicked: root.searchRequested()
            }
        }

        // ---- Новое для тебя ----
        SectionCardGrid {
            width: content.width
            visible: root.picks.length > 0
            title: "Новое для тебя"
            model: root.picks
            cardWidth: root.cardWidth
            cardSpacing: root.cardSpacing
            roundArtwork: false

            onCardClicked: function(index, item) {
                root.openPick(item)
            }

            onPlayRequested: function(index, item) {
                root.playPick(item)
            }
        }

        // ---- Волны по настроению ----
        SectionCardGrid {
            width: content.width
            visible: root.waves.length > 0
            title: "Волны по настроению"
            model: root.waves
            cardWidth: root.cardWidth
            cardSpacing: root.cardSpacing
            roundArtwork: true

            onCardClicked: function(index, item) {
                // Клик по кругу открывает страницу станции.
                const station = String(item.station || "")
                const separator = station.indexOf(":")
                const type = separator > 0 ? station.substring(0, separator) : ""
                const tag = separator > 0 ? station.substring(separator + 1) : station

                if (type.length > 0 && tag.length > 0) {
                    root.stationPageRequested(type, tag, item.title || "Волна")
                }
            }

            onPlayRequested: function(index, item) {
                root.startWheelWave(item)
            }
        }

        PersonalPlaylistsSection {
            width: content.width
            controller: root.controller
            homeMode: true
        }
    }

    component ActionButton: Button {
        id: actionButton

        property string glyph: ""
        property bool emphasized: false

        highlighted: emphasized
        icon.name: {
            switch (glyph) {
                case "play": return "media-playback-start"
                case "chart": return "view-media-recent"
                case "playlist": return "view-media-playlist"
                case "heartFilled": return "starred-symbolic"
                case "search": return "edit-find"
                default: return ""
            }
        }
    }

    component SectionCardGrid: Item {
        id: gridSection

        property string title
        property var model
        property int cardWidth: 150
        property int cardSpacing: 18
        property bool roundArtwork: false

        signal cardClicked(int index, var item)
        signal playRequested(int index, var item)

        readonly property bool isMobile: (typeof window !== "undefined" && window.isMobileMode) || gridSection.width < 540

        // Полностью адаптивное число колонок (2 на мобильных экранах, без лимита в 6 колонок на десктопе)
        readonly property int columns: isMobile
            ? 2
            : Math.max(2, Math.floor((gridSection.width + gridSection.cardSpacing) / (gridSection.cardWidth + gridSection.cardSpacing)))

        // Динамическая ширина карточки для равномерного заполнения всей рабочей области
        readonly property int effectiveCardWidth: Math.floor(
            (gridSection.width - (gridSection.columns - 1) * gridSection.cardSpacing) / gridSection.columns)

        readonly property int rowCount: Math.ceil(
            (gridSection.model ? gridSection.model.length : 0) / Math.max(1, gridSection.columns))

        readonly property int cardHeight: gridSection.roundArtwork ? 206 : (gridSection.effectiveCardWidth + 56)

        implicitHeight:
            listHeader.implicitHeight +
            gridSection.rowCount * (gridSection.cardHeight + gridSection.cardSpacing) + 16

        Column {
            width: gridSection.width
            spacing: 14

            Kirigami.Heading {
                id: listHeader
                width: gridSection.width
                level: 2
                text: gridSection.title
            }

            Grid {
                width: gridSection.width

                columns: gridSection.columns
                spacing: gridSection.cardSpacing

                Repeater {
                    model: gridSection.model

                    delegate: KdeMediaCard {
                        cardWidth: gridSection.effectiveCardWidth
                        cardHeight: gridSection.cardHeight
                        roundArtwork: gridSection.roundArtwork
                        title: String(modelData.title || modelData.name || "")
                        subtitle: String(modelData.description || modelData.subtitle || "")
                        coverUri: modelData.coverUri ? String(modelData.coverUri) : (modelData.coverUrl ? String(modelData.coverUrl) : "")
                        backgroundColor: (modelData.color && String(modelData.color).length > 0)
                            ? modelData.color
                            : "transparent"

                        onActivated: gridSection.cardClicked(index, modelData)
                        onPlayRequested: gridSection.playRequested(index, modelData)
                    }
                }
            }
        }
    }
}