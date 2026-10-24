import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Summoned by bin/browser-profile-open with the link(s) to open and the
// browser's profiles:
//   { launcher, lastUsed, urls: [...], profiles: [{ dir, name, email, avatar }] }
// Choosing a profile runs the launcher again with --profile-directory, which
// hands the links to the real browser. Escape drops them.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string launcher: ""
  property var urls: []
  property int selectedIndex: 0

  property color background: Commons.Color.menu.background
  property color foreground: Commons.Color.menu.text
  property color border: Commons.Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Commons.Color.menu.scrim
  property color selectedBackground: Commons.Color.menu.selectedBackground
  property color selectedText: Commons.Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int contentSpacing: Style.spacing.md
  property int rowHeight: Math.max(Style.space(48), Style.font.title + Style.font.bodySmall + Style.spacing.controlPaddingY * 3)
  property int avatarSize: rowHeight - Style.spacing.controlPaddingY * 2
  property int cardWidth: Math.min(Style.space(420), panel.width - Style.gapsOut * 2)

  readonly property string linkText: {
    if (!urls.length) return ""
    var more = urls.length > 1 ? "  (+" + (urls.length - 1) + " more)" : ""
    return urls[0] + more
  }

  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") || {} } catch (e) {
      console.warn("imeredith.browser-profile: bad payload", e)
    }

    var profiles = Array.isArray(payload.profiles) ? payload.profiles : []
    var urls = Array.isArray(payload.urls) ? payload.urls.map(String) : []
    if (!payload.launcher || profiles.length === 0 || urls.length === 0) {
      root.dismiss()
      return
    }

    root.launcher = String(payload.launcher)
    root.urls = urls
    profileModel.clear()
    var selected = 0
    for (var i = 0; i < profiles.length; i++) {
      var p = profiles[i] || {}
      var dir = String(p.dir || "")
      if (!dir) continue
      if (dir === payload.lastUsed) selected = profileModel.count
      profileModel.append({
        dir: dir,
        name: String(p.name || dir),
        email: String(p.email || ""),
        avatar: p.avatar ? "file://" + String(p.avatar) : ""
      })
    }
    root.selectedIndex = selected
    root.opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "imeredith.browser-profile")
  }

  function select(delta) {
    if (profileModel.count === 0) return
    selectedIndex = (selectedIndex + delta + profileModel.count) % profileModel.count
    profileList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function activateIndex(index) {
    if (index < 0 || index >= profileModel.count) return
    var dir = profileModel.get(index).dir
    var command = [root.launcher, "--profile-directory=" + dir].concat(root.urls)
    root.dismiss()
    Quickshell.execDetached(command)
  }

  function initials(name) {
    var words = String(name || "").trim().split(/\s+/)
    if (!words[0]) return "?"
    var letters = words[0].charAt(0) + (words.length > 1 ? words[1].charAt(0) : "")
    return letters.toUpperCase()
  }

  ListModel { id: profileModel }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "imeredith-browser-profile"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: content.implicitHeight + card.contentTopInset + card.contentBottomInset
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.dismiss()
            event.accepted = true
          } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K
                     || (event.key === Qt.Key_Backtab)) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J
                     || event.key === Qt.Key_Tab) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateIndex(root.selectedIndex)
            event.accepted = true
          } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            root.activateIndex(event.key - Qt.Key_1)
            event.accepted = true
          }
        }
      }

      Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: "Open link in…"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          width: parent.width
          text: root.linkText
          color: root.foreground
          opacity: 0.58
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideMiddle
        }

        ListView {
          id: profileList
          width: parent.width
          height: Math.min(contentHeight, root.rowHeight * 6)
          model: profileModel
          clip: true
          interactive: contentHeight > height
          boundsBehavior: Flickable.StopAtBounds

          delegate: Rectangle {
            id: row
            required property int index
            required property string name
            required property string email
            required property string avatar

            readonly property bool hasCursor: index === root.selectedIndex

            width: ListView.view.width
            height: root.rowHeight
            radius: root.cornerRadius
            color: hasCursor ? root.selectedBackground : "transparent"

            Item {
              id: avatarSlot
              width: root.avatarSize
              height: root.avatarSize
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.controlPaddingX
              anchors.verticalCenter: parent.verticalCenter

              Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Util.alpha(root.foreground, 0.12)
                visible: picture.status !== Image.Ready

                Text {
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: root.initials(row.name)
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                }
              }

              Rectangle {
                id: avatarMask
                anchors.fill: parent
                radius: width / 2
                visible: false
                layer.enabled: true
              }

              Image {
                id: picture
                anchors.fill: parent
                source: row.avatar
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
                layer.enabled: true
                layer.smooth: true
                layer.effect: MultiEffect {
                  maskEnabled: true
                  maskSource: avatarMask
                  maskThresholdMin: 0.3
                  maskSpreadAtMin: 0.3
                }
              }
            }

            Column {
              anchors.left: avatarSlot.right
              anchors.leftMargin: Style.spacing.controlGap + Style.spacing.xs
              anchors.right: shortcut.left
              anchors.rightMargin: Style.spacing.controlGap
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacing.xxs

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: row.name
                color: row.hasCursor ? root.selectedText : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: row.email
                visible: row.email !== ""
                color: root.foreground
                opacity: 0.58
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }
            }

            Text {
              id: shortcut
              anchors.right: parent.right
              anchors.rightMargin: Style.spacing.controlPaddingX
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: row.index < 9 ? String(row.index + 1) : ""
              color: root.foreground
              opacity: 0.4
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: if (containsMouse) root.selectedIndex = row.index
              onClicked: root.activateIndex(row.index)
            }
          }
        }
      }
    }
  }
}
