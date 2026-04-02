# 🏎️ Telemetry & DBC Mapping Audit Report

This document outlines the current state of the CAN-to-Dashboard mapping. Use this as a checklist to ensure the "Hero Gauges" and Safety Systems function correctly before pushing to the car.

---

## ✅ 1. Correctly Mapped Variables
*These variables are fully implemented in `uart.c`, decoded correctly in `vehicledataprovider.cpp`, and used in QML.*

| Property | CAN ID | Logic / Bitmask | Status |
| :--- | :--- | :--- | :--- |
| `m_speed` | 801 | `extractS16(data, 3) * 0.01` | **OK** |
| `m_power` | 801 | `data[0] * 1.0` | **OK** |
| `m_soc` | 801 | `data[6]` (8-bit) | **OK** |
| `m_voltage` | 1315 | `extractS16(data, 0) * 0.1` | **OK** |
| `m_currentDc` | 1315 | `extractS16(data, 4) * 0.01` | **OK** |
| `m_accelX/Y` | 1799 | `extractS16 * 0.02 / 9.81` (G-conversion) | **OK** |
| `m_throttleVal` | 798 | `extractU16(data, 0) * 0.001` | **Scaled** (See Clarifications) |
| `m_coolingActive`| 103 | `(data[0] & (1 << 4))` | **OK** |
| `m_tv/regen/tc` | 801 | `data[7]` Bitfield | **OK** |
| `m_igbt/motorTemp`| 701-704| Bytes 0 and 1 | **OK** |
| `m_rpmFL/FR/RL/RR`| 701-704| `extractS16(data, 2)` | **OK** |
| `m_cellXMin/MaxV` | 1600-1605| `extractU16 * 0.001` | **OK** |

---

## ❌ 2. Broken or Partially Mapped Variables
*These require immediate code changes to function on the dashboard.*

### A. Missing from UART Sender (`uart.c`)
The dashboard expects these IDs, but the APU/UART sender is not currently forwarding them.
*   **ID 806 (VCU_APU_Info)**: Contains `Power_Target_kW`.
    *   *Fix*: Add `CAN_MCU_VCU_APU_INFO_FRAME_ID` to `UART_INTRESTED_CAN_IDS` in `uart.c`.

### B. Missing Aggregate Logic (Safety Critical)
The **Global Warning Banner** (`Main.qml`) depends on these, but they are currently **static/default values**.
*   `m_minCellVoltage`
*   `m_maxCellVoltage`
*   `m_minCellTemp`
*   `m_maxCellTemp`
    *   *Fix*: Inside `parseCanMessage`, after updating individual cell values (IDs 1600-1608), you must run a loop/comparison to find the absolute min/max and update these variables. **Without this, the "CRITICAL BATTERY" warning will never trigger.**

### C. Commented Out in Sender
*   **IDs 714-717 (Tyre Temperatures)**: These are commented out in `uart.c`.
    *   *Fix*: Uncomment in `uart.c` and add `case 714...717` to the `switch` in `vehicledataprovider.cpp`.

---

## 🔍 3. Unmapped / Missing in DBC
*These variables are requested by the QML UI but do not exist in the current DBC-to-C++ logic.*

1.  **`m_brakeBias`**: QML expects a percentage (e.g., 54.0). It is currently hardcoded in C++.
2.  **`m_lapTime` & `m_timeDelta`**: QML uses these for the predictive lap timer.
    *   *Note*: Lap **Count** is correctly mapped (ID 1282), but the actual timer logic is missing.
3.  **`m_radioActive` & `m_ssActive`**: Status icons in QML have no corresponding CAN ID logic.
4.  **Tyre Pressures**: As you noted, these are not in the DBC. They will remain at the default `1.2 bar` on the Diagnostic Page.

---

## ⚠️ 4. Logic Clarifications Required

### APPS Scaling (Throttle)
*   **DBC Factor**: 1 (implies 0 to 100).
*   **C++ Code**: `0.001` (implies 0 to 1000).
*   **Clarification**: Is the VCU sending a raw ADC value (0-1000) or a percentage? If it's a percentage, your dashboard will show `0.1%` instead of `100%`.

### Brake Pressure Scaling
*   **Current Logic**: `(val * 0.01) / 100.0`.
*   **Assumption**: This assumes the pressure sensor maxes out at **100 bar**.
*   **Clarification**: Verify the maximum master cylinder pressure. If the car only reaches 60 bar, the UI brake bar will never go past 60%.

### Torque Requested vs Actual
*   **Offset Check**: Inverters 701-704 use `extractS16(data, 4)` for Requested and `extractS16(data, 6)` for Actual.
*   **Verification**: Ensure the Inverter DBC matches these byte offsets. Currently, the code assumes Requested Torque starts at Byte 4 and Actual starts at Byte 6.
