/*#include "vehicledataprovider.h"

VehicleDataProvider::VehicleDataProvider(QObject *parent)
    : QObject(parent),m_speed(0), m_voltage(400.0), m_power(0.0),
    m_soc(100), m_powerTarget(60.0), m_brakeBias(54.0),
    m_accelX(0.0), m_accelY(0.0),
    m_tcWarning(false), m_coolingActive(true), m_tvActive(true),
    m_maxCellTemp(25.0), m_minCellVoltage(4.1), m_maxCellVoltage(4.2), m_currentDc(0.0),
    m_requestedTorque(0), m_igbtTempL(30), m_igbtTempR(30),
    m_motorTempL(30), m_motorTempR(30), m_tyresOk(true),
    m_fakeTime(0) {

    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &VehicleDataProvider::updateMockData);
    m_timer->start(16);
}


// 2. THE READ BUFFERS (Getters)

int VehicleDataProvider::speed() const { return m_speed; }
double VehicleDataProvider::voltage() const { return m_voltage; }
double VehicleDataProvider::power() const { return m_power; }
int VehicleDataProvider::soc() const { return m_soc; }
double VehicleDataProvider::powerTarget() const { return m_powerTarget; }
double VehicleDataProvider::brakeBias() const { return m_brakeBias; }
double VehicleDataProvider::accelX() const { return m_accelX; }
double VehicleDataProvider::accelY() const { return m_accelY; }

bool VehicleDataProvider::tcWarning() const { return m_tcWarning; }
bool VehicleDataProvider::coolingActive() const { return m_coolingActive; }
bool VehicleDataProvider::tvActive() const { return m_tvActive; }

double VehicleDataProvider::maxCellTemp() const { return m_maxCellTemp; }
double VehicleDataProvider::minCellVoltage() const { return m_minCellVoltage; }
double VehicleDataProvider::maxCellVoltage() const { return m_maxCellVoltage; }
double VehicleDataProvider::currentDc() const { return m_currentDc; }

int VehicleDataProvider::requestedTorque() const { return m_requestedTorque; }
int VehicleDataProvider::igbtTempL() const { return m_igbtTempL; }
int VehicleDataProvider::igbtTempR() const { return m_igbtTempR; }
int VehicleDataProvider::motorTempL() const { return m_motorTempL; }
int VehicleDataProvider::motorTempR() const { return m_motorTempR; }
bool VehicleDataProvider::tyresOk() const { return m_tyresOk; }
void VehicleDataProvider::updateMockData() {
    m_fakeTime++;
    m_speed = 75+35 * std::sin(m_fakeTime/50);

    // Simulate battery drain and voltage sag under load
    if (m_fakeTime % 100 == 0 && m_soc > 0) m_soc -= 1;
    m_voltage = 390.0 + 10.0 * std::cos(m_fakeTime / 50.0);
    m_power = (m_speed / 110.0) * m_powerTarget; // Power scales with speed

    // Simulate G-Forces (We move the Math.sin logic from QML into C++)
    m_accelX = std::sin(m_fakeTime / 40.0) * 1.5;
    m_accelY = std::cos(m_fakeTime / 40.0) * 1.5;

    // Simulate Traction Control activating during high acceleration
    m_tcWarning = (m_accelY > 1.2 || m_accelX > 1.2);

    // Simulate Accumulator temperatures slowly rising
    m_maxCellTemp = 25.0 + (m_fakeTime / 200.0);
    m_currentDc = m_power * 1000 / m_voltage; // P = V*I -> I = P/V

    // Simulate Motor / Inverter temperatures
    m_igbtTempL = 30 + (m_speed / 4);
    m_igbtTempR = 31 + (m_speed / 4);
    m_motorTempL = 40 + (m_speed / 3);
    m_motorTempR = 42 + (m_speed / 3);


    // 4. THE INTERRUPT TRIGGERS (Emitting Signals)
    // CRITICAL: Changing a C++ variable does NOTHING to the screen.
    // You MUST emit the signal to notify the QML engine that a value changed.
    emit speedChanged();
    emit voltageChanged();
    emit powerChanged();
    emit socChanged();
    emit accelXChanged();
    emit accelYChanged();
    emit tcWarningChanged();
    emit maxCellTempChanged();
    emit currentDcChanged();
    emit igbtTempLChanged();
    emit igbtTempRChanged();
    emit motorTempLChanged();
    emit motorTempRChanged();

}*/

#include "vehicledataprovider.h"
#include <QSerialPort>
#include <QSerialPortInfo>
#include <QStringList>
#include <QDateTime>
#include <QDebug>
#include <QFile>
#include <QVariant>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

//CONSTRUCTOR (UART Initialization)

