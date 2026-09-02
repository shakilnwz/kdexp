import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "snxz.taskbar"

  property bool expanded: false
  property real revealProgress: 0
  readonly property int itemExtent: Style.space(20)
  readonly property int itemGap: Style.space(6)
  readonly property int itemCount: ToplevelManager.toplevels.values.length
  readonly property int drawerExtent: itemCount > 0 ? itemCount * itemExtent + (itemCount - 1) * itemGap : 0
  readonly property real revealExtent: drawerExtent * revealProgress
  readonly property int animationDuration: 200

  property var iconCache: ({})

  implicitHeight: barSize
  implicitWidth: drawerArea.implicitWidth
  visible: !vertical && itemCount > 0

  Behavior on revealProgress {
    NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic }
  }

  onExpandedChanged: revealProgress = expanded ? 1 : 0

  function resolveIcon(appId, title) {
    var rawId = String(appId || "").trim()
    var cacheKey = rawId + "::" + String(title || "")
    if (root.iconCache[cacheKey]) return root.iconCache[cacheKey]

    var resolved = ""
    var idLower = rawId.toLowerCase()
    var idBase = rawId.indexOf(".") >= 0 ? rawId.split(".").pop().toLowerCase() : idLower

    // 1. Match against installed desktop entries (finds StartupWMClass and custom icons)
    try {
      var apps = DesktopEntries.applications.values || []
      for (var i = 0; i < apps.length; i++) {
        var entry = apps[i]
        if (!entry) continue
        var entryId = String(entry.id || "").toLowerCase()
        var entryName = String(entry.name || "").toLowerCase()
        var wmClass = String(entry.startupWMClass || "").toLowerCase()

        if (entryId === idLower || entryId === idLower + ".desktop" ||
            entryName === idLower || (wmClass && wmClass === idLower)) {
          if (entry.icon) {
            var iconP = Quickshell.iconPath(entry.icon, true)
            if (iconP && iconP.length > 0) {
              resolved = iconP
              break
            }
          }
        }
      }
    } catch (e) {}

    // 2. Direct theme lookup across candidate names and common aliases
    if (!resolved && rawId.length > 0) {
      var candidates = [
        rawId,
        idLower,
        idLower + "-browser",
        idBase,
        idBase + "-browser",
        "org.gnome." + idBase,
        "org.kde." + idBase
      ]

      for (var c = 0; c < candidates.length; c++) {
        var themed = Quickshell.iconPath(candidates[c], true)
        if (themed && themed.length > 0) {
          resolved = themed
          break
        }
      }
    }

    // 3. Fallback executable icon
    if (!resolved) {
      resolved = Quickshell.iconPath("application-x-executable", true)
    }

    root.iconCache[cacheKey] = resolved
    return resolved
  }

  function activateOffset(delta) {
    var toplevels = ToplevelManager.toplevels.values
    if (!toplevels || toplevels.length <= 1) return
    var currentIndex = -1
    for (var i = 0; i < toplevels.length; i++) {
      if (toplevels[i] === ToplevelManager.activeToplevel) {
        currentIndex = i
        break
      }
    }
    if (currentIndex === -1) currentIndex = 0
    var step = delta > 0 ? -1 : 1
    var nextIndex = (currentIndex + step + toplevels.length) % toplevels.length
    toplevels[nextIndex].activate()
  }

  Item {
    id: drawerArea
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: root.revealExtent + chevronBtn.implicitWidth
    implicitHeight: root.barSize

    HoverHandler {
      onHoveredChanged: root.expanded = hovered
    }

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: function(event) {
        root.activateOffset(event.angleDelta.y)
      }
    }

    Item {
      id: iconClip
      x: 0
      anchors.verticalCenter: parent.verticalCenter
      width: root.revealExtent
      height: root.barSize
      clip: true

      Row {
        id: layout
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.itemGap

        Repeater {
          model: ToplevelManager.toplevels.values

          delegate: Item {
            id: delegateRoot
            width: root.itemExtent
            height: root.barSize

            readonly property var toplevel: modelData
            readonly property bool isActive: toplevel === ToplevelManager.activeToplevel

            Rectangle {
              anchors.centerIn: parent
              width: Style.space(20)
              height: Style.space(16)
              radius: Style.radius.small
              color: isActive ? (root.bar ? root.bar.accentColor : Style.color.accent) : "transparent"
              opacity: isActive ? 0.25 : 0
            }

            Image {
              anchors.centerIn: parent
              width: Style.space(12)
              height: Style.space(12)
              source: root.resolveIcon(toplevel.appId, toplevel.title)
              fillMode: Image.PreserveAspectFit
              sourceSize.width: width * Screen.devicePixelRatio
              sourceSize.height: height * Screen.devicePixelRatio
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
              cursorShape: Qt.PointingHandCursor

              onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                  toplevel.close()
                } else {
                  toplevel.activate()
                }
              }
              onEntered: if (root.bar) root.bar.showTooltip(delegateRoot, toplevel.title || toplevel.appId || "Window")
              onExited: if (root.bar) root.bar.hideTooltip(delegateRoot)
            }
          }
        }
      }
    }

    BarIconButton {
      id: chevronBtn
      bar: root.bar
      width: implicitWidth
      height: implicitHeight
      x: root.revealExtent
      text: "\uf054"
      onPressed: root.expanded = !root.expanded
    }
  }
}
