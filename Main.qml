import QtQuick
import QtQuick.Controls
import FormulaDash

Window {
    width: 800
    height: 480
    visible: true
    title: "Formula Student Dashboard"
    visibility:  Window.FullScreen
    color: "black"

    //We instantiate the C++ backend here once.
    //This is the single source of truth for the entire application.
    VehicleDataProvider {
        id: telemetryProvider
    }

    Connections {
        target: telemetryProvider

        // Linear page model walked by the page-nav rotary (central encoder 1):
        //   [Mission Select]  <--  [Driver]  -->  [Diagnostics tab0 -> tab1 -> tab2]
        function onNavigateNextPage() {           // CW / forward (rightward)
            var it = stackView.currentItem;
            if (it && it.objectName === "missionSelectionPage") {
                // Mission sits left of Driver -> forward returns to Driver
                stackView.pop(null);
            } else if (stackView.depth === 1) {
                // Driver -> Diagnostics
                stackView.push(Qt.resolvedUrl("DiagnosticPage.qml"), {
                    "telemetry": telemetryProvider
                });
            } else if (it && it.objectName === "diagnosticPage") {
                // Advance through the diagnostic tabs (stays put at the last one)
                it.nextTab();
            }
        }

        function onNavigatePrevPage() {           // CCW / backward (leftward)
            var it = stackView.currentItem;
            if (it && it.objectName === "diagnosticPage") {
                // Step back through tabs; from the first tab, pop out to Driver
                if (!it.prevTab())
                    stackView.pop();
            } else if (stackView.depth === 1) {
                // Driver -> Mission Selection (Mission sits left of Driver)
                stackView.push(Qt.resolvedUrl("MissionSelectionPage.qml"), {
                    "telemetry": telemetryProvider
                });
            }
            // On Mission Selection (leftmost): turning further back does nothing
        }

        // Scroll within the current page (central encoder 3). The page opts in by
        // defining wheelScrollDown()/wheelScrollUp(); pages without them ignore it.
        function onScrollNext() {
            var it = stackView.currentItem;
            if (it && typeof it.wheelScrollDown === "function")
                it.wheelScrollDown();
        }
        function onScrollPrev() {
            var it = stackView.currentItem;
            if (it && typeof it.wheelScrollUp === "function")
                it.wheelScrollUp();
        }

        // Encoder push -> let the current page confirm its selection.
        function onSelectPressed() {
            var it = stackView.currentItem;
            if (it && typeof it.wheelSelect === "function")
                it.wheelSelect();
        }

        // Back button -> pop one level toward the Driver page.
        function onNavigateBack() {
            if (stackView.depth > 1)
                stackView.pop();
        }

        // Inner-Right button -> jump straight to Mission Selection from ANY page
        // (previously only worked on the Driver page, so it was dead on Diagnostics).
        function onOpenMissionSelect() {
            if (stackView.currentItem && stackView.currentItem.objectName === "missionSelectionPage")
                return;                 // already there
            stackView.pop(null);        // unwind to Driver (no-op if already there)
            stackView.push(Qt.resolvedUrl("MissionSelectionPage.qml"), {
                "telemetry": telemetryProvider
            });
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }
    //The Navigation Deck.
    StackView {
        id: stackView
        anchors.fill: parent

        // We are creating the DriverPage and injecting the telemetryProvider
        // directly into its custom 'telemetry' property.
        initialItem: DriverPage {
            telemetry: telemetryProvider
        }
    }

    //NEW: HIDDEN PIT CREW OVERRIDE
    // A large invisible touch zone on the far left side of the screen
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 100

        onDoubleClicked: {
            // If we are on the Driver page, push the Diagnostics page
            if (stackView.depth === 1) {
                stackView.push(Qt.resolvedUrl("DiagnosticPage.qml"), {
                    "telemetry": telemetryProvider
                });
            } // If we are on the Diagnostics page, pop back to the Driver page
            else {
                stackView.pop();
            }
        }
    }
    //HIDDEN DRIVER MENU OVERRIDE (Simulating Steering Wheel Button)
    //A large invisible touch zone on the far right side of the screen
    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 100

        onDoubleClicked: {
            //If on Driver page, push Mission Selection
            if (stackView.depth === 1) {
                stackView.push(Qt.resolvedUrl("MissionSelectionPage.qml"), {
                    "telemetry": telemetryProvider
                });
            } // If already on a sub-page, pop back to the Driver page
            else {
                stackView.pop();
            }
        }
    }
    // ==========================================
    // GLOBAL WARNING MANAGER & BANNER
    // ==========================================
    QtObject {
        id: warningManager

        property real maxCellTempLimit: 100.0
        property real minCellVoltageLimit: 2.8
        property real maxInverterTempLimit: 85.0

        property string currentWarningText: {
            // PRIORITY 1: Battery Temperatures (Highest Danger)
            if (telemetryProvider.maxCellTemp >= maxCellTempLimit) {
                return "CRITICAL: ACCUMULATOR OVERTEMP (" + telemetryProvider.maxCellTemp.toFixed(1) + " °C)";
            }
            // PRIORITY 2: Battery Voltages
            if (telemetryProvider.minCellVoltage <= minCellVoltageLimit) {
                return "CRITICAL: CELL UNDERVOLTAGE (" + telemetryProvider.minCellVoltage.toFixed(2) + " V)";
            }
            // PRIORITY 3: Powertrain Temps
            if (telemetryProvider.igbtTempFL >= maxInverterTempLimit || telemetryProvider.igbtTempFR >= maxInverterTempLimit || telemetryProvider.igbtTempRL >= maxInverterTempLimit || telemetryProvider.igbtTempRR >= maxInverterTempLimit) {
                return "WARNING: INVERTER OVERTEMP";
            }
            return "";
        }

        property color currentWarningColor: {
            if (telemetryProvider.maxCellTemp >= maxCellTempLimit)
                return "#ff0000";
            if (telemetryProvider.minCellVoltage <= minCellVoltageLimit)
                return "#ff0000";
            if (telemetryProvider.igbtTempFL >= maxInverterTempLimit)
                return "#ff9900";
            return "transparent";
        }

        property bool isWarningActive: currentWarningText !== ""
    }

    Rectangle {
        id: globalWarningBanner
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: 120
        radius: 10
        z: 999 // Forces it above EVERYTHING in the StackView/SwipeView

        color: warningManager.currentWarningColor
        visible: warningManager.isWarningActive

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: warningManager.isWarningActive
            NumberAnimation {
                to: 0.6
                duration: 250
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 1.0
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            color: "transparent"
            border.color: "black"
            border.width: 4
            radius: 8
        }
        Text {
            // 1. Define the strict bounding box with margins so it doesn't touch the borders
            anchors.fill: parent
            anchors.margins: 20

            // 2. Center the text within that box
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            text: warningManager.currentWarningText
            color: "white"

            // 3. THE MAGIC FIX: Auto-Scaling
            font.pixelSize: 45           // This acts as the MAXIMUM allowed size
            minimumPixelSize: 20         // It will never shrink smaller than this
            fontSizeMode: Text.Fit       // Tells QML to calculate the perfect size to prevent overflow

            font.bold: true
            font.letterSpacing: 2
            style: Text.Outline
            styleColor: "black"
        }
    }
}
