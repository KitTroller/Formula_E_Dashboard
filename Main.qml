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

        // Central encoder 1 is the ONE rotary:
        //  - on the Main Menu / Mission Selection pages it scrolls the list,
        //  - on the Diagnostics page it switches tabs,
        //  - on the Driver page it does nothing (navigation goes through the menu).
        function onNavigateNextPage() {           // CW / forward
            var it = stackView.currentItem;
            if (!it) return;
            if (it.objectName === "mainMenuPage" || it.objectName === "missionSelectionPage")
                it.wheelScrollDown();
            else if (it.objectName === "diagnosticPage")
                it.nextTab();                     // next tab (stays at the last one)
        }

        function onNavigatePrevPage() {           // CCW / backward
            var it = stackView.currentItem;
            if (!it) return;
            if (it.objectName === "mainMenuPage" || it.objectName === "missionSelectionPage")
                it.wheelScrollUp();
            else if (it.objectName === "diagnosticPage")
                it.prevTab();                     // previous tab (stays at the first one)
        }

        // Encoder push -> let the current page act on its selection
        // (Main Menu opens a page; Mission Selection confirms the mission).
        function onSelectPressed() {
            var it = stackView.currentItem;
            if (it && typeof it.wheelSelect === "function")
                it.wheelSelect();
        }

        // Back button -> pop one level (sub-page -> Menu, Menu -> Driver).
        function onNavigateBack() {
            if (stackView.depth > 1)
                stackView.pop();
        }

        // Inner-Right button toggles the Main Menu:
        //  - on the Menu        -> back to the Driver page,
        //  - on the Driver page -> open the Menu,
        //  - on any deeper page -> return home to the Driver page.
        function onToggleMenu() {
            var it = stackView.currentItem;
            if (it && it.objectName === "mainMenuPage") {
                stackView.pop(null);              // Menu -> Driver
            } else if (stackView.depth === 1) {
                stackView.push(Qt.resolvedUrl("MainMenuPage.qml"), {
                    "telemetry": telemetryProvider
                });                               // Driver -> Menu
            } else {
                stackView.pop(null);              // deeper page -> Driver (home)
            }
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
            // Touch mirror of the Inner-Right button: toggle the Main Menu / go home
            var it = stackView.currentItem;
            if (it && it.objectName === "mainMenuPage")
                stackView.pop(null);
            else if (stackView.depth === 1)
                stackView.push(Qt.resolvedUrl("MainMenuPage.qml"), {
                    "telemetry": telemetryProvider
                });
            else
                stackView.pop(null);
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
