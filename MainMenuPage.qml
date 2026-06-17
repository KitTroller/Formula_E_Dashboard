import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: 800
    height: 480
    id: menuRoot
    objectName: "mainMenuPage"

    // Backend handle, forwarded to the pages that need it (Mission Selection,
    // Diagnostics). Injected from Main.qml's stackView.push().
    property var telemetry

    // ---- Steering-wheel hooks (called from Main.qml) ----
    // Encoder 1 scroll moves the highlight; encoder-1 push opens the entry.
    function wheelScrollDown() {
        if (menuList.currentIndex < menuList.count - 1)
            menuList.currentIndex++;
    }
    function wheelScrollUp() {
        if (menuList.currentIndex > 0)
            menuList.currentIndex--;
    }
    function wheelSelect() {
        openSelected();
    }

    // Open the page for the currently highlighted entry. Accumulator / Powertrain /
    // CAN Sniffer are the three tabs of DiagnosticPage, opened at the matching tab.
    function openSelected() {
        var view = menuRoot.StackView.view;
        switch (menuList.currentIndex) {
        case 0:
            view.push(Qt.resolvedUrl("MissionSelectionPage.qml"), { "telemetry": menuRoot.telemetry });
            break;
        case 1:
            view.push(Qt.resolvedUrl("DiagnosticPage.qml"), { "telemetry": menuRoot.telemetry, "startTab": 0 });
            break;
        case 2:
            view.push(Qt.resolvedUrl("DiagnosticPage.qml"), { "telemetry": menuRoot.telemetry, "startTab": 1 });
            break;
        case 3:
            view.push(Qt.resolvedUrl("CanSnifferPage.qml"), { "telemetry": menuRoot.telemetry });
            break;
        }
    }

    // Premium dark engineering background
    Rectangle {
        anchors.fill: parent
        color: "#050a15"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 15

        // HEADER
        Text {
            text: "MAIN MENU"
            color: "#00ffcc"
            font.pixelSize: 28
            font.bold: true
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
        }

        // THE MENU LIST
        ListView {
            id: menuList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10
            boundsBehavior: Flickable.StopAtBounds
            bottomMargin: 20

            model: ["MISSION SELECTION", "ACCUMULATOR", "POWERTRAIN", "CAN SNIFFER"]

            delegate: Rectangle {
                width: ListView.view.width
                height: 65
                radius: 8

                color: index === menuList.currentIndex ? "#ffcc00" : "#cc0a1525"
                border.color: index === menuList.currentIndex ? "#ffffff" : "#1a3344"
                border.width: index === menuList.currentIndex ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 25
                    anchors.rightMargin: 25

                    Text {
                        text: modelData
                        color: index === menuList.currentIndex ? "black" : "white"
                        font.pixelSize: 24
                        font.bold: true
                        font.letterSpacing: 1
                        Layout.fillWidth: true
                    }

                    Text {
                        text: ">>"
                        color: "black"
                        font.pixelSize: 24
                        font.bold: true
                        visible: index === menuList.currentIndex
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: menuList.currentIndex = index
                    onDoubleClicked: {
                        menuList.currentIndex = index;
                        menuRoot.openSelected();
                    }
                }
            }
        }

        // OPEN BUTTON (touch equivalent of pressing the rotary)
        Rectangle {
            Layout.fillWidth: true
            height: 70
            radius: 8
            color: "#00ffcc"

            Text {
                anchors.centerIn: parent
                text: "OPEN  " + menuList.model[menuList.currentIndex]
                color: "black"
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 2
            }

            MouseArea {
                anchors.fill: parent
                onClicked: menuRoot.openSelected()
                onPressed: parent.opacity = 0.7
                onReleased: parent.opacity = 1.0
            }
        }
    }
}
