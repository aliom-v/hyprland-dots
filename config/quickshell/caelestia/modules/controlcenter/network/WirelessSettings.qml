pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Appearance.spacing.normal

    SettingsHeader {
        icon: "wifi"
        title: qsTr("网络设置")
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("无线网络状态")
        description: qsTr("无线网络基础设置")
    }

    SectionContainer {
        ToggleRow {
            label: qsTr("无线网络已启用")
            checked: Nmcli.wifiEnabled
            toggle.onToggled: {
                Nmcli.enableWifi(checked);
            }
        }
    }

    SectionHeader {
        Layout.topMargin: Appearance.spacing.large
        title: qsTr("网络信息")
        description: qsTr("当前网络连接")
    }

    SectionContainer {
        contentSpacing: Appearance.spacing.small / 2

        PropertyRow {
            label: qsTr("当前连接网络")
            value: Nmcli.active ? Nmcli.active.ssid : qsTr("未连接")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("信号强度")
            value: Nmcli.active ? qsTr("%1%").arg(Nmcli.active.strength) : qsTr("不可用")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("安全性")
            value: Nmcli.active ? (Nmcli.active.isSecure ? ((Nmcli.active.security && Nmcli.active.security.length > 0) ? Nmcli.active.security : qsTr("已加密")) : qsTr("开放网络")) : qsTr("不可用")
        }

        PropertyRow {
            showTopMargin: true
            label: qsTr("频率")
            value: Nmcli.active ? qsTr("%1 MHz").arg(Nmcli.active.frequency) : qsTr("不可用")
        }
    }
}
