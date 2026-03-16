import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Hyprland._Ipc

ShellRoot {
    id: root

    property bool launcherVisible: false
    property bool launcherInterrupted: false
    property string activeScreenName: ""

    function showLauncher(): void {
        activeScreenName = Hyprland.focusedMonitor?.name ?? "";
        launcherVisible = true;
    }

    function hideLauncher(): void {
        launcherVisible = false;
    }

    function toggleLauncher(): void {
        if (launcherVisible)
            hideLauncher();
        else
            showLauncher();
    }

    GlobalShortcut {
        appid: "launcher"
        name: "launcher"
        description: "Toggle launcher"

        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted)
                root.toggleLauncher();

            root.launcherInterrupted = false;
        }
    }

    GlobalShortcut {
        appid: "launcher"
        name: "launcherInterrupt"
        description: "Interrupt launcher shortcut"

        onPressed: root.launcherInterrupted = true
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggleLauncher();
        }

        function open(): void {
            root.showLauncher();
        }

        function close(): void {
            root.hideLauncher();
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            required property ShellScreen modelData

            LauncherWindow {
                screen: modelData
                active: root.launcherVisible
                activeScreenName: root.activeScreenName
                screenName: modelData.name ?? ""

                onCloseRequested: root.hideLauncher()
            }
        }
    }
}
