import qs.components
import qs.services
import qs.config
import QtQuick.Layouts

ColumnLayout {
    spacing: Appearance.spacing.small

    StyledText {
        text: qsTr("大写锁定：%1").arg(Hypr.capsLock ? "开启" : "关闭")
    }

    StyledText {
        text: qsTr("数字锁定：%1").arg(Hypr.numLock ? "开启" : "关闭")
    }
}
