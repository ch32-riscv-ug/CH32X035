/********************************** (C) COPYRIGHT *******************************
 * File Name          : main.c
 * Author             : WCH
 * Version            : V1.0.0
 * Date               : 2026/08/06
 * Description        : Main program body.
 *********************************************************************************
 * Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
 * Attention: This software (modified or not) and binary are used for 
 * microcontroller manufactured by Nanjing Qinheng Microelectronics.
 *******************************************************************************/

/*
 *@Note
 A demo for wui
  pins: 
    FLASH_CS   -- PA4
    FLASH_DO   -- PA6  (SPI1_MISO)
    FLASH_DI   -- PA7  (SPI1_MOSI)
    FLASH_CLK  -- PA5  (SPI1_SCK)
    
    LCD_LED    -- PB4
    LCD_DC     -- PB2
    LCD_RST    -- PB3
    LCD_CS     -- PB1
    LCD_SCK    -- PA5  (SPI1_SCK)
    LCD_MOSI   -- PA7  (SPI1_MOSI)
*/
/*********************************IMPORTANT!******************************
  Set WUI_INTERNAL_FLASH (images.h) to select resource 
 location: 0 = external SPI flash, 1 = internal flash.
 *********************************IMPORTANT!******************************/
#include "debug.h"
#include "string.h"
#include "lcd.h"
#include "wui.h"
#include "wui_user/wui_page.h"
#include "wui_port.h"

#define TIM_PCK (1000ul)
/*********************************************************************
 * @fn      TIM3_init
 *
 * @brief   Initialize TIM3 for WCHGUI
 *        
 * @return  none.
 */
void TIM3_init()
{
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM3, ENABLE);

    TIM_TimeBaseInitTypeDef TIM_TimeBaseInitStructure = {0};

    TIM_Cmd(TIM3, DISABLE);

    TIM_TimeBaseInitStructure.TIM_Period        = 0xffff;
    TIM_TimeBaseInitStructure.TIM_Prescaler     = ((SystemCoreClock) / TIM_PCK) - 1;
    TIM_TimeBaseInitStructure.TIM_ClockDivision = TIM_CKD_DIV1;
    TIM_TimeBaseInitStructure.TIM_CounterMode   = TIM_CounterMode_Up;
    TIM_TimeBaseInit(TIM3, &TIM_TimeBaseInitStructure);

    TIM_ARRPreloadConfig(TIM3, DISABLE);
    TIM_ClearFlag(TIM3, TIM_FLAG_Update);

    TIM_Cmd(TIM3, ENABLE);
}
/*********************************************************************
 * @fn      TIM2_Encoder_Init
 *
 * @brief   Initialize TIM2 for encoder
 *        
 * @return  none.
 */
void TIM2_Encoder_Init()
{
    TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
    TIM_ICInitTypeDef       TIM_ICInitStructure;
    GPIO_InitTypeDef        GPIO_InitStructure = {0};

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);

    GPIO_InitStructure.GPIO_Pin  = GPIO_Pin_0 | GPIO_Pin_1;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init(GPIOA, &GPIO_InitStructure);

    TIM_TimeBaseStructInit(&TIM_TimeBaseStructure);
    TIM_TimeBaseStructure.TIM_Prescaler     = 0x0;
    TIM_TimeBaseStructure.TIM_Period        = 160;
    TIM_TimeBaseStructure.TIM_ClockDivision = TIM_CKD_DIV1;
    TIM_TimeBaseStructure.TIM_CounterMode   = TIM_CounterMode_Up;
    TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);

    TIM_EncoderInterfaceConfig(TIM2, TIM_EncoderMode_TI12, TIM_ICPolarity_Rising, TIM_ICPolarity_Rising);

    TIM_ICStructInit(&TIM_ICInitStructure);
    TIM_ICInitStructure.TIM_ICFilter = 10;
    TIM_ICInit(TIM2, &TIM_ICInitStructure);

    TIM_SetCounter(TIM2, 0);
    TIM_Cmd(TIM2, ENABLE);
}
/*********************************************************************
 * @fn      check_direction
 *
 * @brief    Compute the absolute value of a signed 32-bit integer.
 *        
 * @param   a Signed 32-bit integer.
 *
 * @return  Absolute value of a 
 */
