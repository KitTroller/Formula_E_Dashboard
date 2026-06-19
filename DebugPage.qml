import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: 800; height: 480
    id: dbgRoot
    objectName: "debugPage"
    property var telemetry

    Rectangle { anchors.fill: parent; color: "#050a15" }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 22

        Text { text: "DEBUG"; color: "#00ffcc"; font.pixelSize: 28; font.bold: true
               font.letterSpacing: 2; Layout.alignment: Qt.AlignHCenter }

        GridLayout {
            columns: 2; columnSpacing: 30; rowSpacing: 14
            Layout.alignment: Qt.AlignHCenter

            Text { text: "Valid frames:"; color: "#8899aa"; font.pixelSize: 22; font.bold: true }
            Text { text: dbgRoot.telemetry ? (dbgRoot.telemetry.freshTick, dbgRoot.telemetry.rxFramesOk()) : "—"
                   color: "white"; font.pixelSize: 22; font.bold: true; font.family: "Menlo" }

            Text { text: "Checksum drops:"; color: "#8899aa"; font.pixelSize: 22; font.bold: true }
            Text { text: dbgRoot.telemetry ? (dbgRoot.telemetry.freshTick, dbgRoot.telemetry.rxChecksumFails()) : "—"
                   color: (dbgRoot.telemetry && dbgRoot.telemetry.rxChecksumFails() > 0) ? "#ff3333" : "white"
                   font.pixelSize: 22; font.bold: true; font.family: "Menlo" }
        }
        Text { text: "menu button = home"; color: "#55687a"; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
    }
}