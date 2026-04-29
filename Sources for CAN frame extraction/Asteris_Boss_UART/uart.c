#include "main.h"
#include "can_mcu.h"
#include "uart.h"
#include <string.h>



const uint32_t UART_INTRESTED_CAN_IDS[TOTAL_CAN_IDS] = {
    // --- VCU & Inverter Dynamics (11) ---
    CAN_MCU_VCU_RL_INFO_FRAME_ID,               // 701 (0x2BD)
    CAN_MCU_VCU_RR_INFO_FRAME_ID,               // 702 (0x2BE)
    CAN_MCU_VCU_FL_INFO_FRAME_ID,               // 703 (0x2BF)
    CAN_MCU_VCU_FR_INFO_FRAME_ID,               // 704 (0x2C0)
    CAN_MCU_VCU_APPS_FRAME_ID,                  // 798 (0x31E)
    CAN_MCU_VCU_STEERING_CALIBRATED_FRAME_ID,   // 799 (0x31F)
    CAN_MCU_VCU_BOOLS_FRAME_ID,                 // 800 (0x320)
    CAN_MCU_VCU_ADU_FRAME_ID,                   // 801 (0x321)
    CAN_MCU_VCU_SUSP_R_FRAME_ID,                // 803 (0x323)
    CAN_MCU_VCU_SERVO_CONTROL_FRAME_ID,         // 804 (0x324)
    CAN_MCU_VCU_APPS_RAW_FRAME_ID,              // 805 (0x325)

    // --- BMS / Accumulator Voltages & Temps (9) ---
    CAN_MCU_BMS_MIN_MAX_S1_S2_FRAME_ID,         // 1600 (0x640)
    CAN_MCU_BMS_MIN_MAX_S3_S4_FRAME_ID,         // 1601 (0x641)
    CAN_MCU_BMS_MIN_MAX_S5_S6_FRAME_ID,         // 1602 (0x642)
    CAN_MCU_BMS_MIN_MAX_S7_S8_FRAME_ID,         // 1603 (0x643)
    CAN_MCU_BMS_MIN_MAX_S9_S10_FRAME_ID,        // 1604 (0x644)
    CAN_MCU_BMS_MIN_MAX_S11_S12_FRAME_ID,       // 1605 (0x645)
    CAN_MCU_BMS_MAX_TEMP_S1_S4_FRAME_ID,        // 1606 (0x646)
    CAN_MCU_BMS_MAX_TEMP_S5_S8_FRAME_ID,        // 1607 (0x647)
    CAN_MCU_BMS_MAX_TEMP_S9_S12_FRAME_ID,       // 1608 (0x648)

    // --- Dashboard & Peripherals (6) ---
    CAN_MCU_DASH_APPS_FRAME_ID,                 // 100 (0x64)
    CAN_MCU_DASH_BRAKE_FRAME_ID,                // 101 (0x65)
    CAN_MCU_DASH_STEERING_FRAME_ID,             // 102 (0x66)
    CAN_MCU_DASH_BOOLS_FRAME_ID,                // 103 (0x67)
    CAN_MCU_DASH_SUSP_F_FRAME_ID,               // 105 (0x69)
    CAN_MCU_DASH_AMI_FRAME_ID,                  // 109 (0x6D)

    // --- Isabellenhutte / Energy Sensors (5) ---
    CAN_MCU_ISABELLEN_IDC_FRAME_ID,             // 1313 (0x521)
    CAN_MCU_ISABELLEN_VDC_FRAME_ID,             // 1314 (0x522)
    CAN_MCU_ISABELLEN_16_BIT_FRAME_ID,          // 1315 (0x523)
    CAN_MCU_ISABELLEN_PDC_FRAME_ID,             // 1318 (0x526)
    CAN_MCU_ISABELLEN_ENERGY_FRAME_ID,          // 1320 (0x528)

    // --- Autonomous / APU / Data Logging (11) ---
    CAN_MCU_APU_STATE_MISSION_FRAME_ID,         // 10 (0x0A)
    CAN_MCU_APU_TEMP_THA_ENHMERWTHEI_FRAME_ID,  // 13 (0x0D)
    CAN_MCU_ASB_FRAME_ID,                       // 35 (0x23)
    CAN_MCU_DV_DRIVING_DYNAMICS_1_FRAME_ID,     // 1280 (0x500)
    CAN_MCU_DV_DRIVING_DYNAMICS_2_FRAME_ID,     // 1281 (0x501)
    CAN_MCU_DV_SYSTEM_STATUS_FRAME_ID,          // 1282 (0x502)
    CAN_MCU_ASB_DATALOGGER_FRAME_ID,            // 1297 (0x511)
    CAN_MCU_PITCH_AND_ROLL_FRAME_ID,            // 1794 (0x702)
    CAN_MCU_VEL_AND_ANG_FRAME_ID,               // 1797 (0x705)
    CAN_MCU_ACC_FRAME_ID,                       // 1799 (0x707)
    CAN_MCU_VEL_AND_ANG_SP_FRAME_ID,            // 1801 (0x709)

    // --- Thermal Cameras & Steering Actuator (5) ---
 //   CAN_MCU_BLDC_EMERGENCY_FRAME_ID,            // 255 (0xFF)
  //  CAN_MCU_TIRETEMP_REARLEFT_PART1_FRAME_ID,   // 714 (0x2CA)
   // CAN_MCU_TIRETEMP_REARLEFT_PART2_FRAME_ID,   // 715 (0x2CB)
   // CAN_MCU_TIRETEMP_REARRIGHT_PART1_FRAME_ID,  // 716 (0x2CC)
   // CAN_MCU_TIRETEMP_REARRIGHT_PART2_FRAME_ID   // 717 (0x2CD)
};