VehicleDataProvider::VehicleDataProvider(QObject *parent)
    : QObject(parent), m_speed(0), m_lapTime(0.0), m_timeDelta(0.0), m_lapCount(0),
    m_accelX(0.0), m_accelY(0.0), m_throttleVal(0.0), m_brakePress(0.0), m_brakeBias(54.0), m_rawBrake(0.0), // added rawBrake everywhere
    // Default Booleans
    m_coolingActive(false), m_radioActive(false), m_tvActive(false),
    m_tcWarning(false), m_regenActive(false), m_ssActive(false),
    // Default Accumulator Values
    m_soc(100), m_voltage(600.0), m_currentDc(0.0), m_power(0.0), m_powerTarget(60.0),//-------changed voltage to 600 change back to 0
    m_minCellTemp(20.0), m_maxCellTemp(25.0), m_minCellVoltage(4.1), m_maxCellVoltage(4.2),
    // Default Powertrain (4WD)
    m_torqueReqFL(0), m_torqueReqFR(0), m_torqueReqRL(0), m_torqueReqRR(0),
    m_torqueActFL(0), m_torqueActFR(0), m_torqueActRL(0), m_torqueActRR(0),
    m_rpmFL(0), m_rpmFR(0), m_rpmRL(0), m_rpmRR(0),
    m_tyrePressFL(1.2), m_tyrePressFR(1.2), m_tyrePressRL(1.2), m_tyrePressRR(1.2),
    m_tyreTempFL(30.0), m_tyreTempFR(30.0), m_tyreTempRL(30.0), m_tyreTempRR(30.0),
    m_motorTempFL(25.0), m_motorTempFR(25.0), m_motorTempRL(25.0), m_motorTempRR(25.0),
    m_igbtTempFL(25.0), m_igbtTempFR(25.0), m_igbtTempRL(25.0), m_igbtTempRR(25.0),
    // Accumulator Cells
    m_cell1MinV(0.0), m_cell2MinV(0.0), m_cell3MinV(0.0), m_cell4MinV(0.0), m_cell5MinV(0.0), m_cell6MinV(0.0), m_cell7MinV(0.0), m_cell8MinV(0.0), m_cell9MinV(0.0), m_cell10MinV(0.0), m_cell11MinV(0.0), m_cell12MinV(0.0),
    m_cell1MaxV(0.0), m_cell2MaxV(0.0), m_cell3MaxV(0.0), m_cell4MaxV(0.0), m_cell5MaxV(0.0), m_cell6MaxV(0.0), m_cell7MaxV(0.0), m_cell8MaxV(0.0), m_cell9MaxV(0.0), m_cell10MaxV(0.0), m_cell11MaxV(0.0), m_cell12MaxV(0.0),
    m_cell1Temp(0.0), m_cell2Temp(0.0), m_cell3Temp(0.0), m_cell4Temp(0.0), m_cell5Temp(0.0), m_cell6Temp(0.0), m_cell7Temp(0.0), m_cell8Temp(0.0), m_cell9Temp(0.0), m_cell10Temp(0.0), m_cell11Temp(0.0), m_cell12Temp(0.0)
{
    loadDbc();   // CAN message catalogue for the sniffer (bundled can_dbc.json)

    // Freshness heartbeat: bump freshTick ~2 Hz so stale values flip to "—" even
    // when no new frame is arriving (a frozen reading is as dangerous as a fake one).
    m_freshTimer = new QTimer(this);
    m_freshTimer->setInterval(500);
    connect(m_freshTimer, &QTimer::timeout, this, [this]() {
        ++m_freshTick;
        emit freshTickChanged();
    });
    m_freshTimer->start();

    // Initialize the Serial Port
    m_serial = new QSerialPort(this);

    // TEMPORARY (presentation): auto-pick the first USB serial device so the
    // same binary works on macOS (/dev/cu.usbmodem*), Linux (/dev/ttyACM0,
    // /dev/ttyUSB0), and the Pi (/dev/serial0 fallback).
    QString chosenPort = QStringLiteral("/dev/serial0");
    const auto ports = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &info : ports) {
        const QString name = info.portName();
        if (name.contains("usbmodem", Qt::CaseInsensitive) ||
            name.contains("usbserial", Qt::CaseInsensitive) ||
            name.startsWith("ttyACM") ||
            name.startsWith("ttyUSB")) {
            chosenPort = info.systemLocation();
            qDebug() << "Auto-detected serial device:" << chosenPort;
            break;
        }
    }
    m_serial->setPortName(chosenPort);
    m_serial->setBaudRate(QSerialPort::Baud115200);

    // Wire the hardware interrupt (readyRead) to our software slot (parseUartData)
    connect(m_serial, &QSerialPort::readyRead, this, &VehicleDataProvider::parseUartData); // Most crucial line!!!!

    // Open the port ReadWrite — we both receive telemetry AND transmit commands
    // (mission select, tuning knobs / steering-wheel toggles). Opening ReadOnly
    // silently dropped every write(), so TX never actually left the dashboard.
    if(m_serial->open(QIODevice::ReadWrite)) {
        qDebug() << "Successfully opened UART port:" << chosenPort;
    } else {
        qDebug() << "Failed to open UART port" << chosenPort << ":" << m_serial->errorString();
    }
}


//THE READ/WRITE BUFFERS (Getters & Setters)
void VehicleDataProvider::setCoolingActive(bool active) { if(m_coolingActive != active) { m_coolingActive = active; emit coolingActiveChanged(); } }
void VehicleDataProvider::setTvActive(bool active) { if(m_tvActive != active) { m_tvActive = active; emit tvActiveChanged(); } }
void VehicleDataProvider::setRegenActive(bool active) { if(m_regenActive != active) { m_regenActive = active; emit regenActiveChanged(); } }
void VehicleDataProvider::setSsActive(bool active) { if(m_ssActive != active) { m_ssActive = active; emit ssActiveChanged(); } }
void VehicleDataProvider::setTcWarning(bool active) { if(m_tcWarning != active) { m_tcWarning = active; emit tcWarningChanged(); } }
void VehicleDataProvider::setRadioActive(bool active) { if(m_radioActive != active) { m_radioActive = active; emit radioActiveChanged(); } }

int VehicleDataProvider::speed() const { return m_speed; }
double VehicleDataProvider::lapTime() const { return m_lapTime; }
double VehicleDataProvider::timeDelta() const { return m_timeDelta; }
int VehicleDataProvider::lapCount() const { return m_lapCount; }
double VehicleDataProvider::accelX() const { return m_accelX; }
double VehicleDataProvider::accelY() const { return m_accelY; }
double VehicleDataProvider::throttleVal() const { return m_throttleVal; }
double VehicleDataProvider::brakePress() const { return m_brakePress; }
double VehicleDataProvider::brakeBias() const { return m_brakeBias; }
double VehicleDataProvider::rawBrake() const {return m_rawBrake;}

bool VehicleDataProvider::coolingActive() const { return m_coolingActive; }
bool VehicleDataProvider::radioActive() const { return m_radioActive; }
bool VehicleDataProvider::tvActive() const { return m_tvActive; }
bool VehicleDataProvider::tcWarning() const { return m_tcWarning; }
bool VehicleDataProvider::regenActive() const { return m_regenActive; }
bool VehicleDataProvider::ssActive() const { return m_ssActive; }

