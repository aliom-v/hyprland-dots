pragma ComponentBehavior: Bound

import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell.Services.SystemTray
import QtQuick

MouseArea {
    id: root

    required property SystemTrayItem modelData
    readonly property string trayIconSource: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    preventStealing: true
    implicitWidth: Appearance.font.size.small * 2
    implicitHeight: Appearance.font.size.small * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: root.trayIconSource
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}