uint32_t static inline iabs(int32_t a)
{
    if (a < 0)
    {
        return -a;
    }
    return a;
}
/*********************************************************************
 * @fn      check_direction
 *
 * @brief   Detect the rotation direction of the encoder
 *        
 * @param   current_value The current count value
 *
 * @return  direction The direction of the encoder's rotation
 */
int32_t check_direction(int current_value)
{

    static int last_value = 0;

    if (current_value == last_value)
    {
        return 0;
    }

    int diff = current_value - last_value;
    if (iabs(diff) < 4)
    {
        return 0;
    }

    int32_t direction;

    if (iabs(diff) < 80)
    {
        if (diff > 0)
        {
            direction = 1;
        }
        else
        {
            direction = -1;
        }
    }
    else
    {
        if (diff > 0)
        {
            direction = -1;
        }
        else
        {
            direction = 1;
        }
    }

    last_value = current_value;
    return direction;
}

#define ENC_KEY_PORT GPIOB
#define ENC_KEY_PIN  (GPIO_Pin_0)

#define ENC_KEY()    ((ENC_KEY_PORT->INDR & ENC_KEY_PIN) == 0)


uint32_t key3_state = 0;
/*********************************************************************
 * @fn      Key_GPIOInit
 *
 * @brief   Initialization of the key pins of the encoder
 *        
 * @return  none.
 */
void Key_GPIOInit(void)
{

    GPIO_InitTypeDef GPIO_InitStructure;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);

    GPIO_InitStructure.GPIO_Pin  = ENC_KEY_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
    GPIO_Init(ENC_KEY_PORT, &GPIO_InitStructure);
}

static uint8_t wui_heap_buffer[2 * 1024];

/*********************************************************************
 * @fn      main
 *
 * @brief   Main program.
 *
 * @return  none
 */
int main(void)
{

    SystemCoreClockUpdate();
    Delay_Init();
#if (SDI_PRINT == SDI_PR_OPEN)
    SDI_Printf_Enable();
#else
    USART_Printf_Init(115200);

#endif
    printf("SystemClk:%d\r\n", SystemCoreClock);
    printf("ChipID:%08x\r\n", DBGMCU_GetCHIPID());

    LCD_Init();
    SPI_FLASH_Init();

    uint32_t id = SPI_Flash_ReadID();
    printf("read id %x\n", id);

    TIM2_Encoder_Init();
    TIM3_init();


    wui_init_data_t init_data = {
        .page_count = WUI_PAGE_COUNT,
        .width      = LCD_WIDTH,
        .height     = LCD_HEIGHT,
        .heap_addr  = wui_heap_buffer,
        .heap_size  = sizeof(wui_heap_buffer),
    };

    wui_init(&init_data);

    wui_register_hal(wui_get_hal());
    wui_page_switch(WUI_START_PAGE);


    while (1)
    {

        uint16_t now = TIM3->CNT;

        if (now > 2)
        {
            TIM3->CNT = 0;

            wui_page_ui_tick(now);
        }
        wui_page_ui_update();

        uint32_t tcnt = TIM2->CNT;

        int32_t dir = check_direction(tcnt);

        if (dir > 0)
        {
            HW_Key_event('a');
        }
        else if (dir < 0)
        {
            HW_Key_event('d');
        }

        uint32_t k3 = ENC_KEY();
        if (k3)
        {
            if (key3_state)
            {
            }
            else
            {
                key3_state = 1;
                HW_Key_event('b');
            }
        }
        else
        {
            key3_state = 0;
        }
    }

    while (1)
        ;
}