int VehicleDataProvider::soc() const { return m_soc; }
double VehicleDataProvider::voltage() const { return m_voltage; }
double VehicleDataProvider::currentDc() const { return m_currentDc; }
double VehicleDataProvider::power() const { return m_power; }
double VehicleDataProvider::powerTarget() const { return m_powerTarget; }
double VehicleDataProvider::minCellTemp() const { return m_minCellTemp; }
double VehicleDataProvider::maxCellTemp() const { return m_maxCellTemp; }
double VehicleDataProvider::minCellVoltage() const { return m_minCellVoltage; }
double VehicleDataProvider::maxCellVoltage() const { return m_maxCellVoltage; }

int VehicleDataProvider::torqueReqFL() const { return m_torqueReqFL; }
int VehicleDataProvider::torqueReqFR() const { return m_torqueReqFR; }
int VehicleDataProvider::torqueReqRL() const { return m_torqueReqRL; }
int VehicleDataProvider::torqueReqRR() const { return m_torqueReqRR; }
int VehicleDataProvider::torqueActFL() const { return m_torqueActFL; }
int VehicleDataProvider::torqueActFR() const { return m_torqueActFR; }
int VehicleDataProvider::torqueActRL() const { return m_torqueActRL; }
int VehicleDataProvider::torqueActRR() const { return m_torqueActRR; }
int VehicleDataProvider::rpmFL() const { return m_rpmFL; }
int VehicleDataProvider::rpmFR() const { return m_rpmFR; }
int VehicleDataProvider::rpmRL() const { return m_rpmRL; }
int VehicleDataProvider::rpmRR() const { return m_rpmRR; }
double VehicleDataProvider::tyrePressFL() const { return m_tyrePressFL; }
double VehicleDataProvider::tyrePressFR() const { return m_tyrePressFR; }
double VehicleDataProvider::tyrePressRL() const { return m_tyrePressRL; }
double VehicleDataProvider::tyrePressRR() const { return m_tyrePressRR; }
double VehicleDataProvider::tyreTempFL() const { return m_tyreTempFL; }
double VehicleDataProvider::tyreTempFR() const { return m_tyreTempFR; }
double VehicleDataProvider::tyreTempRL() const { return m_tyreTempRL; }
double VehicleDataProvider::tyreTempRR() const { return m_tyreTempRR; }
double VehicleDataProvider::motorTempFL() const { return m_motorTempFL; }
double VehicleDataProvider::motorTempFR() const { return m_motorTempFR; }
double VehicleDataProvider::motorTempRL() const { return m_motorTempRL; }
double VehicleDataProvider::motorTempRR() const { return m_motorTempRR; }
double VehicleDataProvider::igbtTempFL() const { return m_igbtTempFL; }
double VehicleDataProvider::igbtTempFR() const { return m_igbtTempFR; }
double VehicleDataProvider::igbtTempRL() const { return m_igbtTempRL; }
double VehicleDataProvider::igbtTempRR() const { return m_igbtTempRR; }

//accumulator getters
// CELL DIAGNOSTIC GETTERS
double VehicleDataProvider::cell1MinV() const { return m_cell1MinV; } double VehicleDataProvider::cell2MinV() const { return m_cell2MinV; } double VehicleDataProvider::cell3MinV() const { return m_cell3MinV; } double VehicleDataProvider::cell4MinV() const { return m_cell4MinV; } double VehicleDataProvider::cell5MinV() const { return m_cell5MinV; } double VehicleDataProvider::cell6MinV() const { return m_cell6MinV; } double VehicleDataProvider::cell7MinV() const { return m_cell7MinV; } double VehicleDataProvider::cell8MinV() const { return m_cell8MinV; } double VehicleDataProvider::cell9MinV() const { return m_cell9MinV; } double VehicleDataProvider::cell10MinV() const { return m_cell10MinV; } double VehicleDataProvider::cell11MinV() const { return m_cell11MinV; } double VehicleDataProvider::cell12MinV() const { return m_cell12MinV; }
double VehicleDataProvider::cell1MaxV() const { return m_cell1MaxV; } double VehicleDataProvider::cell2MaxV() const { return m_cell2MaxV; } double VehicleDataProvider::cell3MaxV() const { return m_cell3MaxV; } double VehicleDataProvider::cell4MaxV() const { return m_cell4MaxV; } double VehicleDataProvider::cell5MaxV() const { return m_cell5MaxV; } double VehicleDataProvider::cell6MaxV() const { return m_cell6MaxV; } double VehicleDataProvider::cell7MaxV() const { return m_cell7MaxV; } double VehicleDataProvider::cell8MaxV() const { return m_cell8MaxV; } double VehicleDataProvider::cell9MaxV() const { return m_cell9MaxV; } double VehicleDataProvider::cell10MaxV() const { return m_cell10MaxV; } double VehicleDataProvider::cell11MaxV() const { return m_cell11MaxV; } double VehicleDataProvider::cell12MaxV() const { return m_cell12MaxV; }
double VehicleDataProvider::cell1Temp() const { return m_cell1Temp; } double VehicleDataProvider::cell2Temp() const { return m_cell2Temp; } double VehicleDataProvider::cell3Temp() const { return m_cell3Temp; } double VehicleDataProvider::cell4Temp() const { return m_cell4Temp; } double VehicleDataProvider::cell5Temp() const { return m_cell5Temp; } double VehicleDataProvider::cell6Temp() const { return m_cell6Temp; } double VehicleDataProvider::cell7Temp() const { return m_cell7Temp; } double VehicleDataProvider::cell8Temp() const { return m_cell8Temp; } double VehicleDataProvider::cell9Temp() const { return m_cell9Temp; } double VehicleDataProvider::cell10Temp() const { return m_cell10Temp; } double VehicleDataProvider::cell11Temp() const { return m_cell11Temp; } double VehicleDataProvider::cell12Temp() const { return m_cell12Temp; }

// Q_INVOKABLE UI INTERACTION
void VehicleDataProvider::toggleTractionControl(bool enable) {
    setTcWarning(enable);
    setKnobValue(9, enable ? 1.0f : 0.0f); // TCON = 9
}

