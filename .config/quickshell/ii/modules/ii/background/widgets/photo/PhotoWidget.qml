pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "photo"
    needsColText: false
    visibleWhenLocked: false
    hoverEnabled: true

    readonly property bool isPolaroid: Config.options.background.widgets.photo.style !== "rounded"
    readonly property int frameSize: Math.max(140, Math.min(360, Config.options.background.widgets.photo.size ?? 220))
    readonly property int sidePad: isPolaroid ? 10 : 0
    readonly property int bottomChin: isPolaroid ? 36 : 0
    readonly property string rawPath: Config.options.background.widgets.photo.imagePath ?? ""
    readonly property bool looksLikeImageFile: /\.(png|jpe?g|webp|avif|bmp)$/i.test(rawPath)
    readonly property string resolvedImageUrl: {
        if (!rawPath || !looksLikeImageFile) return "";
        if (rawPath.startsWith("file://") || rawPath.startsWith("http")) return rawPath;
        return Qt.resolvedUrl("file://" + rawPath);
    }
    readonly property string captionText: Config.options.background.widgets.photo.caption ?? ""
    readonly property real effectiveTilt: Config.options.background.widgets.photo.tilt ?? 0
    readonly property bool isHovered: root.containsMouse || shuffleBtn.containsMouse || pickBtn.containsMouse

    implicitWidth: frameSize + sidePad * 2
    implicitHeight: frameSize + sidePad + bottomChin

    // If user points imagePath to a folder instead of a file, resolve an image from it automatically.
    onRawPathChanged: {
        if (rawPath && rawPath.length > 0 && !looksLikeImageFile) {
            pickImage("--random");
        }
    }

    Component.onCompleted: {
        if (rawPath && rawPath.length > 0 && !looksLikeImageFile) {
            pickImage("--random");
        }
    }

    function pickImage(modeFlag) {
        if (imagePickerProc.running) return;
        const scriptPath = FileUtils.trimFileProtocol(`${Directories.scriptPath}/images/pick-image.py`);
        imagePickerProc.command = ["python3", scriptPath, modeFlag, root.rawPath];
        imagePickerProc.running = true;
    }

    Process {
        id: imagePickerProc
        stdout: StdioCollector {
            id: pickerCollector
            onStreamFinished: {
                const chosen = pickerCollector.text.trim();
                if (chosen.length > 0) {
                    Config.options.background.widgets.photo.imagePath = chosen;
                }
            }
        }
    }

    Item {
        id: rotatedContainer
        anchors.fill: parent
        rotation: root.effectiveTilt
        transformOrigin: Item.Center
        antialiasing: true

        StyledRectangularShadow {
            target: cardFrame
        }

        Rectangle {
            id: cardFrame
            anchors.fill: parent
            radius: root.isPolaroid ? Appearance.rounding.normal : Appearance.rounding.large
            color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, root.isPolaroid ? 0.14 : 0.24)
            border.width: 1
            border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.35)
            antialiasing: true
            // 4x MSAA smoothing only when tilted; zero offscreen layer cost at 0 deg.
            layer.enabled: root.effectiveTilt !== 0
            layer.samples: 4
            layer.smooth: true

            // Photo area clipped natively with Quickshell's rounded ClippingRectangle
            ClippingRectangle {
                id: photoContainer
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: root.sidePad
                    leftMargin: root.sidePad
                    rightMargin: root.sidePad
                }
                height: root.frameSize
                radius: root.isPolaroid ? Appearance.rounding.small : Appearance.rounding.large
                color: ColorUtils.transparentize(Appearance.colors.colLayer1Base, 0.3)

                Image {
                    id: photoImage
                    anchors.fill: parent
                    source: root.resolvedImageUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    cache: true
                    sourceSize: Qt.size(root.frameSize * 2, root.frameSize * 2)
                    visible: status === Image.Ready

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            console.log("[PhotoWidget] Image ready:", source);
                        } else if (status === Image.Error) {
                            console.warn("[PhotoWidget] Failed to load image:", source);
                        }
                    }
                }

                // Subtle placeholder when no image or loading error
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: photoImage.status !== Image.Ready

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 28
                        text: "photo_library"
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Choose image")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }

                // Floating caption pill for rounded borderless mode
                Rectangle {
                    visible: !root.isPolaroid && root.captionText.length > 0
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        margins: 10
                    }
                    implicitWidth: Math.min(parent.width - 20, roundedCapText.implicitWidth + 18)
                    implicitHeight: roundedCapText.implicitHeight + 8
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.25)
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)

                    StyledText {
                        id: roundedCapText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, photoContainer.width - 38)
                        text: root.captionText
                        elide: Text.ElideRight
                        color: Appearance.colors.colOnLayer0
                        renderType: root.effectiveTilt !== 0 ? Text.QtRendering : Text.NativeRendering
                        font {
                            family: Appearance.font.family.reading
                            pixelSize: Appearance.font.pixelSize.smaller
                            weight: Font.Medium
                            hintingPreference: root.effectiveTilt !== 0 ? Font.PreferNoHinting : Font.PreferDefaultHinting
                        }
                    }
                }

                // Hover action pills (top-right)
                Row {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 8
                    }
                    spacing: 5
                    opacity: root.isHovered ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                    PhotoActionButton {
                        id: shuffleBtn
                        iconName: "shuffle"
                        onClicked: root.pickImage("--random")
                    }

                    PhotoActionButton {
                        id: pickBtn
                        iconName: "folder_open"
                        onClicked: root.pickImage("--pick")
                    }
                }
            }

            // Polaroid bottom chin caption
            Item {
                visible: root.isPolaroid
                anchors {
                    top: photoContainer.bottom
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    leftMargin: 12
                    rightMargin: 12
                }

                RowLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 3
                        color: Appearance.colors.colPrimary
                        visible: root.captionText.length > 0
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.captionText.length > 0 ? root.captionText : Translation.tr("Memories")
                        horizontalAlignment: root.captionText.length > 0 ? Text.AlignLeft : Text.AlignHCenter
                        elide: Text.ElideRight
                        color: Appearance.colors.colOnLayer0
                        renderType: root.effectiveTilt !== 0 ? Text.QtRendering : Text.NativeRendering
                        font {
                            family: Appearance.font.family.reading
                            pixelSize: Appearance.font.pixelSize.smallie
                            weight: Font.Medium
                            hintingPreference: root.effectiveTilt !== 0 ? Font.PreferNoHinting : Font.PreferDefaultHinting
                        }
                    }
                }
            }
        }
    }

    component PhotoActionButton: Rectangle {
        id: actionBtn
        required property string iconName
        signal clicked()

        readonly property alias containsMouse: actionMouse.containsMouse

        width: 26
        height: 26
        radius: Appearance.rounding.full
        color: actionMouse.containsMouse
            ? Appearance.colors.colPrimaryContainer
            : ColorUtils.transparentize(Appearance.colors.colLayer0Base, 0.22)
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)

        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 15
            text: actionBtn.iconName
            color: actionMouse.containsMouse
                ? Appearance.colors.colOnPrimaryContainer
                : Appearance.colors.colOnLayer0
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionBtn.clicked()
        }
    }
}
