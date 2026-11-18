pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "todo"
    needsColText: false
    visibleWhenLocked: false

    implicitWidth: 300
    implicitHeight: cardColumn.implicitHeight + 24

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    readonly property var allIndexedTasks: (Todo.list ?? []).map((item, idx) => ({
        content: item.content ?? "",
        done: Boolean(item.done),
        originalIndex: idx
    }))
    readonly property int unfinishedCount: allIndexedTasks.filter(t => !t.done).length
    readonly property var sortedTasks: {
        const showDone = Config.options.background.widgets.todo.showCompleted;
        const base = showDone ? allIndexedTasks : allIndexedTasks.filter(t => !t.done);
        return base.slice().sort((a, b) => Number(a.done) - Number(b.done));
    }
    readonly property int maxVisible: Math.max(1, Config.options.background.widgets.todo.maxItems ?? 6)
    readonly property var visibleTasks: sortedTasks.slice(0, maxVisible)
    readonly property int hiddenCount: Math.max(0, sortedTasks.length - visibleTasks.length)

    function openSidebarTodo() {
        Persistent.states.sidebar.bottomGroup.collapsed = false;
        Persistent.states.sidebar.bottomGroup.tab = 1; // To Do tab
        GlobalStates.sidebarRightOpen = true;
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
                spacing: 8

                MaterialSymbol {
                    iconSize: 18
                    text: "checklist"
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Config.options.background.widgets.todo.title || Translation.tr("Today's Focus")
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.normal
                        weight: Font.DemiBold
                    }
                }

                // Pending count badge
                Rectangle {
                    implicitWidth: countText.implicitWidth + 12
                    implicitHeight: 20
                    radius: Appearance.rounding.full
                    color: root.unfinishedCount > 0
                        ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)
                        : ColorUtils.transparentize(Appearance.m3colors.m3successContainer, 0.2)

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: root.unfinishedCount > 0 ? `${root.unfinishedCount} left` : "Clear"
                        color: root.unfinishedCount > 0
                            ? Appearance.colors.colOnPrimaryContainer
                            : Appearance.m3colors.m3onSuccessContainer
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.DemiBold
                        }
                    }
                }

                // Toggle show/hide completed tasks
                IconPillButton {
                    iconName: Config.options.background.widgets.todo.showCompleted ? "visibility" : "visibility_off"
                    active: !Config.options.background.widgets.todo.showCompleted
                    onClicked: {
                        Config.options.background.widgets.todo.showCompleted = !Config.options.background.widgets.todo.showCompleted;
                    }
                }

                // Open sidebar To Do editor
                IconPillButton {
                    iconName: "add"
                    onClicked: root.openSidebarTodo()
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
                visible: root.visibleTasks.length === 0
                Layout.fillWidth: true
                implicitHeight: emptyCol.implicitHeight + 20
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.45)

                ColumnLayout {
                    id: emptyCol
                    anchors.centerIn: parent
                    spacing: 6

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        MaterialSymbol {
                            iconSize: 18
                            text: "task_alt"
                            color: Appearance.m3colors.m3success
                        }

                        StyledText {
                            text: root.allIndexedTasks.length > 0
                                ? Translation.tr("All tasks completed")
                                : Translation.tr("No active tasks")
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smallie
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: addEmptyRow.implicitWidth + 16
                        implicitHeight: 24
                        radius: Appearance.rounding.full
                        color: addEmptyMouse.containsMouse
                            ? Appearance.colors.colPrimaryContainerHover
                            : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.15)

                        RowLayout {
                            id: addEmptyRow
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                iconSize: 14
                                text: "add"
                                color: Appearance.colors.colOnPrimaryContainer
                            }
                            StyledText {
                                text: Translation.tr("Add task")
                                color: Appearance.colors.colOnPrimaryContainer
                                font {
                                    pixelSize: Appearance.font.pixelSize.smaller
                                    weight: Font.Medium
                                }
                            }
                        }

                        MouseArea {
                            id: addEmptyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openSidebarTodo()
                        }
                    }
                }
            }

            // Task list
            ColumnLayout {
                visible: root.visibleTasks.length > 0
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.visibleTasks
                    delegate: Rectangle {
                        id: taskRow
                        required property var modelData

                        readonly property bool isHovered: rowToggleMouse.containsMouse || rowDeleteMouse.containsMouse
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
                            spacing: 8

                            // Checkbox
                            Rectangle {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                radius: 5
                                color: taskRow.modelData.done
                                    ? Appearance.colors.colPrimary
                                    : "transparent"
                                border.width: taskRow.modelData.done ? 0 : 1.5
                                border.color: rowToggleMouse.containsMouse
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOutline

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: taskRow.modelData.done
                                    iconSize: 12
                                    text: "check"
                                    color: Appearance.colors.colOnPrimary
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: taskRow.modelData.content
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                opacity: taskRow.modelData.done ? 0.55 : 1.0
                                color: taskRow.modelData.done
                                    ? Appearance.colors.colSubtext
                                    : Appearance.colors.colOnLayer0
                                font {
                                    family: Appearance.font.family.main
                                    pixelSize: Appearance.font.pixelSize.smallie
                                    strikeout: taskRow.modelData.done
                                }
                            }

                            // Placeholder space so delete button clicks don't trigger row toggle
                            Item {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                            }
                        }

                        MouseArea {
                            id: rowToggleMouse
                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                                left: parent.left
                                right: rowDeleteBtn.left
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (taskRow.modelData.done) {
                                    Todo.markUnfinished(taskRow.modelData.originalIndex);
                                } else {
                                    Todo.markDone(taskRow.modelData.originalIndex);
                                }
                            }
                        }

                        // Subtle delete button on hover
                        Rectangle {
                            id: rowDeleteBtn
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 6
                            }
                            width: 22
                            height: 22
                            radius: Appearance.rounding.full
                            opacity: taskRow.isHovered ? 1 : 0
                            visible: opacity > 0
                            color: rowDeleteMouse.containsMouse
                                ? ColorUtils.transparentize(Appearance.colors.colErrorContainer, 0.15)
                                : "transparent"

                            MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: 14
                                text: "close"
                                color: rowDeleteMouse.containsMouse
                                    ? Appearance.colors.colError
                                    : Appearance.colors.colSubtext
                            }

                            MouseArea {
                                id: rowDeleteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Todo.deleteItem(taskRow.modelData.originalIndex)
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
                text: `+ ${root.hiddenCount} more in sidebar`
                color: moreMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallest

                MouseArea {
                    id: moreMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openSidebarTodo()
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