void VehicleDataProvider::toggleTorqueVectoring(bool enable) {
    setTvActive(enable);
    setKnobValue(8, enable ? 1.0f : 0.0f); // TVON = 8
}

void VehicleDataProvider::toggleRegen(bool enable) {
    setRegenActive(enable);
    setKnobValue(7, enable ? 1.0f : 0.0f); // REGENON = 7
}

void VehicleDataProvider::setKnobValue(int index, float value) {
    QByteArray payload;
    payload.resize(5); // DLC is 5 for DASH_TUNING_VCU
    payload[0] = static_cast<uint8_t>(index);
    memcpy(payload.data() + 1, &value, sizeof(float));

    // Send CAN ID 106 (0x6A), DLC 5
    sendUartCanMessage(106, 5, payload);
}

// MISSION SELECT TRANSMITTER
// Driver confirmed an autonomous mission on the MissionSelectionPage -> send a
// framed 3-byte packet down the UART for the autonomous/VCU board:
//   [0xAA header] [ASCII '1'..'7'] [checksum = 0xAA ^ value]
//   1 = Manual driving   2 = Acceleration   3 = Skidpad   4 = Autocross
//   5 = Trackdrive       6 = EBS test       7 = DV Inspection
void VehicleDataProvider::selectMissionMode(int missionCode) {
    if (missionCode < 1 || missionCode > 7) {
        qWarning() << "selectMissionMode: ignoring out-of-range code" << missionCode;
        return;
    }
    if (!m_serial || !m_serial->isOpen()) {
        qWarning() << "selectMissionMode: serial port not open, cannot send" << missionCode;
        return;
    }

    const uint8_t value = static_cast<uint8_t>('0' + missionCode); // ASCII '1'..'6'
    QByteArray cmd;
    cmd.append(static_cast<char>(0xAA));               // header / sync byte
    cmd.append(static_cast<char>(value));              // payload: '1'..'6'
    cmd.append(static_cast<char>(0xAA ^ value));       // XOR checksum
    m_serial->write(cmd);
    qDebug() << "Mission select -> UART:" << cmd.toHex(' ');
}

// UART TRANSMITTER
void VehicleDataProvider::sendUartCanMessage(uint32_t canId, uint8_t dlc, const QByteArray& data) {
    if (!m_serial || !m_serial->isOpen()) return;

    QByteArray uartPacket;
    uartPacket.append(static_cast<char>(0xAA)); // Sync byte

    // 32-bit CAN ID (Little-Endian to match your receiver FSM)
    uartPacket.append(static_cast<char>(canId & 0xFF));
    uartPacket.append(static_cast<char>((canId >> 8) & 0xFF));
    uartPacket.append(static_cast<char>((canId >> 16) & 0xFF));
    uartPacket.append(static_cast<char>((canId >> 24) & 0xFF));

    uartPacket.append(static_cast<char>(dlc));  // DLC
    uartPacket.append(data);                    // Payload

    // Calculate Checksum (XOR logic matches your receiver)
    uint8_t checksum = dlc;
    for (int i = 0; i < data.size(); i++) {
        checksum ^= static_cast<uint8_t>(data[i]);
    }
    uartPacket.append(static_cast<char>(checksum));

    // Dispatch to hardware
    m_serial->write(uartPacket);
}

// ==========================================
// STEERING-WHEEL INPUT HANDLER
// ==========================================
// Protocol (steeringwheel-STeeringV3 firmware, Core/Src/main.c):
//   ID 0x01..0x05 = encoder 1..5 rotation, VALUE 1=CW 2=CCW
//   ID 0x06 / 0x07 / 0x0C = encoder 1/2/3 push (S1/S2/S3), VALUE 1=pressed
//   ID 0x08 RB, 0x09 LB, 0x0A Back, 0x0B Spare, 0x0D InnerRight, 0x0E InnerLeft
// A detent emits 1-2 pulses and the switches aren't debounced in firmware, so
// every event is time-debounced here: one detent / one press = one action.
void VehicleDataProvider::handleSteeringWheelInput(uint8_t id, uint8_t value) {
    static constexpr int kRotDebounceMs = 70;   // collapse a detent's extra pulses
    static constexpr int kBtnDebounceMs = 180;  // swallow mechanical switch bounce
    const qint64 now = QDateTime::currentMSecsSinceEpoch();

    // ---- Encoder rotations (0x01..0x05), VALUE 1=CW 2=CCW ------------------
    if (id >= 0x01 && id <= 0x05) {
        if (id == m_lastRotId && (now - m_lastRotMs) < kRotDebounceMs)
            return;                              // duplicate pulse of the same detent
        m_lastRotId = id;
        m_lastRotMs = now;

        const bool cw = (value == 1);
        switch (id) {
        case 0x01:                               // central encoder 1 -> page nav (or scroll on mission page)
            if (cw) emit navigateNextPage();
            else    emit navigatePrevPage();
            break;
        default:                                 // EN2..EN5 unused (single-rotary control)
            break;
        }
        return;
    }

    // ---- Switches & buttons (VALUE always 1 = pressed) --------------------
    if (id == m_lastBtnId && (now - m_lastBtnMs) < kBtnDebounceMs)
        return;                                  // mechanical bounce
    m_lastBtnId = id;
    m_lastBtnMs = now;

    switch (id) {
    case 0x06:                                   // encoder-1 push -> select / confirm
        emit selectPressed();
        break;
    case 0x0A:                                   // Back button -> previous page
        emit navigateBack();
        break;
    case 0x0D:                                   // Inner-Right -> toggle the main menu
        emit toggleMenu();
        break;
    // Status indicators (Regen / TC / TV / cooling / …) are driven SOLELY by the
    // ECU now — the ECU is the single source of truth and a driver-board request
    // isn't safety-critical, so the wheel no longer toggles them locally.
    // RB (0x08), LB (0x09), Inner-Left (0x0E), S2 (0x07), Spare (0x0B) are free.
    default:
        break;
    }
}

//THE UART INTERRUPT SERVICE ROUTINE

