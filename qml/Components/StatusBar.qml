import QtQuick
import QtQuick.Controls

Label {
    id: root

    property string message: "Готово"
    property int hideDelay: 3000

    height: 32
    leftPadding: 16
    rightPadding: 16

    text: message

    color: AppTheme.textPrimary

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    background: Rectangle {
        radius: 16
        color: AppTheme.panel
        border.color: AppTheme.border
        border.width: 1
    }

    elide: Text.ElideRight

    opacity: 0
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: 200 } }

    function show(text) {
        const raw = String(text || "").trim()
        if (raw.length === 0) return

        // Подавляем любые отладочные, технические и шлюзовые сетевые тосты
        if (/колесо/i.test(raw) ||
            /загружен/i.test(raw) ||
            /gateway/i.test(raw) ||
            /502|503|504/.test(raw) ||
            /элементов \d+/i.test(raw) ||
            /моя волна/i.test(raw) ||
            /загрузка/i.test(raw)) {
            console.log("Suppressed status toast:", raw)
            return
        }

        root.message = raw
        root.opacity = 1
        hideTimer.restart()
    }

    function hide() {
        root.opacity = 0
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: root.hide()
    }
}