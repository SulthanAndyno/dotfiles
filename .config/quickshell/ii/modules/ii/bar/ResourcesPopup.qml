import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    onActiveChanged: {
        ResourceUsage.popupOpen = active;
        if (active) ResourceUsage.refreshNvNow();
    }

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    // Helper function to format VRAM cleanly in MB or GB
    function formatVRAM(usedMB, totalMB) {
        return totalMB >= 1024
            ? `${(usedMB / 1024).toFixed(1)} / ${(totalMB / 1024).toFixed(1)} GB`
            : `${Math.round(usedMB)} / ${Math.round(totalMB)} MB`;
    }

    component SectionDivider: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Appearance.colors.colOutlineVariant
        opacity: 0.45
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 185
            spacing: 4

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "clock_loader_60"
                label: Translation.tr("Used:")
                value: root.formatKB(ResourceUsage.memoryUsed)
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "check_circle"
                label: Translation.tr("Free:")
                value: root.formatKB(ResourceUsage.memoryFree)
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "empty_dashboard"
                label: Translation.tr("Total:")
                value: root.formatKB(ResourceUsage.memoryTotal)
            }
        }

        SectionDivider {
            visible: ResourceUsage.swapTotal > 0
        }

        ColumnLayout {
            visible: ResourceUsage.swapTotal > 0
            Layout.fillWidth: true
            spacing: 4

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "clock_loader_60"
                label: Translation.tr("Used:")
                value: root.formatKB(ResourceUsage.swapUsed)
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "check_circle"
                label: Translation.tr("Free:")
                value: root.formatKB(ResourceUsage.swapFree)
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "empty_dashboard"
                label: Translation.tr("Total:")
                value: root.formatKB(ResourceUsage.swapTotal)
            }
        }

        SectionDivider {}

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "bolt"
                label: Translation.tr("Load:")
                value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
            }
        }

        SectionDivider {
            visible: ResourceUsage.amdAvailable
        }

        ColumnLayout {
            visible: ResourceUsage.amdAvailable
            Layout.fillWidth: true
            spacing: 4

            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "iGPU (AMD)"
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "bolt"
                label: Translation.tr("Load:")
                value: `${Math.round(ResourceUsage.amdUsage)}%`
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "clock_loader_60"
                label: Translation.tr("VRAM:")
                value: root.formatVRAM(ResourceUsage.amdMemoryUsedMB, ResourceUsage.amdMemoryTotalMB)
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: Translation.tr("Temp:")
                value: `${Math.round(ResourceUsage.amdTemp)}°C`
            }
        }

        SectionDivider {
            visible: ResourceUsage.nvAvailable
        }

        ColumnLayout {
            visible: ResourceUsage.nvAvailable
            Layout.fillWidth: true
            spacing: 4

            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "RTX 3050"
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "bolt"
                label: Translation.tr("Load:")
                value: `${Math.round(ResourceUsage.nvUsage)}%`
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "clock_loader_60"
                label: Translation.tr("VRAM:")
                value: root.formatVRAM(ResourceUsage.nvMemoryUsedMB, ResourceUsage.nvMemoryTotalMB)
            }
            StyledPopupValueRow {
                Layout.fillWidth: true
                icon: "device_thermostat"
                label: Translation.tr("Temp:")
                value: ResourceUsage.nvSleeping ? Translation.tr("Sleep") : `${Math.round(ResourceUsage.nvTemp)}°C`
            }
        }
    }
}
