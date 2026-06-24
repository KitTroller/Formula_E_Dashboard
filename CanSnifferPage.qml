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
    property real wheelAcc: 0            // accumulates mouse/trackpad wheel until one row-step

    // ---- Steering-wheel hooks (from Main.qml) ----
    function wheelScrollDown() { if (selectedId === -1) msgList.incrementCurrentIndex(); } // wraps
    function wheelScrollUp()   { if (selectedId === -1) msgList.decrementCurrentIndex(); } // wraps
    // Desktop only: a trackpad/mouse wheel notch (±120) steps one row. The
    // accumulator keeps a fast trackpad swipe from skipping several rows at once.
    // (Flip the <= / >= if natural-scroll direction feels inverted.)
    function wheelStep(dy) {
        if (selectedId !== -1) return;
        wheelAcc += dy;
        while (wheelAcc <= -120) { msgList.incrementCurrentIndex(); wheelAcc += 120; }
        while (wheelAcc >=  120) { msgList.decrementCurrentIndex(); wheelAcc -= 120; }
    }
    function wheelSelect() {
        if (selectedId === -1)
            openDetail(msgModel[msgList.currentIndex].id);   // list -> detail
        else
            selectedId = -1;                                 // detail -> back to list
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
        // thin rule grounds the header to the drum below
        Rectangle { Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.preferredHeight: 1; color: "#1a3344" }

        PathView {
            id: msgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: sniffRoot.msgModel

            pathItemCount: 9                              // visible rows on the drum (tune this)
            preferredHighlightBegin: 0.5                  // pin the selected row to the centre
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange   // <- this is what makes it loop
            flickDeceleration: 800
            highlightMoveDuration: 150   // default ~300; lower = snappier,


            // Χρησιμοποίησε την formula: Size_Ratio=1/(2-cos(nθ)) οπου θ= 2π/107 με 107 τον αριθμο των can frames και n ο ακαίραιος αριθμός απόστασης από τo κέντρικό delegate----------------------
            path: Path {
                startX: msgList.width / 2; startY: 0
                PathAttribute { name: "rowScale"; value: 0.973 }
                PathAttribute { name: "rowOpacity"; value: 0.70 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.111 }

                PathAttribute { name: "rowScale"; value: 0.985 }
                PathAttribute { name: "rowOpacity"; value: 0.80 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.222 }

                PathAttribute { name: "rowScale"; value: 0.993 }
                PathAttribute { name: "rowOpacity"; value: 0.90 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.333 }

                PathAttribute { name: "rowScale"; value: 0.999 }
                PathAttribute { name: "rowOpacity"; value: 0.97 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.444 }

                PathAttribute { name: "rowScale"; value: 1.000 }
                PathAttribute { name: "rowOpacity"; value: 1.00 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.555 }

                PathAttribute { name: "rowScale"; value: 0.999 }
                PathAttribute { name: "rowOpacity"; value: 0.97 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.666 }

                PathAttribute { name: "rowScale"; value: 0.993 }
                PathAttribute { name: "rowOpacity"; value: 0.90 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.777 }

                PathAttribute { name: "rowScale"; value: 0.985 }
                PathAttribute { name: "rowOpacity"; value: 0.80 }
                PathLine { x: msgList.width / 2; y: msgList.height * 0.888}

                PathAttribute { name: "rowScale"; value: 0.973 }
                PathAttribute { name: "rowOpacity"; value: 0.70 }
                //PathLine { x: msgList.width / 2; y: msgList.height}
            }

            delegate: Rectangle {
                id: row
                property bool current: PathView.isCurrentItem
                width: msgList.width
                height: 34
                radius: 5
                // Off-path/recycled delegates (happens on fast scroll) report
                // undefined for these custom path attributes — fall back to a real
                // number so we never assign undefined, and hide rows off the drum.
                visible: PathView.onPath
                scale:   PathView.rowScale   !== undefined ? PathView.rowScale   : 1
                opacity: PathView.rowOpacity !== undefined ? PathView.rowOpacity : 1
                z: current ? 1 : 0
                color: current ? "#ffcc00" : "#cc0a1525"
                border.color: current ? "#ffffff" : "#1a3344"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Text {
                        text: modelData.idHex
                        color: row.current ? "#222222" : "#7790a5"
                        font.pixelSize: 15; font.bold: true; font.family: "Menlo"
                        Layout.preferredWidth: 70
                    }
                    Text {
                        text: modelData.name
                        color: row.current ? "black" : "white"
                        font.pixelSize: 16; font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {                                 // keep the "—" col so the header lines up
                        text: "—"
                        color: row.current ? "#222222" : "#55687a"
                        font.pixelSize: 15; font.bold: true; font.family: "Menlo"
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 70
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: msgList.currentIndex = index        // tap a row -> rotates it to centre
                    onDoubleClicked: sniffRoot.openDetail(modelData.id)
                    onWheel: (wheel) => sniffRoot.wheelStep(wheel.angleDelta.y)  // desktop scroll
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
            text: "press = back to list   ·   menu button = home"
            color: "#55687a"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
