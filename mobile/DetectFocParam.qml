/*
    Copyright 2018 Benjamin Vedder	benjamin@vedder.se

    This file is part of VESC Tool.

    VESC Tool is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    VESC Tool is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    */

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import Vedder.vesc.bmsinterface 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Item {
    property int parentWidth: 10
    property real res: 0.0
    property real ind: 0.0
    property real lambda: 0.0
    property real kp: 0.0
    property real ki: 0.0
    property real gain: 0.0

    property Commands mCommands: VescIf.commands()
    property ConfigParams mbmsConfig: VescIf.bmsConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()

    function openDialog() {
        dialog.open()
    }

    function updateDisplay() {
        resultArea.text =
                "R      : " + parseFloat(res * 1e3).toFixed(2) + " m\u03A9\n" +
                "L      : " + parseFloat(ind * 1e6).toFixed(2) + " µH\n" +
                "\u03BB      : " + parseFloat(lambda * 1e3).toFixed(3) + " mWb\n" +
                "KP     : " + parseFloat(kp).toFixed(4) + "\n" +
                "KI     : " + parseFloat(ki).toFixed(2) + "\n" +
                "Gain   : " + parseFloat(gain).toFixed(2)
    }

    function calcKpKi() {
        if (res < 1e-10) {
            VescIf.emitMessageDialog("Calculate Error",
                                     "R is 0. Please measure it first.",
                                     false, false)
            return;
        }

        if (ind < 1e-10) {
            VescIf.emitMessageDialog("Calculate Error",
                                     "L is 0. Please measure it first.",
                                     false, false)
            return;
        }

        // https://e2e.ti.com/blogs_/b/motordrivecontrol/archive/2015/07/20/teaching-your-pi-controller-to-behave-part-ii
        var tc = tcBox.realValue * 1e-6
        var bw = 1.0 / tc
        kp = ind * bw;
        ki = res * bw;

        updateDisplay()
    }

    function calcGain() {
        if (lambda < 1e-10) {
            VescIf.emitMessageDialog("Calculate Error",
                                     "\u03BB is 0. Please measure it first.",
                                     false, false)
            return;
        }

        gain = 0.001 / (lambda * lambda)

        updateDisplay()
    }

    function testConnected() {
        if (VescIf.isPortConnected()) {
            return true
        } else {
            VescIf.emitMessageDialog(
                        "Connection Error",
                        "The VESC is not connected. Please connect it to run detection.",
                        false, false)
            return false
        }
    }

    Component.onCompleted: {
        updateDisplay()
    }

    Dialog {
        id: dialog
        standardButtons: Dialog.Close
        modal: true
        focus: true
        width: parentWidth - 20
        height: Math.min(implicitHeight, column.height - 40)
        closePolicy: Popup.CloseOnEscape
        x: 10
        y: 10

        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: parent.width
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                DoubleSpinBox {
                    id: currentBox
                    Layout.fillWidth: true
                    decimals: 2
                    realValue: 5.0
                    realFrom: 0.0
                    realTo: 200.0
                    prefix: "I: "
                    suffix: " A"
                }

                DoubleSpinBox {
                    id: dutyBox
                    Layout.fillWidth: true
                    decimals: 2
                    realValue: 0.5
                    realFrom: 0.0
                    realTo: 1.0
                    realStepSize: 0.1
                    prefix: "D: "
                }

                DoubleSpinBox {
                    id: erpmBox
                    Layout.fillWidth: true
                    decimals: 1
                    realValue: 450.0
                    realFrom: 0.0
                    realTo: 20000.0
                    realStepSize: 10.0
                    prefix: "\u03C9: "
                    suffix: " ERPM"
                }

                DoubleSpinBox {
                    id: tcBox
                    Layout.fillWidth: true
                    decimals: 1
                    realValue: 1000.0
                    realFrom: 0.0
                    realTo: 1000000.0
                    realStepSize: 100.0
                    prefix: "T: "
                    suffix: " µS"
                }

                Button {
                    text: "Help"
                    Layout.fillWidth: true
                    onClicked: {
                        VescIf.emitMessageDialog(
                                    mInfoConf.getLongName("help_foc_detect"),
                                    mInfoConf.getDescription("help_foc_detect"),
                                    true, true)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Detect R&L"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            if (!testConnected()) {
                                return
                            }

                            detectRlDialog.open()
                        }
                    }

                    Button {
                        text: "DETECT \u03BB"
                        font.capitalization: Font.MixedCase
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            if (!testConnected()) {
                                return
                            }

                            if (res < 1e-9) {
                                VescIf.emitMessageDialog("Detect",
                                                         "R is 0. Please measure it first.",
                                                         false, false)
                            } else {
                                detectLambdaDialog.open()
                            }
                        }
                    }
                }

                Button {
                    text: "CALCULATE KP, KI AND \u03BB"
                    font.capitalization: Font.MixedCase
                    Layout.fillWidth: true
                    onClicked: {
                        calcKpKi()
                        calcGain()
                    }
                }

                TextArea {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    readOnly: true
                    font.family: "DejaVu Sans Mono"
                }

                Button {
                    text: "Apply & Close"
                    Layout.fillWidth: true
                    onClicked: {
                        if (res < 1e-10) {
                            VescIf.emitMessageDialog("Apply Error",
                                                     "R is 0. Please measure it first.",
                                                     false, false)
                            return
                        }

                        if (ind < 1e-10) {
                            VescIf.emitMessageDialog("Apply Error",
                                                     "L is 0. Please measure it first.",
                                                     false, false)
                            return
                        }

                        if (lambda < 1e-10) {
                            VescIf.emitMessageDialog("Apply Error",
                                                     "\u03BB is 0. Please measure it first.",
                                                     false, false)
                            return
                        }

                        calcKpKi()
                        calcGain()

                        mbmsConfig.updateParamDouble("foc_motor_r", res)
                        mbmsConfig.updateParamDouble("foc_motor_l", ind)
                        mbmsConfig.updateParamDouble("foc_motor_flux_linkage", lambda)
                        mbmsConfig.updateParamDouble("foc_current_kp", kp)
                        mbmsConfig.updateParamDouble("foc_current_ki", ki)
                        mbmsConfig.updateParamDouble("foc_observer_gain", gain * 1e6)

                        dialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: detectRlDialog
        standardButtons: Dialog.Ok
        modal: true
        focus: true
        width: parentWidth - 20
        closePolicy: Popup.CloseOnEscape
        title: "Measure R & L"

        x: 10
        y: dialog.y + dialog.height / 2 - height / 2

        Text {
            id: detectRlLabel
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "When measuring R & L the motor is going to make some noises, but " +
                "not rotate. These noises are completely normal, so don't unplug " +
                "anything unless you see smoke."
        }

        onAccepted: {
            mCommands.measureRL()
        }
    }

    Dialog {
        id: detectLambdaDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        width: parentWidth - 20
        closePolicy: Popup.CloseOnEscape
        title: "Warning"

        x: 10
        y: dialog.y + dialog.height / 2 - height / 2

        Text {
            id: detectLambdaLabel
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "<font color=\"red\">Warning: </font>" +
                "This is going to spin up the motor. Make " +
                "sure that nothing is in the way."
        }

        onAccepted: {
            mCommands.measureLinkage(currentBox.realValue, erpmBox.realValue, dutyBox.realValue, res)
        }
    }

    Connections {
        target: mCommands

        onMotorRLReceived: {
            if (r < 1e-9 && l < 1e-9) {
                VescIf.emitStatusMessage("Bad FOC Detection Result Received", false)
                VescIf.emitMessageDialog("Bad Detection Result",
                                         "Could not measure the motor resistance and inductance.",
                                         false, false)
            } else {
                VescIf.emitStatusMessage("FOC Detection Result Received", true)
                res = r
                ind = l * 1e-6
                calcKpKi()
            }
        }

        onMotorLinkageReceived: {
            if (flux_linkage < 1e-9) {
                VescIf.emitStatusMessage("Bad FOC Detection Result Received", false)
                VescIf.emitMessageDialog("Bad Detection Result",
                                         "Could not measure the flux linkage properly. Adjust " +
                                         "the start parameters according to the help text and try again.",
                                         false, false)
            } else {
                VescIf.emitStatusMessage("FOC Detection Result Received", true)
                lambda = flux_linkage
                calcGain()
            }
        }
    }
}
