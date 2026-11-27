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

    configEntryName: "docker"
    needsColText: false
    visibleWhenLocked: false

    property bool daemonActive: false
    property var containers: []
    readonly property int maxVisible: Math.max(1, Config.options.background.widgets.docker.maxItems ?? 5)
    readonly property int runningCount: containers.filter(c => c.state === "running").length
    readonly property var visibleContainers: containers.slice(0, maxVisible)
    readonly property int hiddenCount: Math.max(0, containers.length - visibleContainers.length)

    readonly property bool hiddenByOff: (Config.options.background.widgets.docker.hideWhenOff ?? false) && !daemonActive
    opacity: ((GlobalStates.screenLocked && !visibleWhenLocked) || hiddenByOff) ? 0 : 1

    implicitWidth: 310
    implicitHeight: cardColumn.implicitHeight + 24

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    function refreshDocker() {
        if (scanDockerProc.running) return;
        const scriptPath = FileUtils.trimFileProtocol(`${Directories.scriptPath}/coding/docker-pulse.sh`);
        scanDockerProc.command = ["bash", scriptPath];
        scanDockerProc.running = true;
    }

    function toggleContainer(id, currentlyRunning) {
        const action = currentlyRunning ? "stop" : "start";
        Quickshell.execDetached(["docker", action, id]);
        delayedRefreshTimer.restart();
    }

    function startDaemon() {
        Quickshell.execDetached(["bash", "-c", "pkexec systemctl start docker && notify-send -u low -i docker -a 'Docker' 'Docker Started' 'Daemon is now active.'"]);
        daemonStartRefreshTimer.restart();
    }

    function openLazydocker() {
        Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/docker_ui.sh"]);
    }

    Timer {
        id: pollTimer
        interval: 30000
        running: Config.options.background.widgets.docker.enable && root.pollingActive
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshDocker()
    }

    Timer {
        id: delayedRefreshTimer
        interval: 750
        repeat: false
        onTriggered: root.refreshDocker()
    }

    Timer {
        id: daemonStartRefreshTimer
        interval: 2200
        repeat: false
        onTriggered: root.refreshDocker()
    }

    Process {
        id: scanDockerProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            id: dockerCollector
            onStreamFinished: {
                const lines = dockerCollector.text.trim().split("\n");
                if (lines.length === 0 || lines[0].trim() !== "DOCKER_ON") {
                    root.daemonActive = false;
                    root.containers = [];
                    return;
                }
                root.daemonActive = true;
                const parsed = [];
                for (let i = 1; i < lines.length; i++) {
                    const parts = lines[i].split("|");
                    if (parts.length >= 5) {
                        parsed.push({
                            id: parts[0].trim(),
                            name: parts[1].trim(),
                            image: parts[2].trim(),
                            state: parts[3].trim().toLowerCase(),
                            status: parts[4].trim()
                        });
                    }
                }
                // Sort running containers first
                parsed.sort((a, b) => Number(b.state === "running") - Number(a.state === "running"));
                root.containers = parsed;
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
                    text: "deployed_code"
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Docker")
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.normal
                        weight: Font.DemiBold
                    }
                }

                Rectangle {
                    implicitWidth: badgeText.implicitWidth + 12
                    implicitHeight: 20
                    radius: Appearance.rounding.full
                    color: !root.daemonActive
                        ? ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.3)
                        : (root.runningCount > 0
                            ? ColorUtils.transparentize(Appearance.m3colors.m3successContainer, 0.15)
                            : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.2))

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: !root.daemonActive
                            ? "Off"
                            : (root.runningCount > 0 ? `${root.runningCount} running` : "0 running")
                        color: !root.daemonActive
                            ? Appearance.colors.colSubtext
                            : (root.runningCount > 0
                                ? Appearance.m3colors.m3onSuccessContainer
                                : Appearance.colors.colOnPrimaryContainer)
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.DemiBold
                        }
                    }
                }

                IconPillButton {
                    iconName: "refresh"
                    onClicked: root.refreshDocker()
                }

                IconPillButton {
                    iconName: "open_in_new"
                    onClicked: root.openLazydocker()
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
            }

            // Daemon Off state
            Rectangle {
                visible: !root.daemonActive
                Layout.fillWidth: true
                implicitHeight: offRow.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.45)

                RowLayout {
                    id: offRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                        rightMargin: 8
                    }
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Daemon sleeping (RAM saved)")
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.font.pixelSize.smallie
                    }

                    Rectangle {
                        implicitWidth: startBtnRow.implicitWidth + 14
                        implicitHeight: 24
                        radius: Appearance.rounding.full
                        color: startDaemonMouse.containsMouse
                            ? Appearance.colors.colPrimaryContainerHover
                            : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)

                        RowLayout {
                            id: startBtnRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                iconSize: 14
                                text: "power_settings_new"
                                color: Appearance.colors.colOnPrimaryContainer
                            }

                            StyledText {
                                text: Translation.tr("Start")
                                color: Appearance.colors.colOnPrimaryContainer
                                font {
                                    pixelSize: Appearance.font.pixelSize.smaller
                                    weight: Font.DemiBold
                                }
                            }
                        }

                        MouseArea {
                            id: startDaemonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startDaemon()
                        }
                    }
                }
            }

            // Daemon ON but no containers
            Rectangle {
                visible: root.daemonActive && root.visibleContainers.length === 0
                Layout.fillWidth: true
                implicitHeight: emptyContainersText.implicitHeight + 16
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.45)

                StyledText {
                    id: emptyContainersText
                    anchors.centerIn: parent
                    text: Translation.tr("Daemon active · No containers created")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                }
            }

            // Container list
            ColumnLayout {
                visible: root.daemonActive && root.visibleContainers.length > 0
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.visibleContainers
                    delegate: Rectangle {
                        id: cRow
                        required property var modelData
                        readonly property bool isRunning: modelData.state === "running"
                        readonly property bool isHovered: rowClickMouse.containsMouse || actionBtnMouse.containsMouse

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
                                color: cRow.isRunning
                                    ? Appearance.m3colors.m3success
                                    : Appearance.colors.colOutline
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: cRow.modelData.name
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colOnLayer0
                                    font {
                                        family: Appearance.font.family.main
                                        pixelSize: Appearance.font.pixelSize.smallie
                                        weight: Font.Medium
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: `${cRow.modelData.status} · ${cRow.modelData.image}`
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colSubtext
                                    font {
                                        family: Appearance.font.family.monospace
                                        pixelSize: Appearance.font.pixelSize.smallest
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 22
                            }
                        }

                        MouseArea {
                            id: rowClickMouse
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                right: actionBtn.left
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openLazydocker()
                        }

                        // Start / Stop button
                        Rectangle {
                            id: actionBtn
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 6
                            }
                            width: 22
                            height: 22
                            radius: Appearance.rounding.full
                            color: actionBtnMouse.containsMouse
                                ? (cRow.isRunning
                                    ? ColorUtils.transparentize(Appearance.colors.colErrorContainer, 0.15)
                                    : ColorUtils.transparentize(Appearance.m3colors.m3successContainer, 0.15))
                                : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: 15
                                text: cRow.isRunning ? "stop" : "play_arrow"
                                color: actionBtnMouse.containsMouse
                                    ? (cRow.isRunning ? Appearance.colors.colError : Appearance.m3colors.m3success)
                                    : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: actionBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleContainer(cRow.modelData.id, cRow.isRunning)
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: root.daemonActive && root.hiddenCount > 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: `+ ${root.hiddenCount} more (click open / Super+Shift+D)`
                color: moreDockerMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest

                MouseArea {
                    id: moreDockerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openLazydocker()
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
