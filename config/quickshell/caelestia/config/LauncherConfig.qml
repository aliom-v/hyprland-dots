import Quickshell.Io

JsonObject {
    property bool enabled: true
    property bool showOnHover: false
    property int maxShown: 7
    property int maxWallpapers: 9 // Warning: even numbers look bad
    property string specialPrefix: "@"
    property string actionPrefix: ">"
    property bool enableDangerousActions: false // Allow actions that can cause losing data, like shutdown, reboot and logout
    property int dragThreshold: 50
    property bool vimKeybinds: false
    property list<string> favouriteApps: []
    property list<string> hiddenApps: []
    property UseFuzzy useFuzzy: UseFuzzy {}
    property Sizes sizes: Sizes {}

    component UseFuzzy: JsonObject {
        property bool apps: false
        property bool actions: false
        property bool schemes: false
        property bool variants: false
        property bool wallpapers: false
    }

    component Sizes: JsonObject {
        property int itemWidth: 600
        property int itemHeight: 57
        property int wallpaperWidth: 280
        property int wallpaperHeight: 200
    }

    property list<var> actions: [
        {
            name: qsTr("计算器"),
            icon: "calculate",
            description: qsTr("执行简单数学计算（由 Qalc 提供）"),
            command: ["autocomplete", "calc"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("配色方案"),
            icon: "palette",
            description: qsTr("切换当前配色方案"),
            command: ["autocomplete", "scheme"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("壁纸"),
            icon: "image",
            description: qsTr("切换当前壁纸"),
            command: ["autocomplete", "wallpaper"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("配色变体"),
            icon: "colors",
            description: qsTr("切换当前配色变体"),
            command: ["autocomplete", "variant"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("透明度"),
            icon: "opacity",
            description: qsTr("调整界面透明度"),
            command: ["autocomplete", "transparency"],
            enabled: false,
            dangerous: false
        },
        {
            name: qsTr("随机壁纸"),
            icon: "casino",
            description: qsTr("切换到随机壁纸"),
            command: ["caelestia", "wallpaper", "-r"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("浅色模式"),
            icon: "light_mode",
            description: qsTr("切换到浅色模式"),
            command: ["setMode", "light"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("深色模式"),
            icon: "dark_mode",
            description: qsTr("切换到深色模式"),
            command: ["setMode", "dark"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("关机"),
            icon: "power_settings_new",
            description: qsTr("关闭系统"),
            command: ["systemctl", "poweroff"],
            enabled: true,
            dangerous: true
        },
        {
            name: qsTr("重启"),
            icon: "cached",
            description: qsTr("重新启动系统"),
            command: ["systemctl", "reboot"],
            enabled: true,
            dangerous: true
        },
        {
            name: qsTr("注销"),
            icon: "exit_to_app",
            description: qsTr("退出当前会话"),
            command: ["loginctl", "terminate-user", ""],
            enabled: true,
            dangerous: true
        },
        {
            name: qsTr("锁屏"),
            icon: "lock",
            description: qsTr("锁定当前会话"),
            command: ["loginctl", "lock-session"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("睡眠"),
            icon: "bedtime",
            description: qsTr("先挂起后休眠"),
            command: ["systemctl", "suspend-then-hibernate"],
            enabled: true,
            dangerous: false
        },
        {
            name: qsTr("设置"),
            icon: "settings",
            description: qsTr("配置桌面壳设置"),
            command: ["caelestia", "shell", "controlCenter", "open"],
            enabled: true,
            dangerous: false
        }
    ]
}