const uint32_t UART_INTRESTED_CAN_FRAME_LENGTH[TOTAL_CAN_IDS] = {
    // --- VCU & Inverter Dynamics (11) ---
    CAN_MCU_VCU_RL_INFO_LENGTH,                 // 8
    CAN_MCU_VCU_RR_INFO_LENGTH,                 // 8
    CAN_MCU_VCU_FL_INFO_LENGTH,                 // 8
    CAN_MCU_VCU_FR_INFO_LENGTH,                 // 8
    CAN_MCU_VCU_APPS_LENGTH,                    // 2
    CAN_MCU_VCU_STEERING_CALIBRATED_LENGTH,     // 6
    CAN_MCU_VCU_BOOLS_LENGTH,                   // 1
    CAN_MCU_VCU_ADU_LENGTH,                     // 8
    CAN_MCU_VCU_SUSP_R_LENGTH,                  // 4
    CAN_MCU_VCU_SERVO_CONTROL_LENGTH,           // 1
    CAN_MCU_VCU_APPS_RAW_LENGTH,                // 8

    // --- BMS / Accumulator Voltages & Temps (9) ---
    CAN_MCU_BMS_MIN_MAX_S1_S2_LENGTH,           // 8
    CAN_MCU_BMS_MIN_MAX_S3_S4_LENGTH,           // 8
    CAN_MCU_BMS_MIN_MAX_S5_S6_LENGTH,           // 8
    CAN_MCU_BMS_MIN_MAX_S7_S8_LENGTH,           // 8
    CAN_MCU_BMS_MIN_MAX_S9_S10_LENGTH,          // 8
    CAN_MCU_BMS_MIN_MAX_S11_S12_LENGTH,         // 8
    CAN_MCU_BMS_MAX_TEMP_S1_S4_LENGTH,          // 8
    CAN_MCU_BMS_MAX_TEMP_S5_S8_LENGTH,          // 8
    CAN_MCU_BMS_MAX_TEMP_S9_S12_LENGTH,         // 8

    // --- Dashboard & Peripherals (6) ---
    CAN_MCU_DASH_APPS_LENGTH,                   // 5
    CAN_MCU_DASH_BRAKE_LENGTH,                  // 5
    CAN_MCU_DASH_STEERING_LENGTH,               // 6
    CAN_MCU_DASH_BOOLS_LENGTH,                  // 4
    CAN_MCU_DASH_SUSP_F_LENGTH,                 // 4
    CAN_MCU_DASH_AMI_LENGTH,                    // 1

    // --- Isabellenhutte / Energy Sensors (5) ---
    CAN_MCU_ISABELLEN_IDC_LENGTH,               // 6
    CAN_MCU_ISABELLEN_VDC_LENGTH,               // 6
    CAN_MCU_ISABELLEN_16_BIT_LENGTH,            // 8
    CAN_MCU_ISABELLEN_PDC_LENGTH,               // 6
    CAN_MCU_ISABELLEN_ENERGY_LENGTH,            // 6

    // --- Autonomous / APU / Data Logging (11) ---
    CAN_MCU_APU_STATE_MISSION_LENGTH,           // 1
    CAN_MCU_APU_TEMP_THA_ENHMERWTHEI_LENGTH,    // 4
    CAN_MCU_ASB_LENGTH,                         // 5
    CAN_MCU_DV_DRIVING_DYNAMICS_1_LENGTH,       // 8
    CAN_MCU_DV_DRIVING_DYNAMICS_2_LENGTH,       // 6
    CAN_MCU_DV_SYSTEM_STATUS_LENGTH,            // 5
    CAN_MCU_ASB_DATALOGGER_LENGTH,              // 5
    CAN_MCU_PITCH_AND_ROLL_LENGTH,              // 4
    CAN_MCU_VEL_AND_ANG_LENGTH,                 // 8
    CAN_MCU_ACC_LENGTH,                         // 6
    CAN_MCU_VEL_AND_ANG_SP_LENGTH,              // 8
};







