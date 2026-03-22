import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: 800
    height: 480
    id: root
    property var telemetry

    // Diagnostic Background (Slightly different from Driver page)
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0c" // Deep, almost black, engineering grey

        // Optional: Draw a subtle grid line pattern for that "Telemetry" feel
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#1a1a1f"
                ctx.lineWidth = 1
                for (var x = 0; x < width; x += 40) {
                    ctx.beginPath()
                    ctx.moveTo(x, 0)
                    ctx.lineTo(x, height)
                    ctx.stroke()
                }
                for (var y = 0; y < height; y += 40) {
                    ctx.beginPath()
                    ctx.moveTo(0, y)
                    ctx.lineTo(width, y)
                    ctx.stroke()
                }
            }
        }
    }

    // ==========================================
    // TOP NAVIGATION MENU (THE TABS)
    // ==========================================
    RowLayout {
        id: topNav
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 50
        spacing: 2 // Creates a tiny gap between tabs

        // Custom Tab Button 1: Accumulator
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: swipeView.currentIndex === 0 ? "#ffcc00" : "#222222"

            Text {
                anchors.centerIn: parent
                text: "ACCUMULATOR"
                color: swipeView.currentIndex === 0 ? "black" : "#888888"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
            }
            MouseArea {
                anchors.fill: parent
                onClicked: swipeView.currentIndex = 0
            }
        }

        // Custom Tab Button 2: Powertrain & Tyres
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: swipeView.currentIndex === 1 ? "#00ffcc" : "#222222"

            Text {
                anchors.centerIn: parent
                text: "POWERTRAIN"
                color: swipeView.currentIndex === 1 ? "black" : "#888888"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
            }
            MouseArea {
                anchors.fill: parent
                onClicked: swipeView.currentIndex = 1
            }
        }

        // Custom Tab Button 3: CAN Bus (Placeholder for future)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: swipeView.currentIndex === 2 ? "#ffffff" : "#222222"

            Text {
                anchors.centerIn: parent
                text: "CAN DATA"
                color: swipeView.currentIndex === 2 ? "black" : "#888888"
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
            }
            MouseArea {
                anchors.fill: parent
                onClicked: swipeView.currentIndex = 2
            }
        }
    }

    // ==========================================
    // THE SWIPEVIEW (CONTENT PAGES)
    // ==========================================
    SwipeView {
        id: swipeView
        anchors.top: topNav.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: 0
        interactive: false // Disables swiping so they MUST use the exact tabs!
        clip: true

        // --- PAGE 0: ACCUMULATOR ---
        Item {
            id: accumulatorTab

            property real globalMinV: 99.0
            property real globalMaxV: 0.0
            property real globalMaxT: 0.0

            // 1. THE MOCK DATA MODEL
            ListModel {
                id: cellModel
                ListElement { name: "S01"; minV: 3.91; maxV: 3.95; temp: 45.2 }
                ListElement { name: "S02"; minV: 3.92; maxV: 3.96; temp: 46.1 }
                ListElement { name: "S03"; minV: 3.82; maxV: 3.94; temp: 45.8 }
                ListElement { name: "S04"; minV: 3.91; maxV: 3.95; temp: 47.0 }
                ListElement { name: "S05"; minV: 3.90; maxV: 3.96; temp: 46.5 }
                ListElement { name: "S06"; minV: 3.91; maxV: 3.95; temp: 58.4 }
                ListElement { name: "S07"; minV: 3.92; maxV: 3.97; temp: 46.2 }
                ListElement { name: "S08"; minV: 3.93; maxV: 4.02; temp: 45.9 }
                ListElement { name: "S09"; minV: 3.91; maxV: 3.95; temp: 46.1 }
                ListElement { name: "S10"; minV: 3.92; maxV: 3.96; temp: 45.5 }
                ListElement { name: "S11"; minV: 3.91; maxV: 3.95; temp: 46.0 }
                ListElement { name: "S12"; minV: 3.92; maxV: 3.96; temp: 45.7 }
            }

            Component.onCompleted: {
                var tempMinV = 99.0; var tempMaxV = 0.0; var tempMaxT = 0.0;
                for (var i = 0; i < cellModel.count; i++) {
                    var item = cellModel.get(i);
                    if (item.minV < tempMinV) tempMinV = item.minV;
                    if (item.maxV > tempMaxV) tempMaxV = item.maxV;
                    if (item.temp > tempMaxT) tempMaxT = item.temp;
                }
                globalMinV = tempMinV; globalMaxV = tempMaxV; globalMaxT = tempMaxT;
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                anchors.topMargin: 10
                spacing: 40

                // ==========================================
                // LEFT SIDE: The Scrollable Data Grid
                // ==========================================
                ColumnLayout {
                    Layout.preferredWidth: 460 // Slightly widened for comfort
                    Layout.fillHeight: true    // Forces this column to take full vertical space
                    spacing: 8

                    // FIXED TABLE HEADER (Never scrolls)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "SEG"; color: "#777777"; font.pixelSize: 15; font.bold: true; Layout.preferredWidth: 60 }
                            Text { text: "MIN (V)"; color: "#777777"; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: "MAX (V)"; color: "#777777"; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: "MAX TEMP"; color: "#777777"; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
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
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 38
                            radius: 6
                            color: index % 2 === 0 ? "#0a1525" : "transparent"

                            property string cellName: "S" + (index + 1).toString().padStart(2, '0')

                            // 1. RAW DATA (Snaps instantly for the color logic)
                            property real rawMinV: {
                                if (!root.telemetry) return 0.0;
                                switch(index) {
                                case 0: return root.telemetry.cell1MinV; case 1: return root.telemetry.cell2MinV;
                                                                         case 2: return root.telemetry.cell3MinV; case 3: return root.telemetry.cell4MinV;
                                                                                                                  case 4: return root.telemetry.cell5MinV; case 5: return root.telemetry.cell6MinV;
                                                                                                                                                           case 6: return root.telemetry.cell7MinV; case 7: return root.telemetry.cell8MinV;
                                                                                                                                                                                                    case 8: return root.telemetry.cell9MinV; case 9: return root.telemetry.cell10MinV;
                                                                                                                                                                                                                                             case 10: return root.telemetry.cell11MinV; case 11: return root.telemetry.cell12MinV;
                                                                                                                                                                                                                                                                                        default: return 0.0;
                                }
                            }
                            property real rawMaxV: {
                                if (!root.telemetry) return 0.0;
                                switch(index) {
                                case 0: return root.telemetry.cell1MaxV; case 1: return root.telemetry.cell2MaxV;
                                                                         case 2: return root.telemetry.cell3MaxV; case 3: return root.telemetry.cell4MaxV;
                                                                                                                  case 4: return root.telemetry.cell5MaxV; case 5: return root.telemetry.cell6MaxV;
                                                                                                                                                           case 6: return root.telemetry.cell7MaxV; case 7: return root.telemetry.cell8MaxV;
                                                                                                                                                                                                    case 8: return root.telemetry.cell9MaxV; case 9: return root.telemetry.cell10MaxV;
                                                                                                                                                                                                                                             case 10: return root.telemetry.cell11MaxV; case 11: return root.telemetry.cell12MaxV;
                                                                                                                                                                                                                                                                                        default: return 0.0;
                                }
                            }
                            property real rawTemp: {
                                if (!root.telemetry) return 0.0;
                                switch(index) {
                                case 0: return root.telemetry.cell1Temp; case 1: return root.telemetry.cell2Temp;
                                                                         case 2: return root.telemetry.cell3Temp; case 3: return root.telemetry.cell4Temp;
                                                                                                                  case 4: return root.telemetry.cell5Temp; case 5: return root.telemetry.cell6Temp;
                                                                                                                                                           case 6: return root.telemetry.cell7Temp; case 7: return root.telemetry.cell8Temp;
                                                                                                                                                                                                    case 8: return root.telemetry.cell9Temp; case 9: return root.telemetry.cell10Temp;
                                                                                                                                                                                                                                             case 10: return root.telemetry.cell11Temp; case 11: return root.telemetry.cell12Temp;
                                                                                                                                                                                                                                                                                        default: return 0.0;
                                }
                            }

                            // 2. ANIMATED DATA (Smoothly interpolates for the Text rendering)
                            property real animMinV: rawMinV
                            Behavior on animMinV { NumberAnimation { duration: 250 } }

                            property real animMaxV: rawMaxV
                            Behavior on animMaxV { NumberAnimation { duration: 250 } }

                            property real animTemp: rawTemp
                            Behavior on animTemp { NumberAnimation { duration: 250 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10

                                Text { text: cellName; color: "#00ffcc"; font.pixelSize: 18; font.bold: true; Layout.preferredWidth: 50 }

                                // Text reads the smoothly Animated variable, but the Color relies on the instant Raw variable!
                                Text {
                                    text: animMinV.toFixed(3)
                                    color: (root.telemetry && rawMinV === root.telemetry.minCellVoltage) ? "#ff3333" : "white"
                                    font.pixelSize: 18; font.bold: true; font.family: "Menlo"; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    text: animMaxV.toFixed(3)
                                    color: (root.telemetry && rawMaxV === root.telemetry.maxCellVoltage) ? "#ff3333" : "white"
                                    font.pixelSize: 18; font.bold: true; font.family: "Menlo"; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    text: animTemp.toFixed(1) + " °C"
                                    color: (root.telemetry && rawTemp === root.telemetry.maxCellTemp) ? "#ff3333" : "white"
                                    font.pixelSize: 18; font.bold: true; font.family: "Menlo"; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight
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
                        spacing: -5; Layout.alignment: Qt.AlignHCenter
                        Text { text: "TOTAL POWER"; color: "#777777"; font.pixelSize: 16; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Text {
                                property real calcPower: root.telemetry ? (root.telemetry.voltage * root.telemetry.currentDc / 1000.0) : 0.0
                                Behavior on calcPower { NumberAnimation { duration: 250 } }
                                text: calcPower.toFixed(1)
                                color: "#ffcc00"; font.pixelSize: 65; font.bold: true
                            }
                            Text { text: "kW"; color: "gray"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 10 }
                        }
                    }

                    // TOTAL VOLTAGE
                    ColumnLayout {
                        spacing: -5; Layout.alignment: Qt.AlignHCenter
                        Text { text: "TOTAL VOLTAGE"; color: "#777777"; font.pixelSize: 16; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Text {
                                property real animVolts: root.telemetry ? root.telemetry.voltage : 0.0
                                Behavior on animVolts { NumberAnimation { duration: 250 } }
                                text: animVolts.toFixed(1)
                                color: "white"; font.pixelSize: 65; font.bold: true
                            }
                            Text { text: "V"; color: "gray"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 10 }
                        }
                    }

                    // TOTAL CURRENT
                    ColumnLayout {
                        spacing: -5; Layout.alignment: Qt.AlignHCenter
                        Text { text: "DC CURRENT"; color: "#777777"; font.pixelSize: 16; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Text {
                                property real animAmps: root.telemetry ? root.telemetry.currentDc : 0.0
                                Behavior on animAmps { NumberAnimation { duration: 250 } }
                                text: animAmps.toFixed(1)
                                color: "white"; font.pixelSize: 65; font.bold: true
                            }
                            Text { text: "A"; color: "gray"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 10 }
                        }
                    }
                }
            }
        }
        // --- PAGE 1: POWERTRAIN ---
        Item {
            Item {
                anchors.fill: parent
                anchors.margins: 20

                // 1. REUSABLE 4WD WHEEL DATA BOX COMPONENT
                // 1. REUSABLE 4WD WHEEL DATA BOX COMPONENT (UPGRADED)
                Component {
                    id: wheelDataBox
                    Rectangle {
                        id: boxRoot
                        width: 195 // Widened to comfortably fit the graph
                        height: 145
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

                        // Graph settings
                        property int maxTorque: 200 // Set your car's max physical Nm per wheel here
                        property bool isLeftSide: wheelName === "FL"
                                                  || wheelName === "RL"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            // Mirrors the layout automatically so the graph is always closest to the car
                            layoutDirection: boxRoot.isLeftSide ? Qt.LeftToRight : Qt.RightToLeft

                            // --- COLUMN 1: THE TEXT DATA ---
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                // TYRE PRESSURE & TEMP HEADER
                                Text {
                                    text: boxRoot.wheelName + " TYRE: " + boxRoot.tyrePress.toFixed(
                                              1) + "b  " + boxRoot.tyreTemp.toFixed(
                                              0) + "°C"
                                    color: (boxRoot.tyrePress < 1.0
                                            || boxRoot.tyreTemp > 90) ? "#ff3333" : "#00ffcc"
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.alignment: boxRoot.alignFlag
                                    Layout.bottomMargin: 4
                                }
                                // RPM
                                RowLayout {
                                    Layout.alignment: boxRoot.alignFlag
                                    Text {
                                        text: "RPM:"
                                        color: "#8899aa"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        text: boxRoot.rpm
                                        color: "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                // REQUESTED TORQUE
                                RowLayout {
                                    Layout.alignment: boxRoot.alignFlag
                                    Text {
                                        text: "TRQ REQ:"
                                        color: "#8899aa"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        text: boxRoot.torqueReq + " Nm"
                                        color: "#ffcc00"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                // ACTUAL TORQUE
                                RowLayout {
                                    Layout.alignment: boxRoot.alignFlag
                                    Text {
                                        text: "TRQ ACT:"
                                        color: "#8899aa"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        text: boxRoot.torqueAct + " Nm"
                                        color: "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                // MOTOR TEMP
                                RowLayout {
                                    Layout.alignment: boxRoot.alignFlag
                                    Text {
                                        text: "MOTOR:"
                                        color: "#8899aa"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        text: boxRoot.motorTemp.toFixed(
                                                  1) + " °C"
                                        color: boxRoot.motorTemp > 65 ? "#ff3333" : "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                                // IGBT TEMP
                                RowLayout {
                                    Layout.alignment: boxRoot.alignFlag
                                    Text {
                                        text: "IGBT:"
                                        color: "#8899aa"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        text: boxRoot.igbtTemp.toFixed(
                                                  1) + " °C"
                                        color: boxRoot.igbtTemp > 60 ? "#ff3333" : "white"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                            }

                            // --- COLUMN 2: THE DYNAMIC TORQUE GRAPH ---
                            Item {
                                Layout.preferredWidth: 12
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
                                    property real torqueRatio: Math.min(
                                                                   Math.abs(
                                                                       boxRoot.torqueAct)
                                                                   / boxRoot.maxTorque,
                                                                   1.0)
                                    property real dynamicHeight: centerPoint * torqueRatio

                                    height: dynamicHeight

                                    // Logic: If positive, anchor to center and grow UP. If negative, anchor to center and grow DOWN.
                                    y: boxRoot.torqueAct
                                       >= 0 ? centerPoint - dynamicHeight : centerPoint

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
                Canvas {
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
                }

                // 3. THE CAR WIREFRAME
                Item {
                    id: carWireframe
                    anchors.centerIn: parent
                    width: 240  // This controls the physical horizontal gap between the Left and Right panels
                    height: 340 // This controls the physical vertical gap between the Front and Rear panels

                    Image {
                        id: topdownImage
                        anchors.centerIn: parent
                        // Tweak these two numbers to make the car perfectly fill the center space.
                        width: 405
                        height: 585

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
                        item.wheelName = "FL"
                        item.alignFlag = Qt.AlignRight
                        item.tyrePress = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyrePressFL : 0.0)
                                    || 0.0
                        })
                        item.tyreTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyreTempFL : 0.0)
                                    || 0.0
                        })
                        item.rpm = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.rpmFL : 0)
                                    || 0
                        })
                        item.torqueReq = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueReqFL : 0)
                                    || 0
                        })
                        item.torqueAct = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueActFL : 0)
                                    || 0
                        })
                        item.motorTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.motorTempFL : 0.0)
                                    || 0.0
                        })
                        item.igbtTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.igbtTempFL : 0.0)
                                    || 0.0
                        })
                    }
                }
                // FRONT RIGHT
                Loader {
                    anchors.left: carWireframe.right
                    anchors.top: carWireframe.top
                    anchors.leftMargin: 30
                    sourceComponent: wheelDataBox
                    onLoaded: {
                        item.wheelName = "FR"
                        item.alignFlag = Qt.AlignLeft
                        item.tyrePress = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyrePressFR : 0.0)
                                    || 0.0
                        })
                        item.tyreTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyreTempFR : 0.0)
                                    || 0.0
                        })
                        item.rpm = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.rpmFR : 0)
                                    || 0
                        })
                        item.torqueReq = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueReqFR : 0)
                                    || 0
                        })
                        item.torqueAct = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueActFR : 0)
                                    || 0
                        })
                        item.motorTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.motorTempFR : 0.0)
                                    || 0.0
                        })
                        item.igbtTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.igbtTempFR : 0.0)
                                    || 0.0
                        })
                    }
                }
                // REAR LEFT
                Loader {
                    anchors.right: carWireframe.left
                    anchors.bottom: carWireframe.bottom
                    anchors.rightMargin: 30
                    sourceComponent: wheelDataBox
                    onLoaded: {
                        item.wheelName = "RL"
                        item.alignFlag = Qt.AlignRight
                        item.tyrePress = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyrePressRL : 0.0)
                                    || 0.0
                        })
                        item.tyreTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyreTempRL : 0.0)
                                    || 0.0
                        })
                        item.rpm = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.rpmRL : 0)
                                    || 0
                        })
                        item.torqueReq = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueReqRL : 0)
                                    || 0
                        })
                        item.torqueAct = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueActRL : 0)
                                    || 0
                        })
                        item.motorTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.motorTempRL : 0.0)
                                    || 0.0
                        })
                        item.igbtTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.igbtTempRL : 0.0)
                                    || 0.0
                        })
                    }
                }
                // REAR RIGHT
                Loader {
                    anchors.left: carWireframe.right
                    anchors.bottom: carWireframe.bottom
                    anchors.leftMargin: 30
                    sourceComponent: wheelDataBox
                    onLoaded: {
                        item.wheelName = "RR"
                        item.alignFlag = Qt.AlignLeft
                        item.tyrePress = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyrePressRR : 0.0)
                                    || 0.0
                        })
                        item.tyreTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.tyreTempRR : 0.0)
                                    || 0.0
                        })
                        item.rpm = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.rpmRR : 0)
                                    || 0
                        })
                        item.torqueReq = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueReqRR : 0)
                                    || 0
                        })
                        item.torqueAct = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.torqueActRR : 0)
                                    || 0
                        })
                        item.motorTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.motorTempRR : 0.0)
                                    || 0.0
                        })
                        item.igbtTemp = Qt.binding(function () {
                            return (root.telemetry ? root.telemetry.igbtTempRR : 0.0)
                                    || 0.0
                        })
                    }
                }
            }
        }

        // --- PAGE 2: CAN DATA ---
        Item {
            Text {
                anchors.centerIn: parent
                text: "RAW HEX DATA LOG COMING SOON"
                color: "#888888"
                font.pixelSize: 24
            }
        }
    }
}
