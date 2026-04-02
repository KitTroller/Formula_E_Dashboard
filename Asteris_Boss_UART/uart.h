#ifndef UART_H
#define UART_H

#include "main.h"
#include "can_mcu.h"
#include "uart.h"
#include <string.h>

#define TOTAL_CAN_IDS 42

struct Can_message {
    uint32_t ID;
    uint8_t  DLC;
    uint8_t Data[8]; 
    volatile uint8_t updated; // IMPORTANT: tells the main loop new data is ready
};

extern UART_HandleTypeDef huart2;

void can_buffer_init(void);
void send_to_can_buffer(uint32_t can_id, uint8_t *can_data);
void send_uart(void);





#endif