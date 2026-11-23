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

    configEntryName: "devServer"
    needsColText: false
    visibleWhenLocked: false

    readonly property bool hiddenByIdle: (Config.options.background.widgets.devServer.hideWhenIdle ?? false) && filteredPorts.length === 0
    opacity: ((GlobalStates.screenLocked && !visibleWhenLocked) || hiddenByIdle) ? 0 : 1

    implicitWidth: 310
    implicitHeight: cardColumn.implicitHeight + 24

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    property var allPorts: []
    readonly property bool showSystemPorts: Config.options.background.widgets.devServer.showSystemPorts ?? false
    readonly property int maxVisible: Math.max(1, Config.options.background.widgets.devServer.maxItems ?? 5)
    readonly property var filteredPorts: showSystemPorts
        ? allPorts
        : allPorts.filter(p => p.pid !== "-")
    readonly property var visiblePorts: filteredPorts.slice(0, maxVisible)
    readonly property int hiddenCount: Math.max(0, filteredPorts.length - visiblePorts.length)

    function refreshPorts() {
        if (!scanPortsProc.running) {
            scanPortsProc.running = true;
        }
    }

    function openPortInBrowser(port) {
        Quickshell.execDetached(["xdg-open", `http://localhost:${port}`]);
    }

    function copyPortUrl(port) {
        Quickshell.execDetached(["bash", "-c", `printf 'http://localhost:%s' "${port}" | wl-copy && notify-send -u low -i edit-copy -a "Dev Servers" "Copied URL" "http://localhost:${port} copied to clipboard."`]);
    }

    function killPort(port) {
        Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/port_manager.sh", "--kill", String(port)]);
        delayedRefreshTimer.restart();
    }

    Timer {
        id: pollTimer
        interval: 4000
        running: Config.options.background.widgets.devServer.enable && !GlobalStates.screenLocked
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshPorts()
    }

    Timer {
        id: delayedRefreshTimer
        interval: 450
        repeat: false
        onTriggered: root.refreshPorts()
    }

    Process {
        id: scanPortsProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: [
            "bash", "-c",
            "ss -tlnp 2>/dev/null | awk 'NR > 1 { local_addr = $4; port = local_addr; sub(/^.*:/, \"\", port); proc = \"system\"; pid = \"-\"; if (match($0, /users:\\(\\(\"[^\"]+\",pid=[0-9]+/)) { s = substr($0, RSTART, RLENGTH); proc = s; sub(/^users:\\(\\(\"*/, \"\", proc); sub(/\",pid=.*$/, \"\", proc); pid = s; sub(/^.*pid=/, \"\", pid); } if (port ~ /^[0-9]+$/) { pnum = port + 0; if (pnum >= 32768 && proc == \"agy\") next; key = port \":\" pid; if (!seen[key]++) { printf \"%s|%s|%s|%s\\n\", port, proc, pid, local_addr; } } }' | sort -t'|' -k1,1n"
        ]
        stdout: StdioCollector {
            id: portsCollector
            onStreamFinished: {
                const raw = portsCollector.text.trim();
                if (raw.length === 0) {
                    root.allPorts = [];
                    return;
                }
                const parsed = [];
                for (const line of raw.split("\n")) {
                    const parts = line.split("|");
                    if (parts.length >= 4) {
                        parsed.push({
                            port: parts[0].trim(),
                            proc: parts[1].trim(),
                            pid: parts[2].trim(),
                            addr: parts[3].trim()
                        });
                    }
                }
                root.allPorts = parsed;
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
                    text: "lan"
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Dev Servers")
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.normal
                        weight: Font.DemiBold
                    }
                }

                // Active ports count badge
                Rectangle {
                    implicitWidth: countText.implicitWidth + 12
                    implicitHeight: 20
                    radius: Appearance.rounding.full
                    color: root.filteredPorts.length > 0
                        ? ColorUtils.transparentize(Appearance.m3colors.m3successContainer, 0.15)
                        : ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.3)

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: root.filteredPorts.length > 0 ? `${root.filteredPorts.length} live` : "Idle"
                        color: root.filteredPorts.length > 0
                            ? Appearance.m3colors.m3onSuccessContainer
                            : Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.DemiBold
                        }
                    }
                }

                // Toggle system/hidden-PID ports
                IconPillButton {
                    iconName: "filter_list"
                    active: root.showSystemPorts
                    onClicked: {
                        Config.options.background.widgets.devServer.showSystemPorts = !root.showSystemPorts;
                    }
                }

                // Manual refresh
                IconPillButton {
                    iconName: "refresh"
                    onClicked: root.refreshPorts()
                }

                // Open Fuzzel Port Manager (Super+Shift+K)
                IconPillButton {
                    iconName: "tune"
                    onClicked: Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/port_manager.sh"])
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
            }

            // Empty state
            Rectangle {
                visible: root.visiblePorts.length === 0
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
                            text: "cloud_off"
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: root.allPorts.length > 0 && !root.showSystemPorts
                                ? Translation.tr("No user dev servers listening")
                                : Translation.tr("No active localhost ports")
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smallie
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.allPorts.length > 0 && !root.showSystemPorts
                            ? Translation.tr("Click filter icon to view system ports")
                            : Translation.tr("Start Vite, Laravel, or Node to see it here")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }
            }

            // Port list
            ColumnLayout {
                visible: root.visiblePorts.length > 0
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.visiblePorts
                    delegate: Rectangle {
                        id: portRow
                        required property var modelData
                        readonly property bool killable: modelData.pid !== "-"
                        readonly property bool isHovered: openRowMouse.containsMouse || openBtnMouse.containsMouse || killBtnMouse.containsMouse

                        Layout.fillWidth: true
                        implicitHeight: rowContent.implicitHeight + 10
                        radius: Appearance.rounding.small
                        color: isHovered
                            ? ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.2)
                            : ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.55)

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

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

                            // Status dot
                            Rectangle {
                                Layout.preferredWidth: 7
                                Layout.preferredHeight: 7
                                radius: 4
                                color: portRow.killable
                                    ? Appearance.m3colors.m3success
                                    : Appearance.colors.colOutline
                            }

                            // :PORT badge
                            Rectangle {
                                implicitWidth: portBadgeText.implicitWidth + 10
                                implicitHeight: 20
                                radius: Appearance.rounding.small
                                color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.2)

                                StyledText {
                                    id: portBadgeText
                                    anchors.centerIn: parent
                                    text: `:${portRow.modelData.port}`
                                    color: Appearance.colors.colOnPrimaryContainer
                                    font {
                                        family: Appearance.font.family.monospace
                                        pixelSize: Appearance.font.pixelSize.smaller
                                        weight: Font.Bold
                                    }
                                }
                            }

                            // Process name & PID
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: portRow.modelData.proc
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
                                    text: portRow.killable
                                        ? `PID ${portRow.modelData.pid} · ${portRow.modelData.addr}`
                                        : `system · ${portRow.modelData.addr}`
                                    elide: Text.ElideRight
                                    color: Appearance.colors.colSubtext
                                    font {
                                        family: Appearance.font.family.monospace
                                        pixelSize: Appearance.font.pixelSize.smallest
                                    }
                                }
                            }

                            // Reserve space for action buttons
                            Item {
                                Layout.preferredWidth: portRow.killable ? 48 : 24
                                Layout.preferredHeight: 22
                            }
                        }

                        // Click main row to copy URL
                        MouseArea {
                            id: openRowMouse
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                right: actionButtons.left
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyPortUrl(portRow.modelData.port)
                        }

                        // Action buttons (Open in browser + Kill)
                        Row {
                            id: actionButtons
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 6
                            }
                            spacing: 2

                            Rectangle {
                                width: 22
                                height: 22
                                radius: Appearance.rounding.full
                                color: openBtnMouse.containsMouse
                                    ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)
                                    : "transparent"

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: 14
                                    text: "open_in_new"
                                    color: openBtnMouse.containsMouse
                                        ? Appearance.colors.colPrimary
                                        : Appearance.colors.colSubtext
                                }

                                MouseArea {
                                    id: openBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openPortInBrowser(portRow.modelData.port)
                                }
                            }

                            Rectangle {
                                visible: portRow.killable
                                width: 22
                                height: 22
                                radius: Appearance.rounding.full
                                color: killBtnMouse.containsMouse
                                    ? ColorUtils.transparentize(Appearance.colors.colErrorContainer, 0.15)
                                    : "transparent"

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: 14
                                    text: "close"
                                    color: killBtnMouse.containsMouse
                                        ? Appearance.colors.colError
                                        : Appearance.colors.colSubtext
                                }

                                MouseArea {
                                    id: killBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.killPort(portRow.modelData.port)
                                }
                            }
                        }
                    }
                }
            }

            // Overflow hint
            StyledText {
                visible: root.hiddenCount > 0
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: `+ ${root.hiddenCount} more (click tune / Super+Shift+K)`
                color: morePortsMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest

                MouseArea {
                    id: morePortsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/port_manager.sh"])
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
