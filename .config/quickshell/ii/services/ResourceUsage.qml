pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Polled resource usage service with RAM, Swap, CPU, and Smart Hybrid GPU usage.
 * Prefers AMD iGPU via sysfs when NVIDIA dGPU is suspended/idle so dGPU can enter D3cold.
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

    property bool gpuAvailable: false
    property string gpuLabel: "GPU"
    property real gpuUsage: 0
    property real gpuUsagePercentage: gpuUsage / 100.0
    property real gpuMemoryUsedMB: 0
    property real gpuMemoryTotalMB: 512
    property real gpuTemp: 0

    // Smart hybrid GPU discovery & power-aware polling state
    property bool gpuDetected: false
    property string amdCardPath: ""
    property string amdTempPath: ""
    property string nvRuntimePath: ""
    property bool nvWorking: false
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

        root.gpuLabel = "GPU (AMD)";
        root.gpuUsage = parseFloat(busyText) || 0;
        root.gpuMemoryUsedMB = (parseFloat(usedText) || 0) / (1024 * 1024);
        root.gpuMemoryTotalMB = (parseFloat(totalText) || (512 * 1024 * 1024)) / (1024 * 1024);
        if (root.amdTempPath !== "") {
            const tempMilli = parseFloat(fileAmdTemp.text().trim());
            if (!isNaN(tempMilli)) root.gpuTemp = tempMilli / 1000.0;
        }
        root.gpuAvailable = true;
    }

    function reloadAmdFiles() {
        if (root.amdCardPath === "") return;
        fileAmdBusy.reload();
        fileAmdVramUsed.reload();
        fileAmdVramTotal.reload();
        if (root.amdTempPath !== "") fileAmdTemp.reload();
    }

    function refreshGpuStats() {
        if (!root.gpuDetected) return;

        root.reloadAmdFiles();

        if (root.nvRuntimePath !== "") {
            fileNvRuntime.reload();
            const nvStatus = fileNvRuntime.text().trim();

            if (nvStatus !== "active") {
                // dGPU is sleeping (D3cold): stay off nvidia-smi so it stays asleep
                root.nvWorking = false;
                root.nvCooldownTicks = 0;
                root.applyAmdStats();
                return;
            }

            if (!root.nvWorking && root.nvCooldownTicks > 0) {
                root.nvCooldownTicks -= 1;
                root.applyAmdStats();
                return;
            }

            if (!gpuProc.running) {
                gpuProc.running = true;
            }
            if (!root.nvWorking) {
                root.applyAmdStats();
            }
            return;
        }

        if (root.amdCardPath !== "") {
            root.applyAmdStats();
        } else if (!gpuProc.running) {
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

    FileView {
        id: fileAmdBusy
        path: root.amdCardPath ? `${root.amdCardPath}/gpu_busy_percent` : ""
        onLoaded: if (!root.nvWorking) root.applyAmdStats()
    }
    FileView {
        id: fileAmdVramUsed
        path: root.amdCardPath ? `${root.amdCardPath}/mem_info_vram_used` : ""
        onLoaded: if (!root.nvWorking) root.applyAmdStats()
    }
    FileView {
        id: fileAmdVramTotal
        path: root.amdCardPath ? `${root.amdCardPath}/mem_info_vram_total` : ""
        onLoaded: if (!root.nvWorking) root.applyAmdStats()
    }
    FileView {
        id: fileAmdTemp
        path: root.amdTempPath ? root.amdTempPath : ""
        onLoaded: if (!root.nvWorking) root.applyAmdStats()
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
                    if (line.startsWith("AMD_CARD=")) root.amdCardPath = line.slice(9).trim();
                    else if (line.startsWith("AMD_TEMP=")) root.amdTempPath = line.slice(9).trim();
                    else if (line.startsWith("NV_RUNTIME=")) root.nvRuntimePath = line.slice(11).trim();
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
                        const nvUsage = parseFloat(parts[0]) || 0;
                        const nvUsedMB = parseFloat(parts[1]) || 0;
                        const nvTotalMB = parseFloat(parts[2]) || 4096;
                        const nvTempVal = parseFloat(parts[3]) || 0;

                        // Only switch telemetry to RTX if dGPU is actively doing work
                        const isWorking = (nvUsage > 0) || (nvUsedMB >= 80);
                        if (isWorking || root.amdCardPath === "") {
                            root.nvWorking = true;
                            root.nvCooldownTicks = 0;
                            root.gpuLabel = "GPU (RTX)";
                            root.gpuUsage = nvUsage;
                            root.gpuMemoryUsedMB = nvUsedMB;
                            root.gpuMemoryTotalMB = nvTotalMB;
                            root.gpuTemp = nvTempVal;
                            root.gpuAvailable = true;
                        } else {
                            // Back off nvidia-smi for ~30s so RTD3 autosuspend can put RTX to sleep
                            root.nvWorking = false;
                            root.nvCooldownTicks = 10;
                            root.applyAmdStats();
                        }
                    }
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.amdCardPath !== "") {
                root.nvWorking = false;
                root.nvCooldownTicks = 10;
                root.applyAmdStats();
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
