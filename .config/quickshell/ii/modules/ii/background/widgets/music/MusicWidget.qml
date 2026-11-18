pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "music"
    needsColText: false
    visibleWhenLocked: false

    implicitWidth: 320
    implicitHeight: 82

    readonly property bool hasTrack: MprisController.activePlayer !== null
    readonly property string artUrl: MprisController.activeTrack?.artUrl ?? ""
    readonly property string titleText: hasTrack
        ? (MprisController.activeTrack?.title || Translation.tr("Unknown Title"))
        : Translation.tr("Nothing playing")
    readonly property string artistText: hasTrack
        ? (MprisController.activeTrack?.artist || Translation.tr("Unknown Artist"))
        : Translation.tr("Play music in Spotify or browser")

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

        RowLayout {
            anchors {
                fill: parent
                margins: 11
            }
            spacing: 11

            // Rounded album cover (downscaled + GPU cached, 0% CPU idle)
            ClippingRectangle {
                Layout.preferredWidth: 58
                Layout.preferredHeight: 58
                radius: Appearance.rounding.small
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.25)

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    cache: true
                    sourceSize: Qt.size(116, 116)
                    visible: status === Image.Ready
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: coverImage.status !== Image.Ready
                    iconSize: 24
                    text: "music_note"
                    color: Appearance.colors.colPrimary
                }
            }

            // Track title & artist
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: 5

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: MprisController.isPlaying
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: MprisController.isPlaying ? Translation.tr("Now Playing") : Translation.tr("Paused")
                        color: MprisController.isPlaying
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colSubtext
                        font {
                            family: Appearance.font.family.monospace
                            pixelSize: Appearance.font.pixelSize.smallest
                            weight: Font.Medium
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.titleText
                    color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight
                    font {
                        family: Appearance.font.family.title
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.DemiBold
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.artistText
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            // Compact tactile playback controls
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                MediaBtn {
                    iconName: "skip_previous"
                    enabled: MprisController.canGoPrevious
                    onClicked: MprisController.previous()
                }

                MediaBtn {
                    iconName: MprisController.isPlaying ? "pause" : "play_arrow"
                    highlighted: true
                    btnSize: 32
                    iconSize: 18
                    enabled: MprisController.canTogglePlaying
                    onClicked: MprisController.togglePlaying()
                }

                MediaBtn {
                    iconName: "skip_next"
                    enabled: MprisController.canGoNext
                    onClicked: MprisController.next()
                }
            }
        }
    }

    component MediaBtn: Rectangle {
        id: btn
        required property string iconName
        property bool highlighted: false
        property bool enabled: true
        property int btnSize: 26
        property int iconSize: 16
        signal clicked()

        implicitWidth: btnSize
        implicitHeight: btnSize
        radius: Appearance.rounding.full
        opacity: enabled ? 1.0 : 0.4
        color: {
            if (highlighted) {
                return (btnMouse.containsMouse && enabled)
                    ? Appearance.colors.colPrimaryContainerHover
                    : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.1);
            }
            return (btnMouse.containsMouse && enabled)
                ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.15)
                : "transparent";
        }

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: btn.iconSize
            text: btn.iconName
            fill: btn.highlighted ? 1 : 0
            color: btn.highlighted
                ? Appearance.colors.colOnPrimaryContainer
                : Appearance.colors.colOnLayer1
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: btn.enabled
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.clicked()
        }
    }
}
