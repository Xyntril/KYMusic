import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import YaMusic 1.0

KdeMediaCard {
    id: root

    property var controller: null
    property int trackCount: 0
    property int year: 0

    subtitle: {
        if (root.subtitle && root.subtitle.length > 0) return root.subtitle
        if (root.trackCount > 0) return qsTr("%1 треков").arg(root.trackCount)
        if (root.year > 0) return String(root.year)
        return ""
    }
}
