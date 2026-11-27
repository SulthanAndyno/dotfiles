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

    configEntryName: "gitPulse"
    needsColText: false
    visibleWhenLocked: false

    readonly property bool showClean: Config.options.background.widgets.gitPulse.showClean ?? false
    readonly property int maxVisible: Math.max(1, Config.options.background.widgets.gitPulse.maxItems ?? 5)
    property var repos: []
    readonly property int attentionCount: repos.filter(r => r.dirty > 0 || r.ahead > 0 || r.behind > 0).length
    readonly property var visibleRepos: repos.slice(0, maxVisible)
    readonly property int hiddenCount: Math.max(0, repos.length - visibleRepos.length)

    readonly property bool hiddenByClean: (Config.options.background.widgets.gitPulse.hideWhenClean ?? false) && attentionCount === 0
    opacity: ((GlobalStates.screenLocked && !visibleWhenLocked) || hiddenByClean) ? 0 : 1

    implicitWidth: 320
    implicitHeight: cardColumn.implicitHeight + 24

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onShowCleanChanged: refreshRepos()

    function refreshRepos() {
        if (scanGitProc.running) return;
        const scriptPath = FileUtils.trimFileProtocol(`${Directories.scriptPath}/coding/git-pulse.sh`);
        scanGitProc.command = ["bash", scriptPath, root.showClean ? "1" : "0"];
        scanGitProc.running = true;
    }

    function openLazygit(repoPath) {
        Quickshell.execDetached(["kitty", "--class", "lazygit", "--directory", repoPath, "-e", "lazygit"]);
    }

    function openTerminal(repoPath) {
        Quickshell.execDetached(["kitty", "--directory", repoPath]);
    }

    Timer {
        id: pollTimer
        interval: 30000
        running: Config.options.background.widgets.gitPulse.enable && !GlobalStates.screenLocked
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshRepos()
    }

    Process {
        id: scanGitProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            id: gitCollector
            onStreamFinished: {
                const raw = gitCollector.text.trim();
                if (raw.length === 0) {
                    root.repos = [];
                    return;
                }
                const parsed = [];
                for (const line of raw.split("\n")) {
                    const parts = line.split("|");
                    if (parts.length >= 6) {
                        parsed.push({
                            path: parts[0].trim(),
                            name: parts[1].trim(),
                            branch: parts[2].trim(),
                            dirty: parseInt(parts[3], 10) || 0,
                            ahead: parseInt(parts[4], 10) || 0,
                            behind: parseInt(parts[5], 10) || 0
                        });
                    }
                }
                root.repos = parsed;
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
                    text: "commit"
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Git Pulse")
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.normal
                        weight: Font.DemiBold
                    }
                }

                Rectangle {
                    implicitWidth: countText.implicitWidth + 12
                    implicitHeight: 20
                    radius: Appearance.rounding.full
                    color: root.attentionCount > 0
                        ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)
                        : ColorUtils.transparentize(Appearance.m3colors.m3successContainer, 0.2)

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: root.attentionCount > 0 ? `${root.attentionCount} active` : "All clean"
                        color: root.attentionCount > 0
                            ? Appearance.colors.colOnPrimaryContainer
                            : Appearance.m3colors.m3onSuccessContainer
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.DemiBold
                        }
                    }
                }

                IconPillButton {
                    iconName: "filter_list"
                    active: root.showClean
                    onClicked: {
                        Config.options.background.widgets.gitPulse.showClean = !root.showClean;
                    }
                }

                IconPillButton {
                    iconName: "refresh"
                    onClicked: root.refreshRepos()
                }

                IconPillButton {
                    iconName: "open_in_new"
                    onClicked: Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/git_ui.sh"])
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
            }

            // Empty / Clean state
            Rectangle {
                visible: root.visibleRepos.length === 0
                Layout.fillWidth: true
                implicitHeight: emptyCol.implicitHeight + 18
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.45)

                ColumnLayout {
                    id: emptyCol
                    anchors.centerIn: parent
                    spacing: 4

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        MaterialSymbol {
                            iconSize: 16
                            text: "check_circle"
                            color: Appearance.m3colors.m3success
                        }

                        StyledText {
                            text: Translation.tr("All workspace repos are clean")
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smallie
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Click filter icon to list clean repos too")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }
            }

            // Repo list
            ColumnLayout {
                visible: root.visibleRepos.length > 0
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.visibleRepos
                    delegate: Rectangle {
                        id: repoRow
                        required property var modelData
                        readonly property bool hasChanges: modelData.dirty > 0 || modelData.ahead > 0 || modelData.behind > 0
                        readonly property bool isHovered: openRowMouse.containsMouse || termBtnMouse.containsMouse

                        Layout.fillWidth: true
                        implicitHeight: rowContent.implicitHeight + 10
                        radius: Appearance.rounding.small
                        color: isHovered
                            ? ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.2)
                            : ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.55)

                        RowLayout {
                            id: rowContent
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8
                                rightMargin: 6
                            }
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 4
                                color: repoRow.modelData.dirty > 0
                                    ? Appearance.colors.colPrimary
                                    : (repoRow.modelData.ahead > 0
                                        ? Appearance.m3colors.m3tertiary
                                        : Appearance.m3colors.m3success)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: repoRow.modelData.name
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnLayer0
                                        font {
                                            family: Appearance.font.family.main
                                            pixelSize: Appearance.font.pixelSize.smallie
                                            weight: Font.Medium
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: branchText.implicitWidth + 8
                                        implicitHeight: 16
                                        radius: Appearance.rounding.small
                                        color: ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.15)

                                        StyledText {
                                            id: branchText
                                            anchors.centerIn: parent
                                            text: repoRow.modelData.branch
                                            color: Appearance.colors.colSubtext
                                            font {
                                                family: Appearance.font.family.monospace
                                                pixelSize: Appearance.font.pixelSize.smallest
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    spacing: 6

                                    StyledText {
                                        visible: repoRow.modelData.dirty > 0
                                        text: `${repoRow.modelData.dirty} modified`
                                        color: Appearance.colors.colPrimary
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Appearance.font.pixelSize.smallest
                                            weight: Font.Medium
                                        }
                                    }

                                    StyledText {
                                        visible: repoRow.modelData.ahead > 0
                                        text: `↑${repoRow.modelData.ahead} unpushed`
                                        color: Appearance.m3colors.m3tertiary
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Appearance.font.pixelSize.smallest
                                            weight: Font.Medium
                                        }
                                    }

                                    StyledText {
                                        visible: repoRow.modelData.behind > 0
                                        text: `↓${repoRow.modelData.behind}`
                                        color: Appearance.colors.colError
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Appearance.font.pixelSize.smallest
                                        }
                                    }

                                    StyledText {
                                        visible: !repoRow.hasChanges
                                        text: "clean"
                                        color: Appearance.m3colors.m3success
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Appearance.font.pixelSize.smallest
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 22
                            }
                        }

                        // Click row -> open Lazygit in repo
                        MouseArea {
                            id: openRowMouse
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                right: termBtn.left
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openLazygit(repoRow.modelData.path)
                        }

                        // Open Kitty shell in repo
                        Rectangle {
                            id: termBtn
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 6
                            }
                            width: 22
                            height: 22
                            radius: Appearance.rounding.full
                            color: termBtnMouse.containsMouse
                                ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)
                                : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: 14
                                text: "terminal"
                                color: termBtnMouse.containsMouse
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: termBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openTerminal(repoRow.modelData.path)
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: root.hiddenCount > 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: `+ ${root.hiddenCount} more repos (click Lazygit / Super+Shift+G)`
                color: moreMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest

                MouseArea {
                    id: moreMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/git_ui.sh"])
                }
            }
        }
    }

    component IconPillButton: Rectangle {
        id: btn
        required property string iconName
        property bool active: false
        signal clicked()

        width: 24
        height: 24
        radius: Appearance.rounding.full
        color: btnMouse.containsMouse
            ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.1)
            : (active ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.25) : "transparent")

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 15
            text: btn.iconName
            color: (btn.active || btnMouse.containsMouse)
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
