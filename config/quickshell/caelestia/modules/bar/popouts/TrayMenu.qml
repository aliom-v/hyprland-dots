pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls

StackView {
    id: root

    required property Item popouts
    required property string trayItemId
    required property QsMenuHandle trayItem

    implicitWidth: currentItem.implicitWidth
    implicitHeight: currentItem.implicitHeight

    initialItem: SubMenu {
        handle: root.trayItem
    }

    pushEnter: NoAnim {}
    pushExit: NoAnim {}
    popEnter: NoAnim {}
    popExit: NoAnim {}

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    function shouldHideEntry(entry: QsMenuEntry, index: int): bool {
        return false;
    }

    function getMenuIcon(icon: string): string {
        if (icon === "")
            return "";
        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=");
            return Qt.resolvedUrl(`${path}/${name.slice(name.lastIndexOf("/") + 1)}`);
        }
        if (icon.includes("://") || icon.startsWith("/"))
            return icon;
        return Quickshell.iconPath(icon, "image-missing");
    }

    function getMenuText(text: string): string {
        return text;
    }

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu
        property bool shown

        padding: Appearance.padding.smaller
        spacing: Appearance.spacing.small

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        QsMenuOpener {
            id: menuOpener

            menu: menu.handle
        }

        Repeater {
            model: menuOpener.children

            StyledRect {
                id: item

                required property QsMenuEntry modelData
                readonly property bool hiddenByFilter: root.shouldHideEntry(item.modelData, index)

                implicitWidth: Config.bar.sizes.trayMenuWidth
                implicitHeight: hiddenByFilter ? 0 : modelData.isSeparator ? 1 : children.implicitHeight

                radius: Appearance.rounding.full
                color: hiddenByFilter ? "transparent" : modelData.isSeparator ? Colours.palette.m3outlineVariant : "transparent"
                visible: !hiddenByFilter

                Loader {
                    id: children

                    anchors.left: parent.left
                    anchors.right: parent.right

                    active: !item.hiddenByFilter && !item.modelData.isSeparator

                    sourceComponent: Item {
                        implicitHeight: label.implicitHeight

                        StateLayer {
                            anchors.margins: -Appearance.padding.small / 2
                            anchors.leftMargin: -Appearance.padding.smaller
                            anchors.rightMargin: -Appearance.padding.smaller

                            radius: item.radius
                            disabled: !item.modelData.enabled

                            function onClicked(): void {
                                const entry = item.modelData;
                                if (entry.hasChildren)
                                    root.push(subMenuComp.createObject(null, {
                                        handle: entry,
                                        isSubMenu: true
                                    }));
                                else {
                                    item.modelData.triggered();
                                    root.popouts.hasCurrent = false;
                                }
                            }
                        }

                        Loader {
                            id: icon

                            anchors.left: parent.left

                            active: item.modelData.icon !== ""

                            sourceComponent: IconImage {
                                implicitSize: label.implicitHeight

                                source: root.getMenuIcon(item.modelData.icon)
                            }
                        }

                        StyledText {
                            id: label

                            anchors.left: icon.right
                            anchors.leftMargin: icon.active ? Appearance.spacing.smaller : 0

                            text: labelMetrics.elidedText
                            color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                        }

                        TextMetrics {
                            id: labelMetrics

                            text: root.getMenuText(item.modelData.text)
                            font.pointSize: label.font.pointSize
                            font.family: label.font.family

                            elide: Text.ElideRight
                            elideWidth: Config.bar.sizes.trayMenuWidth - (icon.active ? icon.implicitWidth + label.anchors.leftMargin : 0) - (expand.active ? expand.implicitWidth + Appearance.spacing.normal : 0)
                        }

                        Loader {
                            id: expand

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right

                            active: item.modelData.hasChildren

                            sourceComponent: MaterialIcon {
                                text: "chevron_right"
                                color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                            }
                        }
                    }
                }
            }
        }

        Loader {
            active: menu.isSubMenu

            sourceComponent: Item {
                implicitWidth: back.implicitWidth
                implicitHeight: back.implicitHeight + Appearance.spacing.small / 2

                Item {
                    anchors.bottom: parent.bottom
                    implicitWidth: back.implicitWidth
                    implicitHeight: back.implicitHeight

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: -Appearance.padding.small / 2
                        anchors.leftMargin: -Appearance.padding.smaller
                        anchors.rightMargin: -Appearance.padding.smaller * 2

                        radius: Appearance.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onSecondaryContainer

                            function onClicked(): void {
                                root.pop();
                            }
                        }
                    }

                    Row {
                        id: back

                        anchors.verticalCenter: parent.verticalCenter

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "chevron_left"
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("返回")
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }

    Component {
        id: subMenuComp

        SubMenu {}
    }
}
