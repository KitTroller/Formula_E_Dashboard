# 🛰️ Telemetry Pipeline Engineering Guide

This guide explains the data flow from the car's CAN bus to the Dashboard UI and provides a template for adding or modifying variables.

---

## 1. The 4-Stage Pipeline

### Stage A: The Car (CAN Bus)
ECUs broadcast raw binary data.
*   **Example**: The VCU sends ID `0x321` (801) containing velocity.
*   **DBC Definition**: `SG_ Velocity : 24|16@1- (0.01,0) [0|0] "km/h"`.
    *   *Translation*: Start at bit 24, length 16 bits, Little-Endian, Signed, Factor 0.01.

### Stage B: The Bridge (`uart.c`)
The MCU filters and packs the CAN message into a UART frame.
1.  **Filter**: ID 801 must be in `UART_INTRESTED_CAN_IDS`.
2.  **Pack**: `0xAA` + `ID` + `DLC` + `DATA` + `CHECKSUM`.
3.  **Transmit**: Sent over physical TX/RX wires to the Raspberry Pi.

### Stage C: The Decoder (`vehicledataprovider.cpp`)
The Pi reconstructs the message and extracts the signals.
1.  **FSM**: State machine handles byte-alignment and checksum verification.
2.  **Extract**: Binary manipulation (bit-shifting and masking).
    *   `extractS16(data, 3)` reads bytes 3 and 4 to get the 16-bit velocity.
3.  **Notify**: The `UPDATE_VAL` macro updates the C++ memory and notifies the QML engine via a Signal.

### Stage D: The Visuals (`.qml` files)
QML properties are "bound" to C++ properties.
*   `text: telemetry.speed.toFixed(0)`
*   Whenever the C++ signal fires, the UI refreshes instantly.

---

## 2. Walkthrough: Adding a New Variable
*Goal: Add "Inverter Temperature" (ID 705) to the dashboard.*

### Step 1: Update the Sender (`uart.c`)
Ensure the MCU is actually sending the data.
1.  Check if ID 705 is in `UART_INTRESTED_CAN_IDS`.
2.  If not, add it to the array and update `Reqougnize_Can_Id` to return a new index.

### Step 2: Define the Property (`vehicledataprovider.h`)
Add the variable to the C++ class so QML can see it.
```cpp
// 1. Add Property
Q_PROPERTY(double invTemp READ invTemp NOTIFY invTempChanged)

// 2. Add Getter
double invTemp() const { return m_invTemp; }

// 3. Add Signal
signals: void invTempChanged();

// 4. Add Private Variable
private: double m_invTemp;
```

### Step 3: Decode the Message (`vehicledataprovider.cpp`)
Add the logic to extract the data from the raw bytes.
```cpp
case 705: {
    if (dlc >= 2) {
        // Assume Temp is a 16-bit signed int at Byte 0
        double rawVal = extractS16(data, 0); 
        double scaledVal = rawVal * 0.1; // Apply DBC factor
        UPDATE_VAL(m_invTemp, scaledVal, invTempChanged);
    }
    break;
}
```

### Step 4: Display in QML (`DriverPage.qml`)
Connect the UI to the new data.
```qml
Text {
    text: "INV TEMP: " + (root.telemetry ? root.telemetry.invTemp : 0) + "°C"
}
```

---

## 3. Data Extraction Cheat Sheet

| Data Type | C++ Extraction Method | Example |
| :--- | :--- | :--- |
| **Bit (Boolean)** | `(data[byteIndex] & (1 << bitOffset)) != 0` | `(data[7] & (1 << 2))` |
| **8-bit Unsigned** | `static_cast<uint8_t>(data[index])` | `data[0]` |
| **16-bit Signed** | `extractS16(data, startIndex)` | `extractS16(data, 4)` |
| **32-bit Signed** | `(d[i]\|d[i+1]<<8\|d[i+2]<<16\|d[i+3]<<24)` | (Rarely used in your DBC) |

**Note on Endianness**: Your current `extractU16/S16` lambdas use **Little-Endian**. If you add a sensor that uses Big-Endian (rare in CAN), you must flip the bit-shifts (`(data[i] << 8) | data[i+1]`).