///////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
struct Can_message canbuffer[TOTAL_CAN_IDS];

void can_buffer_init(void){
	for(int i=0; i<TOTAL_CAN_IDS; i++){
		canbuffer[i].ID=UART_INTRESTED_CAN_IDS[i];
		canbuffer[i].DLC=UART_INTRESTED_CAN_FRAME_LENGTH[i];
		canbuffer[i].Data[0]=0;
		canbuffer[i].Data[1]=0;
		canbuffer[i].Data[2]=0;
		canbuffer[i].Data[3]=0;
		canbuffer[i].Data[4]=0;
		canbuffer[i].Data[5]=0;
		canbuffer[i].Data[6]=0;
		canbuffer[i].Data[7]=0;
		canbuffer[i].updated=0;
	}
}

int Reqougnize_Can_Id(uint32_t can_id) {
    switch (can_id) {
        // --- VCU & Inverter Dynamics (11) ---
        case CAN_MCU_VCU_RL_INFO_FRAME_ID:               return 0;
        case CAN_MCU_VCU_RR_INFO_FRAME_ID:               return 1;
        case CAN_MCU_VCU_FL_INFO_FRAME_ID:               return 2;
        case CAN_MCU_VCU_FR_INFO_FRAME_ID:               return 3;
        case CAN_MCU_VCU_APPS_FRAME_ID:                  return 4;
        case CAN_MCU_VCU_STEERING_CALIBRATED_FRAME_ID:   return 5;
        case CAN_MCU_VCU_BOOLS_FRAME_ID:                 return 6;
        case CAN_MCU_VCU_ADU_FRAME_ID:                   return 7;
        case CAN_MCU_VCU_SUSP_R_FRAME_ID:                return 8;
        case CAN_MCU_VCU_SERVO_CONTROL_FRAME_ID:         return 9;
        case CAN_MCU_VCU_APPS_RAW_FRAME_ID:              return 10;

        // --- BMS / Accumulator Voltages & Temps (9) ---
        case CAN_MCU_BMS_MIN_MAX_S1_S2_FRAME_ID:         return 11;
        case CAN_MCU_BMS_MIN_MAX_S3_S4_FRAME_ID:         return 12;
        case CAN_MCU_BMS_MIN_MAX_S5_S6_FRAME_ID:         return 13;
        case CAN_MCU_BMS_MIN_MAX_S7_S8_FRAME_ID:         return 14;
        case CAN_MCU_BMS_MIN_MAX_S9_S10_FRAME_ID:        return 15;
        case CAN_MCU_BMS_MIN_MAX_S11_S12_FRAME_ID:       return 16;
        case CAN_MCU_BMS_MAX_TEMP_S1_S4_FRAME_ID:        return 17;
        case CAN_MCU_BMS_MAX_TEMP_S5_S8_FRAME_ID:        return 18;
        case CAN_MCU_BMS_MAX_TEMP_S9_S12_FRAME_ID:       return 19;

        // --- Dashboard & Peripherals (6) ---
        case CAN_MCU_DASH_APPS_FRAME_ID:                 return 20;
        case CAN_MCU_DASH_BRAKE_FRAME_ID:                return 21;
        case CAN_MCU_DASH_STEERING_FRAME_ID:             return 22;
        case CAN_MCU_DASH_BOOLS_FRAME_ID:                return 23;
        case CAN_MCU_DASH_SUSP_F_FRAME_ID:               return 24;
        case CAN_MCU_DASH_AMI_FRAME_ID:                  return 25;

        // --- Isabellenhutte / Energy Sensors (5) ---
        case CAN_MCU_ISABELLEN_IDC_FRAME_ID:             return 26;
        case CAN_MCU_ISABELLEN_VDC_FRAME_ID:             return 27;
        case CAN_MCU_ISABELLEN_16_BIT_FRAME_ID:          return 28;
        case CAN_MCU_ISABELLEN_PDC_FRAME_ID:             return 29;
        case CAN_MCU_ISABELLEN_ENERGY_FRAME_ID:          return 30;

        // --- Autonomous / APU / Data Logging (11) ---
        case CAN_MCU_APU_STATE_MISSION_FRAME_ID:         return 31;
        case CAN_MCU_APU_TEMP_THA_ENHMERWTHEI_FRAME_ID:  return 32;
        case CAN_MCU_ASB_FRAME_ID:                       return 33;
        case CAN_MCU_DV_DRIVING_DYNAMICS_1_FRAME_ID:     return 34;
        case CAN_MCU_DV_DRIVING_DYNAMICS_2_FRAME_ID:     return 35;
        case CAN_MCU_DV_SYSTEM_STATUS_FRAME_ID:          return 36;
        case CAN_MCU_ASB_DATALOGGER_FRAME_ID:            return 37;
        case CAN_MCU_PITCH_AND_ROLL_FRAME_ID:            return 38;
        case CAN_MCU_VEL_AND_ANG_FRAME_ID:               return 39;
        case CAN_MCU_ACC_FRAME_ID:                       return 40;
        case CAN_MCU_VEL_AND_ANG_SP_FRAME_ID:            return 41;

        // --- Thermal Cameras & Steering Actuator (Commented Out) ---
        // case CAN_MCU_BLDC_EMERGENCY_FRAME_ID:              return 42;
        // case CAN_MCU_TIRETEMP_REARLEFT_PART1_FRAME_ID:     return 43;
        // case CAN_MCU_TIRETEMP_REARLEFT_PART2_FRAME_ID:     return 44;
        // case CAN_MCU_TIRETEMP_REARRIGHT_PART1_FRAME_ID:    return 45;
        // case CAN_MCU_TIRETEMP_REARRIGHT_PART2_FRAME_ID:    return 46;

        default: return -1; // Ignore unknown IDs
    }
}




