/*
    Copyright 2018 - 2019 Benjamin Vedder	benjamin@vedder.se

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

import QtQuick 2.5
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0

import Ennoid.bmsinterface 1.0
import Ennoid.commands 1.0
import Ennoid.configparams 1.0

Item {
    id: rtData
    property Commands mCommands: VescIf.commands()
    property ConfigParams mbmsConfig: VescIf.bmsConfig()
    property bool isHorizontal: rtData.width > rtData.height

    property int gaugeSize: isHorizontal ? Math.min((height - valMetrics.height * 4) - 30, width / 3.5 - 10) :
                                           Math.min(width / 1.4,
                                                    (height - valMetrics.height * 4) / 2.3 - 10)


    property int gaugeSize2: gaugeSize * 0.65
    property int gaugeVMargin: isHorizontal ? 0 : -gaugeSize * 0.05
    property int gaugeHMargin: isHorizontal ? -gaugeSize * 0.1 : gaugeSize * 0.02

    Component.onCompleted: {
        mCommands.emitEmptySetupValues()
    }

    GridLayout {
        anchors.fill: parent
        anchors.topMargin: 5
        columns: isHorizontal ? 3 : 1
        columnSpacing: 0

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: gaugeVMargin
            Layout.preferredHeight: isHorizontal ? gaugeSize : gaugeSize2
            spacing: 0

            CustomGauge {
                id: powerGauge
                Layout.preferredWidth: gaugeSize2
                Layout.preferredHeight: gaugeSize2
                Layout.alignment: (isHorizontal ? Qt.AlignTop : Qt.AlignVCenter)
                Layout.rightMargin: gaugeHMargin
                maximumValue: 10000
                minimumValue: -10000
                tickmarkScale: 0.001
                tickmarkSuffix: "k"
                labelStep: 1000
                value: 1000
                unitText: "W"
                typeText: "Power"
            }

            CustomGauge {
                id: currentGauge
                Layout.preferredWidth: gaugeSize2
                Layout.preferredHeight: gaugeSize2
                Layout.alignment: isHorizontal ? Qt.AlignBottom : Qt.AlignVCenter
                Layout.rightMargin: gaugeHMargin
                minimumValue: 0
                maximumValue: 60
                labelStep: maximumValue > 60 ? 20 : 10
                unitText: "A"
                typeText: "Current"
            }
        }

        CustomGauge {
            id: speedGauge
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: gaugeSize
            Layout.preferredHeight: gaugeSize
            minimumValue: 0
            maximumValue: 60
            minAngle: -250
            maxAngle: 70
            labelStep: maximumValue > 60 ? 20 : 10
            value: 20
            unitText: "km/h"
            typeText: "Speed"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: gaugeVMargin
            Layout.preferredHeight: isHorizontal ? gaugeSize : gaugeSize2
            spacing: 0

            CustomGauge {
                id: batteryGauge
                Layout.preferredWidth: gaugeSize2
                Layout.preferredHeight: gaugeSize2
                Layout.alignment: isHorizontal ? Qt.AlignBottom : Qt.AlignVCenter
                Layout.leftMargin: gaugeHMargin
                minimumValue: 0
                maximumValue: 100
                value: 95
                unitText: "%"
                typeText: "Battery"
                traceColor: "green"
            }

            CustomGauge {
                id: dutyGauge
                Layout.preferredWidth: gaugeSize2
                Layout.preferredHeight: gaugeSize2
                Layout.alignment: isHorizontal ? Qt.AlignTop : Qt.AlignVCenter
                Layout.leftMargin: gaugeHMargin
                maximumValue: 100
                minimumValue: -100
                labelStep: 20
                value: 0
                unitText: "%"
                typeText: "Duty"
            }
        }

        Rectangle {
            id: textRect
            color: "#272727"

            Layout.fillWidth: true
            Layout.preferredHeight: valMetrics.height * 4 + 20
            Layout.alignment: Qt.AlignBottom
            Layout.columnSpan: isHorizontal ? 3 : 1

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 2
                color: "#81D4FA"
            }

            Text {
                id: valText
                color: "white"
                text: VescIf.getConnectedPortName()
                font.family: "DejaVu Sans Mono"
                verticalAlignment: Text.AlignVCenter
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
            }

            Text {
                id: valText2
                color: "white"
                text: VescIf.getConnectedPortName()
                font.family: "DejaVu Sans Mono"
                verticalAlignment: Text.AlignVCenter
                anchors.left: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
            }

            TextMetrics {
                id: valMetrics
                font: valText.font
                text: valText.text
            }
        }
    }

    Connections {
        target: mCommands

        onValuesSetupReceived: {
            currentGauge.maximumValue = Math.ceil(mbmsConfig.getParamDouble("maxAllowedCurrent") / 5) * 5 * values.num_vescs
            currentGauge.minimumValue = -currentGauge.maximumValue

            currentGauge.value = values.packCurrent
            dutyGauge.value = values.duty_now * 100.0
            batteryGauge.value = values.battery_level * 100.0

            var fl = mbmsConfig.getParamDouble("foc_motor_flux_linkage")
            var rpmMax = (values.v_in * 60.0) / (Math.sqrt(3.0) * 2.0 * Math.PI * fl)
            var speedFact = ((mbmsConfig.getParamInt("si_motor_poles") / 2.0) * 60.0 *
                    mbmsConfig.getParamDouble("si_gear_ratio")) /
                    (mbmsConfig.getParamDouble("si_wheel_diameter") * Math.PI)
            var speedMax = 3.6 * rpmMax / speedFact
            var speedMaxRound = (Math.ceil(speedMax / 10.0) * 10.0)

            if (Math.abs(speedGauge.maximumValue - speedMaxRound) > 6.0) {
                speedGauge.maximumValue = speedMaxRound
                speedGauge.minimumValue = -speedMaxRound
            }

            speedGauge.value = values.speed * 3.6

            var powerMax = Math.min(values.v_in * Math.min(mbmsConfig.getParamDouble("l_in_current_max"),
                                                           mbmsConfig.getParamDouble("l_current_max")),
                                    mbmsConfig.getParamDouble("l_watt_max")) * values.num_vescs
            var powerMaxRound = (Math.ceil(powerMax / 1000.0) * 1000.0)

            if (Math.abs(powerGauge.maximumValue - powerMaxRound) > 1.2) {
                powerGauge.maximumValue = powerMaxRound
                powerGauge.minimumValue = -powerMaxRound
            }

            powerGauge.value = (values.current_in * values.v_in)

            valText.text =
                    "mAh Out: " + parseFloat(values.amp_hours * 1000.0).toFixed(1) + "\n" +
                    "mAh In : " + parseFloat(values.amp_hours_charged * 1000.0).toFixed(1) + "\n" +
                    "Wh Out : " + parseFloat(values.watt_hours).toFixed(2) + "\n" +
                    "Wh In  : " + parseFloat(values.watt_hours_charged).toFixed(2)

            var wh_km = (values.watt_hours - values.watt_hours_charged) / (values.tachometer_abs / 1000.0)

            valText2.text =
                    "Km Trip : " + parseFloat(values.tachometer_abs / 1000.0).toFixed(3) + "\n" +
                    "Wh/Km   : " + parseFloat(wh_km).toFixed(1) + "\n" +
                    "Km Range: " + parseFloat(values.battery_wh / wh_km).toFixed(2) + "\n" +
                    "VESCs   : " + values.num_vescs
        }
    }
}
