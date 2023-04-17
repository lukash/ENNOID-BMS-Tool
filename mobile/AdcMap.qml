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

import Ennoid.bmsinterface 1.0
import Ennoid.commands 1.0
import Ennoid.configparams 1.0

Item {
    property int parentWidth: 10
    property real vMin: 0.0
    property real vMax: 0.0
    property real vCenter: 0.0
    property real vNow: 0.0
    property real valueNow: 0.5
    property real vMin2: 0.0
    property real vMax2: 0.0
    property real vNow2: 0.0
    property real valueNow2: 0.5
    property bool resetDone: true

    property Commands mCommands: VescIf.commands()
    property ConfigParams mAppConf: VescIf.appConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()

    function openDialog() {
        dialog.open()
    }

    function updateDisplay() {
        resultArea.text =
                "Value  : " + parseFloat(valueNow).toFixed(2) + "\n" +
                "Value2 : " + parseFloat(valueNow2).toFixed(2) + "\n\n" +
                "Now    : " + parseFloat(vNow).toFixed(2) + " V\n" +
                "Min    : " + parseFloat(vMin).toFixed(2) + " V\n" +
                "Max    : " + parseFloat(vMax).toFixed(2) + " V\n" +
                "Center : " + parseFloat(vCenter).toFixed(2) + " V\n\n" +
                "Now2   : " + parseFloat(vNow2).toFixed(2) + " V\n" +
                "Min2   : " + parseFloat(vMin2).toFixed(2) + " V\n" +
                "Max2   : " + parseFloat(vMax2).toFixed(2) + " V"

        valueBar.value = valueNow
        valueBar2.value = valueNow2
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

                TextArea {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    readOnly: true
                    wrapMode: TextEdit.WordWrap
                    font.family: "DejaVu Sans Mono"
                }

                ProgressBar {
                    id: valueBar
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    from: 0.0
                    to: 1.0
                    value: 0.0
                }

                ProgressBar {
                    id: valueBar2
                    Layout.fillWidth: true
                    from: 0.0
                    to: 1.0
                    value: 0.0
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Help"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            VescIf.emitMessageDialog(
                                        mInfoConf.getLongName("app_adc_mapping_help"),
                                        mInfoConf.getDescription("app_adc_mapping_help"),
                                        true, true)
                        }
                    }

                    Button {
                        text: "Reset"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            vMin = 0.0
                            vMax = 0.0
                            vCenter = 0.0
                            vMin2 = 0.0
                            vMax2 = 0.0
                            resetDone = true
                            updateDisplay()
                        }
                    }
                }

                Button {
                    text: "Apply & Write"
                    Layout.fillWidth: true
                    onClicked: {
                        mAppConf.updateParamDouble("app_adc_conf.voltage_start", vMin)
                        mAppConf.updateParamDouble("app_adc_conf.voltage_end", vMax)
                        mAppConf.updateParamDouble("app_adc_conf.voltage_center", vCenter)
                        mAppConf.updateParamDouble("app_adc_conf.voltage2_start", vMin2)
                        mAppConf.updateParamDouble("app_adc_conf.voltage2_end", vMax2)
                        VescIf.emitStatusMessage("Start, End and Center ADC Voltages Applied", true)
                        mCommands.setAppConf()
                    }
                }
            }
        }
    }

    Timer {
        id: rtTimer
        interval: 50
        running: true
        repeat: true

        onTriggered: {
            if (VescIf.isPortConnected() && dialog.visible) {
                mCommands.getDecodedAdc()
            }
        }
    }

    Connections {
        target: mCommands

        onDecodedAdcReceived: {
            valueNow = value
            vNow = voltage
            valueNow2 = value2
            vNow2 = voltage2

            if (resetDone) {
                resetDone = false
                vMin = vNow
                vMax = vNow
                vMin2 = vNow2
                vMax2 = vNow2
            }

            if (vNow < vMin) {
                vMin = vNow
            }

            if (vNow > vMax) {
                vMax = vNow
            }

            var range = vMax - vMin
            var pos = vNow - vMin

            if (pos > (range / 4.0) && pos < ((3.0 * range) / 4.0)) {
                vCenter = vNow
            } else {
                vCenter = range / 2.0 + vMin
            }

            if (vNow2 < vMin2) {
                vMin2 = vNow2
            }

            if (vNow2 > vMax2) {
                vMax2 = vNow2
            }

            updateDisplay()
        }
    }
}
