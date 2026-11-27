pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "githubStreak"
    needsColText: false
    visibleWhenLocked: false

    readonly property string configuredUsername: Config.options.background.widgets.githubStreak.username ?? "SulthanAndyno"
    readonly property int weeksShown: Math.max(8, Math.min(36, Config.options.background.widgets.githubStreak.weeksShown ?? 20))
    readonly property bool useGithubGreen: Config.options.background.widgets.githubStreak.useGithubGreen ?? true

    property string resolvedUsername: configuredUsername
    property int totalYear: 0
    property int todayCount: 0
    property bool todayDone: false
    property int currentStreak: 0
    property int longestStreak: 0
    property var weeks: []
    property var monthLabels: []
    property string updatedAt: ""
    property bool isCached: false
    property bool hasError: false
    property var hoveredDay: null
    property double lastFetchMs: 0

    readonly property int cellSize: weeksShown > 26 ? 9 : 11
    readonly property int cellGap: 3

    implicitWidth: Math.max(304, (weeks.length > 0 ? weeks.length : weeksShown) * (cellSize + cellGap) - cellGap + 36)
    implicitHeight: cardColumn.implicitHeight + 24

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onConfiguredUsernameChanged: refreshGraph()
    onWeeksShownChanged: refreshGraph()

    function refreshGraph() {
        if (fetchProc.running) return;
        root.lastFetchMs = Date.now();
        const scriptPath = FileUtils.trimFileProtocol(`${Directories.scriptPath}/coding/github-streak.py`);
        fetchProc.command = ["python3", scriptPath, root.configuredUsername, String(root.weeksShown)];
        fetchProc.running = true;
    }

    function openProfile() {
        const user = root.resolvedUsername || root.configuredUsername;
        if (!user) return;
        Quickshell.execDetached(["xdg-open", `https://github.com/${user}`]);
    }

    function levelColor(level) {
        if (level <= 0) {
            return ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.25);
        }
        if (root.useGithubGreen) {
            if (Appearance.m3colors.darkmode) {
                switch (level) {
                    case 1: return "#0e4429";
                    case 2: return "#006d32";
                    case 3: return "#26a641";
                    default: return "#39d353";
                }
            }
            switch (level) {
                case 1: return "#9be9a8";
                case 2: return "#40c463";
                case 3: return "#30a14e";
                default: return "#216e39";
            }
        }
        switch (level) {
            case 1: return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.72);
            case 2: return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.50);
            case 3: return ColorUtils.transparentize(Appearance.colors.colPrimary, 0.25);
            default: return Appearance.colors.colPrimary;
        }
    }

    Timer {
        id: pollTimer
        interval: 900000 // 15 minutes
        running: Config.options.background.widgets.githubStreak.enable && root.pollingActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.weeks.length === 0 || (Date.now() - root.lastFetchMs) >= 300000) {
                root.refreshGraph();
            }
        }
    }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            id: graphCollector
            onStreamFinished: {
                const raw = graphCollector.text.trim();
                if (raw.length === 0) return;
                try {
                    const data = JSON.parse(raw);
                    if (data.error && (!data.weeks || data.weeks.length === 0)) {
                        root.hasError = true;
                        return;
                    }
                    root.hasError = false;
                    root.resolvedUsername = data.username || root.configuredUsername;
                    root.totalYear = data.totalYear ?? 0;
                    root.todayCount = data.todayCount ?? 0;
                    root.todayDone = Boolean(data.todayDone);
                    root.currentStreak = data.currentStreak ?? 0;
                    root.longestStreak = data.longestStreak ?? 0;
                    root.weeks = data.weeks ?? [];
                    root.monthLabels = data.monthLabels ?? [];
                    root.updatedAt = data.updatedAt ?? "";
                    root.isCached = Boolean(data.cached);
                } catch (e) {
                    root.hasError = true;
                }
            }
        }
    }

    StyledRectangularShadow {
        target: cardBackground
    }

    Rectangle {
        id: cardBackground
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.24)
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)

        ColumnLayout {
            id: cardColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                MaterialSymbol {
                    iconSize: 18
                    fill: root.currentStreak > 0 ? 1 : 0
                    text: root.currentStreak > 0 ? "local_fire_department" : "calendar_view_month"
                    color: root.currentStreak > 0
                        ? (root.useGithubGreen ? "#39d353" : Appearance.colors.colPrimary)
                        : Appearance.colors.colSubtext
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("GitHub Contributions")
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.DemiBold
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: `@${root.resolvedUsername}${root.isCached ? " • cached" : (root.updatedAt ? " • " + root.updatedAt : "")}`
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest - 1
                        }
                    }
                }

                // Today badge
                Rectangle {
                    implicitWidth: todayText.implicitWidth + 12
                    implicitHeight: 20
                    radius: Appearance.rounding.full
                    color: root.todayDone
                        ? ColorUtils.transparentize(root.useGithubGreen ? "#26a641" : Appearance.colors.colPrimary, 0.78)
                        : ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.2)
                    border.width: 1
                    border.color: root.todayDone
                        ? ColorUtils.transparentize(root.useGithubGreen ? "#39d353" : Appearance.colors.colPrimary, 0.45)
                        : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.5)

                    StyledText {
                        id: todayText
                        anchors.centerIn: parent
                        text: root.todayDone ? `+${root.todayCount} today` : "0 today"
                        color: root.todayDone
                            ? (root.useGithubGreen ? "#39d353" : Appearance.colors.colPrimary)
                            : Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.DemiBold
                        }
                    }
                }

                IconPillButton {
                    iconName: "refresh"
                    onClicked: root.refreshGraph()
                }

                IconPillButton {
                    iconName: "open_in_new"
                    onClicked: root.openProfile()
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
            }

            // Heatmap container
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heatmapCol.implicitHeight + 14
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.5)
                border.width: 1
                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                ColumnLayout {
                    id: heatmapCol
                    anchors {
                        centerIn: parent
                    }
                    spacing: 4

                    // Month header row
                    Row {
                        visible: !root.hasError && root.weeks.length > 0
                        spacing: root.cellGap

                        Repeater {
                            model: root.weeks.length
                            delegate: Item {
                                required property int index
                                width: root.cellSize
                                height: 12

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    text: root.monthLabels[index] ?? ""
                                    color: Appearance.colors.colSubtext
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }

                    // Weeks grid (columns = weeks, rows = Sun..Sat)
                    Row {
                        visible: !root.hasError && root.weeks.length > 0
                        spacing: root.cellGap

                        Repeater {
                            model: root.weeks
                            delegate: Column {
                                required property var modelData
                                required property int index
                                spacing: root.cellGap

                                Repeater {
                                    model: modelData
                                    delegate: Rectangle {
                                        required property var modelData
                                        readonly property int lvl: modelData.level ?? 0
                                        readonly property bool isHovered: root.hoveredDay && root.hoveredDay.date === modelData.date

                                        width: root.cellSize
                                        height: root.cellSize
                                        radius: 2.5
                                        color: root.levelColor(lvl)
                                        border.width: isHovered ? 1.2 : (lvl === 0 ? 0.8 : 0)
                                        border.color: isHovered
                                            ? Appearance.colors.colOnLayer0
                                            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: root.hoveredDay = modelData
                                            onExited: {
                                                if (root.hoveredDay && root.hoveredDay.date === modelData.date) {
                                                    root.hoveredDay = null;
                                                }
                                            }
                                            onClicked: root.openProfile()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Loading / error state
                    StyledText {
                        visible: root.hasError || root.weeks.length === 0
                        padding: 16
                        text: root.hasError
                            ? Translation.tr("Could not load GitHub contributions (click refresh)")
                            : Translation.tr("Loading GitHub contributions...")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }
                }
            }

            // Hover detail + Legend row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: root.hoveredDay
                        ? `${root.hoveredDay.count} contrib${root.hoveredDay.count === 1 ? "" : "s"} • ${root.hoveredDay.date}`
                        : Translation.tr("Hover any square for date details")
                    color: root.hoveredDay ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.monospace
                        pixelSize: Appearance.font.pixelSize.smallest - 1
                    }
                }

                Row {
                    spacing: 3
                    Layout.alignment: Qt.AlignVCenter

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Less")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest - 2
                    }

                    Repeater {
                        model: [0, 1, 2, 3, 4]
                        delegate: Rectangle {
                            required property int modelData
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: 2
                            color: root.levelColor(modelData)
                            border.width: modelData === 0 ? 0.6 : 0
                            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("More")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest - 2
                    }
                }
            }

            // Stats Strip
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                uniformCellSizes: true

                StatTile {
                    Layout.fillWidth: true
                    label: Translation.tr("Streak")
                    valueText: `${root.currentStreak}d`
                    accent: root.currentStreak > 0
                    accentColor: root.useGithubGreen ? "#39d353" : Appearance.colors.colPrimary
                }

                StatTile {
                    Layout.fillWidth: true
                    label: Translation.tr("Best (1y)")
                    valueText: `${root.longestStreak}d`
                }

                StatTile {
                    Layout.fillWidth: true
                    label: Translation.tr("Year Total")
                    valueText: `${root.totalYear}`
                }
            }
        }
    }

    component StatTile: Rectangle {
        id: tile
        required property string label
        required property string valueText
        property bool accent: false
        property color accentColor: Appearance.colors.colPrimary

        implicitHeight: 40
        radius: Appearance.rounding.normal
        color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.42)
        border.width: 1
        border.color: tile.accent
            ? ColorUtils.transparentize(tile.accentColor, 0.55)
            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)

        Column {
            anchors.centerIn: parent
            spacing: 1

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.valueText
                color: tile.accent ? tile.accentColor : Appearance.colors.colOnLayer0
                font {
                    family: Appearance.font.family.monospace
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Bold
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest - 1
            }
        }
    }

    component IconPillButton: Rectangle {
        id: btn
        required property string iconName
        signal clicked()

        width: 24
        height: 24
        radius: Appearance.rounding.full
        color: btnMouse.containsMouse
            ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.1)
            : "transparent"

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 15
            text: btn.iconName
            color: btnMouse.containsMouse
                ? Appearance.colors.colPrimary
                : Appearance.colors.colOnLayer1
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
