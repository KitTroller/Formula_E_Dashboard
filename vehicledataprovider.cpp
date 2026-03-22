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
#include <QStringList>
#include <QDebug>

//CONSTRUCTOR (UART Initialization)

VehicleDataProvider::VehicleDataProvider(QObject *parent)
    : QObject(parent), m_speed(0), m_lapTime(0.0), m_timeDelta(0.0), m_lapCount(0),
    m_accelX(0.0), m_accelY(0.0), m_throttleVal(0.0), m_brakePress(0.0), m_brakeBias(54.0),
    // Default Booleans
    m_coolingActive(false), m_radioActive(false), m_tvActive(false),
    m_tcWarning(false), m_regenActive(false), m_ssActive(false),
    // Default Accumulator Values
    m_soc(100), m_voltage(400.0), m_currentDc(0.0), m_power(0.0), m_powerTarget(60.0),
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
    // Initialize the Serial Port
    m_serial = new QSerialPort(this);

    // Virtual port for testing. On the Raspberry Pi, this will be "/dev/ttyAMA0" or "/dev/ttyUSB0"
    m_serial->setPortName("/tmp/ttyV0");
    m_serial->setBaudRate(QSerialPort::Baud115200);

    // Wire the hardware interrupt (readyRead) to our software slot (parseUartData)
    connect(m_serial, &QSerialPort::readyRead, this, &VehicleDataProvider::parseUartData); // Most crucial line!!!!

    // Open the port
    if(m_serial->open(QIODevice::ReadOnly)) {
        qDebug() << "Successfully opened virtual UART port!";
    } else {
        qDebug() << "Failed to open UART port. (We will create it in the terminal next)";
    }
}


//THE READ BUFFERS (Getters)
int VehicleDataProvider::speed() const { return m_speed; }
double VehicleDataProvider::lapTime() const { return m_lapTime; }
double VehicleDataProvider::timeDelta() const { return m_timeDelta; }
int VehicleDataProvider::lapCount() const { return m_lapCount; }
double VehicleDataProvider::accelX() const { return m_accelX; }
double VehicleDataProvider::accelY() const { return m_accelY; }
double VehicleDataProvider::throttleVal() const { return m_throttleVal; }
double VehicleDataProvider::brakePress() const { return m_brakePress; }
double VehicleDataProvider::brakeBias() const { return m_brakeBias; }

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

