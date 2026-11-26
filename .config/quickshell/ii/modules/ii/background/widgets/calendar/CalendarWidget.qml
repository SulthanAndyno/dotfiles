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

    configEntryName: "calendar"
    needsColText: false
    visibleWhenLocked: false

    implicitWidth: 300
    implicitHeight: cardColumn.implicitHeight + 24

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    readonly property date currentToday: DateTime.clock.date
    readonly property string todayIso: formatIsoDate(currentToday.getFullYear(), currentToday.getMonth(), currentToday.getDate())
    property int viewYear: currentToday.getFullYear()
    property int viewMonth: currentToday.getMonth() // 0..11

    readonly property bool startMonday: Config.options.background.widgets.calendar.startMonday ?? true
    readonly property bool showDeadlines: Config.options.background.widgets.calendar.showDeadlines ?? true
    readonly property int maxDeadlines: Math.max(1, Config.options.background.widgets.calendar.maxDeadlines ?? 4)
    readonly property bool isViewingCurrentMonth: viewYear === currentToday.getFullYear() && viewMonth === currentToday.getMonth()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var shortMonthNames: [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    readonly property var dayHeaders: startMonday
        ? ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        : ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    function pad2(n) {
        return n < 10 ? ("0" + n) : String(n);
    }

    function formatIsoDate(y, mZeroBased, d) {
        return `${y}-${pad2(mZeroBased + 1)}-${pad2(d)}`;
    }

    function parseIsoLocal(isoStr) {
        const parts = String(isoStr ?? "").split("-");
        if (parts.length !== 3) return null;
        const y = parseInt(parts[0], 10);
        const m = parseInt(parts[1], 10) - 1;
        const d = parseInt(parts[2], 10);
        if (isNaN(y) || isNaN(m) || isNaN(d)) return null;
        return new Date(y, m, d);
    }

    function formatShortDate(isoStr) {
        const dt = parseIsoLocal(isoStr);
        if (!dt) return isoStr;
        return `${shortMonthNames[dt.getMonth()]} ${dt.getDate()}`;
    }

    function daysUntil(isoStr) {
        const target = parseIsoLocal(isoStr);
        if (!target) return 9999;
        const todayMidnight = new Date(currentToday.getFullYear(), currentToday.getMonth(), currentToday.getDate());
        return Math.round((target.getTime() - todayMidnight.getTime()) / 86400000);
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear -= 1;
        } else {
            viewMonth -= 1;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear += 1;
        } else {
            viewMonth += 1;
        }
    }

    function jumpToToday() {
        viewYear = currentToday.getFullYear();
        viewMonth = currentToday.getMonth();
    }

    readonly property var rawDeadlines: Config.options.background.widgets.calendar.deadlines ?? []
    readonly property var deadlineDateMap: {
        const map = {};
        for (const item of rawDeadlines) {
            if (item && item.date) map[item.date] = true;
        }
        return map;
    }
    readonly property var sortedDeadlines: {
        const list = [];
        for (let i = 0; i < rawDeadlines.length; i++) {
            const item = rawDeadlines[i];
            if (!item || !item.title || !item.date) continue;
            const diff = daysUntil(item.date);
            list.push({
                title: item.title,
                date: item.date,
                shortDate: formatShortDate(item.date),
                diffDays: diff,
                originalIndex: i
            });
        }
        list.sort((a, b) => a.date.localeCompare(b.date));
        return list;
    }
    readonly property var visibleDeadlines: sortedDeadlines.slice(0, maxDeadlines)
    readonly property int hiddenDeadlinesCount: Math.max(0, sortedDeadlines.length - visibleDeadlines.length)

    readonly property var calendarCells: {
        const firstDay = new Date(viewYear, viewMonth, 1);
        const jsDow = firstDay.getDay(); // 0=Sun..6=Sat
        const leadingOffset = startMonday ? ((jsDow + 6) % 7) : jsDow;
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        const totalCells = (leadingOffset + daysInMonth) > 35 ? 42 : 35;

        const cells = [];
        for (let i = 0; i < totalCells; i++) {
            const dt = new Date(viewYear, viewMonth, 1 - leadingOffset + i);
            const iso = formatIsoDate(dt.getFullYear(), dt.getMonth(), dt.getDate());
            cells.push({
                day: dt.getDate(),
                iso: iso,
                inMonth: dt.getMonth() === viewMonth,
                isToday: iso === todayIso,
                hasDeadline: Boolean(deadlineDateMap[iso])
            });
        }
        return cells;
    }

    function openAddDeadlineDialog(initialIso) {
        if (addDeadlineProc.running) return;
        const scriptPath = FileUtils.trimFileProtocol(`${Directories.scriptPath}/calendar/add-deadline.py`);
        addDeadlineProc.command = ["python3", scriptPath, initialIso || todayIso];
        addDeadlineProc.running = true;
    }

    function removeDeadline(originalIdx) {
        const current = Config.options.background.widgets.calendar.deadlines ?? [];
        const nextList = [];
        for (let i = 0; i < current.length; i++) {
            if (i !== originalIdx) nextList.push(current[i]);
        }
        Config.options.background.widgets.calendar.deadlines = nextList;
    }

    Process {
        id: addDeadlineProc
        stdout: StdioCollector {
            id: addDeadlineCollector
            onStreamFinished: {
                const raw = addDeadlineCollector.text.trim();
                if (raw.length === 0) return;
                try {
                    const entry = JSON.parse(raw);
                    if (entry.title && entry.date) {
                        const current = Config.options.background.widgets.calendar.deadlines ?? [];
                        const nextList = [...current, { title: entry.title, date: entry.date }];
                        Config.options.background.widgets.calendar.deadlines = nextList;
                    }
                } catch (e) {
                    // Ignore malformed output
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

            // Header: Month Year + Navigation + Add Deadline
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                MaterialSymbol {
                    iconSize: 18
                    text: "calendar_month"
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: `${root.monthNames[root.viewMonth]} ${root.viewYear}`
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.normal
                        weight: Font.DemiBold
                    }
                }

                IconPillButton {
                    visible: !root.isViewingCurrentMonth
                    iconName: "today"
                    active: true
                    onClicked: root.jumpToToday()
                }

                IconPillButton {
                    iconName: "chevron_left"
                    onClicked: root.prevMonth()
                }

                IconPillButton {
                    iconName: "chevron_right"
                    onClicked: root.nextMonth()
                }

                IconPillButton {
                    visible: root.showDeadlines
                    iconName: "add"
                    onClicked: root.openAddDeadlineDialog(root.todayIso)
                }
            }

            // Weekday labels
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: root.dayHeaders
                    delegate: StyledText {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.Medium
                        }
                    }
                }
            }

            // Month day grid
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: root.calendarCells
                    delegate: Rectangle {
                        id: dayCell
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: Appearance.rounding.full
                        color: modelData.isToday
                            ? Appearance.colors.colPrimary
                            : (dayMouse.containsMouse
                                ? ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.25)
                                : "transparent")

                        StyledText {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: modelData.hasDeadline ? -2 : 0
                            text: String(dayCell.modelData.day)
                            opacity: dayCell.modelData.inMonth ? 1.0 : 0.35
                            color: dayCell.modelData.isToday
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colOnLayer0
                            font {
                                family: Appearance.font.family.numbers
                                pixelSize: Appearance.font.pixelSize.smaller
                                weight: dayCell.modelData.isToday ? Font.Bold : Font.Normal
                            }
                        }

                        // Deadline dot indicator
                        Rectangle {
                            visible: dayCell.modelData.hasDeadline
                            width: 4
                            height: 4
                            radius: 2
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                                bottomMargin: 3
                            }
                            color: dayCell.modelData.isToday
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colPrimary
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openAddDeadlineDialog(dayCell.modelData.iso)
                        }
                    }
                }
            }

            // Upcoming Deadlines / Countdown Section
            ColumnLayout {
                visible: root.showDeadlines
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Deadlines")
                        color: Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.smaller
                            weight: Font.DemiBold
                        }
                    }

                    StyledText {
                        text: root.sortedDeadlines.length > 0 ? `${root.sortedDeadlines.length} tracked` : "Empty"
                        color: Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                        }
                    }
                }

                // Empty deadline hint
                Rectangle {
                    visible: root.visibleDeadlines.length === 0
                    Layout.fillWidth: true
                    implicitHeight: emptyHint.implicitHeight + 12
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.45)

                    StyledText {
                        id: emptyHint
                        anchors.centerIn: parent
                        text: Translation.tr("Click any date or + to add deadline")
                        color: emptyHintMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }

                    MouseArea {
                        id: emptyHintMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openAddDeadlineDialog(root.todayIso)
                    }
                }

                // Deadline countdown rows
                ColumnLayout {
                    visible: root.visibleDeadlines.length > 0
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.visibleDeadlines
                        delegate: Rectangle {
                            id: dlRow
                            required property var modelData
                            readonly property bool isToday: modelData.diffDays === 0
                            readonly property bool isUrgent: modelData.diffDays > 0 && modelData.diffDays <= 3
                            readonly property bool isPast: modelData.diffDays < 0
                            readonly property bool isHovered: dlRowMouse.containsMouse || dlDeleteMouse.containsMouse

                            Layout.fillWidth: true
                            implicitHeight: dlRowContent.implicitHeight + 10
                            radius: Appearance.rounding.small
                            color: isHovered
                                ? ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.2)
                                : ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.55)

                            RowLayout {
                                id: dlRowContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 8
                                    rightMargin: 6
                                }
                                spacing: 6

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: dlRow.modelData.title
                                        elide: Text.ElideRight
                                        opacity: dlRow.isPast ? 0.55 : 1.0
                                        color: Appearance.colors.colOnLayer0
                                        font {
                                            family: Appearance.font.family.main
                                            pixelSize: Appearance.font.pixelSize.smallie
                                            weight: Font.Medium
                                            strikeout: dlRow.isPast
                                        }
                                    }

                                    StyledText {
                                        text: dlRow.modelData.shortDate
                                        color: Appearance.colors.colSubtext
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Appearance.font.pixelSize.smallest
                                        }
                                    }
                                }

                                // Countdown badge (H-N / Today! / Passed)
                                Rectangle {
                                    implicitWidth: badgeText.implicitWidth + 10
                                    implicitHeight: 20
                                    radius: Appearance.rounding.full
                                    color: dlRow.isToday
                                        ? Appearance.colors.colErrorContainer
                                        : (dlRow.isUrgent
                                            ? Appearance.colors.colPrimaryContainer
                                            : ColorUtils.transparentize(Appearance.colors.colLayer2Base, 0.25))

                                    StyledText {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: dlRow.isToday
                                            ? "Today!"
                                            : (dlRow.isPast
                                                ? `+${Math.abs(dlRow.modelData.diffDays)}d`
                                                : `H-${dlRow.modelData.diffDays}`)
                                        color: dlRow.isToday
                                            ? Appearance.colors.colOnErrorContainer
                                            : (dlRow.isUrgent
                                                ? Appearance.colors.colOnPrimaryContainer
                                                : Appearance.colors.colOnLayer1)
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Appearance.font.pixelSize.smallest
                                            weight: Font.Bold
                                        }
                                    }
                                }

                                Item {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                }
                            }

                            MouseArea {
                                id: dlRowMouse
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: dlDeleteBtn.left
                                }
                                hoverEnabled: true
                            }

                            Rectangle {
                                id: dlDeleteBtn
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 6
                                }
                                width: 20
                                height: 20
                                radius: Appearance.rounding.full
                                opacity: dlRow.isHovered ? 1 : 0
                                visible: opacity > 0
                                color: dlDeleteMouse.containsMouse
                                    ? ColorUtils.transparentize(Appearance.colors.colErrorContainer, 0.15)
                                    : "transparent"

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    iconSize: 13
                                    text: "close"
                                    color: dlDeleteMouse.containsMouse
                                        ? Appearance.colors.colError
                                        : Appearance.colors.colSubtext
                                }

                                MouseArea {
                                    id: dlDeleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeDeadline(dlRow.modelData.originalIndex)
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.hiddenDeadlinesCount > 0
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: `+ ${root.hiddenDeadlinesCount} more deadlines`
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallest
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
