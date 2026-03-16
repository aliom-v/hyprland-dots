import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: window

    required property bool active
    required property string activeScreenName
    required property string screenName

    signal closeRequested()

    property string query: ""
    property var allApps: []
    property var results: []
    property int currentIndex: results.length > 0 ? 0 : -1

    LauncherTheme {
        id: theme
    }

    readonly property bool shown: active && (activeScreenName === "" || activeScreenName === screenName)
    readonly property int maxVisibleResults: 7
    readonly property int rowHeight: 70
    readonly property int rowSpacing: 8
    readonly property int listViewportHeight: results.length > 0
        ? (rowHeight + rowSpacing) * Math.min(maxVisibleResults, results.length) - rowSpacing
        : 0
    readonly property color panelColor: theme.alpha(theme.surfaceContainerHigh, 0.94)
    readonly property color panelBorder: theme.alpha(theme.outlineVariant, 0.9)
    readonly property color panelInnerBorder: theme.alpha(theme.surfaceForeground, 0.08)
    readonly property color scrimColor: theme.alpha(theme.scrim, 0.48)
    readonly property color accentColor: theme.surfaceForeground
    readonly property color accentStrong: theme.primary
    readonly property color mutedText: theme.surfaceVariantForeground
    readonly property color subtleText: theme.alpha(theme.surfaceVariantForeground, 0.72)
    readonly property color rowColor: "#00000000"
    readonly property color rowHoverColor: theme.alpha(theme.primaryContainer, 0.18)
    readonly property color rowActiveColor: theme.alpha(theme.primary, 0.16)

    anchors.top: true
    anchors.right: true
    anchors.bottom: true
    anchors.left: true

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: shown
    color: "transparent"
    WlrLayershell.namespace: "launcher"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: shown || backdrop.opacity > 0.01 || launcherCard.opacity > 0.01

    function normalizeText(value: string): string {
        return (value ?? "").toString().trim().toLowerCase();
    }

    function subsequenceScore(haystack: string, needle: string): real {
        if (!haystack || !needle)
            return -1;

        let lastIndex = -1;
        let gapPenalty = 0;

        for (let i = 0; i < needle.length; i++) {
            const idx = haystack.indexOf(needle[i], lastIndex + 1);
            if (idx === -1)
                return -1;

            if (lastIndex !== -1)
                gapPenalty += idx - lastIndex - 1;

            lastIndex = idx;
        }

        return Math.max(0, 260 - gapPenalty * 7 - Math.max(0, haystack.length - needle.length) * 0.6);
    }

    function entryScore(entry: DesktopEntry, loweredQuery: string, tokens: var): real {
        const name = normalizeText(entry.name);
        const genericName = normalizeText(entry.genericName);
        const comment = normalizeText(entry.comment);
        const id = normalizeText(entry.id);
        const keywords = normalizeText((entry.keywords ?? []).join(" "));
        const categories = normalizeText((entry.categories ?? []).join(" "));
        const haystack = `${name} ${genericName} ${comment} ${id} ${keywords} ${categories}`;

        let score = -1;

        const exactFields = [name, genericName, id];
        for (const field of exactFields) {
            if (!field)
                continue;

            if (field === loweredQuery)
                score = Math.max(score, 2400 - field.length);
            else if (field.startsWith(loweredQuery))
                score = Math.max(score, 2000 - field.length * 0.4);
            else {
                const containsIndex = field.indexOf(loweredQuery);
                if (containsIndex !== -1)
                    score = Math.max(score, 1600 - containsIndex * 20 - field.length * 0.2);
            }
        }

        if (tokens.length > 0) {
            let tokenScore = 1200;
            let allMatched = true;

            for (const token of tokens) {
                const tokenIndex = haystack.indexOf(token);
                if (tokenIndex === -1) {
                    allMatched = false;
                    break;
                }

                tokenScore -= tokenIndex * 4;
            }

            if (allMatched)
                score = Math.max(score, tokenScore);
        }

        score = Math.max(score, 900 + subsequenceScore(name, loweredQuery));
        score = Math.max(score, 780 + subsequenceScore(genericName, loweredQuery));
        score = Math.max(score, 620 + subsequenceScore(id, loweredQuery));

        if (comment.includes(loweredQuery))
            score = Math.max(score, 680 - comment.indexOf(loweredQuery) * 4);

        if (keywords.includes(loweredQuery))
            score = Math.max(score, 640 - keywords.indexOf(loweredQuery) * 4);

        return score;
    }

    function rebuildResults(): void {
        const loweredQuery = normalizeText(query);

        if (!loweredQuery) {
            results = allApps.slice();
            currentIndex = results.length > 0 ? 0 : -1;
            return;
        }

        const tokens = loweredQuery.split(/\s+/).filter(token => token.length > 0);
        const matches = [];

        for (const entry of allApps) {
            const score = entryScore(entry, loweredQuery, tokens);
            if (score >= 0)
                matches.push({ entry, score });
        }

        matches.sort((left, right) => {
            if (right.score !== left.score)
                return right.score - left.score;

            return (left.entry.name ?? "").localeCompare(right.entry.name ?? "");
        });

        results = matches.map(match => match.entry);
        currentIndex = results.length > 0 ? 0 : -1;
    }

    function refreshApps(): void {
        const entries = DesktopEntries.applications.values
            .filter(entry => !entry.noDisplay)
            .slice()
            .sort((left, right) => (left.name ?? "").localeCompare(right.name ?? ""));

        allApps = entries;
        rebuildResults();
    }

    function closeLauncher(): void {
        query = "";
        rebuildResults();
        closeRequested();
    }

    function activateCurrent(): void {
        if (currentIndex < 0 || currentIndex >= results.length)
            return;

        results[currentIndex].execute();
        closeLauncher();
    }

    function moveSelection(step: int): void {
        if (results.length === 0)
            return;

        if (currentIndex < 0) {
            currentIndex = step > 0 ? 0 : results.length - 1;
            return;
        }

        currentIndex = Math.max(0, Math.min(results.length - 1, currentIndex + step));
    }

    function moveSelectionPage(step: int): void {
        moveSelection(step * Math.max(1, maxVisibleResults - 1));
    }

    function selectIndex(index: int): void {
        if (index < 0 || index >= results.length)
            return;

        currentIndex = index;
    }

    Component.onCompleted: refreshApps()
    onShownChanged: {
        if (shown) {
            query = "";
            rebuildResults();
            Qt.callLater(() => searchInput.forceActiveFocus());
        }
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged(): void {
            window.refreshApps();
        }
    }

    HyprlandFocusGrab {
        active: shown
        windows: [window]
        onCleared: window.closeLauncher()
    }

    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: scrimColor
        opacity: shown ? 0.82 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: shown
        onClicked: window.closeLauncher()
    }

    Item {
        id: launcherCard

        width: Math.min(Math.max(620, (screen?.width ?? 1280) * 0.36), 860)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: shown ? Math.max(72, (screen?.height ?? 720) * 0.11) : Math.max(48, (screen?.height ?? 720) * 0.08)
        implicitHeight: contentColumn.implicitHeight + 28

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.965

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 30
            color: theme.alpha(theme.scrim, 0.2)
            y: 14
            opacity: shown ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: cardSurface

            anchors.fill: parent
            radius: 30
            color: panelColor
            border.color: panelBorder
            border.width: 1
            clip: true
            antialiasing: true

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#7f000000"
                shadowBlur: 0.55
                shadowVerticalOffset: 16
                shadowHorizontalOffset: 0
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.color: panelInnerBorder
                border.width: 1
                opacity: 0.7
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 104
                radius: parent.radius
                color: theme.alpha(theme.surfaceForeground, 0.05)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Column {
                id: contentColumn

                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Rectangle {
                    id: searchBar

                    width: parent.width
                    height: 74
                    radius: 22
                    color: theme.alpha(theme.surfaceForeground, 0.05)
                    border.color: searchInput.activeFocus ? accentStrong : theme.alpha(theme.surfaceForeground, 0.12)
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 160
                        }
                    }

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 16
                        color: theme.alpha(theme.primaryContainer, 0.35)
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "Q"
                            color: theme.primary
                            font.family: theme.sansFamily
                            font.pixelSize: theme.fontLarger
                            font.bold: true
                        }
                    }

                    TextInput {
                        id: searchInput

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 76
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter

                        color: accentColor
                        font.family: theme.sansFamily
                        font.pixelSize: theme.fontExtraLarge
                        font.weight: Font.DemiBold
                        selectionColor: theme.alpha(theme.primary, 0.35)
                        selectedTextColor: theme.surfaceForeground
                        clip: true
                        Keys.priority: Keys.BeforeItem

                        text: window.query
                        onTextChanged: {
                            window.query = text;
                            window.rebuildResults();
                        }

                        Keys.onEscapePressed: event => {
                            window.closeLauncher();
                            event.accepted = true;
                        }

                        Keys.onDownPressed: event => {
                            window.moveSelection(1);
                            event.accepted = true;
                        }

                        Keys.onUpPressed: event => {
                            window.moveSelection(-1);
                            event.accepted = true;
                        }

                        Keys.onTabPressed: event => {
                            window.moveSelection(1);
                            event.accepted = true;
                        }

                        Keys.onBacktabPressed: event => {
                            window.moveSelection(-1);
                            event.accepted = true;
                        }

                        Keys.onReturnPressed: event => {
                            window.activateCurrent();
                            event.accepted = true;
                        }

                        Keys.onEnterPressed: event => {
                            window.activateCurrent();
                            event.accepted = true;
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_PageDown) {
                                window.moveSelectionPage(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                window.moveSelectionPage(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Home) {
                                window.selectIndex(0);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_End) {
                                window.selectIndex(window.results.length - 1);
                                event.accepted = true;
                            }
                        }

                        Text {
                            visible: searchInput.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search apps"
                            color: subtleText
                            font.family: searchInput.font.family
                            font.pixelSize: searchInput.font.pixelSize
                            font.weight: Font.Medium
                        }
                    }
                }

                Item {
                    width: parent.width
                    implicitHeight: results.length > 0 ? resultList.height : emptyState.implicitHeight

                    ListView {
                        id: resultList

                        visible: results.length > 0
                        width: parent.width
                        height: listViewportHeight
                        model: window.results
                        currentIndex: window.currentIndex
                        interactive: false
                        spacing: rowSpacing
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        preferredHighlightBegin: 0
                        preferredHighlightEnd: height
                        highlightRangeMode: ListView.ApplyRange

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0)
                                positionViewAtIndex(currentIndex, ListView.Contain);
                        }

                        highlightFollowsCurrentItem: false
                        highlight: Rectangle {
                            radius: 18
                            color: rowActiveColor
                            border.color: theme.alpha(theme.primary, 0.2)
                            border.width: 1
                            y: resultList.currentItem?.y ?? 0
                            implicitWidth: resultList.width
                            implicitHeight: resultList.currentItem?.height ?? 0

                            Behavior on y {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on implicitHeight {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        add: Transition {
                            NumberAnimation {
                                properties: "opacity,y"
                                from: 0
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }

                        move: Transition {
                            NumberAnimation {
                                properties: "y"
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        remove: Transition {
                            NumberAnimation {
                                properties: "opacity,y"
                                to: 0
                                duration: 120
                                easing.type: Easing.InCubic
                            }
                        }

                        delegate: Rectangle {
                            id: row

                            required property var modelData
                            required property int index

                            width: resultList.width
                            height: rowHeight
                            radius: 18
                            color: rowMouse.containsMouse && resultList.currentIndex !== index ? rowHoverColor : rowColor
                            border.color: rowMouse.containsMouse && resultList.currentIndex !== index ? theme.alpha(theme.surfaceForeground, 0.08) : "#00000000"
                            border.width: 1
                            scale: resultList.currentIndex === index ? 1 : 0.992

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            MouseArea {
                                id: rowMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                onEntered: window.selectIndex(index)
                                onClicked: {
                                    window.selectIndex(index);
                                    window.activateCurrent();
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                spacing: 16

                                Item {
                                    width: 38
                                    height: parent.height

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 28
                                        source: Quickshell.iconPath(modelData?.icon, "application-x-executable")
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 96
                                    spacing: 3

                                    Text {
                                        text: modelData?.name ?? ""
                                        color: accentColor
                                        font.family: theme.sansFamily
                                        font.pixelSize: theme.fontLarge
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        text: modelData?.comment || modelData?.genericName || modelData?.id || ""
                                        color: mutedText
                                        font.family: theme.sansFamily
                                        font.pixelSize: theme.fontNormal
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: emptyState

                        visible: results.length === 0
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "No matching apps"
                            color: accentColor
                            font.family: theme.sansFamily
                            font.pixelSize: theme.fontExtraLarge - 2
                            font.weight: Font.DemiBold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: query.length > 0 ? "Try a different app name, keyword, or category." : "Start typing to search the installed desktop apps."
                            color: mutedText
                            font.family: theme.sansFamily
                            font.pixelSize: theme.fontNormal + 1
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}
