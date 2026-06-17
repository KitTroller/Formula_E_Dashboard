import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: 800
    height: 480
    id: missionRoot
    objectName: "missionSelectionPage"

    // Backend handle injected from Main.qml's stackView.push(). Used to transmit
    // the selected mission code (1..6) out the UART on confirm.
    property var telemetry

    // ---- Steering-wheel hooks (called from Main.qml) ----
    // Encoder 1 scroll moves the highlight; encoder-1 push confirms.
    function wheelScrollDown() {
        if (missionList.currentIndex < missionList.count - 1)
            missionList.currentIndex++;
    }
    function wheelScrollUp() {
        if (missionList.currentIndex > 0)
            missionList.currentIndex--;
    }
    function wheelSelect() {
        confirmMission();
    }

    // Single source of truth for confirming a mission (touch CONFIRM + encoder push).
    function confirmMission() {
        var selectedMission = missionList.model[missionList.currentIndex];
        console.log("Mission Locked: " + selectedMission);

        // Transmit the mission code (1..7) over the serial port.
        // currentIndex 0..6 maps directly to MANUAL..DV INSPECTION, so +1.
        if (missionRoot.telemetry)
            missionRoot.telemetry.selectMissionMode(missionList.currentIndex + 1);

        missionRoot.StackView.view.push(Qt.resolvedUrl("ActiveMissionPage.qml"), {
            "missionName": selectedMission
        });
    }

    // Premium dark engineering background
    Rectangle {
        anchors.fill: parent
        color: "#050a15"

        // Subtle grid background
        /*Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#0a1525"
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
        }*/
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 15

        // HEADER
        Text {
            text: "AUTONOMOUS MISSION SELECT"
            color: "#00ffcc"
            font.pixelSize: 28
            font.bold: true
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
        }

        // THE SLEEK MISSION LIST
        ListView {
            id: missionList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10

            // Removed snapMode for smooth scrolling, added boundsBehavior
            boundsBehavior: Flickable.StopAtBounds
            bottomMargin: 20 // Gives "EBS TEST" room to breathe at the bottom!

            model: ["MANUAL DRIVING", "ACCELERATION", "SKIDPAD", "AUTOCROSS", "TRACKDRIVE", "EBS TEST", "DV INSPECTION"]

            delegate: Rectangle {
                width: ListView.view.width
                height: 65
                radius: 8

                color: index === missionList.currentIndex ? "#ffcc00" : "#cc0a1525"
                border.color: index === missionList.currentIndex ? "#ffffff" : "#1a3344"
                border.width: index === missionList.currentIndex ? 2 : 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 25
                    anchors.rightMargin: 25

                    Text {
                        text: modelData
                        color: index === missionList.currentIndex ? "black" : "white"
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
                        visible: index === missionList.currentIndex
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: missionList.currentIndex = index
                }
            }
        }

        // THE SAFETY CONFIRM BUTTON
        Rectangle {
            Layout.fillWidth: true
            height: 70
            radius: 8
            // FIX: Uses signature Cyan for armed missions, dark grey for manual
            color: missionList.currentIndex === 0 ? "#444444" : "#00ffcc"

            Text {
                anchors.centerIn: parent
                text: missionList.currentIndex
                      === 0 ? "RETURN TO MANUAL CONTROL" : "CONFIRM "
                              + missionList.model[missionList.currentIndex]
                color: missionList.currentIndex
                       === 0 ? "white" : "black" // Black text on Cyan pops perfectly
                font.pixelSize: 22
                font.bold: true
                font.letterSpacing: 2
            }

            MouseArea {
                anchors.fill: parent
                onClicked: missionRoot.confirmMission()

                onPressed: parent.opacity = 0.7
                onReleased: parent.opacity = 1.0
            }
        }
    }
}
