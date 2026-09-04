import QtQuick
import qs.Commons
import qs.Ui

// Noctchill launcher: the unit wordmark (logo.png beside this file) in place
// of a glyph. Left click opens the menu, right click opens a terminal.
// Swap the file for logo-orig.png (original blues) or logo-o.png (just the
// "o" mark) to change the look without touching the code.
BarWidget {
  id: root
  moduleName: "bar.menu"

  readonly property real logoHeight: Math.round(barSize * 0.5)
  readonly property real sidePad: Style.spaceReal(4)

  implicitWidth: vertical ? barSize : logo.paintedWidth + sidePad * 2
  implicitHeight: vertical ? logo.paintedHeight + sidePad * 2 : barSize

  Image {
    id: logo
    anchors.centerIn: parent
    // The waterline hangs below the letters, so lift the image a little to
    // put the letters themselves on the bar's centre line.
    anchors.verticalCenterOffset: -Math.round(root.logoHeight * 0.15)
    source: Qt.resolvedUrl("logo.png")
    height: root.logoHeight
    // Wide wordmark rotates to run along a vertical bar.
    rotation: root.vertical ? -90 : 0
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    sourceSize.height: root.logoHeight * 3
    opacity: mouse.containsMouse ? 1 : 0.9
    Behavior on opacity { NumberAnimation { duration: 140 } }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, "Menu")
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: function(m) {
      if (!root.bar) return
      root.bar.hideTooltip(root)
      if (m.button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
