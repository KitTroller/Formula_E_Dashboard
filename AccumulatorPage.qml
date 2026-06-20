import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "accumulatorPage"
    width: 800
    height: 480
    property var telemetry

    // Diagnostic Background
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0c"
        Image {
            anchors.fill: parent
            source: "qrc:/FormulaDash/assets/background_bold_1.png"
            fillMode: Image.Tile
            opacity: 0.3
        }
    }

    Item {
        id: accumulatorTab
        anchors.fill: parent

        property real globalMinV: 99.0
        property real globalMaxV: 0.0
        property real globalMaxT: 0.0

        // 1. THE MOCK DATA MODEL
        ListModel {
            id: cellModel
            ListElement {
                name: "S01"
                minV: 3.91
                maxV: 3.95
                temp: 45.2
            }
            ListElement {
                name: "S02"
                minV: 3.92
                maxV: 3.96
                temp: 46.1
            }
            ListElement {
                name: "S03"
                minV: 3.82
                maxV: 3.94
                temp: 45.8
            }
            ListElement {
                name: "S04"
                minV: 3.91
                maxV: 3.95
                temp: 47.0
            }
            ListElement {
                name: "S05"
                minV: 3.90
                maxV: 3.96
                temp: 46.5
            }
            ListElement {
                name: "S06"
                minV: 3.91
                maxV: 3.95
                temp: 58.4
            }
            ListElement {
                name: "S07"
                minV: 3.92
                maxV: 3.97
                temp: 46.2
            }
            ListElement {
                name: "S08"
                minV: 3.93
                maxV: 4.02
                temp: 45.9
            }
            ListElement {
                name: "S09"
                minV: 3.91
                maxV: 3.95
                temp: 46.1
            }
            ListElement {
                name: "S10"
                minV: 3.92
                maxV: 3.96
                temp: 45.5
            }
            ListElement {
                name: "S11"
                minV: 3.91
                maxV: 3.95
                temp: 46.0
            }
            ListElement {
                name: "S12"
                minV: 3.92
                maxV: 3.96
                temp: 45.7
            }
        }

        Component.onCompleted: {
            var tempMinV = 99.0;
            var tempMaxV = 0.0;
            var tempMaxT = 0.0;
            for (var i = 0; i < cellModel.count; i++) {
                var item = cellModel.get(i);
                if (item.minV < tempMinV)
                    tempMinV = item.minV;
                if (item.maxV > tempMaxV)
                    tempMaxV = item.maxV;
                if (item.temp > tempMaxT)
                    tempMaxT = item.temp;
            }
            globalMinV = tempMinV;
            globalMaxV = tempMaxV;
            globalMaxT = tempMaxT;
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            anchors.topMargin: 6
            spacing: 40

            // ==========================================
            // LEFT SIDE: The Scrollable Data Grid
            // ==========================================
            ColumnLayout {
                Layout.preferredWidth: 460 // Slightly widened for comfort
                Layout.fillHeight: true    // Forces this column to take full vertical space
                spacing: 4

                // FIXED TABLE HEADER (Never scrolls)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "SEG"
                            color: "#777777"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.preferredWidth: 60
                        }
                        Text {
                            text: "MIN (V)"
                            color: "#777777"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "MAX (V)"
                            color: "#777777"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                        }
                        Text {
                            text: "MAX TEMP"
                            color: "#777777"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    // The underline border is now safely managed by the ColumnLayout
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#334455"
                    }
                }

                // SCROLLABLE TABLE BODY (WIRED TO C++)
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Pass exactly 12 integers to generate 12 rows
                    model: 12
                    spacing: 1
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 36
                        radius: 6
                        color: index % 2 === 0 ? "#0a1525" : "transparent"

                        property string cellName: "S" + (index + 1).toString().padStart(2, '0')

                        // CAN source ids for this row's freshness check:
                        // cell voltages are paired per msg (1600=cells1&2, 1601=3&4, …);
                        // temps are grouped 4-per-msg (1606=1-4, 1607=5-8, 1608=9-12).
                        property int vMsgId: 1600 + Math.floor(index / 2)
                        property int tMsgId: 1606 + Math.floor(index / 4)
                        property bool vFresh: root.telemetry && (root.telemetry.freshTick, root.telemetry.isFresh(vMsgId))
                        property bool tFresh: root.telemetry && (root.telemetry.freshTick, root.telemetry.isFresh(tMsgId))

                        // 1. RAW DATA (Snaps instantly for the color logic)
                        property real rawMinV: {
                            if (!root.telemetry)
                                return 0.0;
                            switch (index) {
                            case 0:
                                return root.telemetry.cell1MinV;
                            case 1:
                                return root.telemetry.cell2MinV;
                            case 2:
                                return root.telemetry.cell3MinV;
                            case 3:
                                return root.telemetry.cell4MinV;
                            case 4:
                                return root.telemetry.cell5MinV;
                            case 5:
                                return root.telemetry.cell6MinV;
                            case 6:
                                return root.telemetry.cell7MinV;
                            case 7:
                                return root.telemetry.cell8MinV;
                            case 8:
                                return root.telemetry.cell9MinV;
                            case 9:
                                return root.telemetry.cell10MinV;
                            case 10:
                                return root.telemetry.cell11MinV;
                            case 11:
                                return root.telemetry.cell12MinV;
                            default:
                                return 0.0;
                            }
                        }
                        property real rawMaxV: {
                            if (!root.telemetry)
                                return 0.0;
                            switch (index) {
                            case 0:
                                return root.telemetry.cell1MaxV;
                            case 1:
                                return root.telemetry.cell2MaxV;
                            case 2:
                                return root.telemetry.cell3MaxV;
                            case 3:
                                return root.telemetry.cell4MaxV;
                            case 4:
                                return root.telemetry.cell5MaxV;
                            case 5:
                                return root.telemetry.cell6MaxV;
                            case 6:
                                return root.telemetry.cell7MaxV;
                            case 7:
                                return root.telemetry.cell8MaxV;
                            case 8:
                                return root.telemetry.cell9MaxV;
                            case 9:
                                return root.telemetry.cell10MaxV;
                            case 10:
                                return root.telemetry.cell11MaxV;
                            case 11:
                                return root.telemetry.cell12MaxV;
                            default:
                                return 0.0;
                            }
                        }
                        property real rawTemp: {
                            if (!root.telemetry)
                                return 0.0;
                            switch (index) {
                            case 0:
                                return root.telemetry.cell1Temp;
                            case 1:
                                return root.telemetry.cell2Temp;
                            case 2:
                                return root.telemetry.cell3Temp;
                            case 3:
                                return root.telemetry.cell4Temp;
                            case 4:
                                return root.telemetry.cell5Temp;
                            case 5:
                                return root.telemetry.cell6Temp;
                            case 6:
                                return root.telemetry.cell7Temp;
                            case 7:
                                return root.telemetry.cell8Temp;
                            case 8:
                                return root.telemetry.cell9Temp;
                            case 9:
                                return root.telemetry.cell10Temp;
                            case 10:
                                return root.telemetry.cell11Temp;
                            case 11:
                                return root.telemetry.cell12Temp;
                            default:
                                return 0.0;
                            }
                        }

                        // 2. ANIMATED DATA (Smoothly interpolates for the Text rendering)
                        property real animMinV: rawMinV
                        Behavior on animMinV {
                            NumberAnimation {
                                duration: 250
                            }
                        }

                        property real animMaxV: rawMaxV
                        Behavior on animMaxV {
                            NumberAnimation {
                                duration: 250
                            }
                        }

                        property real animTemp: rawTemp
                        Behavior on animTemp {
                            NumberAnimation {
                                duration: 250
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            Text {
                                text: cellName
                                color: "#00ffcc"
                                font.pixelSize: 20
                                font.bold: true
                                Layout.preferredWidth: 50
                            }

                            // Text reads the smoothly Animated variable, but the Color relies on the instant Raw variable!
                            Text {
                                text: vFresh ? animMinV.toFixed(3) : "—"
                                color: (root.telemetry && rawMinV === root.telemetry.minCellVoltage) ? "#ff3333" : "white"
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "Menlo"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: vFresh ? animMaxV.toFixed(3) : "—"
                                color: (root.telemetry && rawMaxV === root.telemetry.maxCellVoltage) ? "#ff3333" : "white"
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "Menlo"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: tFresh ? (animTemp.toFixed(1) + " °C") : "—"
                                color: (root.telemetry && rawTemp === root.telemetry.maxCellTemp) ? "#ff3333" : "white"
                                font.pixelSize: 20
                                font.bold: true
                                font.family: "Menlo"
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // ==========================================
            // RIGHT SIDE: Master Summary Stats (Fixed in place)
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                Layout.topMargin: 20
                spacing: 35 // Increased spacing since we have room

                // TOTAL POWER
                ColumnLayout {
                    spacing: -5
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "TOTAL POWER"
                        color: "#777777"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Text {
                            property real calcPower: root.telemetry ? (root.telemetry.voltage * root.telemetry.currentDc / 1000.0) : 0.0
                            Behavior on calcPower {
                                NumberAnimation {
                                    duration: 250
                                }
                            }
                            text: (root.telemetry && (root.telemetry.freshTick, root.telemetry.isFresh(1315))) ? calcPower.toFixed(1) : "—"
                            color: "#ffcc00"
                            font.pixelSize: 65
                            font.bold: true
                        }
                        Text {
                            text: "kW"
                            color: "gray"
                            font.pixelSize: 20
                            font.bold: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 10
                        }
                    }
                }

                // TOTAL VOLTAGE
                ColumnLayout {
                    spacing: -5
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "TOTAL VOLTAGE"
                        color: "#777777"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Text {
                            property real animVolts: root.telemetry ? root.telemetry.voltage : 0.0
                            Behavior on animVolts {
                                NumberAnimation {
                                    duration: 250
                                }
                            }
                            text: (root.telemetry && (root.telemetry.freshTick, root.telemetry.isFresh(1315))) ? animVolts.toFixed(1) : "—"
                            color: "white"
                            font.pixelSize: 65
                            font.bold: true
                        }
                        Text {
                            text: "V"
                            color: "gray"
                            font.pixelSize: 20
                            font.bold: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 10
                        }
                    }
                }

                // TOTAL CURRENT
                ColumnLayout {
                    spacing: -5
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "DC CURRENT"
                        color: "#777777"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Text {
                            property real animAmps: root.telemetry ? root.telemetry.currentDc : 0.0
                            Behavior on animAmps {
                                NumberAnimation {
                                    duration: 250
                                }
                            }
                            text: (root.telemetry && (root.telemetry.freshTick, root.telemetry.isFresh(1315))) ? animAmps.toFixed(1) : "—"
                            color: "white"
                            font.pixelSize: 65
                            font.bold: true
                        }
                        Text {
                            text: "A"
                            color: "gray"
                            font.pixelSize: 20
                            font.bold: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 10
                        }
                    }
                }
            }
        }
    }
}