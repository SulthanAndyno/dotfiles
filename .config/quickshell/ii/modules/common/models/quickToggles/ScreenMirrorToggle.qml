import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common

QuickToggleModel {
    readonly property var extMonitors: (HyprlandData.monitors ?? []).filter(m => m.name !== "eDP-1")
    readonly property bool isMirrored: extMonitors.some(m => m.mirrorOf && m.mirrorOf !== "none")
    readonly property bool hasExternal: extMonitors.length > 0

    name: Translation.tr("Display")
    toggled: isMirrored
    icon: isMirrored ? "cast_connected" : (hasExternal ? "connected_tv" : "cast")
    statusText: isMirrored ? "Duplicate" : (hasExternal ? "Extend" : "Single")

    mainAction: () => {
        Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/display_mode.sh", "--toggle"]);
    }
    altAction: () => {
        GlobalStates.sidebarRightOpen = false;
        Quickshell.execDetached(["bash", "/home/Shuu/.config/hypr/scripts/display_mode.sh"]);
    }
    tooltipText: Translation.tr("Left-click: Toggle Duplicate/Extend • Right-click: Display menu (Super+P)")
}
