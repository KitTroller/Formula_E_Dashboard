import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: 800
    height: 480
    id: activeMissionPage

    // This property catches the mission name sent from the MissionSelectionPage!
    property string missionName: "UNKNOWN MISSION"

    Rectangle {
        anchors.fill: parent
        color: "#050a15"

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
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "VEHICLE ARMED FOR"
            color: "#ffcc00"
            font.pixelSize: 24
            font.letterSpacing: 4
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: missionName
            color: "#00ffcc"
            font.pixelSize: 75
            font.bold: true
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // HIDDEN EXIT OVERRIDE: Double-click anywhere to abort the mission and go back
    MouseArea {
        anchors.fill: parent
        onDoubleClicked: {
            activeMissionPage.StackView.view.pop()
        }
    }
}
