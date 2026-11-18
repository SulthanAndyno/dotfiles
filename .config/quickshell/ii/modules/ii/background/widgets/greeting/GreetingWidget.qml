pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "greeting"
    needsColText: false
    visibleWhenLocked: false

    implicitWidth: Math.max(260, cardContent.implicitWidth + 32)
    implicitHeight: cardContent.implicitHeight + 24

    readonly property int currentHour: DateTime.clock.date.getHours()
    readonly property string displayName: Config.options.background.widgets.greeting.userName || SystemInfo.username
    readonly property string greetingPrefix: {
        if (currentHour >= 5 && currentHour < 12) return "Good morning";
        if (currentHour >= 12 && currentHour < 17) return "Good afternoon";
        if (currentHour >= 17 && currentHour < 21) return "Good evening";
        return "Good night";
    }
    readonly property string greetingIcon: {
        if (currentHour >= 5 && currentHour < 12) return "wb_twilight";
        if (currentHour >= 12 && currentHour < 17) return "wb_sunny";
        if (currentHour >= 17 && currentHour < 21) return "nights_stay";
        return "bedtime";
    }
    readonly property string powerProfileLabel: {
        switch (PowerProfiles.profile) {
            case PowerProfile.Performance: return "Perf";
            case PowerProfile.PowerSaver: return "Saver";
            default: return "Balanced";
        }
    }
    readonly property string powerProfileIcon: {
        switch (PowerProfiles.profile) {
            case PowerProfile.Performance: return "local_fire_department";
            case PowerProfile.PowerSaver: return "energy_savings_leaf";
            default: return "airwave";
        }
    }
    readonly property int monitorRefreshHz: {
        if (HyprlandData.monitors && HyprlandData.monitors.length > 0) {
            return Math.round(HyprlandData.monitors[0].refreshRate ?? 0);
        }
        return 0;
    }

    // Re-sync monitor refresh rate right after power profile transitions without polling
    Timer {
        id: monitorSyncTimer
        interval: 450
        repeat: false
        onTriggered: HyprlandData.updateMonitors()
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            monitorSyncTimer.restart();
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
            id: cardContent
            anchors.centerIn: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Time-of-day badge
                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.65)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 20
                        text: root.greetingIcon
                        color: Appearance.colors.colPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: `${root.greetingPrefix}, ${root.displayName}`
                        color: Appearance.colors.colOnLayer0
                        font {
                            family: Appearance.font.family.expressive
                            pixelSize: Appearance.font.pixelSize.larger
                            weight: Font.DemiBold
                        }
                    }

                    RowLayout {
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: PowerProfiles.profile === PowerProfile.Performance
                                ? Appearance.colors.colPrimary
                                : Appearance.m3colors.m3success
                        }

                        StyledText {
                            readonly property string customSub: Config.options.background.widgets.greeting.subtitle
                            text: (customSub && customSub.length > 0)
                                ? `${customSub} · ${SystemInfo.distroName}`
                                : SystemInfo.distroName
                            color: Appearance.colors.colSubtext
                            font {
                                family: Appearance.font.family.monospace
                                pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                    }
                }
            }

            // Lightweight reactive telemetry pills
            RowLayout {
                visible: Config.options.background.widgets.greeting.showStatusChips
                Layout.fillWidth: true
                spacing: 6

                StatusChip {
                    iconName: "schedule"
                    labelText: `up ${DateTime.uptime}`
                }

                StatusChip {
                    iconName: root.powerProfileIcon
                    labelText: root.powerProfileLabel
                    highlighted: PowerProfiles.profile === PowerProfile.Performance
                }

                StatusChip {
                    visible: root.monitorRefreshHz > 0
                    iconName: "monitor"
                    labelText: `${root.monitorRefreshHz}Hz`
                }

                StatusChip {
                    visible: Battery.available
                    iconName: Battery.isPluggedIn ? "bolt" : "battery_std"
                    labelText: `${Math.round(Battery.percentage * 100)}%`
                }
            }
        }
    }

    component StatusChip: Rectangle {
        id: chip
        required property string iconName
        required property string labelText
        property bool highlighted: false

        implicitHeight: 24
        implicitWidth: chipRow.implicitWidth + 14
        radius: Appearance.rounding.full
        color: highlighted
            ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.25)
            : ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.35)
        border.width: 1
        border.color: highlighted
            ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.55)
            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.6)

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                iconSize: 13
                text: chip.iconName
                color: chip.highlighted ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            }

            StyledText {
                text: chip.labelText
                color: chip.highlighted ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                font {
                    family: Appearance.font.family.monospace
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Medium
                }
            }
        }
    }
}