void send_to_can_buffer(uint32_t can_id, uint8_t *can_data) {
    int index = Reqougnize_Can_Id(can_id);
    if(index >= 0) {
        // Use your predefined DLC
        uint8_t len = canbuffer[index].DLC; 
        memcpy(canbuffer[index].Data, can_data, len);
        canbuffer[index].updated = 1; // Trigger the UART loop
    }
}

void send_uart(void) {
    uint8_t sync_byte = 0xAA;
    uint8_t checksum;

    for(int i = 0; i < TOTAL_CAN_IDS; i++) {
        if (canbuffer[i].updated) {
            checksum = canbuffer[i].DLC;
            for(int j = 0; j < canbuffer[i].DLC; j++) {
                checksum ^= canbuffer[i].Data[j];
            }

            HAL_UART_Transmit(&huart2, &sync_byte, 1, 10);
            HAL_UART_Transmit(&huart2, (uint8_t*)&canbuffer[i].ID, 4, 10);
            HAL_UART_Transmit(&huart2, &canbuffer[i].DLC, 1, 10);
            HAL_UART_Transmit(&huart2, canbuffer[i].Data, canbuffer[i].DLC, 10);
            HAL_UART_Transmit(&huart2, &checksum, 1, 10);

            canbuffer[i].updated = 0; // Reset
        }
    }
}




