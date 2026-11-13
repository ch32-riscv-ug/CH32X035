/********************************** (C) COPYRIGHT *******************************
 * File Name          : main.c
 * Author             : WCH
 * Version            : V1.0.0
 * Date               : 2023/12/26
 * Description        : Main program body.
*********************************************************************************
* Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
* Attention: This software (modified or not) and binary are used for
* microcontroller manufactured by Nanjing Qinheng Microelectronics.
*******************************************************************************/

/*
 *@Note
 *GPIO routine:
 *PA0 push-pull output.
 *
 ***Only PA0--PA15 and PC16--PC17 support input pull-down.
 */

#include "debug.h"
#include "lcd.h"
#include "GT9xx.h"
#include "wvui.h"
#include "wvui_port_display.h"
#include "wvui_port_input.h"
#include "wvui_app.h"

#define PANEL_W (320)
#define PANEL_H (240)

static wvui_color_t s_pfb[(uint32_t)PANEL_W * WVUI_CFG_PFB_LINES];

static uintptr_t s_arena_transient_mem[192];
static wvui_arena_t s_arena_transient;

/* Global define */

/* Global Variable */



#define TIM_PCK (8000ul)

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
    USART_Printf_Init(115200);
    printf("SystemClk:%d\r\n", SystemCoreClock);

    TIM3_init();

 
 
 

    wvui_cfg_t cfg = {0};
    int rc;

    if (lcd_init() != 0)
    {
        printf("FAIL: lcd_init()\r\n");
        return 1;
    }

    if (Touch_Init() != 0)
    {
        printf("WARN: touch init failed\r\n");
    }
    else
    {
        printf("touch panel %ux%u\r\n",
               (unsigned)touchChipInfo.width, (unsigned)touchChipInfo.height);
    }

    wvui_port_display_configure(1u);

    cfg.w = PANEL_W;
    cfg.h = PANEL_H;
    cfg.bg = WVUI_RGB565(245, 247, 250);
    cfg.pfb = s_pfb;
    cfg.pfb_pixels = (uint32_t)PANEL_W * WVUI_CFG_PFB_LINES;
    cfg.double_buffer = 1u;

    rc = wvui_init(wvui_port_display(), &cfg);
    if (rc != WVUI_OK)
    {
        printf("FAIL: wvui_init rc=%d\r\n", rc);
        return 1;
    }

    printf("wvui: %dx%d db=%u rows=%u\r\n", (int)wvui_info()->w, (int)wvui_info()->h,
           (unsigned)wvui_info()->double_buffer, (unsigned)wvui_info()->chunk_rows);

    wvui_arena_init(&s_arena_transient, s_arena_transient_mem,
                   (uint32_t)sizeof(s_arena_transient_mem));
    wvui_driver_bind_arena(NULL, &s_arena_transient);
    wvui_driver_bind_input(wvui_port_input());

    if (app_init() != 0)
    {
        printf("FAIL: app init\r\n");
        return 1;
    }

    printf("OK: wvui ready\r\n");

    while (1)
    {
        wvui_app_tick();
 
    }
}
