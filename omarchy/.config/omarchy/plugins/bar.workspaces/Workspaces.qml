import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Noctchill workspaces: each workspace wears one member of the unit.
//
// Drop a square portrait at idols/<name>.png and it takes over the slot.
// Until that file exists the slot falls back to the member's colour:
//   empty     — a faint dot
//   occupied  — a solid dot
//   focused   — a soft pill, easing in and out
// With a portrait present the geometry never moves; the face desaturates
// instead, and the focused one comes back to full colour inside a ring.
BarWidget {
  id: root
  moduleName: "bar.workspaces"

  // Override wholesale from shell.json with a "members" object keyed by
  // workspace id, e.g. { "1": { "name": "madoka", "color": "#988ED7" } }. Colours are
  // sampled from each member's hair in the theme's idol.png.
  readonly property var members: root.setting("members", {
    "1": { "name": "toru",      "color": "#D7AA8E" },
    "2": { "name": "madoka",    "color": "#988ED7" },
    "3": { "name": "koito",     "color": "#D78EB9" },
    "4": { "name": "hinana",    "color": "#D7958E" },
    "5": { "name": "noctchill", "color": "#5B8DEF" }
  })

  // Portraits live next to this file unless shell.json points elsewhere.
  readonly property string iconDir: {
    var dir = root.setting("iconDir", "")
    return dir === "" ? Qt.resolvedUrl("idols/").toString() : Util.fileUrl(dir) + "/"
  }

  function memberFor(id) {
    var m = members ? members[String(id)] : undefined
    return m === undefined ? null : m
  }

  function iconFor(id) {
    var m = memberFor(id)
    return m && m.name ? iconDir + encodeURIComponent(m.name) + ".png" : ""
  }

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
  readonly property real icon: Style.spaceReal(root.setting("iconSize", 20))
  readonly property real ring: Style.spaceReal(2)
  // Fixed cells, so filling a workspace never shifts the row sideways.
  readonly property real cell: Math.max(root.icon + root.ring * 2, root.pill)

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
        id: slot
        required property int modelData
        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property var member: root.memberFor(modelData)
        readonly property color tint: member && member.color ? member.color : root.fg
        readonly property bool hasIcon: face.status === Image.Ready

        width: root.cell
        height: root.cell

        // Round stencil for the portrait. Never drawn itself; MultiEffect
        // samples its layer texture as the alpha mask.
        Item {
          id: stencil
          anchors.fill: portrait
          visible: false
          layer.enabled: true

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "white"
            antialiasing: true
          }
        }

        Item {
          id: portrait
          anchors.centerIn: parent
          width: root.icon
          height: root.icon
          visible: slot.hasIcon

          scale: slot.focused ? 1 : 0.88
          opacity: slot.focused ? 1 : (slot.occupied ? 0.85 : 0.4)
          Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
          Behavior on opacity { NumberAnimation { duration: 200 } }

          layer.enabled: true
          layer.smooth: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: stencil
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.2
            // Unfocused members hang back in grey; the current one is in colour.
            saturation: slot.focused ? 0 : (slot.occupied ? -0.5 : -1)
            brightness: slot.focused ? 0 : (slot.occupied ? -0.05 : -0.15)
            Behavior on saturation { NumberAnimation { duration: 220 } }
            Behavior on brightness { NumberAnimation { duration: 220 } }
          }

          Image {
            id: face
            anchors.fill: parent
            source: root.iconFor(slot.modelData)
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: root.icon * 2
            sourceSize.height: root.icon * 2
            smooth: true
            mipmap: true
            cache: true
            asynchronous: true
          }
        }

        Rectangle {
          // Ring around the focused portrait, in that member's colour.
          anchors.centerIn: parent
          width: root.icon + root.ring * 2
          height: width
          radius: width / 2
          color: "transparent"
          border.width: Math.max(1, root.ring / 2)
          border.color: slot.tint
          antialiasing: true
          visible: slot.hasIcon
          opacity: slot.focused ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 220 } }
        }

        Rectangle {
          // Stand-in until idols/<name>.png exists: the old dot, member-coloured.
          anchors.centerIn: parent
          visible: !slot.hasIcon
          width: root.vertical ? root.dot : (slot.focused ? root.pill : root.dot)
          height: root.vertical ? (slot.focused ? root.pill : root.dot) : root.dot
          radius: root.dot / 2
          color: slot.tint
          opacity: slot.focused ? 1 : (slot.occupied ? 0.85 : 0.28)

          Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
          Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
          Behavior on color { ColorAnimation { duration: 200 } }
          Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        MouseArea {
          // Generous hit box so the small marks stay easy to click.
          anchors.centerIn: parent
          width: parent.width + root.gap
          height: root.barSize
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(slot.modelData)
        }
      }
    }
  }
}