void VehicleDataProvider::parseUartData() {
    // 1. Grab whatever bytes just arrived on the serial port
    QByteArray rawData = m_serial->readAll();

    // 2. Feed every single byte, one by one, into the State Machine
    for (int i = 0; i < rawData.size(); ++i) {
        processIncomingByte(static_cast<uint8_t>(rawData.at(i)));
    }
}

// ==========================================
// THE FINITE STATE MACHINE (FSM)
// ==========================================
void VehicleDataProvider::processIncomingByte(uint8_t byte) {
    switch (m_rxState) {

    case WAIT_SYNC:
        // Waiting for the magic 0xAA start byte
        if (byte == 0xAA) {
            m_rxState = READ_ID;
            m_bytesRead = 0;
            m_currentId = 0;
        }
        break;

    case READ_ID:
        // Reconstruct the 32-bit CAN ID (Little-Endian)
        m_currentId |= (static_cast<uint32_t>(byte) << (m_bytesRead * 8));
        m_bytesRead++;
        
        // INTERCEPT STEERING WHEEL 4-BYTE PACKET [0xAA, MSG_ID, VALUE, CHECKSUM]
        if (m_bytesRead == 3) {
            uint8_t msgId = m_currentId & 0xFF;
            uint8_t value = (m_currentId >> 8) & 0xFF;
            uint8_t expectedChecksum = 0xAA ^ msgId ^ value;
            
            // Steering-wheel IDs span 0x01..0x0E: 0x01-0x05 are encoder
            // rotations, 0x06-0x0E are switches/buttons. (The old code stopped
            // at 0x06 and silently dropped every encoder rotation.) The XOR
            // checksum guards against a real CAN header being mistaken for one.
            if (msgId >= 0x01 && msgId <= 0x0E && byte == expectedChecksum) {
                // SUCCESS! It's a physical wheel event, not a CAN packet header
                handleSteeringWheelInput(msgId, value);
                m_rxState = WAIT_SYNC; // Reset the FSM
                break;
            }
        }

        if (m_bytesRead == 4) {
            m_rxState = READ_DLC;
        }
        break;

    case READ_DLC:
        // The Length of the data payload
        m_currentDlc = byte;
        m_payloadBuffer.clear();

        if (m_currentDlc > 0 && m_currentDlc <= 8) {
            m_rxState = READ_DATA;
        } else {
            m_rxState = READ_CHECKSUM;
        }
        break;

    case READ_DATA:
        // Collect the raw payload bytes
        m_payloadBuffer.append(byte);
        if (m_payloadBuffer.size() == m_currentDlc) {
            m_rxState = READ_CHECKSUM;
        }
        break;

    case READ_CHECKSUM:
        // Verify integrity using XOR checksum
        uint8_t calculatedChecksum = m_currentDlc;
        for (int i = 0; i < m_payloadBuffer.size(); i++) {
            calculatedChecksum ^= static_cast<uint8_t>(m_payloadBuffer[i]);
        }

        if (calculatedChecksum == byte) {
            // SUCCESS! The packet is 100% valid. Send it to the DBC decoder.
            ++m_rxFramesOk;
            parseCanMessage(m_currentId, m_currentDlc, m_payloadBuffer);
        } else {
            ++m_rxChecksumFail;
            qWarning() << "UART Checksum Failed! Dropping packet.";
        }

        // Reset to look for the next message
        m_rxState = WAIT_SYNC;
        break;
    }
}