//THE UART INTERRUPT SERVICE ROUTINE
void VehicleDataProvider::parseUartData() {
    // Read all available bytes from the USB buffer
    m_serialBuffer.append(m_serial->readAll());


    // <--- THE MAGIC STATIC VARIABLES --->
//------------------------------------------------------------Testing
    // Only process the data if we see a newline (\n) character
    while (m_serialBuffer.contains('\n')) {

        // Extract one full line and remove it from the buffer
        int newlineIndex = m_serialBuffer.indexOf('\n');
        QByteArray rawLine = m_serialBuffer.left(newlineIndex);
        m_serialBuffer.remove(0, newlineIndex + 1);

        // Clean up the string (removes invisible carriage returns)
        QString dataString = QString::fromUtf8(rawLine).trimmed();

        // Chop the string by commas
        QStringList parts = dataString.split(',');

        // If we got exactly 88 pieces of data, update our memory
        if (parts.size() >= 88) {

// THE STATE-CHANGE GUARD MACRO
// This prevents the C++ from bombarding the QML GPU with redundant redraw signals
#define UPDATE_VAL(member, newVal, signal) \
            if (member != (newVal)) { member = (newVal); emit signal(); }

            // General & Driver Inputs
            UPDATE_VAL(m_speed, parts[0].toInt(), speedChanged)
            UPDATE_VAL(m_lapTime, parts[1].toDouble(), lapTimeChanged)
            UPDATE_VAL(m_timeDelta, parts[2].toDouble(), timeDeltaChanged)
            UPDATE_VAL(m_lapCount, parts[3].toInt(), lapCountChanged)
            UPDATE_VAL(m_accelX, parts[4].toDouble(), accelXChanged)
            UPDATE_VAL(m_accelY, parts[5].toDouble(), accelYChanged)
            UPDATE_VAL(m_throttleVal, parts[6].toDouble(), throttleValChanged)
            UPDATE_VAL(m_brakePress, parts[7].toDouble(), brakePressChanged)
            UPDATE_VAL(m_brakeBias, parts[8].toDouble(), brakeBiasChanged)

            // Status Indicators
            UPDATE_VAL(m_coolingActive, parts[9].toInt() == 1, coolingActiveChanged)
            UPDATE_VAL(m_radioActive, parts[10].toInt() == 1, radioActiveChanged)
            UPDATE_VAL(m_tvActive, parts[11].toInt() == 1, tvActiveChanged)
            UPDATE_VAL(m_tcWarning, parts[12].toInt() == 1, tcWarningChanged)
            UPDATE_VAL(m_regenActive, parts[13].toInt() == 1, regenActiveChanged)
            UPDATE_VAL(m_ssActive, parts[14].toInt() == 1, ssActiveChanged)

            // Accumulator
            UPDATE_VAL(m_soc, parts[15].toInt(), socChanged)
            UPDATE_VAL(m_voltage, parts[16].toDouble(), voltageChanged)
            UPDATE_VAL(m_currentDc, parts[17].toDouble(), currentDcChanged)
            UPDATE_VAL(m_power, parts[18].toDouble(), powerChanged)
            UPDATE_VAL(m_powerTarget, parts[19].toDouble(), powerTargetChanged)
            UPDATE_VAL(m_minCellTemp, parts[20].toDouble(), minCellTempChanged)
            UPDATE_VAL(m_maxCellTemp, parts[21].toDouble(), maxCellTempChanged)
            UPDATE_VAL(m_minCellVoltage, parts[22].toDouble(), minCellVoltageChanged)
            UPDATE_VAL(m_maxCellVoltage, parts[23].toDouble(), maxCellVoltageChanged)

            // Powertrain 4WD - Torque Requested
            UPDATE_VAL(m_torqueReqFL, parts[24].toInt(), torqueReqFLChanged)
            UPDATE_VAL(m_torqueReqFR, parts[25].toInt(), torqueReqFRChanged)
            UPDATE_VAL(m_torqueReqRL, parts[26].toInt(), torqueReqRLChanged)
            UPDATE_VAL(m_torqueReqRR, parts[27].toInt(), torqueReqRRChanged)

            // Powertrain 4WD - Torque Actual
            UPDATE_VAL(m_torqueActFL, parts[28].toInt(), torqueActFLChanged)
            UPDATE_VAL(m_torqueActFR, parts[29].toInt(), torqueActFRChanged)
            UPDATE_VAL(m_torqueActRL, parts[30].toInt(), torqueActRLChanged)
            UPDATE_VAL(m_torqueActRR, parts[31].toInt(), torqueActRRChanged)

            // RPM
            UPDATE_VAL(m_rpmFL, parts[32].toInt(), rpmFLChanged)
            UPDATE_VAL(m_rpmFR, parts[33].toInt(), rpmFRChanged)
            UPDATE_VAL(m_rpmRL, parts[34].toInt(), rpmRLChanged)
            UPDATE_VAL(m_rpmRR, parts[35].toInt(), rpmRRChanged)

            // Tyre Pressures
            UPDATE_VAL(m_tyrePressFL, parts[36].toDouble(), tyrePressFLChanged)
            UPDATE_VAL(m_tyrePressFR, parts[37].toDouble(), tyrePressFRChanged)
            UPDATE_VAL(m_tyrePressRL, parts[38].toDouble(), tyrePressRLChanged)
            UPDATE_VAL(m_tyrePressRR, parts[39].toDouble(), tyrePressRRChanged)

            // Tyre Temps
            UPDATE_VAL(m_tyreTempFL, parts[40].toDouble(), tyreTempFLChanged)
            UPDATE_VAL(m_tyreTempFR, parts[41].toDouble(), tyreTempFRChanged)
            UPDATE_VAL(m_tyreTempRL, parts[42].toDouble(), tyreTempRLChanged)
            UPDATE_VAL(m_tyreTempRR, parts[43].toDouble(), tyreTempRRChanged)

            // Motor Temps
            UPDATE_VAL(m_motorTempFL, parts[44].toDouble(), motorTempFLChanged)
            UPDATE_VAL(m_motorTempFR, parts[45].toDouble(), motorTempFRChanged)
            UPDATE_VAL(m_motorTempRL, parts[46].toDouble(), motorTempRLChanged)
            UPDATE_VAL(m_motorTempRR, parts[47].toDouble(), motorTempRRChanged)

            // IGBT Temps
            UPDATE_VAL(m_igbtTempFL, parts[48].toDouble(), igbtTempFLChanged)
            UPDATE_VAL(m_igbtTempFR, parts[49].toDouble(), igbtTempFRChanged)
            UPDATE_VAL(m_igbtTempRL, parts[50].toDouble(), igbtTempRLChanged)
            UPDATE_VAL(m_igbtTempRR, parts[51].toDouble(), igbtTempRRChanged)

            // Cell Min Voltages (Indices 52-63)
            UPDATE_VAL(m_cell1MinV, parts[52].toDouble(), cell1MinVChanged)
            UPDATE_VAL(m_cell2MinV, parts[53].toDouble(), cell2MinVChanged)
            UPDATE_VAL(m_cell3MinV, parts[54].toDouble(), cell3MinVChanged)
            UPDATE_VAL(m_cell4MinV, parts[55].toDouble(), cell4MinVChanged)
            UPDATE_VAL(m_cell5MinV, parts[56].toDouble(), cell5MinVChanged)
            UPDATE_VAL(m_cell6MinV, parts[57].toDouble(), cell6MinVChanged)
            UPDATE_VAL(m_cell7MinV, parts[58].toDouble(), cell7MinVChanged)
            UPDATE_VAL(m_cell8MinV, parts[59].toDouble(), cell8MinVChanged)
            UPDATE_VAL(m_cell9MinV, parts[60].toDouble(), cell9MinVChanged)
            UPDATE_VAL(m_cell10MinV, parts[61].toDouble(), cell10MinVChanged)
            UPDATE_VAL(m_cell11MinV, parts[62].toDouble(), cell11MinVChanged)
            UPDATE_VAL(m_cell12MinV, parts[63].toDouble(), cell12MinVChanged)

            // Cell Max Voltages (Indices 64-75)
            UPDATE_VAL(m_cell1MaxV, parts[64].toDouble(), cell1MaxVChanged)
            UPDATE_VAL(m_cell2MaxV, parts[65].toDouble(), cell2MaxVChanged)
            UPDATE_VAL(m_cell3MaxV, parts[66].toDouble(), cell3MaxVChanged)
            UPDATE_VAL(m_cell4MaxV, parts[67].toDouble(), cell4MaxVChanged)
            UPDATE_VAL(m_cell5MaxV, parts[68].toDouble(), cell5MaxVChanged)
            UPDATE_VAL(m_cell6MaxV, parts[69].toDouble(), cell6MaxVChanged)
            UPDATE_VAL(m_cell7MaxV, parts[70].toDouble(), cell7MaxVChanged)
            UPDATE_VAL(m_cell8MaxV, parts[71].toDouble(), cell8MaxVChanged)
            UPDATE_VAL(m_cell9MaxV, parts[72].toDouble(), cell9MaxVChanged)
            UPDATE_VAL(m_cell10MaxV, parts[73].toDouble(), cell10MaxVChanged)
            UPDATE_VAL(m_cell11MaxV, parts[74].toDouble(), cell11MaxVChanged)
            UPDATE_VAL(m_cell12MaxV, parts[75].toDouble(), cell12MaxVChanged)

            // Cell Max Temps (Indices 76-87)
            UPDATE_VAL(m_cell1Temp, parts[76].toDouble(), cell1TempChanged)
            UPDATE_VAL(m_cell2Temp, parts[77].toDouble(), cell2TempChanged)
            UPDATE_VAL(m_cell3Temp, parts[78].toDouble(), cell3TempChanged)
            UPDATE_VAL(m_cell4Temp, parts[79].toDouble(), cell4TempChanged)
            UPDATE_VAL(m_cell5Temp, parts[80].toDouble(), cell5TempChanged)
            UPDATE_VAL(m_cell6Temp, parts[81].toDouble(), cell6TempChanged)
            UPDATE_VAL(m_cell7Temp, parts[82].toDouble(), cell7TempChanged)
            UPDATE_VAL(m_cell8Temp, parts[83].toDouble(), cell8TempChanged)
            UPDATE_VAL(m_cell9Temp, parts[84].toDouble(), cell9TempChanged)
            UPDATE_VAL(m_cell10Temp, parts[85].toDouble(), cell10TempChanged)
            UPDATE_VAL(m_cell11Temp, parts[86].toDouble(), cell11TempChanged)
            UPDATE_VAL(m_cell12Temp, parts[87].toDouble(), cell12TempChanged)

#undef UPDATE_VAL
        }
        else {
            qDebug() << "Malformed UART string received:" << dataString;
        }
    }
    //----------------------------------------------------------------Testing

    //-------------------------------------------------------------------------Testing
    }
