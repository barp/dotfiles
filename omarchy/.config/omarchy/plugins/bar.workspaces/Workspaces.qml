import QtQuick
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Noctchill workspaces: no digits, just a quiet row of marks.
//   empty     — a faint dot
//   occupied  — a solid dot
//   focused   — a soft pill in the accent colour, easing in and out
BarWidget {
  id: root
  moduleName: "bar.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) if (values[i].id === id) return values[i]
    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(l, r) { return l - r })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property real dot: Style.spaceReal(6)
  readonly property real pill: Style.spaceReal(20)
  readonly property real gap: Style.spaceReal(7)
  readonly property real edge: Style.spaceReal(4)

  implicitWidth: vertical ? barSize : flow.implicitWidth + edge * 2
  implicitHeight: vertical ? flow.implicitHeight + edge * 2 : barSize

  Grid {
    id: flow
    anchors.centerIn: parent
    columns: root.vertical ? 1 : root.workspaceIds().length
    spacing: root.gap
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter

    Repeater {
      model: root.workspaceIds()

      Item {
        id: cell
        required property int modelData
        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        width: root.vertical ? root.dot : (focused ? root.pill : root.dot)
        height: root.vertical ? (focused ? root.pill : root.dot) : root.dot

        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle {
          anchors.fill: parent
          radius: root.dot / 2
          color: cell.focused ? Color.accent : root.fg
          opacity: cell.focused ? 1 : (cell.occupied ? 0.85 : 0.28)
          Behavior on color { ColorAnimation { duration: 200 } }
          Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        MouseArea {
          // Generous hit box so the small dots stay easy to click.
          anchors.centerIn: parent
          width: parent.width + root.gap
          height: root.barSize
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(cell.modelData)
        }
      }
    }
  }
}
