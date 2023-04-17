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
    property real mOffset: 0.0
    property real mRatio: 0.0
    property bool mInverted: false

    property Commands mCommands: VescIf.commands()
    property ConfigParams mbmsConfig: VescIf.bmsConfig()
    property ConfigParams mInfoConf: VescIf.infoConfig()

    function openDialog() {
        dialog.open()
    }

    function updateDisplay() {
        resultArea.text =
                "Offset   : " + parseFloat(mOffset).toFixed(1) + "\n" +
                "Ratio    : " + parseFloat(mRatio).toFixed(1) + "\n" +
                "Inverted : " + mInverted
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
                    realValue: 10.0
                    realFrom: 0.0
                    realTo: 200.0
                    prefix: "I: "
                    suffix: " A"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Help"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            VescIf.emitMessageDialog(
                                        mInfoConf.getLongName("help_foc_encoder_detect"),
                                        mInfoConf.getDescription("help_foc_encoder_detect"),
                                        true, true)
                        }
                    }

                    Button {
                        text: "Detect"
                        Layout.preferredWidth: 50
                        Layout.fillWidth: true
                        onClicked: {
                            if (!testConnected()) {
                                return
                            }

                            detectDialog.open()
                        }
                    }
                }

                TextArea {
                    id: resultArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    readOnly: true
                    wrapMode: TextEdit.WordWrap
                    font.family: "DejaVuSansMono"
                }

                Button {
                    text: "Apply & Close"
                    Layout.fillWidth: true
                    onClicked: {
                        mbmsConfig.updateParamDouble("foc_encoder_offset", mOffset)
                        mbmsConfig.updateParamDouble("foc_encoder_ratio", mRatio)
                        mbmsConfig.updateParamBool("foc_encoder_inverted", mInverted)

                        VescIf.emitStatusMessage("Encoder Parameters Applied", true)

                        dialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: detectDialog
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true
        width: parentWidth - 20
        closePolicy: Popup.CloseOnEscape
        title: "Detect FOC Encoder Parameters"

        x: 10
        y: dialog.y + dialog.height / 2 - height / 2

        Text {
            id: detectLambdaLabel
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            wrapMode: Text.WordWrap
            text:
                "This is going to turn the motor slowly. Make " +
                "sure that nothing is in the way."
        }

        onAccepted: {
            mCommands.measureEncoder(currentBox.realValue)
        }
    }

    Connections {
        target: mCommands

        onEncoderParamReceived: {
            if (offset > 1000.0) {
                VescIf.emitStatusMessage("Encoder not enabled in firmware", false)
                VescIf.emitMessageDialog("Error",
                                         "Encoder support is not enabled. Enable it in the general settings.",
                                         false, false)
            } else {
                VescIf.emitStatusMessage("Encoder Result Received", true)
                mOffset = offset
                mRatio = ratio
                mInverted = inverted
                updateDisplay()
            }
        }
    }
}