// ==========================================
// PHASE 3: THE DBC DECODER
// ==========================================
void VehicleDataProvider::parseCanMessage(uint32_t canId, uint8_t dlc, const QByteArray& data) {

    // CAN sniffer: record EVERY valid frame (known or not) for the live trace.
    recordRawFrame(canId, data);

    if (data.size() < dlc) return; // Safety check

#define UPDATE_VAL(member, newVal, signal) \
    if (member != (newVal)) { member = (newVal); emit signal(); }

    auto extractU16 = [](const QByteArray& d, int startIndex) -> uint16_t {
        return static_cast<uint8_t>(d[startIndex]) | (static_cast<uint8_t>(d[startIndex + 1]) << 8);
    };
    auto extractS16 = [](const QByteArray& d, int startIndex) -> int16_t {
        return static_cast<uint8_t>(d[startIndex]) | (static_cast<uint8_t>(d[startIndex + 1]) << 8);
    };

    switch (canId) {

    // ----------------------------------------------------
    // ID 801: HERO GAUGE (Speed, Power, SoC, Status Bools)
    // ----------------------------------------------------
    case 801: {
        if (dlc >= 8) {
            UPDATE_VAL(m_power, static_cast<int8_t>(data[0]) * 1.0, powerChanged);
            UPDATE_VAL(m_speed, static_cast<int>(extractS16(data, 3) * 0.01), speedChanged);
            UPDATE_VAL(m_soc, static_cast<int>(static_cast<int8_t>(data[6])), socChanged);

            bool tvOn      = (data[7] & (1 << 0)) != 0;
            bool regenOn   = (data[7] & (1 << 1)) != 0;
            bool tcOn      = (data[7] & (1 << 2)) != 0;
            bool coolingOn = (data[7] & (1 << 3)) != 0; // TEMP demo: bits 3-5 carry
            bool radioOn   = (data[7] & (1 << 4)) != 0; // cooling/radio/sideslip from
            bool ssOn      = (data[7] & (1 << 5)) != 0; // the Arduino demo bridge
            UPDATE_VAL(m_tvActive, tvOn, tvActiveChanged);
            UPDATE_VAL(m_regenActive, regenOn, regenActiveChanged);
            UPDATE_VAL(m_tcWarning, tcOn, tcWarningChanged);
            UPDATE_VAL(m_coolingActive, coolingOn, coolingActiveChanged);
            UPDATE_VAL(m_radioActive, radioOn, radioActiveChanged);
            UPDATE_VAL(m_ssActive, ssOn, ssActiveChanged);
        }
        break;
    }

    // ----------------------------------------------------
    // ID 103: DASH BOOLS (Cooling Active)
    // ----------------------------------------------------
    case 103: {
        if (dlc >= 1) {
            bool cooling = (data[0] & (1 << 4)) != 0; // Bit 4
            UPDATE_VAL(m_coolingActive, cooling, coolingActiveChanged);
        }
        break;
    }

    // ----------------------------------------------------
    // ID 806: VCU APU INFO (Power Target)
    // ----------------------------------------------------
    case 806: {
        if (dlc >= 4) {
            // Power_Target_kW starts at bit 19, length 10.
            // Bits 19-28 span across Byte 2 and Byte 3.
            uint16_t rawPowerTarget = (extractU16(data, 2) >> 3) & 0x03FF;
            UPDATE_VAL(m_powerTarget, rawPowerTarget * 0.1, powerTargetChanged);
        }
        break;
    }

    // ----------------------------------------------------
    // ID 1282: SYSTEM STATUS (Lap Counter)
    // ----------------------------------------------------
    case 1282: {
        if (dlc >= 2) {
            // LAP_COUNTER starts at bit 11, length 4. (Inside Byte 1)
            uint8_t rawLap = (data[1] >> 3) & 0x0F;
            UPDATE_VAL(m_lapCount, static_cast<int>(rawLap), lapCountChanged);
        }
        break;
    }

    // ----------------------------------------------------
    // ID 1315: ISABELLEN MEASUREMENT (HV Voltage & Current)
    // ----------------------------------------------------
    case 1315: {
        if (dlc >= 6) {
            UPDATE_VAL(m_voltage, extractS16(data, 0) * 0.1, voltageChanged);
            // Idc_16_bit is at bit 32 (Byte 4)
            UPDATE_VAL(m_currentDc, extractS16(data, 4) * 0.01, currentDcChanged);
        }
        break;
    }

    // ----------------------------------------------------
    // PEDALS & G-METER
    // ----------------------------------------------------
    case 798: // APPS
        if (dlc >= 2) UPDATE_VAL(m_throttleVal, extractU16(data, 0) * 0.001, throttleValChanged);
        break;
    case 101: // Brake Pressure
        if (dlc >= 2) UPDATE_VAL(m_brakePress, std::min((extractU16(data, 0) * 0.01) / 300.0, 1.0), brakePressChanged); // maximum is 300
        if (dlc >= 2) UPDATE_VAL(m_rawBrake,(extractU16(data,0)* 0.01), rawBrakeChanged); // added reading for raw brake pressure
        break;
    case 1799: // SensoricSolutions Accel
        if (dlc >= 4) {
            UPDATE_VAL(m_accelX, (extractS16(data, 0) * 0.02) / 9.81, accelXChanged);
            UPDATE_VAL(m_accelY, (extractS16(data, 2) * 0.02) / 9.81, accelYChanged);
        }
        break;

    // ----------------------------------------------------
    // INVERTERS (701 - 704) -> [FIXED TORQUE OFFSETS]
    // ----------------------------------------------------
    case 701: // RL
        if (dlc >= 8) {
            UPDATE_VAL(m_igbtTempRL, static_cast<double>(data[0]), igbtTempRLChanged);
            UPDATE_VAL(m_motorTempRL, static_cast<double>(data[1]), motorTempRLChanged);
            UPDATE_VAL(m_rpmRL, static_cast<int>(extractS16(data, 2)), rpmRLChanged);
            UPDATE_VAL(m_torqueReqRL, static_cast<int>(extractS16(data, 4) * 0.01), torqueReqRLChanged); // Byte 4
            UPDATE_VAL(m_torqueActRL, static_cast<int>(extractS16(data, 6) * 0.01), torqueActRLChanged); // Byte 6
        }
        break;
    case 702: // RR
        if (dlc >= 8) {
            UPDATE_VAL(m_igbtTempRR, static_cast<double>(data[0]), igbtTempRRChanged);
            UPDATE_VAL(m_motorTempRR, static_cast<double>(data[1]), motorTempRRChanged);
            UPDATE_VAL(m_rpmRR, static_cast<int>(extractS16(data, 2)), rpmRRChanged);
            UPDATE_VAL(m_torqueReqRR, static_cast<int>(extractS16(data, 4) * 0.01), torqueReqRRChanged);
            UPDATE_VAL(m_torqueActRR, static_cast<int>(extractS16(data, 6) * 0.01), torqueActRRChanged);
        }
        break;
    case 703: // FL
        if (dlc >= 8) {
            UPDATE_VAL(m_igbtTempFL, static_cast<double>(data[0]), igbtTempFLChanged);
            UPDATE_VAL(m_motorTempFL, static_cast<double>(data[1]), motorTempFLChanged);
            UPDATE_VAL(m_rpmFL, static_cast<int>(extractS16(data, 2)), rpmFLChanged);
            UPDATE_VAL(m_torqueReqFL, static_cast<int>(extractS16(data, 4) * 0.01), torqueReqFLChanged);
            UPDATE_VAL(m_torqueActFL, static_cast<int>(extractS16(data, 6) * 0.01), torqueActFLChanged);
        }
        break;
    case 704: // FR
        if (dlc >= 8) {
            UPDATE_VAL(m_igbtTempFR, static_cast<double>(data[0]), igbtTempFRChanged);
            UPDATE_VAL(m_motorTempFR, static_cast<double>(data[1]), motorTempFRChanged);
            UPDATE_VAL(m_rpmFR, static_cast<int>(extractS16(data, 2)), rpmFRChanged);
            UPDATE_VAL(m_torqueReqFR, static_cast<int>(extractS16(data, 4) * 0.01), torqueReqFRChanged);
            UPDATE_VAL(m_torqueActFR, static_cast<int>(extractS16(data, 6) * 0.01), torqueActFRChanged);
        }
        break;

    // ----------------------------------------------------
    // BMS CELL VOLTAGES & TEMPS (1600 - 1608)
    // ----------------------------------------------------
    case 1600: // Cells 1 & 2
        if (dlc >= 8) {
            UPDATE_VAL(m_cell1MinV, extractU16(data, 0) * 0.001, cell1MinVChanged);
            UPDATE_VAL(m_cell1MaxV, extractU16(data, 2) * 0.001, cell1MaxVChanged);
            UPDATE_VAL(m_cell2MinV, extractU16(data, 4) * 0.001, cell2MinVChanged);
            UPDATE_VAL(m_cell2MaxV, extractU16(data, 6) * 0.001, cell2MaxVChanged);
        }
        break;
    case 1601: // Cells 3 & 4
        if (dlc >= 8) {
            UPDATE_VAL(m_cell3MinV, extractU16(data, 0) * 0.001, cell3MinVChanged);
            UPDATE_VAL(m_cell3MaxV, extractU16(data, 2) * 0.001, cell3MaxVChanged);
            UPDATE_VAL(m_cell4MinV, extractU16(data, 4) * 0.001, cell4MinVChanged);
            UPDATE_VAL(m_cell4MaxV, extractU16(data, 6) * 0.001, cell4MaxVChanged);
        }
        break;
    case 1602: // Cells 5 & 6
        if (dlc >= 8) {
            UPDATE_VAL(m_cell5MinV, extractU16(data, 0) * 0.001, cell5MinVChanged);
            UPDATE_VAL(m_cell5MaxV, extractU16(data, 2) * 0.001, cell5MaxVChanged);
            UPDATE_VAL(m_cell6MinV, extractU16(data, 4) * 0.001, cell6MinVChanged);
            UPDATE_VAL(m_cell6MaxV, extractU16(data, 6) * 0.001, cell6MaxVChanged);
        }
        break;
    case 1603: // Cells 7 & 8
        if (dlc >= 8) {
            UPDATE_VAL(m_cell7MinV, extractU16(data, 0) * 0.001, cell7MinVChanged);
            UPDATE_VAL(m_cell7MaxV, extractU16(data, 2) * 0.001, cell7MaxVChanged);
            UPDATE_VAL(m_cell8MinV, extractU16(data, 4) * 0.001, cell8MinVChanged);
            UPDATE_VAL(m_cell8MaxV, extractU16(data, 6) * 0.001, cell8MaxVChanged);
        }
        break;
    case 1604: // Cells 9 & 10
        if (dlc >= 8) {
            UPDATE_VAL(m_cell9MinV, extractU16(data, 0) * 0.001, cell9MinVChanged);
            UPDATE_VAL(m_cell9MaxV, extractU16(data, 2) * 0.001, cell9MaxVChanged);
            UPDATE_VAL(m_cell10MinV, extractU16(data, 4) * 0.001, cell10MinVChanged);
            UPDATE_VAL(m_cell10MaxV, extractU16(data, 6) * 0.001, cell10MaxVChanged);
        }
        break;
    case 1605: // Cells 11 & 12
        if (dlc >= 8) {
            UPDATE_VAL(m_cell11MinV, extractU16(data, 0) * 0.001, cell11MinVChanged);
            UPDATE_VAL(m_cell11MaxV, extractU16(data, 2) * 0.001, cell11MaxVChanged);
            UPDATE_VAL(m_cell12MinV, extractU16(data, 4) * 0.001, cell12MinVChanged);
            UPDATE_VAL(m_cell12MaxV, extractU16(data, 6) * 0.001, cell12MaxVChanged);
        }
        break;
    case 1606: // Temp Cells 1-4
        if (dlc >= 8) {
            UPDATE_VAL(m_cell1Temp, extractU16(data, 0) * 0.01, cell1TempChanged);
            UPDATE_VAL(m_cell2Temp, extractU16(data, 2) * 0.01, cell2TempChanged);
            UPDATE_VAL(m_cell3Temp, extractU16(data, 4) * 0.01, cell3TempChanged);
            UPDATE_VAL(m_cell4Temp, extractU16(data, 6) * 0.01, cell4TempChanged);
        }
        break;
    case 1607: // Temp Cells 5-8
        if (dlc >= 8) {
            UPDATE_VAL(m_cell5Temp, extractU16(data, 0) * 0.01, cell5TempChanged);
            UPDATE_VAL(m_cell6Temp, extractU16(data, 2) * 0.01, cell6TempChanged);
            UPDATE_VAL(m_cell7Temp, extractU16(data, 4) * 0.01, cell7TempChanged);
            UPDATE_VAL(m_cell8Temp, extractU16(data, 6) * 0.01, cell8TempChanged);
        }
        break;
    case 1608: // Temp Cells 9-12
        if (dlc >= 8) {
            UPDATE_VAL(m_cell9Temp, extractU16(data, 0) * 0.01, cell9TempChanged);
            UPDATE_VAL(m_cell10Temp, extractU16(data, 2) * 0.01, cell10TempChanged);
            UPDATE_VAL(m_cell11Temp, extractU16(data, 4) * 0.01, cell11TempChanged);
            UPDATE_VAL(m_cell12Temp, extractU16(data, 6) * 0.01, cell12TempChanged);
        }
        break;

    default:
        break;
    }

#undef UPDATE_VAL
}

