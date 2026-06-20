import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    objectName: "powertrainPage"
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
        anchors.fill: parent
        Item {
            anchors.fill: parent
            anchors.margins: 20

            // 1. REUSABLE 4WD WHEEL DATA BOX COMPONENT
            // 1. REUSABLE 4WD WHEEL DATA BOX COMPONENT (UPGRADED)
            Component {
                id: wheelDataBox
                Rectangle {
                    id: boxRoot
                    width: 255 // Wider for bigger, more readable fonts (title removed)
                    height: 200 // fits 5 rows (RPM/torques + motor/IGBT temps) comfortably
                    color: "#cc050a15"
                    border.color: "#1a3344"
                    border.width: 1
                    radius: 8

                    // The 7 variables injected from C++
                    property string wheelName: "FL"
                    property real tyrePress: 0.0
                    property real tyreTemp: 0.0
                    property int rpm: 0
                    property int torqueReq: 0
                    property int torqueAct: 0
                    property real motorTemp: 0.0
                    property real igbtTemp: 0.0
                    property int alignFlag: Qt.AlignLeft
                    // CAN id feeding this wheel (RL=701 RR=702 FL=703 FR=704); set by the Loader.
                    property int sourceId: 0
                    property bool fresh: root.telemetry && (root.telemetry.freshTick, root.telemetry.isFresh(sourceId))

                    // Graph settings
                    property int maxTorque: 200 // Set your car's max physical Nm per wheel here
                    property bool isLeftSide: wheelName === "FL" || wheelName === "RL"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        // Mirrors the layout automatically so the graph is always closest to the car
                        layoutDirection: boxRoot.isLeftSide ? Qt.LeftToRight : Qt.RightToLeft

                        // --- COLUMN 1: THE TEXT DATA ---
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            /* WHEEL/TYRE TITLE + tyre pressure/temp removed for more text space.
                               Re-enable this block (and the tyrePress/tyreTemp bindings) when the car sends tyre data:
                            Text {
                                text: boxRoot.wheelName + " TYRE"
                                color: "#00ffcc"
                                font.pixelSize: 20
                                font.bold: true
                                font.letterSpacing: 1
                                Layout.alignment: Qt.AlignHCenter
                                Layout.bottomMargin: 4
                            }
                            Text {
                                text: boxRoot.wheelName + " TYRE: " + boxRoot.tyrePress.toFixed(1) + "b  " + boxRoot.tyreTemp.toFixed(0) + "°C"
                                color: (boxRoot.tyrePress < 1.0 || boxRoot.tyreTemp > 90) ? "#ff3333" : "#00ffcc"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                                Layout.bottomMargin: 4
                            }
                            */
                            // RPM

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "RPM:"
                                    color: "#8899aa"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    text: boxRoot.fresh ? boxRoot.rpm : "—"
                                    color: "white"
                                    font.pixelSize: 26
                                    font.bold: true
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                }
                            }
                            // REQUESTED TORQUE
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "TRQ REQ:"
                                    color: "#8899aa"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    text: boxRoot.fresh ? (boxRoot.torqueReq + " Nm") : "—"
                                    color: "#ffcc00"
                                    font.pixelSize: 26
                                    font.bold: true
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                }
                            }
                            // ACTUAL TORQUE
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "TRQ ACT:"
                                    color: "#8899aa"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    text: boxRoot.fresh ? (boxRoot.torqueAct + " Nm") : "—"
                                    color: "white"
                                    font.pixelSize: 26
                                    font.bold: true
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                }
                            }
                            // MOTOR TEMPERATURE
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "MOTOR:"
                                    color: "#8899aa"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    text: boxRoot.fresh ? (boxRoot.motorTemp.toFixed(1) + " °C") : "—"
                                    color: boxRoot.motorTemp > 65 ? "#ff3333" : "white"
                                    font.pixelSize: 26
                                    font.bold: true
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                }
                            }
                            // IGBT TEMPERATURE
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "IGBT:"
                                    color: "#8899aa"
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.preferredWidth: 85
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    text: boxRoot.fresh ? (boxRoot.igbtTemp.toFixed(1) + " °C") : "—"
                                    color: boxRoot.igbtTemp > 60 ? "#ff3333" : "white"
                                    font.pixelSize: 26
                                    font.bold: true
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // --- COLUMN 2: THE DYNAMIC TORQUE GRAPH ---
                        Item {
                            Layout.preferredWidth: 20 // increased thicccccness------
                            Layout.fillHeight: true
                            Layout.topMargin: 20 // Pushes the bar down to align with the actual torque text
                            Layout.bottomMargin: 5

                            // Dark Background Track
                            Rectangle {
                                anchors.fill: parent
                                color: "#0a111a"
                                border.color: "#334455"
                                border.width: 1
                                radius: 4
                            }

                            // The Center Zero-Line
                            Rectangle {
                                width: parent.width + 4
                                height: 2
                                color: "white"
                                anchors.centerIn: parent
                            }

                            // The Dynamic Bar
                            Rectangle {
                                width: parent.width
                                radius: 2

                                // Math to calculate height and position
                                property real centerPoint: parent.height / 2
                                property real torqueRatio: Math.min(Math.abs(boxRoot.torqueAct) / boxRoot.maxTorque, 1.0)
                                property real dynamicHeight: centerPoint * torqueRatio

                                height: dynamicHeight

                                // Logic: If positive, anchor to center and grow UP. If negative, anchor to center and grow DOWN.
                                y: boxRoot.torqueAct >= 0 ? centerPoint - dynamicHeight : centerPoint

                                // Logic: Neon Cyan for positive (Drive), Neon Red for negative (Regen)
                                color: boxRoot.torqueAct >= 0 ? "#00ffcc" : "#ff3333"

                                // Hardware Acceleration Smoothing
                                Behavior on height {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                Behavior on y {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutQuad
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 2. THE CONNECTOR LINES
            /*Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#1a3344"
                    ctx.lineWidth = 2

                    var cx = width / 2
                    var cy = height / 2

                    ctx.beginPath()
                    ctx.moveTo(cx - 105, cy - 55)
                    ctx.lineTo(cx - 150, cy - 90)
                    ctx.moveTo(cx + 105, cy - 55)
                    ctx.lineTo(cx + 150, cy - 90)
                    ctx.moveTo(cx - 100, cy + 150)
                    ctx.lineTo(cx - 150, cy + 120)
                    ctx.moveTo(cx + 100, cy + 150)
                    ctx.lineTo(cx + 150, cy + 120)
                    ctx.stroke()
                }
            }*/

            // 3. THE CAR WIREFRAME
            Item {
                id: carWireframe
                anchors.centerIn: parent
                width: 210  // Narrower so the wider wheel boxes have more room (controls L/R gap)
                height: 420 // Raised to 420 so the 200px-tall top & bottom boxes don't overlap (2x200 < 420)

                Image {
                    id: topdownImage
                    anchors.centerIn: parent
                    // Tweak these two numbers to make the car perfectly fill the center space.
                    width: 360
                    height: 520

                    anchors.horizontalCenterOffset: -10

                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/FormulaDash/assets/topdown.png"
                }

                // Loading Placeholder (Now sized to the 140x300 gap instead of the massive image)
                Rectangle {
                    anchors.fill: parent
                    color: "#050a15"
                    border.color: "#1a3344"
                    border.width: 2
                    radius: 10
                    visible: topdownImage.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: "CAR\nWIREFRAME\nAREA"
                        color: "#334455"
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // 4. THE FOUR WHEEL BOXES (Fully Wired to C++)
            // FRONT LEFT
            Loader {
                anchors.right: carWireframe.left
                anchors.top: carWireframe.top
                anchors.rightMargin: 30
                sourceComponent: wheelDataBox
                onLoaded: {
                    item.wheelName = "FL";
                    item.sourceId = 703;
                    item.alignFlag = Qt.AlignRight;
                    item.tyrePress = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyrePressFL : 0.0) || 0.0;
                    });
                    item.tyreTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyreTempFL : 0.0) || 0.0;
                    });
                    item.rpm = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.rpmFL : 0) || 0;
                    });
                    item.torqueReq = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueReqFL : 0) || 0;
                    });
                    item.torqueAct = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueActFL : 0) || 0;
                    });
                    item.motorTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.motorTempFL : 0.0) || 0.0;
                    });
                    item.igbtTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.igbtTempFL : 0.0) || 0.0;
                    });
                }
            }
            // FRONT RIGHT
            Loader {
                anchors.left: carWireframe.right
                anchors.top: carWireframe.top
                anchors.leftMargin: 30
                sourceComponent: wheelDataBox
                onLoaded: {
                    item.wheelName = "FR";
                    item.sourceId = 704;
                    item.alignFlag = Qt.AlignLeft;
                    item.tyrePress = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyrePressFR : 0.0) || 0.0;
                    });
                    item.tyreTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyreTempFR : 0.0) || 0.0;
                    });
                    item.rpm = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.rpmFR : 0) || 0;
                    });
                    item.torqueReq = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueReqFR : 0) || 0;
                    });
                    item.torqueAct = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueActFR : 0) || 0;
                    });
                    item.motorTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.motorTempFR : 0.0) || 0.0;
                    });
                    item.igbtTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.igbtTempFR : 0.0) || 0.0;
                    });
                }
            }
            // REAR LEFT
            Loader {
                anchors.right: carWireframe.left
                anchors.bottom: carWireframe.bottom
                anchors.rightMargin: 30
                sourceComponent: wheelDataBox
                onLoaded: {
                    item.wheelName = "RL";
                    item.sourceId = 701;
                    item.alignFlag = Qt.AlignRight;
                    item.tyrePress = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyrePressRL : 0.0) || 0.0;
                    });
                    item.tyreTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyreTempRL : 0.0) || 0.0;
                    });
                    item.rpm = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.rpmRL : 0) || 0;
                    });
                    item.torqueReq = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueReqRL : 0) || 0;
                    });
                    item.torqueAct = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueActRL : 0) || 0;
                    });
                    item.motorTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.motorTempRL : 0.0) || 0.0;
                    });
                    item.igbtTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.igbtTempRL : 0.0) || 0.0;
                    });
                }
            }
            // REAR RIGHT
            Loader {
                anchors.left: carWireframe.right
                anchors.bottom: carWireframe.bottom
                anchors.leftMargin: 30
                sourceComponent: wheelDataBox
                onLoaded: {
                    item.wheelName = "RR";
                    item.sourceId = 702;
                    item.alignFlag = Qt.AlignLeft;
                    item.tyrePress = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyrePressRR : 0.0) || 0.0;
                    });
                    item.tyreTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.tyreTempRR : 0.0) || 0.0;
                    });
                    item.rpm = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.rpmRR : 0) || 0;
                    });
                    item.torqueReq = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueReqRR : 0) || 0;
                    });
                    item.torqueAct = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.torqueActRR : 0) || 0;
                    });
                    item.motorTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.motorTempRR : 0.0) || 0.0;
                    });
                    item.igbtTemp = Qt.binding(function () {
                        return (root.telemetry ? root.telemetry.igbtTempRR : 0.0) || 0.0;
                    });
                }
            }
        }
    }
    // Paste the entire contents of what used to be the second Item in the SwipeView.
    // This includes Component { id: wheelDataBox }, the carWireframe Item, and the 4 Loaders.
    // Note: ensure you retain `anchors.fill: parent` and `anchors.margins: 20` on the top-level layout element.
}