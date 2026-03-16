pragma Singleton

import ".."
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${Config.launcher.actionPrefix}variant `.length);
    }

    list: [
        Variant {
            variant: "vibrant"
            icon: "sentiment_very_dissatisfied"
            name: qsTr("鲜艳")
            description: qsTr("高彩度配色，主色盘彩度拉满。")
        },
        Variant {
            variant: "tonalspot"
            icon: "android"
            name: qsTr("柔和")
            description: qsTr("Material 主题默认配色，低彩度的柔和粉彩。")
        },
        Variant {
            variant: "expressive"
            icon: "compare_arrows"
            name: qsTr("表现")
            description: qsTr("中等彩度配色，主色盘色相与种子颜色不同，变化更多。")
        },
        Variant {
            variant: "fidelity"
            icon: "compare"
            name: qsTr("保真")
            description: qsTr("尽量贴合种子颜色，即使种子颜色非常鲜艳也会保留。")
        },
        Variant {
            variant: "content"
            icon: "sentiment_calm"
            name: qsTr("内容")
            description: qsTr("与保真模式几乎一致。")
        },
        Variant {
            variant: "fruitsalad"
            icon: "nutrition"
            name: qsTr("水果沙拉")
            description: qsTr("更活泼的主题，种子颜色的色相不会直接出现在主题中。")
        },
        Variant {
            variant: "rainbow"
            icon: "looks"
            name: qsTr("彩虹")
            description: qsTr("更活泼的主题，种子颜色的色相不会直接出现在主题中。")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: qsTr("中性")
            description: qsTr("接近灰阶，带一点彩度。")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: qsTr("单色")
            description: qsTr("全部为灰阶色，没有彩度。")
        }
    ]
    useFuzzy: Config.launcher.useFuzzy.variants

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: AppList): void {
            list.visibilities.launcher = false;
            Quickshell.execDetached(["caelestia", "scheme", "set", "-v", variant]);
        }
    }
}