// ==========================================
// CAN SNIFFER (DBC-driven, Kvaser-style live trace)
// ==========================================

// Load the static message catalogue produced by tools/dbc_to_json.py.
void VehicleDataProvider::loadDbc() {
    // Try the known Qt-resource prefixes (qt_add_qml_module placement varies by Qt version).
    const QStringList candidates = {
        QStringLiteral(":/FormulaDash/can_dbc.json"),
        QStringLiteral(":/qt/qml/FormulaDash/can_dbc.json"),
        QStringLiteral(":/can_dbc.json")
    };
    QFile f;
    for (const QString &p : candidates) {
        f.setFileName(p);
        if (f.open(QIODevice::ReadOnly))
            break;
    }
    if (!f.isOpen()) {
        qWarning() << "CAN sniffer: could not open can_dbc.json from any resource path";
        return;
    }
    const QJsonObject root = QJsonDocument::fromJson(f.readAll()).object();
    const QJsonArray msgs  = root.value(QStringLiteral("messages")).toArray();
    m_dbc.clear();
    m_dbcIndex.clear();
    for (const QJsonValue &mv : msgs) {
        const QJsonObject mo = mv.toObject();
        CanMessageDef def;
        def.id   = static_cast<quint32>(mo.value("id").toDouble());
        def.name = mo.value("name").toString();
        def.dlc  = mo.value("dlc").toInt();
        const QJsonArray sigs = mo.value("signals").toArray();
        for (const QJsonValue &sv : sigs) {
            const QJsonObject so = sv.toObject();
            CanSignal s;
            s.name         = so.value("name").toString();
            s.startBit     = so.value("start").toInt();
            s.bitLen       = so.value("len").toInt();
            s.littleEndian = so.value("le").toBool(true);
            s.isSigned     = so.value("signed").toBool(false);
            s.factor       = so.value("factor").toDouble(1.0);
            s.offset       = so.value("offset").toDouble(0.0);
            s.unit         = so.value("unit").toString();
            def.sigs.append(s);
        }
        m_dbcIndex.insert(def.id, m_dbc.size());
        m_dbc.append(def);
    }
    qDebug() << "CAN sniffer: loaded" << m_dbc.size() << "messages from DBC";
}

