import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Kvaser-style live CAN trace. On enter we ask the other board to stream every
// message; we keep the latest frame per id (in C++) and show it here.
//  - List mode: every DBC message (sorted by id), with a live "last seen" counter.
//  - Detail mode: all signals of the highlighted message, decoded, "—" if unseen.
Item {
    width: 800
    height: 480
    id: sniffRoot
    objectName: "canSnifferPage"

    property var telemetry

    property var msgModel: []            // [{id,idHex,name,dlc}] from the DBC (set once)
    property int selectedId: -1          // -1 = list mode, otherwise show that message's detail
    property var detailModel: []         // decoded signals of the selected message
    property int refreshTick: 0          // bumped ~4 Hz to refresh counters/values

    // ---- Steering-wheel hooks (from Main.qml) ----
    function wheelScrollDown() {
        if (selectedId === -1 && msgList.currentIndex < msgList.count - 1) {
            msgList.currentIndex++;
            msgList.positionViewAtIndex(msgList.currentIndex, ListView.Contain);
        }
    }
    function wheelScrollUp() {
        if (selectedId === -1 && msgList.currentIndex > 0) {
            msgList.currentIndex--;
            msgList.positionViewAtIndex(msgList.currentIndex, ListView.Contain);
        }
    }
    function wheelSelect() {
            if (selectedId === -1)
                openDetail(msgModel[msgList.currentIndex].id); // list -> detail
        }

    function wheelBack() {
        if (selectedId !== -1) {
            selectedId = -1; // detail -> back to list
            return true;
        }
        return false;
    }

    function openDetail(id) {
        selectedId = id;
        refreshDetail();
    }
    function refreshDetail() {
        if (selectedId !== -1 && telemetry)
            detailModel = telemetry.snifferDecode(selectedId);
    }

    Component.onCompleted: {
        if (telemetry) {
            telemetry.setSnifferActive(true);   // ask the board to start streaming
            msgModel = telemetry.snifferMessages();
        }
    }
    Component.onDestruction: {
        if (telemetry)
            telemetry.setSnifferActive(false);  // stop the flood when we leave
    }

    // Heartbeat that drives the live counters / decoded values (not too fast).
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            sniffRoot.refreshTick++;
            sniffRoot.refreshDetail();
        }
    }

    Rectangle { anchors.fill: parent; color: "#050a15" }

    // ======================= LIST MODE =======================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8
        visible: sniffRoot.selectedId === -1

        Text {
            text: "CAN SNIFFER"
            color: "#00ffcc"
            font.pixelSize: 24
            font.bold: true
            font.letterSpacing: 2
            Layout.alignment: Qt.AlignHCenter
        }

        // Column header so the right-hand column reads clearly as the live timer.
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 10
            Text { text: "ID"; color: "#55687a"; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 70 }
            Text { text: "MESSAGE"; color: "#55687a"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Text { text: "LAST SEEN"; color: "#55687a"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 70 }
        }

        ListView {
            id: msgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 3
            boundsBehavior: Flickable.StopAtBounds
            model: sniffRoot.msgModel
            // No highlightRange: changing currentIndex must NOT auto-scroll/animate
            // (that caused the click-jump). The rotary nudges the view itself, and a
            // touch-click lands on an already-visible row, so neither path scrolls jankily.

            delegate: Rectangle {
                id: row
                width: ListView.view.width
                height: 34
                radius: 5
                color: index === msgList.currentIndex ? "#ffcc00" : "#cc0a1525"
                border.color: index === msgList.currentIndex ? "#ffffff" : "#1a3344"
                border.width: 1

                property bool seen: false /*sniffRoot.telemetry ----------------temporary until logic is added
                                    ? (sniffRoot.refreshTick, sniffRoot.telemetry.snifferReceived(modelData.id))
                                    : false*/

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: modelData.idHex
                        color: index === msgList.currentIndex ? "#222222" : "#7790a5"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Menlo"
                        Layout.preferredWidth: 70
                    }
                    Text {
                        text: modelData.name
                        color: index === msgList.currentIndex ? "black" : "white"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    // Live "last seen" counter — refreshes on every tick.
                    Text {
                        text: "—" /*sniffRoot.telemetry-------- temporarily made just "-"
                              ? (sniffRoot.refreshTick, sniffRoot.telemetry.snifferLastSeen(modelData.id))
                              : "—"*/
                        color: index === msgList.currentIndex
                               ? "#222222"
                               : (row.seen ? "#00ffcc" : "#55687a")
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Menlo"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 70
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: msgList.currentIndex = index
                    onDoubleClicked: sniffRoot.openDetail(modelData.id)
                }
            }
        }

        Text {
            text: "rotate = scroll   ·   press = open   ·   menu button = home"
            color: "#55687a"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // ======================= DETAIL MODE =======================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 8
        visible: sniffRoot.selectedId !== -1

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: {
                    if (sniffRoot.selectedId === -1) return "";
                    for (var i = 0; i < sniffRoot.msgModel.length; i++)
                        if (sniffRoot.msgModel[i].id === sniffRoot.selectedId)
                            return sniffRoot.msgModel[i].idHex + "  " + sniffRoot.msgModel[i].name;
                    return "0x" + sniffRoot.selectedId.toString(16);
                }
                color: "#00ffcc"
                font.pixelSize: 22
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            RowLayout {
                spacing: 6
                Text { text: "last seen"; color: "#55687a"; font.pixelSize: 13 }
                Text {
                    text: "-"/*sniffRoot.telemetry && sniffRoot.selectedId !== -1---------- temporarily
                          ? (sniffRoot.refreshTick, sniffRoot.telemetry.snifferLastSeen(sniffRoot.selectedId))
                          : "—"*/
                    color: "#7790a5"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "Menlo"
                }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#334455" }

        // Column header for the decoded signals
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 14
            Layout.rightMargin: 14
            Text { text: "SIGNAL"; color: "#55687a"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
            Text { text: "VALUE"; color: "#55687a"; font.pixelSize: 12; font.bold: true }
        }

        ListView {
            id: sigList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: sniffRoot.detailModel

            delegate: Rectangle {
                width: ListView.view.width
                height: 36
                radius: 5
                color: index % 2 === 0 ? "#0a1525" : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    Text {
                        text: modelData.name
                        color: "#aebccb"
                        font.pixelSize: 17
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.value
                        color: modelData.value === "—" ? "#55687a" : "white"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Menlo"
                        horizontalAlignment: Text.AlignRight
                    }
                    Text {
                        text: modelData.unit
                        color: "#7790a5"
                        font.pixelSize: 14
                        Layout.preferredWidth: 48
                        Layout.leftMargin: 6
                    }
                }
            }
        }

        Text {
            text: "back button = back to list   ·   menu button = home"
            color: "#55687a"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
