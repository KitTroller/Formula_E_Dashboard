/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define InnerLeftDetect_Pin GPIO_PIN_13
#define InnerLeftDetect_GPIO_Port GPIOC
#define InnerLeftDetect_EXTI_IRQn EXTI15_10_IRQn
#define InnerRightDetect_Pin GPIO_PIN_14
#define InnerRightDetect_GPIO_Port GPIOC
#define InnerRightDetect_EXTI_IRQn EXTI15_10_IRQn
#define User_LED_Pin GPIO_PIN_15
#define User_LED_GPIO_Port GPIOC
#define EN2Button_Pin GPIO_PIN_3
#define EN2Button_GPIO_Port GPIOC
#define EN2Button_EXTI_IRQn EXTI3_IRQn
#define Encoder_2B_Pin GPIO_PIN_0
#define Encoder_2B_GPIO_Port GPIOA
#define Encoder_2A_Pin GPIO_PIN_1
#define Encoder_2A_GPIO_Port GPIOA
#define Encoder_1A_Pin GPIO_PIN_6
#define Encoder_1A_GPIO_Port GPIOA
#define Encoder_1B_Pin GPIO_PIN_7
#define Encoder_1B_GPIO_Port GPIOA
#define EN1Button_Pin GPIO_PIN_0
#define EN1Button_GPIO_Port GPIOB
#define EN1Button_EXTI_IRQn EXTI0_IRQn
#define EN3Button_Pin GPIO_PIN_15
#define EN3Button_GPIO_Port GPIOB
#define EN3Button_EXTI_IRQn EXTI15_10_IRQn
#define Encoder_3B_Pin GPIO_PIN_6
#define Encoder_3B_GPIO_Port GPIOC
#define Encoder_3A_Pin GPIO_PIN_7
#define Encoder_3A_GPIO_Port GPIOC
#define PWM_RB_LED_Pin GPIO_PIN_8
#define PWM_RB_LED_GPIO_Port GPIOC
#define RightButtonDetect_Pin GPIO_PIN_9
#define RightButtonDetect_GPIO_Port GPIOC
#define RightButtonDetect_EXTI_IRQn EXTI9_5_IRQn
#define Encoder_5A_Pin GPIO_PIN_8
#define Encoder_5A_GPIO_Port GPIOA
#define Encoder_5B_Pin GPIO_PIN_9
#define Encoder_5B_GPIO_Port GPIOA
#define PWM_LB_LED_Pin GPIO_PIN_10
#define PWM_LB_LED_GPIO_Port GPIOA
#define LeftButtonDetect_Pin GPIO_PIN_12
#define LeftButtonDetect_GPIO_Port GPIOA
#define LeftButtonDetect_EXTI_IRQn EXTI15_10_IRQn
#define BackButtonDetect_Pin GPIO_PIN_4
#define BackButtonDetect_GPIO_Port GPIOB
#define BackButtonDetect_EXTI_IRQn EXTI4_IRQn
#define SpareButtonDetect_Pin GPIO_PIN_5
#define SpareButtonDetect_GPIO_Port GPIOB
#define SpareButtonDetect_EXTI_IRQn EXTI9_5_IRQn
#define Encoder_4A_Pin GPIO_PIN_6
#define Encoder_4A_GPIO_Port GPIOB
#define Encoder_4B_Pin GPIO_PIN_7
#define Encoder_4B_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */
//Defines for encoder values
	#define EN1_Value TIM3->CNT
	#define EN2_Value TIM5->CNT
	#define EN3_Value TIM8->CNT
	#define EN4_Value TIM4->CNT
	#define EN5_Value TIM1->CNT
	
	// Defines for switches
	#define switchEN1 HAL_GPIO_ReadPin(GPIOC, GPIO_PIN_4)
	#define switchEN2 HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_2)
 
/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