// Stash the latest payload + arrival time for an id (called on every valid frame).
void VehicleDataProvider::recordRawFrame(quint32 id, const QByteArray &data) {
    m_rawData[id]   = data;
    m_rawLastMs[id] = QDateTime::currentMSecsSinceEpoch();
}

// Decode one little-endian signal out of a payload (CAN_MCU.dbc is all Intel @1).
double VehicleDataProvider::decodeSignal(const QByteArray &data, const CanSignal &s) {
    quint64 raw = 0;
    const int n = qMin(data.size(), 8);
    for (int i = 0; i < n; ++i)
        raw |= static_cast<quint64>(static_cast<quint8>(data[i])) << (8 * i);

    const quint64 mask = (s.bitLen >= 64) ? ~0ULL : ((1ULL << s.bitLen) - 1ULL);
    const quint64 bits = (raw >> s.startBit) & mask;

    if (s.isSigned && s.bitLen < 64 && (bits & (1ULL << (s.bitLen - 1))))
        return static_cast<double>(static_cast<qint64>(bits | ~mask)) * s.factor + s.offset;
    return static_cast<double>(bits) * s.factor + s.offset;
}

// Tell the other board to start/stop flooding every CAN message.
// Framed command: [0xAA][id][0xAA^id]; id 'S' = start, 'E' = end.
void VehicleDataProvider::setSnifferActive(bool on) {
    if (!m_serial || !m_serial->isOpen()) {
        qWarning() << "setSnifferActive: serial port not open";
        return;
    }
    const uint8_t id = on ? static_cast<uint8_t>('S') : static_cast<uint8_t>('E');
    QByteArray cmd;
    cmd.append(static_cast<char>(0xAA));
    cmd.append(static_cast<char>(id));
    cmd.append(static_cast<char>(0xAA ^ id));
    m_serial->write(cmd);
    qDebug() << "Sniffer cmd ->" << cmd.toHex(' ');
}

// The full message list for the scrollable trace (sorted by id ascending).
QVariantList VehicleDataProvider::snifferMessages() const {
    QVariantList out;
    out.reserve(m_dbc.size());
    for (const CanMessageDef &m : m_dbc) {
        QVariantMap row;
        row["id"]    = m.id;
        row["idHex"] = QStringLiteral("0x%1").arg(m.id, 3, 16, QLatin1Char('0')).toUpper();
        row["name"]  = m.name;
        row["dlc"]   = m.dlc;
        out.append(row);
    }
    return out;
}

bool VehicleDataProvider::snifferReceived(int id) const {
    return m_rawLastMs.contains(static_cast<quint32>(id));
}

QString VehicleDataProvider::snifferLastSeen(int id) const {
    const quint32 key = static_cast<quint32>(id);
    if (!m_rawLastMs.contains(key))
        return QStringLiteral("—");
    const qint64 age = QDateTime::currentMSecsSinceEpoch() - m_rawLastMs.value(key);
    if (age < 1000)
        return QString::number(age) + QStringLiteral(" ms");
    return QString::number(age / 1000.0, 'f', 1) + QStringLiteral(" s");
}

// ---- Data freshness helpers (used by every live readout in QML) ----
bool VehicleDataProvider::isFresh(int canId) const {
    const auto it = m_rawLastMs.constFind(static_cast<quint32>(canId));
    if (it == m_rawLastMs.constEnd())
        return false;                                   // never received
    return (QDateTime::currentMSecsSinceEpoch() - it.value()) <= kStaleTimeoutMs;
}

QString VehicleDataProvider::fmt(double value, int canId, int decimals) const {
    if (!isFresh(canId))
        return QStringLiteral("—");
    return QString::number(value, 'f', decimals);
}

QString VehicleDataProvider::fmtInt(double value, int canId) const {
    if (!isFresh(canId))
        return QStringLiteral("—");
    return QString::number(qRound64(value));
}

// Decode every signal of a message from its latest payload. "—" when nothing seen.
QVariantList VehicleDataProvider::snifferDecode(int id) const {
    QVariantList out;
    const quint32 key = static_cast<quint32>(id);
    if (!m_dbcIndex.contains(key))
        return out;
    const CanMessageDef &def = m_dbc.at(m_dbcIndex.value(key));
    const bool have = m_rawData.contains(key);
    const QByteArray data = have ? m_rawData.value(key) : QByteArray();
    for (const CanSignal &s : def.sigs) {
        QVariantMap row;
        row["name"] = s.name;
        row["unit"] = s.unit;
        if (!have) {
            row["value"] = QStringLiteral("—");
        } else {
            const double v = decodeSignal(data, s);
            if (s.factor == 1.0 && s.offset == 0.0)
                row["value"] = QString::number(static_cast<qint64>(v));
            else
                row["value"] = QString::number(v, 'f', 3);
        }
        out.append(row);
    }
    return out;
}