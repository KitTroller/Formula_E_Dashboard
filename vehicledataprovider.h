#pragma once

#include <QObject>
#include <QTimer>
#include <qqml.h>
#include <QSerialPort>

class VehicleDataProvider : public QObject{
    Q_OBJECT
    QML_ELEMENT

    //Exposed registers
    Q_PROPERTY(int speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(double brakeBias READ brakeBias NOTIFY brakeBiasChanged)
    Q_PROPERTY(double accelX READ accelX NOTIFY accelXChanged)
    Q_PROPERTY(double accelY READ accelY NOTIFY accelYChanged)
    Q_PROPERTY(double lapTime READ lapTime NOTIFY lapTimeChanged)//added lap time
    Q_PROPERTY(int lapCount READ lapCount NOTIFY lapCountChanged)
    Q_PROPERTY(double throttleVal READ throttleVal NOTIFY throttleValChanged)
    Q_PROPERTY(double brakePress READ brakePress NOTIFY brakePressChanged)
    Q_PROPERTY(double timeDelta READ timeDelta NOTIFY timeDeltaChanged) // Added this

    //Status indicators
    Q_PROPERTY(bool coolingActive READ coolingActive WRITE setCoolingActive NOTIFY coolingActiveChanged)
    Q_PROPERTY(bool tvActive READ tvActive WRITE setTvActive NOTIFY tvActiveChanged)
    Q_PROPERTY(bool regenActive READ regenActive WRITE setRegenActive NOTIFY regenActiveChanged)
    Q_PROPERTY(bool ssActive READ ssActive WRITE setSsActive NOTIFY ssActiveChanged)
    Q_PROPERTY(bool tcWarning READ tcWarning WRITE setTcWarning NOTIFY tcWarningChanged)
    Q_PROPERTY(bool radioActive READ radioActive WRITE setRadioActive NOTIFY radioActiveChanged)

    //Accumulator dignostics
    Q_PROPERTY(double minCellVoltage READ minCellVoltage NOTIFY minCellVoltageChanged)
    Q_PROPERTY(double maxCellVoltage READ maxCellVoltage NOTIFY maxCellVoltageChanged)
    Q_PROPERTY(double currentDc READ currentDc NOTIFY currentDcChanged)
    Q_PROPERTY(double power READ power NOTIFY powerChanged)
    Q_PROPERTY(double powerTarget READ powerTarget NOTIFY powerTargetChanged)
    Q_PROPERTY(int soc READ soc NOTIFY socChanged)
    Q_PROPERTY(double voltage READ voltage NOTIFY voltageChanged)
    Q_PROPERTY(double minCellTemp READ minCellTemp NOTIFY minCellTempChanged)
    Q_PROPERTY(double maxCellTemp READ maxCellTemp NOTIFY maxCellTempChanged)

    //Powertrain & Tyres
    // Torque Requested (+/-)
    Q_PROPERTY(int torqueReqFL READ torqueReqFL NOTIFY torqueReqFLChanged)
    Q_PROPERTY(int torqueReqFR READ torqueReqFR NOTIFY torqueReqFRChanged)
    Q_PROPERTY(int torqueReqRL READ torqueReqRL NOTIFY torqueReqRLChanged)
    Q_PROPERTY(int torqueReqRR READ torqueReqRR NOTIFY torqueReqRRChanged)
    // Torque Actual
    Q_PROPERTY(int torqueActFL READ torqueActFL NOTIFY torqueActFLChanged)
    Q_PROPERTY(int torqueActFR READ torqueActFR NOTIFY torqueActFRChanged)
    Q_PROPERTY(int torqueActRL READ torqueActRL NOTIFY torqueActRLChanged)
    Q_PROPERTY(int torqueActRR READ torqueActRR NOTIFY torqueActRRChanged)

    // RPM
    Q_PROPERTY(int rpmFL READ rpmFL NOTIFY rpmFLChanged)
    Q_PROPERTY(int rpmFR READ rpmFR NOTIFY rpmFRChanged)
    Q_PROPERTY(int rpmRL READ rpmRL NOTIFY rpmRLChanged)
    Q_PROPERTY(int rpmRR READ rpmRR NOTIFY rpmRRChanged)
    // Tyre Pressures
    Q_PROPERTY(double tyrePressFL READ tyrePressFL NOTIFY tyrePressFLChanged)
    Q_PROPERTY(double tyrePressFR READ tyrePressFR NOTIFY tyrePressFRChanged)
    Q_PROPERTY(double tyrePressRL READ tyrePressRL NOTIFY tyrePressRLChanged)
    Q_PROPERTY(double tyrePressRR READ tyrePressRR NOTIFY tyrePressRRChanged)
    // Tyre Temperatures
    Q_PROPERTY(double tyreTempFL READ tyreTempFL NOTIFY tyreTempFLChanged)
    Q_PROPERTY(double tyreTempFR READ tyreTempFR NOTIFY tyreTempFRChanged)
    Q_PROPERTY(double tyreTempRL READ tyreTempRL NOTIFY tyreTempRLChanged)
    Q_PROPERTY(double tyreTempRR READ tyreTempRR NOTIFY tyreTempRRChanged)
    // Motor Temps
    Q_PROPERTY(double motorTempFL READ motorTempFL NOTIFY motorTempFLChanged)
    Q_PROPERTY(double motorTempFR READ motorTempFR NOTIFY motorTempFRChanged)
    Q_PROPERTY(double motorTempRL READ motorTempRL NOTIFY motorTempRLChanged)
    Q_PROPERTY(double motorTempRR READ motorTempRR NOTIFY motorTempRRChanged)
    // IGBT (Inverter) Temps
    Q_PROPERTY(double igbtTempFL READ igbtTempFL NOTIFY igbtTempFLChanged)
    Q_PROPERTY(double igbtTempFR READ igbtTempFR NOTIFY igbtTempFRChanged)
    Q_PROPERTY(double igbtTempRL READ igbtTempRL NOTIFY igbtTempRLChanged)
    Q_PROPERTY(double igbtTempRR READ igbtTempRR NOTIFY igbtTempRRChanged)

    //Accumulator Battery Cells
    // Cell 1-12 Diagnostics
    Q_PROPERTY(double cell1MinV READ cell1MinV NOTIFY cell1MinVChanged)
    Q_PROPERTY(double cell2MinV READ cell2MinV NOTIFY cell2MinVChanged)
    Q_PROPERTY(double cell3MinV READ cell3MinV NOTIFY cell3MinVChanged)
    Q_PROPERTY(double cell4MinV READ cell4MinV NOTIFY cell4MinVChanged)
    Q_PROPERTY(double cell5MinV READ cell5MinV NOTIFY cell5MinVChanged)
    Q_PROPERTY(double cell6MinV READ cell6MinV NOTIFY cell6MinVChanged)
    Q_PROPERTY(double cell7MinV READ cell7MinV NOTIFY cell7MinVChanged)
    Q_PROPERTY(double cell8MinV READ cell8MinV NOTIFY cell8MinVChanged)
    Q_PROPERTY(double cell9MinV READ cell9MinV NOTIFY cell9MinVChanged)
    Q_PROPERTY(double cell10MinV READ cell10MinV NOTIFY cell10MinVChanged)
    Q_PROPERTY(double cell11MinV READ cell11MinV NOTIFY cell11MinVChanged)
    Q_PROPERTY(double cell12MinV READ cell12MinV NOTIFY cell12MinVChanged)

    Q_PROPERTY(double cell1MaxV READ cell1MaxV NOTIFY cell1MaxVChanged)
    Q_PROPERTY(double cell2MaxV READ cell2MaxV NOTIFY cell2MaxVChanged)
    Q_PROPERTY(double cell3MaxV READ cell3MaxV NOTIFY cell3MaxVChanged)
    Q_PROPERTY(double cell4MaxV READ cell4MaxV NOTIFY cell4MaxVChanged)
    Q_PROPERTY(double cell5MaxV READ cell5MaxV NOTIFY cell5MaxVChanged)
    Q_PROPERTY(double cell6MaxV READ cell6MaxV NOTIFY cell6MaxVChanged)
    Q_PROPERTY(double cell7MaxV READ cell7MaxV NOTIFY cell7MaxVChanged)
    Q_PROPERTY(double cell8MaxV READ cell8MaxV NOTIFY cell8MaxVChanged)
    Q_PROPERTY(double cell9MaxV READ cell9MaxV NOTIFY cell9MaxVChanged)
    Q_PROPERTY(double cell10MaxV READ cell10MaxV NOTIFY cell10MaxVChanged)
    Q_PROPERTY(double cell11MaxV READ cell11MaxV NOTIFY cell11MaxVChanged)
    Q_PROPERTY(double cell12MaxV READ cell12MaxV NOTIFY cell12MaxVChanged)

    Q_PROPERTY(double cell1Temp READ cell1Temp NOTIFY cell1TempChanged)
    Q_PROPERTY(double cell2Temp READ cell2Temp NOTIFY cell2TempChanged)
    Q_PROPERTY(double cell3Temp READ cell3Temp NOTIFY cell3TempChanged)
    Q_PROPERTY(double cell4Temp READ cell4Temp NOTIFY cell4TempChanged)
    Q_PROPERTY(double cell5Temp READ cell5Temp NOTIFY cell5TempChanged)
    Q_PROPERTY(double cell6Temp READ cell6Temp NOTIFY cell6TempChanged)
    Q_PROPERTY(double cell7Temp READ cell7Temp NOTIFY cell7TempChanged)
    Q_PROPERTY(double cell8Temp READ cell8Temp NOTIFY cell8TempChanged)
    Q_PROPERTY(double cell9Temp READ cell9Temp NOTIFY cell9TempChanged)
    Q_PROPERTY(double cell10Temp READ cell10Temp NOTIFY cell10TempChanged)
    Q_PROPERTY(double cell11Temp READ cell11Temp NOTIFY cell11TempChanged)
    Q_PROPERTY(double cell12Temp READ cell12Temp NOTIFY cell12TempChanged)

public:
    explicit VehicleDataProvider(QObject *parent = nullptr);

    // Setters
    void setCoolingActive(bool active);
    void setTvActive(bool active);
    void setRegenActive(bool active);
    void setSsActive(bool active);
    void setTcWarning(bool active);
    void setRadioActive(bool active);

    // Call these directly from your QML buttons/sliders
    Q_INVOKABLE void toggleTractionControl(bool enable);
    Q_INVOKABLE void toggleTorqueVectoring(bool enable);
    Q_INVOKABLE void toggleRegen(bool enable);
    Q_INVOKABLE void setKnobValue(int index, float value);

    // Get Functions
    int speed() const; double lapTime() const; double timeDelta() const; int lapCount() const;
    double accelX() const; double accelY() const; double throttleVal() const;
    double brakePress() const; double brakeBias() const;

    bool coolingActive() const; bool radioActive() const; bool tvActive() const;
    bool tcWarning() const; bool regenActive() const; bool ssActive() const;

    int soc() const; double voltage() const; double currentDc() const;
    double power() const; double powerTarget() const;
    double minCellTemp() const; double maxCellTemp() const;
    double minCellVoltage() const; double maxCellVoltage() const;

    int torqueReqFL() const; int torqueReqFR() const; int torqueReqRL() const; int torqueReqRR() const;
    int torqueActFL() const; int torqueActFR() const; int torqueActRL() const; int torqueActRR() const;
    int rpmFL() const; int rpmFR() const; int rpmRL() const; int rpmRR() const;
    double tyrePressFL() const; double tyrePressFR() const; double tyrePressRL() const; double tyrePressRR() const;
    double tyreTempFL() const; double tyreTempFR() const; double tyreTempRL() const; double tyreTempRR() const;
    double motorTempFL() const; double motorTempFR() const; double motorTempRL() const; double motorTempRR() const;
    double igbtTempFL() const; double igbtTempFR() const; double igbtTempRL() const; double igbtTempRR() const;

    //Accumulator getters
    double cell1MinV() const; double cell2MinV() const; double cell3MinV() const; double cell4MinV() const; double cell5MinV() const; double cell6MinV() const; double cell7MinV() const; double cell8MinV() const; double cell9MinV() const; double cell10MinV() const; double cell11MinV() const; double cell12MinV() const;
    double cell1MaxV() const; double cell2MaxV() const; double cell3MaxV() const; double cell4MaxV() const; double cell5MaxV() const; double cell6MaxV() const; double cell7MaxV() const; double cell8MaxV() const; double cell9MaxV() const; double cell10MaxV() const; double cell11MaxV() const; double cell12MaxV() const;
    double cell1Temp() const; double cell2Temp() const; double cell3Temp() const; double cell4Temp() const; double cell5Temp() const; double cell6Temp() const; double cell7Temp() const; double cell8Temp() const; double cell9Temp() const; double cell10Temp() const; double cell11Temp() const; double cell12Temp() const;
signals:
    // Navigation Signals for QML
    void navigateNextPage();
    void navigatePrevPage();
    void selectMission();
    void toggleDiagnosticTab();

    // Hardware Interrupt Triggers
    void speedChanged(); void lapTimeChanged(); void timeDeltaChanged(); void lapCountChanged();
    void accelXChanged(); void accelYChanged(); void throttleValChanged();
    void brakePressChanged(); void brakeBiasChanged();

    void coolingActiveChanged(); void radioActiveChanged(); void tvActiveChanged();
    void tcWarningChanged(); void regenActiveChanged(); void ssActiveChanged();

    void socChanged(); void voltageChanged(); void currentDcChanged();
    void powerChanged(); void powerTargetChanged();
    void minCellTempChanged(); void maxCellTempChanged();
    void minCellVoltageChanged(); void maxCellVoltageChanged();

    void torqueReqFLChanged(); void torqueReqFRChanged(); void torqueReqRLChanged(); void torqueReqRRChanged();
    void torqueActFLChanged(); void torqueActFRChanged(); void torqueActRLChanged(); void torqueActRRChanged();
    void rpmFLChanged(); void rpmFRChanged(); void rpmRLChanged(); void rpmRRChanged();
    void tyrePressFLChanged(); void tyrePressFRChanged(); void tyrePressRLChanged(); void tyrePressRRChanged();
    void tyreTempFLChanged(); void tyreTempFRChanged(); void tyreTempRLChanged(); void tyreTempRRChanged();
    void motorTempFLChanged(); void motorTempFRChanged(); void motorTempRLChanged(); void motorTempRRChanged();
    void igbtTempFLChanged(); void igbtTempFRChanged(); void igbtTempRLChanged(); void igbtTempRRChanged();

    //Accumulator signals
    void cell1MinVChanged(); void cell2MinVChanged(); void cell3MinVChanged(); void cell4MinVChanged(); void cell5MinVChanged(); void cell6MinVChanged(); void cell7MinVChanged(); void cell8MinVChanged(); void cell9MinVChanged(); void cell10MinVChanged(); void cell11MinVChanged(); void cell12MinVChanged();
    void cell1MaxVChanged(); void cell2MaxVChanged(); void cell3MaxVChanged(); void cell4MaxVChanged(); void cell5MaxVChanged(); void cell6MaxVChanged(); void cell7MaxVChanged(); void cell8MaxVChanged(); void cell9MaxVChanged(); void cell10MaxVChanged(); void cell11MaxVChanged(); void cell12MaxVChanged();
    void cell1TempChanged(); void cell2TempChanged(); void cell3TempChanged(); void cell4TempChanged(); void cell5TempChanged(); void cell6TempChanged(); void cell7TempChanged(); void cell8TempChanged(); void cell9TempChanged(); void cell10TempChanged(); void cell11TempChanged(); void cell12TempChanged();

private slots:
    void parseUartData();

private:
    // Internal Memory (The actual C++ variables)
    int m_speed; double m_lapTime; double m_timeDelta; int m_lapCount;
    double m_accelX; double m_accelY; double m_throttleVal;
    double m_brakePress; double m_brakeBias;

    bool m_coolingActive; bool m_radioActive; bool m_tvActive;
    bool m_tcWarning; bool m_regenActive; bool m_ssActive;

    int m_soc; double m_voltage; double m_currentDc;
    double m_power; double m_powerTarget;
    double m_minCellTemp; double m_maxCellTemp;
    double m_minCellVoltage; double m_maxCellVoltage;

    int m_torqueReqFL, m_torqueReqFR, m_torqueReqRL, m_torqueReqRR;
    int m_torqueActFL, m_torqueActFR, m_torqueActRL, m_torqueActRR;
    int m_rpmFL, m_rpmFR, m_rpmRL, m_rpmRR;
    double m_tyrePressFL, m_tyrePressFR, m_tyrePressRL, m_tyrePressRR;
    double m_tyreTempFL, m_tyreTempFR, m_tyreTempRL, m_tyreTempRR;
    double m_motorTempFL, m_motorTempFR, m_motorTempRL, m_motorTempRR;
    double m_igbtTempFL, m_igbtTempFR, m_igbtTempRL, m_igbtTempRR;

    // Accumulator Variables
    double m_cell1MinV, m_cell2MinV, m_cell3MinV, m_cell4MinV, m_cell5MinV, m_cell6MinV, m_cell7MinV, m_cell8MinV, m_cell9MinV, m_cell10MinV, m_cell11MinV, m_cell12MinV;
    double m_cell1MaxV, m_cell2MaxV, m_cell3MaxV, m_cell4MaxV, m_cell5MaxV, m_cell6MaxV, m_cell7MaxV, m_cell8MaxV, m_cell9MaxV, m_cell10MaxV, m_cell11MaxV, m_cell12MaxV;
    double m_cell1Temp, m_cell2Temp, m_cell3Temp, m_cell4Temp, m_cell5Temp, m_cell6Temp, m_cell7Temp, m_cell8Temp, m_cell9Temp, m_cell10Temp, m_cell11Temp, m_cell12Temp;

    QSerialPort *m_serial;

    // ==========================================
    // NEW: UART BINARY STATE MACHINE DEFINITIONS
    // ==========================================
    enum RxState {
        WAIT_SYNC,
        READ_ID,
        READ_DLC,
        READ_DATA,
        READ_CHECKSUM
    };

    RxState m_rxState = WAIT_SYNC;

    uint32_t m_currentId = 0;
    uint8_t m_currentDlc = 0;
    QByteArray m_payloadBuffer;
    int m_bytesRead = 0;

    void processIncomingByte(uint8_t byte);
    void parseCanMessage(uint32_t canId, uint8_t dlc, const QByteArray& data);
    
    // Transmission and Steering Wheel Handler
    void sendUartCanMessage(uint32_t canId, uint8_t dlc, const QByteArray& payload);
    void handleSteeringWheelInput(uint8_t buttonId, uint8_t action);

};
