import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import YaMusic 1.0
import "../Components"

Item {
    id: root

    property var controller
    property bool homeMode: false

    readonly property bool isMobile:
        (typeof window !== "undefined" && window.isMobileMode) || width < 680

    readonly property int sectionSpacing: 32
    readonly property int titleSpacing: 14
    readonly property int cardSpacing: 18
    readonly property int artworkTextSpacing: 10
    readonly property int titleHeight: 20
    readonly property int trackCountHeight: 16

    implicitHeight: sectionsColumn.implicitHeight

    Column {
        id: sectionsColumn

        width: parent.width
        spacing: root.sectionSpacing

        Repeater {
            model: root.controller !== null && root.controller !== undefined
                ? root.controller.personalPlaylistsModel
                : null

            delegate: Column {
                id: sectionItem

                required property string title
                required property string type
                required property var playlists
                required property var albums

                // На главной остаётся только подборка «Собираем для вас»:
                // новые плейлисты и релизы открываются кнопками-разделами.
                readonly property bool allowedOnHome:
                    !root.homeMode ||
                    sectionItem.type === "personal-playlists"

                readonly property bool isAlbumsSection:
                    sectionItem.type === "new-releases"

                // На главной — не больше 4 карточек в ряду
                readonly property var visiblePlaylists:
                    root.homeMode
                        ? sectionItem.playlists.slice(0, 4)
                        : sectionItem.playlists

                readonly property bool hasContent:
                    sectionItem.isAlbumsSection
                        ? sectionItem.albums !== null && sectionItem.albums !== undefined &&
                          sectionItem.albums.length > 0
                        : sectionItem.visiblePlaylists !== null &&
                          sectionItem.visiblePlaylists !== undefined &&
                          sectionItem.visiblePlaylists.length > 0

                width: sectionsColumn.width
                spacing: root.titleSpacing

                visible: sectionItem.allowedOnHome && sectionItem.hasContent

                readonly property real cardWidth: {
                    const count = sectionItem.isAlbumsSection
                        ? (sectionItem.albums ? sectionItem.albums.length : 0)
                        : (sectionItem.visiblePlaylists ? sectionItem.visiblePlaylists.length : 0)

                    if (count <= 0) {
                        return 160
                    }

                    if (sectionItem.width <= 0) {
                        return 160
                    }

                    return Math.max(120, Math.min(240, (sectionItem.width -
                        Math.max(0, count - 1) * root.cardSpacing) / count))
                }

                readonly property real cardHeight:
                    sectionItem.cardWidth + 56

                Kirigami.Heading {
                    width: parent.width
                    level: 2
                    text: sectionItem.title
                    elide: Text.ElideRight
                }

                Grid {
                    width: parent.width
                    columns: root.isMobile ? 2 : Math.max(2, Math.floor((width + root.cardSpacing) / (168 + root.cardSpacing)))
                    spacing: root.cardSpacing

                    Repeater {
                        model: sectionItem.isAlbumsSection
                            ? sectionItem.albums
                            : sectionItem.visiblePlaylists

                        delegate: KdeMediaCard {
                            id: playlistCard

                            required property var modelData

                            readonly property bool isAlbumCard:
                                sectionItem.isAlbumsSection

                            cardWidth: root.isMobile
                                ? Math.floor((sectionItem.width - root.cardSpacing) / 2)
                                : 168
                            cardHeight: Math.round(cardWidth + 56)

                            title: String(playlistCard.modelData.title || playlistCard.modelData.name || "")
                            subtitle: playlistCard.isAlbumCard
                                ? (Number(playlistCard.modelData.year || 0) > 0
                                    ? String(playlistCard.modelData.year)
                                    : "")
                                : (Number(playlistCard.modelData.trackCount || 0) > 0
                                    ? qsTr("%1 треков").arg(Number(playlistCard.modelData.trackCount))
                                    : "")
                            coverUri: playlistCard.modelData.coverUri
                                ? String(playlistCard.modelData.coverUri)
                                : (playlistCard.modelData.coverUrl ? String(playlistCard.modelData.coverUrl) : "")

                            onActivated: {
                                if (root.controller === null || root.controller === undefined) {
                                    return
                                }

                                if (playlistCard.isAlbumCard) {
                                    const albumId = String(playlistCard.modelData.albumId || "")
                                    if (albumId.length > 0) {
                                        root.controller.loadAlbum(albumId)
                                    }
                                } else {
                                    const uid = String(playlistCard.modelData.uid || "")
                                    const kind = Number(playlistCard.modelData.kind || 0)
                                    if (uid.length > 0 && kind > 0) {
                                        root.controller.selectPersonalPlaylist(uid, kind)
                                    }
                                }
                            }

                            onPlayRequested: {
                                if (root.controller === null || root.controller === undefined) {
                                    return
                                }

                                if (playlistCard.isAlbumCard) {
                                    const albumId = String(playlistCard.modelData.albumId || "")
                                    if (albumId.length > 0) {
                                        root.controller.playAlbum(albumId)
                                    }
                                } else {
                                    const uid = String(playlistCard.modelData.uid || "")
                                    const kind = Number(playlistCard.modelData.kind || 0)
                                    if (uid.length > 0 && kind > 0) {
                                        root.controller.selectPersonalPlaylist(uid, kind)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}