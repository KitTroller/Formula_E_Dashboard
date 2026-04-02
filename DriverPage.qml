import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes    // Required for GPU-accelerated geometry
import QtQuick.Effects   // Required for MultiEffect (Drop shadows/glows)

Item {
    id: root
    width: 800
    height: 480

    property var telemetry

    Image {
        id: bgGrid
        anchors.fill: parent
        source: "qrc:/FormulaDash/assets/background_bold_1.png"
        fillMode: Image.PreserveAspectCrop
    }

    Image {
        id: teamLogo
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 10
        source: "qrc:/FormulaDash/assets/team_logo_right.png"
        width: 140
        fillMode: Image.PreserveAspectFit
    }

    Item {
        anchors.fill: parent
        anchors.margins: 20
        anchors.topMargin: 50 // Push the grid down slightly to clear the logo

        // ==========================================
        // LEFT COLUMN: Energy & Power
        // ==========================================
        ColumnLayout {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 220 // Explicit width constraint
            spacing: 25
            // --- STATE OF CHARGE (SoC) ---
            ColumnLayout {
                spacing: -10
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Layout.topMargin: -30 // Pull the WHOLE SoC block up!

                Text {
                    text: "SoC"
                    color: "#777777"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 2
                    Layout.leftMargin: 22
                }

                RowLayout {
                    spacing: 0

                    Image {
                        Layout.preferredWidth: 160 // MASSIVE INCREASE
                        Layout.preferredHeight: 80

                        // Negative margins eat invisible PNG padding
                        Layout.leftMargin: -30
                        Layout.rightMargin: -35
                        Layout.alignment: Qt.AlignVCenter

                        fillMode: Image.PreserveAspectFit
                        property real currentSoc: root.telemetry ? root.telemetry.soc : 0
                        source: {
                            if (currentSoc >= 85)
                                return "qrc:/FormulaDash/assets/battery_6.png";
                            if (currentSoc >= 68)
                                return "qrc:/FormulaDash/assets/battery_5.png";
                            if (currentSoc >= 51)
                                return "qrc:/FormulaDash/assets/battery_4.png";
                            if (currentSoc >= 34)
                                return "qrc:/FormulaDash/assets/battery_3.png";
                            if (currentSoc >= 17)
                                return "qrc:/FormulaDash/assets/battery_2.png";
                            if (currentSoc >= 5)
                                return "qrc:/FormulaDash/assets/battery_1.png";
                            return "qrc:/FormulaDash/assets/battery_0.png";
                        }
                    }

                    Text {
                        property real animatedSoc: root.telemetry ? root.telemetry.soc : 0
                        Behavior on animatedSoc {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                        text: Math.round(animatedSoc) + "%"
                        color: animatedSoc > 20 ? "#ffffff" : "#ff3333"
                        font.pixelSize: 32
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Space filler between SOC and Metrics
            Item {
                Layout.preferredHeight: 2
            }

            // --- ACCUMULATOR VOLTAGE & POWER TARGET ---
            ColumnLayout {
                Layout.topMargin: 5 // Gave it a little breathing room from the battery
                spacing: 15

                // 1. VOLTAGE BLOCK (Restored Text + Bolt + Huge Numbers)
                ColumnLayout {
                    spacing: -5
                    Text {
                        text: "ACCUMULATOR VOLTAGE"
                        color: "#777777"
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 1.5
                        Layout.leftMargin: 5 // Aligns the text with the numbers below
                    }
                    RowLayout {
                        spacing: -5 // Pulls Volt number close to the Bolt
                        Layout.leftMargin: -10 // Pulls the bolt slightly left

                        // DYNAMIC VOLTAGE BOLT
                        Image {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                            fillMode: Image.PreserveAspectFit

                            // CRITICAL VOLTAGE LOGIC: Evaluates directly against 350V threshold
                            property bool isCritical: root.telemetry ? (root.telemetry.voltage <= 350.0) : false
                            source: isCritical ? "qrc:/FormulaDash/assets/accumulator_voltage_warning.png" : "qrc:/FormulaDash/assets/accumulator_voltage_normal.png"
                        }

                        Text {
                            // 1. Catch the raw C++ data in a local property
                            property real animatedVoltage: root.telemetry ? root.telemetry.voltage : 0.0

                            // 2. Force QML to smoothly interpolate any changes over 250ms
                            Behavior on animatedVoltage {
                                NumberAnimation {
                                    duration: 250
                                }
                            }

                            // 3. Bind the text to the SMOOTH animated variable
                            text: animatedVoltage.toFixed(1) + " V"

                            // 4. Bind the color to the RAW variable so the red warning is instant!
                            color: (root.telemetry && root.telemetry.voltage <= 350.0) ? "#ff3333" : "white"

                            font.pixelSize: 45
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                // 2. POWER TARGET (Tightly underneath)
                ColumnLayout {
                    spacing: -5
                    Layout.leftMargin: 20
                    Text {
                        text: "POWER TARGET"
                        color: "#777777"
                        font.pixelSize: 14
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    Text {
                        text: (root.telemetry ? root.telemetry.powerTarget.toFixed(0) : "0") + " kW"
                        color: "#ffcc00"
                        font.pixelSize: 30
                        font.bold: true
                    } // Upscaled slightly to balance the voltage
                }
            }

            // --- THE MAGIC FLEXIBLE SPACER (The "Spring") ---
            Item {
                Layout.fillHeight: true
            }
        }

        // ==========================================
        // CENTER COLUMN: Speed, Pedals & G-Meter
        // ==========================================
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter // THE PIXEL-PERFECT FIX
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 300 // Explicit width constraint
            spacing: 5
            // THE LAP TIME DELTA
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15
                Rectangle {
                    // Logic: Green if Delta is negative (faster), Red if positive (slower)
                    property real dTime: root.telemetry ? root.telemetry.timeDelta : 0.0
                    color: dTime <= 0 ? "#00A36C" : "#ff3333"
                    width: 120
                    height: 35
                    radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: (parent.dTime > 0 ? "+" : "") + parent.dTime.toFixed(3) + " s"
                        color: "white"
                        font.pixelSize: 20
                        font.bold: true
                    }
                }
                Rectangle {
                    color: "#00A36C"
                    width: 150
                    height: 35
                    radius: 4
                    Text {
                        anchors.centerIn: parent
                        // Combines Lap Count and Lap Time!
                        text: root.telemetry ? "L" + root.telemetry.lapCount + " - " + root.telemetry.lapTime.toFixed(1) + "s" : "L0 - 0.0s"
                        color: "#ffffff"
                        font.pixelSize: 20
                        font.bold: true
                    }
                }
            }

            // THE GLOWING CIRCULAR HERO GAUGE

            // ==========================================
            // SPLIT GLOWING HERO GAUGE (+ DUT19 LAYOUT)
            // ==========================================
            Item {
                id: heroGaugeContainer
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                width: 280
                height: 280

                // Your smooth animation logic for both variables
                property real animatedSpeed: root.telemetry ? root.telemetry.speed : 0
                property real animatedPower: root.telemetry ? root.telemetry.power : 0
                Behavior on animatedSpeed {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutSine
                    }
                }
                Behavior on animatedPower {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutSine
                    }
                }

                /*Canvas {
                    id: splitCanvas
                    anchors.fill: parent

                    property real currentSpeed: parent.animatedSpeed
                    property real currentPower: parent.animatedPower

                    property real maxSpeed: 120.0
                    property real maxPower: 80.0

                    onCurrentSpeedChanged: requestPaint()
                    onCurrentPowerChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var cx = width / 2
                        var cy = height / 2
                        var r = (width / 2) - 30 // Shrunk to fit numbers outside

                        // Top Arc Math (1.05 PI to 1.95 PI) - Sweeps left to right over the top
                        var speedStart = Math.PI * 1.05
                        var speedEnd = Math.PI * 1.95
                        var speedSweep = speedEnd - speedStart

                        // Bottom Arc Math (0.95 PI to 0.05 PI) - Sweeps left to right under the bottom
                        var powerStart = Math.PI * 0.95
                        var powerEnd = Math.PI * 0.05
                        var powerSweep = powerStart - powerEnd

                        // 1. Draw Background Arcs
                        ctx.lineWidth = 15
                        ctx.lineCap = "round"
                        ctx.strokeStyle = "#222222"

                        ctx.beginPath()
                        ctx.arc(cx, cy, r, speedStart, speedEnd)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.arc(cx, cy, r, powerStart, powerEnd,
                                true) // 'true' for counter-clockwise
                        ctx.stroke()

                        // 2. Draw the Glowing Speed Arc (Top)
                        var speedRatio = Math.min(currentSpeed,
                                                  maxSpeed) / maxSpeed
                        if (speedRatio > 0) {
                            var currentSpeedAngle = speedStart + (speedRatio * speedSweep)

                            ctx.beginPath()
                            ctx.arc(cx, cy, r, speedStart, currentSpeedAngle)
                            ctx.lineWidth = 15

                            // Your gradient! Adjusted to map left-to-right across the arc
                            var speedGradient = ctx.createLinearGradient(0, cy,
                                                                         width,
                                                                         cy)
                            speedGradient.addColorStop(0.0, "#00ffcc")
                            speedGradient.addColorStop(1.0, "#ffcc00")

                            ctx.strokeStyle = speedGradient
                            ctx.shadowColor = "#00ffcc"
                            ctx.shadowBlur = 10
                            ctx.stroke()
                            ctx.shadowBlur = 0 // Reset shadow

                            // Your Perpendicular Leading Line
                            var sIn = r - 15
                            var sOut = r + 15
                            ctx.beginPath()
                            ctx.moveTo(cx + sIn * Math.cos(currentSpeedAngle),
                                       cy + sIn * Math.sin(currentSpeedAngle))
                            ctx.lineTo(cx + sOut * Math.cos(currentSpeedAngle),
                                       cy + sOut * Math.sin(currentSpeedAngle))
                            ctx.lineWidth = 4
                            ctx.strokeStyle = "white"
                            ctx.stroke()
                        }

                        // 3. Draw the Glowing Power Arc (Bottom)
                        var absPower = Math.abs(currentPower)
                        var powerRatio = Math.min(absPower, maxPower) / maxPower
                        if (powerRatio > 0) {
                            var currentPowerAngle = powerStart - (powerRatio * powerSweep)
                            var powerColor = currentPower
                                    < 0 ? "#00ffcc" : "#ffcc00" // Green/Cyan for regen

                            ctx.beginPath()
                            ctx.arc(cx, cy, r, powerStart,
                                    currentPowerAngle, true)
                            ctx.lineWidth = 15
                            ctx.strokeStyle = powerColor
                            ctx.shadowColor = powerColor
                            ctx.shadowBlur = 10
                            ctx.stroke()
                            ctx.shadowBlur = 0

                            // Your Perpendicular Leading Line
                            var pIn = r - 15
                            var pOut = r + 15
                            ctx.beginPath()
                            ctx.moveTo(cx + pIn * Math.cos(currentPowerAngle),
                                       cy + pIn * Math.sin(currentPowerAngle))
                            ctx.lineTo(cx + pOut * Math.cos(currentPowerAngle),
                                       cy + pOut * Math.sin(currentPowerAngle))
                            ctx.lineWidth = 4
                            ctx.strokeStyle = "white"
                            ctx.stroke()
                        }
                    }
                }*/

                // ==========================================
                // HARDWARE ACCELERATED SPLIT HERO GAUGE
                // ==========================================
                // ==========================================
                // HARDWARE ACCELERATED SPLIT HERO GAUGE
                // ==========================================
                Shape {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.samples: 4

                    // 1. SPEED BACKGROUND ARC (Top)
                    ShapePath {
                        strokeColor: "#1a1a1f"
                        strokeWidth: 15
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: heroGaugeContainer.width / 2
                            centerY: heroGaugeContainer.height / 2
                            radiusX: 110
                            radiusY: 110
                            startAngle: 189
                            sweepAngle: 162
                        }
                    }

                    // 2. POWER BACKGROUND ARC (Bottom)
                    ShapePath {
                        strokeColor: "#1a1a1f"
                        strokeWidth: 15
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: heroGaugeContainer.width / 2
                            centerY: heroGaugeContainer.height / 2
                            radiusX: 110
                            radiusY: 110
                            startAngle: 171
                            sweepAngle: -162 // Negative sweep goes counter-clockwise!
                        }
                    }

                    // 3. SPEED ACTIVE ARC (Top) - Signature Cyan
                    ShapePath {
                        strokeColor: "#00ffcc"
                        strokeWidth: 15
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: heroGaugeContainer.width / 2
                            centerY: heroGaugeContainer.height / 2
                            radiusX: 110
                            radiusY: 110
                            startAngle: 189
                            sweepAngle: {
                                // Notice we use heroGaugeContainer.animatedSpeed instead of raw telemetry!
                                var val = heroGaugeContainer.animatedSpeed;
                                var ratio = Math.max(0.001, Math.min(val / 145.0, 1.0));
                                return 162 * ratio;
                            }
                        }
                    }

                    // 4. POWER ACTIVE ARC (Bottom) - Dynamically changes to Red at high power
                    ShapePath {
                        strokeColor: (root.telemetry && root.telemetry.power > 80) ? "#ff3333" : "#ffcc00"
                        strokeWidth: 15
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: heroGaugeContainer.width / 2
                            centerY: heroGaugeContainer.height / 2
                            radiusX: 110
                            radiusY: 110
                            startAngle: 171
                            sweepAngle: {
                                // Uses 40 for testing if telemetry is missing
                                var val = Math.abs(heroGaugeContainer.animatedPower);
                                var ratio = Math.max(0.001, Math.min(val / 80.0, 1.0));
                                return -162 * ratio;
                            }
                        }
                    }
                }

                // 4. THE NUMBERS AROUND THE TOP ARC ONLY
                Repeater {
                    model: [0, 20, 40, 60, 80, 100, 120]
                    delegate: Text {
                        property real val: modelData
                        // Mathematically mapped to match the 1.05 to 1.95 PI sweep
                        property real angle: Math.PI * 1.05 + (val / 120.0) * (Math.PI * 0.9)
                        property real labelRadius: (280 / 2) - 8

                        x: 140 + labelRadius * Math.cos(angle) - (width / 2)
                        y: 140 + labelRadius * Math.sin(angle) - (height / 2)

                        text: val
                        color: "gray"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }

                // 5. THE STACKED CENTER TEXT
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: -4

                    Text {
                        text: Math.round(heroGaugeContainer.animatedSpeed)
                        color: "white"
                        font.pixelSize: 70 // Shrunk slightly to fit the stacked layout
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "km/h"
                        color: "#aaaaaa"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -8
                    }

                    // Thin separator line to divide Speed and Power
                    Rectangle {
                        width: 90
                        height: 2
                        color: "#444444"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                    }

                    Text {
                        text: Math.abs(heroGaugeContainer.animatedPower).toFixed(1)
                        color: heroGaugeContainer.animatedPower < 0 ? "#00ffcc" : "#ffcc00"
                        font.pixelSize: 32
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "kW"
                        color: "#aaaaaa"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -4
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -20
                spacing: 40

                // BRAKE
                ColumnLayout {
                    spacing: 5
                    Rectangle {
                        width: 24
                        height: 90
                        radius: 12
                        color: "#111111"
                        border.color: "#333333"
                        border.width: 2
                        clip: true

                        // REAL C++ BINDING: 0.0 to 1.0
                        property real brakeVal: root.telemetry ? root.telemetry.brakePress : 0.0
                        Behavior on brakeVal {
                            NumberAnimation {
                                duration: 50
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 12
                            height: parent.height * parent.brakeVal
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "#ff3333"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "#880000"
                                }
                            }
                        }
                    }
                    Text {
                        text: "BRK"
                        color: "#666666"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // THROTTLE
                ColumnLayout {
                    spacing: 5
                    Rectangle {
                        width: 24
                        height: 90
                        radius: 12
                        color: "#111111"
                        border.color: "#333333"
                        border.width: 2
                        clip: true

                        // REAL C++ BINDING: 0.0 to 1.0 (0% to 100%)
                        property real throttleVal: root.telemetry ? root.telemetry.throttleVal : 0.0
                        Behavior on throttleVal {
                            NumberAnimation {
                                duration: 50
                            }
                        } // Extremely fast 50ms smooth update

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 12
                            height: parent.height * parent.throttleVal
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "#00ffcc"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "#006644"
                                }
                            }
                        }
                    }
                    Text {
                        text: "THR"
                        color: "#666666"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // ==========================================
        // RIGHT COLUMN: Vehicle Dynamics & Indicators
        // ==========================================
        ColumnLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 160 // Explicit width constraint
            spacing: 10
            // INDICATORS (Compacted font and spacing)
            // 1. TOP ICONS (Grouped Side-by-Side to save vertical space!)
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 20 // Space between the two icons

                // COOLING ICON
                Item {
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/cooling_off.png" // Update to png!
                        opacity: (root.telemetry && root.telemetry.coolingActive) ? 0.0 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/cooling_on.png" // Update to png!
                        opacity: (root.telemetry && root.telemetry.coolingActive) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }

                // RADIO ICON
                Item {
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/radio_off.png"
                        opacity: (root.telemetry && root.telemetry.radioActive) ? 0.0 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/radio_on.png"
                        opacity: (root.telemetry && root.telemetry.radioActive) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }
                // TRACTION CONTROL ICON
                Item {
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/tc_off.png"
                        opacity: (root.telemetry && root.telemetry.tcWarning) ? 0.0 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/tc_on.png"
                        opacity: (root.telemetry && root.telemetry.tcWarning) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }
            }
            // REGENERATION ICON
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 20 // Space between the two icons
                Item {
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/regen_off.png"
                        opacity: (root.telemetry && root.telemetry.regenActive) ? 0.0 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/regen_on.png"
                        opacity: (root.telemetry && root.telemetry.regenActive) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/torque_vectoring_off.png"
                        opacity: (root.telemetry && root.telemetry.tvActive) ? 0.0 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/torque_vectoring_on.png"
                        opacity: (root.telemetry && root.telemetry.tvActive) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }
                Item {
                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/sideslip_off.png"
                        opacity: (root.telemetry && root.telemetry.ssActive) ? 0.0 : 1.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/FormulaDash/assets/sideslip_on.png"
                        opacity: (root.telemetry && root.telemetry.ssActive) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }
            }

            // 2. TEXT ALERTS (Tightly stacked, right-aligned)
            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 10
                spacing: 8

                // Using the same fade logic for the text so it looks active/inactive
                //Text { text: "TORQUE VECT"; color: "white"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignRight; opacity: (root.telemetry && root.telemetry.tvActive) ? 1.0 : 0.3 }
                //Text { text: "TRACTION"; color: "white"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignRight; opacity: (root.telemetry && root.telemetry.tcWarning) ? 1.0 : 0.3 }
                //Text { text: "REGEN"; color: "white"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignRight; opacity: (root.telemetry && root.telemetry.regenActive) ? 1.0 : 0.3 }
                //Text { text: "SIDE SLIP"; color: "white"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignRight; opacity: (root.telemetry && root.telemetry.ssActive) ? 1.0 : 0.3 }
            }

            // 3. THE MAGIC SPRING (Pushes the top items UP and bottom items DOWN)
            // --- THE MAGIC SPRING ---
            // This pushes the Text Alerts UP, and forces Brake Bias & G-Meter safely DOWN
            //Item { Layout.fillHeight: true }

            // --- BRAKE BIAS (Properly Right-Aligned) ---
            ColumnLayout {
                Layout.alignment: Qt.AlignRight // THIS WAS MISSING
                spacing: -4

                Text {
                    text: "BRAKE BIAS"
                    color: "gray"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignRight // THIS WAS MISSING
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight // THIS WAS MISSING
                    Text {
                        property real animatedBias: (root.telemetry ? root.telemetry.brakeBias : 0.0) || 0.0
                        Behavior on animatedBias {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                        text: animatedBias.toFixed(1)
                        color: "white"
                        font.pixelSize: 40
                        font.bold: true
                    }
                    Text {
                        text: "% F"
                        color: "gray"
                        font.pixelSize: 16
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 6
                    }
                }
            }
            // ==========================================
            // DYNAMIC G-FORCE METER (SMOOTH TRAIL EDITION)
            // ==========================================
            Item {
                id: gMeterContainer
                Layout.topMargin: 10
                Layout.alignment: Qt.AlignRight
                width: 140
                height: 140

                property real currentGx: root.telemetry ? root.telemetry.accelX : 0.0
                property real currentGy: root.telemetry ? root.telemetry.accelY : 0.0

                // The Memory for the Ghost Trail
                property var trailHistory: []
                property int maxTrailPoints: 20

                // The Sampler: Records the G-Force 33 times a second (30ms)
                Timer {
                    interval: 30
                    running: true
                    repeat: true
                    onTriggered: {
                        // We copy the array, add the new point, and reassign it
                        // so QML knows it needs to redraw the Repeater
                        var newTrail = gMeterContainer.trailHistory.slice();
                        newTrail.unshift({
                            "gx": gMeterContainer.currentGx,
                            "gy": gMeterContainer.currentGy
                        });
                        if (newTrail.length > gMeterContainer.maxTrailPoints) {
                            newTrail.pop();
                        }
                        gMeterContainer.trailHistory = newTrail;
                    }
                }

                // Smoothing the raw telemetry data
                Behavior on currentGx {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on currentGy {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                /*Canvas {
                    id: gMeterCanvas
                    anchors.fill: parent

                    property var trail: []
                    property int maxTrailPoints: 20 // Slightly longer trail looks better
                    property real maxG: 2.0

                    // The fix: Sample the position at a strict 30ms interval (~33 FPS)
                    Timer {
                        interval: 30
                        running: true
                        repeat: true
                        onTriggered: {
                            // Grab both X and Y simultaneously to avoid the "staircase"
                            gMeterCanvas.trail.unshift({
                                                           "x": gMeterContainer.currentGx,
                                                           "y": gMeterContainer.currentGy
                                                       })
                            if (gMeterCanvas.trail.length > gMeterCanvas.maxTrailPoints) {
                                gMeterCanvas.trail.pop()
                            }
                            gMeterCanvas.requestPaint()
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var cx = width / 2
                        var cy = height / 2
                        var r = (width / 2) - 10

                        // 1. Draw Target Rings & Crosshairs (Crisp, no glow)
                        ctx.strokeStyle = "#555555"
                        ctx.lineWidth = 1.5

                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.arc(cx, cy, r / 2, 0, 2 * Math.PI)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.moveTo(cx, cy - r)
                        ctx.lineTo(cx, cy + r)
                        ctx.moveTo(cx - r, cy)
                        ctx.lineTo(cx + r, cy)
                        ctx.stroke()

                        // 2. Text Labels
                        ctx.fillStyle = "#aaaaaa"
                        ctx.font = "bold 11px sans-serif"
                        ctx.fillText("1G", cx + 4, cy - (r / 2) + 4)
                        ctx.fillText("2G", cx + 4, cy - r + 12)

                        // 3. Draw the Smooth History Trail
                        if (trail.length > 1) {
                            for (var i = 0; i < trail.length - 1; i++) {
                                var p1 = trail[i]
                                var p2 = trail[i + 1]

                                var x1 = cx + (p1.x / maxG) * r
                                var y1 = cy - (p1.y / maxG) * r
                                var x2 = cx + (p2.x / maxG) * r
                                var y2 = cy - (p2.y / maxG) * r

                                ctx.beginPath()
                                ctx.moveTo(x1, y1)
                                ctx.lineTo(x2, y2)

                                var maxOpacity = 0.4
                                var alpha = maxOpacity * (1.0 - (i / maxTrailPoints))
                                ctx.strokeStyle = "rgba(0, 255, 204, " + alpha + ")"
                                ctx.lineWidth = 3.0 - (i * 0.15)
                                ctx.lineCap = "round"
                                ctx.lineJoin = "round" // Smooths out the line connections
                                ctx.stroke()
                            }
                        }

                        // 4. Draw the Current G-Dot (WITH GLOW)
                        var currentDotX = cx + (gMeterContainer.currentGx / maxG) * r
                        var currentDotY = cy - (gMeterContainer.currentGy / maxG) * r

                        ctx.beginPath()
                        ctx.arc(currentDotX, currentDotY, 5, 0, 2 * Math.PI)
                        ctx.fillStyle = "#ffcc00"

                        // Turn the glow ON just for the dot
                        ctx.shadowColor = "#ffcc00"
                        ctx.shadowBlur = 10
                        ctx.fill()

                        // Turn the glow OFF immediately so it doesn't bleed into the next frame
                        ctx.shadowBlur = 0
                    }
                }*/

                // ==========================================
                // HARDWARE ACCELERATED G-METER TRAIL
                // ==========================================
                // ==========================================
                // STATIC BACKGROUND (Rings & Crosshairs)
                // ==========================================
                // Crosshairs
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: 1.5
                    color: "#555555"
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 1.5
                    height: parent.height - 20
                    color: "#555555"
                }

                // Outer 2G Ring
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 20
                    height: parent.height - 20
                    radius: width / 2
                    color: "transparent"
                    border.color: "#555555"
                    border.width: 1.5
                }

                // Inner 1G Ring
                Rectangle {
                    anchors.centerIn: parent
                    width: (parent.width - 20) / 2
                    height: (parent.height - 20) / 2
                    radius: width / 2
                    color: "transparent"
                    border.color: "#555555"
                    border.width: 1.5
                }

                // Labels
                Text {
                    x: parent.width / 2 + 4
                    y: parent.height / 2 - ((parent.width - 20) / 4) + 2
                    text: "1G"
                    color: "#aaaaaa"
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    x: parent.width / 2 + 4
                    y: parent.height / 2 - ((parent.width - 20) / 2) + 2
                    text: "2G"
                    color: "#aaaaaa"
                    font.pixelSize: 11
                    font.bold: true
                }

                // 1. The Fading Historical Ghost Trail
                Repeater {
                    model: gMeterContainer.trailHistory.length

                    Rectangle {
                        // Fetch the historical X/Y from the array
                        property real histX: gMeterContainer.trailHistory[index].gx
                        property real histY: gMeterContainer.trailHistory[index].gy

                        // Map the G-Force to the circle's radius
                        x: (parent.width / 2) + (histX / 2.0) * ((parent.width - 20) / 2) - width / 2
                        y: (parent.height / 2) - (histY / 2.0) * ((parent.height - 20) / 2) - height / 2

                        width: 6
                        height: 6
                        radius: 3
                        color: "#00ffcc"

                        // Opacity fades out based on how old the point is in the array
                        opacity: 0.4 * (1.0 - (index / gMeterContainer.maxTrailPoints))
                    }
                }

                // 2. The Current Live G-Dot
                Rectangle {
                    id: liveGDot

                    x: (parent.width / 2) + (gMeterContainer.currentGx / 2.0) * ((parent.width - 20) / 2) - width / 2
                    y: (parent.height / 2) - (gMeterContainer.currentGy / 2.0) * ((parent.height - 20) / 2) - height / 2

                    width: 12
                    height: 12
                    radius: 6
                    color: "#ffcc00"

                    // Native GPU Drop Shadow for the glow effect
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#ffcc00"
                        shadowBlur: 1.0
                    }

                    // Smooth hardware-accelerated movement
                    Behavior on x {
                        NumberAnimation {
                            duration: 50
                            easing.type: Easing.OutQuad
                        }
                    }
                    Behavior on y {
                        NumberAnimation {
                            duration: 50
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }
}
