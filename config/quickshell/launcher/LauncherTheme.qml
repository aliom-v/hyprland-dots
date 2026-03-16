import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`
    readonly property string shellConfigPath: `${configHome}/caelestia/shell.json`
    readonly property string schemePath: `${stateHome}/caelestia/scheme.json`

    property string sansFamily: "Rubik"
    property string monoFamily: "CaskaydiaCove NF"
    property string materialFamily: "Material Symbols Rounded"
    property string clockFamily: "Rubik"
    property real fontScale: 1

    readonly property int fontSmall: Math.round(11 * fontScale)
    readonly property int fontSmaller: Math.round(12 * fontScale)
    readonly property int fontNormal: Math.round(13 * fontScale)
    readonly property int fontLarger: Math.round(15 * fontScale)
    readonly property int fontLarge: Math.round(18 * fontScale)
    readonly property int fontExtraLarge: Math.round(28 * fontScale)

    property color background: "#131317"
    property color surface: "#131317"
    property color surfaceContainer: "#1f1f23"
    property color surfaceContainerHigh: "#2a292e"
    property color surfaceContainerHighest: "#353438"
    property color surfaceForeground: "#e5e1e7"
    property color surfaceVariantForeground: "#c7c5d1"
    property color outline: "#918f9a"
    property color outlineVariant: "#46464f"
    property color primary: "#bfc1ff"
    property color primaryForeground: "#282b60"
    property color primaryContainer: "#6f72ac"
    property color primaryContainerForeground: "#000028"
    property color scrim: "#000000"

    function alpha(colorValue: color, alphaValue: real): color {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, alphaValue);
    }

    function applyShellConfig(data: string): void {
        try {
            const config = JSON.parse(data);
            const family = config?.appearance?.font?.family ?? {};
            const size = config?.appearance?.font?.size ?? {};

            sansFamily = family.sans || "Rubik";
            monoFamily = family.mono || "CaskaydiaCove NF";
            materialFamily = family.material || "Material Symbols Rounded";
            clockFamily = family.clock || sansFamily;
            fontScale = size.scale || 1;
        } catch (error) {
            // Keep defaults when user config is empty or invalid.
        }
    }

    function applyScheme(data: string): void {
        try {
            const colours = JSON.parse(data)?.colours ?? {};

            background = colours.background ? `#${colours.background}` : background;
            surface = colours.surface ? `#${colours.surface}` : surface;
            surfaceContainer = colours.surfaceContainer ? `#${colours.surfaceContainer}` : surfaceContainer;
            surfaceContainerHigh = colours.surfaceContainerHigh ? `#${colours.surfaceContainerHigh}` : surfaceContainerHigh;
            surfaceContainerHighest = colours.surfaceContainerHighest ? `#${colours.surfaceContainerHighest}` : surfaceContainerHighest;
            surfaceForeground = colours.onSurface ? `#${colours.onSurface}` : surfaceForeground;
            surfaceVariantForeground = colours.onSurfaceVariant ? `#${colours.onSurfaceVariant}` : surfaceVariantForeground;
            outline = colours.outline ? `#${colours.outline}` : outline;
            outlineVariant = colours.outlineVariant ? `#${colours.outlineVariant}` : outlineVariant;
            primary = colours.primary ? `#${colours.primary}` : primary;
            primaryForeground = colours.onPrimary ? `#${colours.onPrimary}` : primaryForeground;
            primaryContainer = colours.primaryContainer ? `#${colours.primaryContainer}` : primaryContainer;
            primaryContainerForeground = colours.onPrimaryContainer ? `#${colours.onPrimaryContainer}` : primaryContainerForeground;
            scrim = colours.scrim ? `#${colours.scrim}` : scrim;
        } catch (error) {
            // Keep defaults when state scheme is missing or invalid.
        }
    }

    FileView {
        path: root.shellConfigPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyShellConfig(text())
    }

    FileView {
        path: root.schemePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyScheme(text())
    }
}
