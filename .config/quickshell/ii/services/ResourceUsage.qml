pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Polled resource usage service with RAM, Swap, CPU, and Dual Hybrid GPU (AMD iGPU + NVIDIA RTX 3050).
 * Keeps sleeping NVIDIA dGPU in D3cold when suspended while exposing live metrics for both GPUs.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

    // Per-GPU metrics
    property bool amdAvailable: false
    property real amdUsage: 0
    property real amdMemoryUsedMB: 0
    property real amdMemoryTotalMB: 512
    property real amdTemp: 0

    property bool nvAvailable: false
    property bool nvSleeping: false
    property bool nvWorking: false
    property real nvUsage: 0
    property real nvMemoryUsedMB: 0
    property real nvMemoryTotalMB: 4096
    property real nvTemp: 0

    // Combined summary properties (used by bar gauge & any single-GPU callers)
    property bool gpuAvailable: amdAvailable || nvAvailable
    property string gpuLabel: nvWorking ? "RTX 3050" : (amdAvailable ? "iGPU (AMD)" : "RTX 3050")
    property real gpuUsage: Math.max(amdAvailable ? amdUsage : 0, (nvAvailable && !nvSleeping) ? nvUsage : 0)
    property real gpuUsagePercentage: gpuUsage / 100.0
    property real gpuMemoryUsedMB: nvWorking ? nvMemoryUsedMB : (amdAvailable ? amdMemoryUsedMB : nvMemoryUsedMB)
    property real gpuMemoryTotalMB: nvWorking ? nvMemoryTotalMB : (amdAvailable ? amdMemoryTotalMB : nvMemoryTotalMB)
    property real gpuTemp: nvWorking ? nvTemp : (amdAvailable ? amdTemp : nvTemp)

    // Discovery & polling control
    property bool gpuDetected: false
    property bool popupOpen: false
    property string amdCardPath: ""
    property string amdTempPath: ""
    property string nvRuntimePath: ""
    property int nvCooldownTicks: 0

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"
    property string maxAvailableGpuString: gpuMemoryTotalMB >= 1024
        ? (gpuMemoryTotalMB / 1024).toFixed(0) + " GB"
        : Math.round(gpuMemoryTotalMB) + " MB"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []
    property list<real> gpuUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function applyAmdStats() {
        if (root.amdCardPath === "") return;
        const busyText = fileAmdBusy.text().trim();
        const usedText = fileAmdVramUsed.text().trim();
        const totalText = fileAmdVramTotal.text().trim();
        if (busyText === "" && usedText === "" && totalText === "") return;

        root.amdUsage = parseFloat(busyText) || 0;
        root.amdMemoryUsedMB = (parseFloat(usedText) || 0) / (1024 * 1024);
        root.amdMemoryTotalMB = (parseFloat(totalText) || (512 * 1024 * 1024)) / (1024 * 1024);
        if (root.amdTempPath !== "") {
            const tempMilli = parseFloat(fileAmdTemp.text().trim());
            if (!isNaN(tempMilli)) root.amdTemp = tempMilli / 1000.0;
        }
        root.amdAvailable = true;
    }

    function reloadAmdFiles() {
        if (root.amdCardPath === "") return;
        fileAmdBusy.reload();
        fileAmdVramUsed.reload();
        fileAmdVramTotal.reload();
        if (root.amdTempPath !== "") fileAmdTemp.reload();
    }

    function refreshNvNow() {
        if (!root.gpuDetected || root.nvRuntimePath === "") return;
        fileNvRuntime.reload();
        const nvStatus = fileNvRuntime.text().trim();
        if (nvStatus === "active") {
            root.nvSleeping = false;
            if (!gpuProc.running) gpuProc.running = true;
        } else {
            root.nvSleeping = true;
            root.nvWorking = false;
            root.nvUsage = 0;
            root.nvMemoryUsedMB = 0;
        }
    }

    function refreshGpuStats() {
        if (!root.gpuDetected) return;

        root.reloadAmdFiles();

        if (root.nvRuntimePath !== "") {
            fileNvRuntime.reload();
            const nvStatus = fileNvRuntime.text().trim();

            if (nvStatus !== "active") {
                // dGPU is sleeping (D3cold): keep sleeping without waking it via nvidia-smi
                root.nvSleeping = true;
                root.nvWorking = false;
                root.nvUsage = 0;
                root.nvMemoryUsedMB = 0;
                root.nvCooldownTicks = 0;
                return;
            }

            root.nvSleeping = false;
            fileAcOnline.reload();
            const onAc = fileAcOnline.text().trim() === "1";

            // Poll nvidia-smi live when working, popup is open, on AC charger, or cooldown elapsed
            if (root.nvWorking || root.popupOpen || onAc || root.nvCooldownTicks <= 0) {
                root.nvCooldownTicks = 0;
                if (!gpuProc.running) {
                    gpuProc.running = true;
                }
            } else {
                root.nvCooldownTicks -= 1;
            }
            return;
        }

        if (!root.amdAvailable && !gpuProc.running) {
            gpuProc.running = true;
        }
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateGpuUsageHistory() {
        gpuUsageHistory = [...gpuUsageHistory, gpuUsagePercentage]
        if (gpuUsageHistory.length > historyLength) {
            gpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
        updateGpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            root.refreshGpuStats()

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileAcOnline; path: "/sys/class/power_supply/ACAD/online" }

    FileView {
        id: fileAmdBusy
        path: root.amdCardPath ? `${root.amdCardPath}/gpu_busy_percent` : ""
        onLoaded: root.applyAmdStats()
    }
    FileView {
        id: fileAmdVramUsed
        path: root.amdCardPath ? `${root.amdCardPath}/mem_info_vram_used` : ""
        onLoaded: root.applyAmdStats()
    }
    FileView {
        id: fileAmdVramTotal
        path: root.amdCardPath ? `${root.amdCardPath}/mem_info_vram_total` : ""
        onLoaded: root.applyAmdStats()
    }
    FileView {
        id: fileAmdTemp
        path: root.amdTempPath ? root.amdTempPath : ""
        onLoaded: root.applyAmdStats()
    }
    FileView {
        id: fileNvRuntime
        path: root.nvRuntimePath ? root.nvRuntimePath : ""
    }

    Process {
        id: detectGpuProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "for c in /sys/class/drm/card[0-9]; do [ -f \"$c/device/vendor\" ] || continue; v=$(cat \"$c/device/vendor\" 2>/dev/null); if [ \"$v\" = \"0x1002\" ]; then echo \"AMD_CARD=$c/device\"; for h in \"$c/device/hwmon\"/hwmon*; do [ -f \"$h/temp1_input\" ] && echo \"AMD_TEMP=$h/temp1_input\" && break; done; elif [ \"$v\" = \"0x10de\" ]; then echo \"NV_RUNTIME=$c/device/power/runtime_status\"; fi; done"]
        running: true
        stdout: StdioCollector {
            id: detectGpuCollector
            onStreamFinished: {
                const lines = detectGpuCollector.text.trim().split("\n");
                for (const line of lines) {
                    if (line.startsWith("AMD_CARD=")) {
                        root.amdCardPath = line.slice(9).trim();
                        root.amdAvailable = true;
                    } else if (line.startsWith("AMD_TEMP=")) {
                        root.amdTempPath = line.slice(9).trim();
                    } else if (line.startsWith("NV_RUNTIME=")) {
                        root.nvRuntimePath = line.slice(11).trim();
                        root.nvAvailable = true;
                    }
                }
                root.gpuDetected = true;
                root.refreshGpuStats();
            }
        }
    }

    Process {
        id: gpuProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu", "--format=csv,noheader,nounits"]
        running: false
        stdout: StdioCollector {
            id: gpuOutputCollector
            onStreamFinished: {
                const out = gpuOutputCollector.text.trim();
                if (out.length > 0) {
                    const parts = out.split(",").map(p => p.trim());
                    if (parts.length >= 4) {
                        root.nvUsage = parseFloat(parts[0]) || 0;
                        root.nvMemoryUsedMB = parseFloat(parts[1]) || 0;
                        root.nvMemoryTotalMB = parseFloat(parts[2]) || 4096;
                        root.nvTemp = parseFloat(parts[3]) || 0;
                        root.nvAvailable = true;
                        root.nvSleeping = false;
                        root.nvWorking = (root.nvUsage > 0) || (root.nvMemoryUsedMB >= 80);
                        if (!root.nvWorking) {
                            root.nvCooldownTicks = 10;
                        } else {
                            root.nvCooldownTicks = 0;
                        }
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.nvWorking = false;
                root.nvCooldownTicks = 10;
            }
        }
    }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
