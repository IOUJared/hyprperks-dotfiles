import "../../commonwidgets" as CW
import "../../config" as C
import "../../state" as S
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Rectangle {
  id: root

  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
  radius: 8
  implicitHeight: 300

  property int profilesRevision: 0

  function updateProfiles() {
    profilesRevision++;
    S.NightLightState.buildProfileConfig();
  }

  function resetProfileTimer() {
    profileDebounceTimer.running = false;
    profileDebounceTimer.running = true;
  }

  Timer {
    id: profileDebounceTimer
    interval: 1000
    repeat: false
    onTriggered: {
      updateProfiles();
    }
  }

  ScrollView {
    id: scrollview

    anchors.fill: parent
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: scrollview.width
      uniformCellSizes: false
      spacing: -1

      anchors {
        top: parent.top
        left: parent.left
      }

      CW.StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 10
        text: "Brightness"
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.h2
        color: C.Config.theme.on_surface
      }

      Spacerr {}

      CW.HorizontalLine {}

      Spacerr {}

      BrightnessSlider {
        visible: S.BrightnessState.hasBacklight && C.Config.misc.brightnessSplit
        label: "Backlight"
        value: S.BrightnessState.backlightBrightness
        Layout.fillWidth: true
        onMoved: S.BrightnessState.setBacklight(value)
        Layout.leftMargin: 15
        Layout.rightMargin: 15
      }

      BrightnessSlider {
        visible: !C.Config.misc.brightnessSplit
        label: "Brightness"
        value: S.BrightnessState.overallBrightness
        Layout.fillWidth: true
        onMoved: S.BrightnessState.setOverall(value)
        Layout.leftMargin: 15
        Layout.rightMargin: 15
      }

      Spacerr {
        visible: (!C.Config.misc.brightnessSplit) || (S.BrightnessState.hasBacklight && C.Config.misc.brightnessSplit)
      }

      ColumnLayout {
        spacing: 5

        Repeater {
          visible: C.Config.misc.brightnessSplit
          model: S.BrightnessState.monitors

          BrightnessSlider {
            required property int index

            visible: S.BrightnessState.brightnesses[index] != -1 && C.Config.misc.brightnessSplit
            label: S.BrightnessState.monitors[index]
            value: S.BrightnessState.brightnesses[index]
            Layout.fillWidth: true
            onMoved: S.BrightnessState.setBrightness(index, value)
            Layout.leftMargin: 15
            Layout.rightMargin: 15
          }
        }
      }

      Spacerr {}

      CW.StyledText {
        visible: C.Config.misc.brightnessSplit && !S.BrightnessState.anyControls
        Layout.fillWidth: true
        text: "No display supports brightness controls"
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.small
        color: Qt.darker(C.Config.theme.on_surface)
      }

      Spacerr {}

      CW.StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 20
        text: "Night Light"
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.pointSize: C.Config.fontSize.h2
        color: C.Config.theme.on_surface
      }

      Spacerr {}

      CW.HorizontalLine {}

      Spacerr {}

      CW.ValueSwitch {
        Layout.fillWidth: true
        Layout.leftMargin: 18.5
        Layout.rightMargin: 15
        label: "Enable night light"
        checked: C.Config.misc.nightLightEnabled
        onToggled: {
          C.Config.misc.nightLightEnabled = checked;
          S.NightLightState.reloadHyprsunset();
        }
      }

      Spacerr {}

      BrightnessSlider {
        label: "Night light intensity"
        icon: "bedtime"
        Layout.fillWidth: true
        Layout.leftMargin: 15
        Layout.rightMargin: 15
        visible: opacity != 0
        value: C.Config.misc.nightLightIntense
        opacity: C.Config.misc.nightLightEnabled && !C.Config.misc.nightLightUseProfiles ? 1 : 0
        Layout.preferredHeight: C.Config.misc.nightLightEnabled && !C.Config.misc.nightLightUseProfiles ? implicitHeight : 0

        Behavior on opacity {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        onMoved: {
          C.Config.misc.nightLightIntense = value;
          S.NightLightState.setIntensity(value);
        }
      }

      Spacerr {
        Layout.preferredHeight: C.Config.misc.nightLightEnabled && !C.Config.misc.nightLightUseProfiles ? 11 : -1
        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_NORMAL
            easing.type: Easing.Linear
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }
      }

      CW.ValueSwitch {
        Layout.fillWidth: true
        Layout.leftMargin: 18.5
        Layout.rightMargin: 15
        visible: opacity != 0
        label: "Use profiles"
        sublabel: "Schedule temperature by time of day"
        checked: C.Config.misc.nightLightUseProfiles
        opacity: C.Config.misc.nightLightEnabled ? 1 : 0
        Layout.preferredHeight: C.Config.misc.nightLightEnabled ? implicitHeight : 0

        Behavior on opacity {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        onToggled: {
          C.Config.misc.nightLightUseProfiles = checked;
          S.NightLightState.reloadHyprsunset();
        }
      }

      Spacerr {
        Layout.preferredHeight: profilesVisible ? 11 : -1
        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.Linear
          }
        }
      }

      ColumnLayout {
        id: profilesColumn
        Layout.fillWidth: true
        Layout.leftMargin: 15
        Layout.rightMargin: 15
        spacing: 8
        visible: opacity != 0
        opacity: profilesVisible ? 1 : 0
        Layout.preferredHeight: profilesVisible ? implicitHeight : 0

        Behavior on opacity {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.BezierSpline
            easing.bezierCurve: C.Globals.anim_CURVE_SMOOTH_SLIDE
          }
        }

        Repeater {
          // revision trick: changing the model ref forces full delegate recreation
          model: profilesRevision, C.Config.misc.nightLightProfiles

          Rectangle {
            id: profileDelegate
            required property int index
            required property var modelData

            Layout.fillWidth: true
            radius: 6
            color: C.Config.applySecondaryOpacity(Qt.lighter(C.Config.theme.surface_container, 1.4))
            implicitHeight: profileLayout.implicitHeight + 16

            ColumnLayout {
              id: profileLayout
              anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 8
              }
              spacing: 4

              RowLayout {
                Layout.fillWidth: true

                CW.StyledText {
                  text: "Profile " + (profileDelegate.index + 1)
                  font.bold: true
                  font.pointSize: C.Config.fontSize.small
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                  width: 24
                  height: 24
                  radius: 12
                  color: removeArea.containsMouse ? Qt.lighter(C.Config.theme.surface_container, 1.5) : Qt.lighter(C.Config.theme.surface_container, 1.2)

                  Behavior on color {
                    ColorAnimation { duration: C.Globals.anim_FAST }
                  }

                  CW.FontIcon {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 14
                    color: C.Config.theme.secondary
                  }

                  MouseArea {
                    id: removeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      let profiles = C.Config.misc.nightLightProfiles;
                      profiles.splice(profileDelegate.index, 1);
                      C.Config.misc.nightLightProfiles = profiles;
                      updateProfiles(); // immediately
                    }
                  }
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CW.StyledText {
                  text: "Time"
                  font.pointSize: C.Config.fontSize.small
                }

                Rectangle {
                  Layout.preferredWidth: 70
                  Layout.preferredHeight: 26
                  color: C.Config.applySecondaryOpacity(C.Config.theme.surface_container)
                  radius: 4

                  TextField {
                    anchors.fill: parent
                    anchors.margins: 2
                    text: profileDelegate.modelData.time
                    font.pointSize: C.Config.fontSize.small
                    color: C.Config.theme.on_surface
                    background: Item {}
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    onTextEdited: {
                      let profiles = C.Config.misc.nightLightProfiles;
                      profiles[profileDelegate.index] = Object.assign({}, profiles[profileDelegate.index], {"time": text});
                      resetProfileTimer();
                    }
                  }
                }

                Item { Layout.fillWidth: true }

                CW.StyledText {
                  text: "Identity"
                  font.pointSize: C.Config.fontSize.small
                }

                CW.StyledSwitch {
                  checked: profileDelegate.modelData.temperature === -1
                  onToggled: {
                    let profiles = C.Config.misc.nightLightProfiles;
                    profiles[profileDelegate.index] = Object.assign({}, profiles[profileDelegate.index], {"temperature": checked ? -1 : 3500});
                    updateProfiles(); // immediately
                  }
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                visible: profileDelegate.modelData.temperature !== -1
                spacing: 2

                RowLayout {
                  Layout.fillWidth: true

                  CW.StyledText {
                    text: "Temperature"
                    font.pointSize: C.Config.fontSize.small
                  }

                  Item { Layout.fillWidth: true }

                  CW.StyledText {
                    text: Math.round(tempSlider.value) + "K"
                    font.pointSize: C.Config.fontSize.small
                    horizontalAlignment: Text.AlignRight
                  }
                }

                CW.StyledSlider {
                  id: tempSlider
                  Layout.fillWidth: true
                  from: 2500
                  to: 4000
                  value: profileDelegate.modelData.temperature
                  onMoved: {
                    let profiles = C.Config.misc.nightLightProfiles;
                    profiles[profileDelegate.index] = Object.assign({}, profiles[profileDelegate.index], {"temperature": Math.round(value)});
                    resetProfileTimer();
                  }
                }
              }
            }
          }
        }

        CW.StyledButton {
          Layout.alignment: Qt.AlignHCenter
          label: "+ Add profile"
          onClicked: {
            let profiles = C.Config.misc.nightLightProfiles;
            profiles.push({"time": "12:00", "temperature": 6500});
            C.Config.misc.nightLightProfiles = profiles;
            updateProfiles(); // immediately
          }
        }
      }

      Spacerr {
        Layout.preferredHeight: profilesVisible ? 11 : -1
        Behavior on Layout.preferredHeight {
          NumberAnimation {
            duration: C.Globals.anim_SLOW
            easing.type: Easing.Linear
          }
        }
      }
    }
  }

  property bool profilesVisible: C.Config.misc.nightLightEnabled && C.Config.misc.nightLightUseProfiles

  // this is horrible but QML has forced my hand.
  component Spacerr: Item {
    Layout.preferredHeight: 11
  }
}
