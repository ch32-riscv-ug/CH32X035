;
INCLUDE				PIOC_INC.ASM
;
;
					ORG   0X0000
					DW    0X0000
					JMP   MCU_START
					DW    0X0FFF
;

FLAG			    EQU   SFR_DATA_REG0
VAR			    	EQU   SFR_DATA_REG1
EVEN			    EQU   SFR_DATA_REG2
ADDR			    EQU   SFR_DATA_REG3
DATA			    EQU   SFR_DATA_REG7


TIM_INIT:			CLRA
					MOVA  SFR_TMR0_INIT
					MOVL  0X03
					AND   FLAG,A
					XORL  0X07
					MOVA  SFR_TIMER_CTRL
					RET

CLK_10:				NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					RET
;
DELAY_US:			CALL  CLK_10
					NOP
					CALL  CLK_10
					NOP
					CALL  CLK_10
					NOP
					CALL  CLK_10
					NOP
					ADDL  0XFF
					NOP
					JNZ   DELAY_US
					RET


CLK_6:				NOP
					NOP
					RET

DELAY_7T:			CALL  CLK_6
					CALL  CLK_6
DELAY_5T:			CALL  CLK_6
					CALL  CLK_6
DELAY_3T:			CALL  CLK_6
					CALL  CLK_6
					NOP
					NOP
					RET

DELAY_1T_4T:		BTSC  FLAG,1
					CALL  DELAY_3T
					RET

DELAY_1T_8T:		BTSC  FLAG,1
					CALL  DELAY_7T
					RET

DELAY:				BTSC  FLAG,0
					CALL  DELAY_1T_8T
					BTSC  FLAG,1
					CALL  DELAY_5T
					CALL  CLK_6
					CALL  CLK_6
					NOP
					NOP
					NOP
					NOP
					RET

BIT:           		BC    SFR_PORT_IO,SB_PORT_OUT0
					BTSC  FLAG,0
					CALL  DELAY_1T_4T
					BTSC  FLAG,1
					CALL  DELAY_3T
					BTSS  SFR_STATUS_REG,SB_GP_BIT_X
					CALL  DELAY
					NOP
	                BS    SFR_PORT_IO,SB_PORT_OUT0
					CALL  CLK_6
					CALL  CLK_6
					CALL  CLK_6
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					INC   EVEN
					BC    SFR_STATUS_REG,SB_GP_BIT_X
					RET	

BIT1:           	CLR   SFR_TMR0_COUNT
					BC    SFR_PORT_IO,SB_PORT_OUT0
					BS    SFR_PORT_DIR,SB_PORT_DIR0
					BS    SFR_TIMER_CTRL,SB_TMR0_ENABLE
					BTSC  FLAG,0
					CALL  DELAY_1T_4T
					BTSC  FLAG,1
					CALL  DELAY_3T
					BC    SFR_STATUS_REG,SB_GP_BIT_X
					MOVL  0X03
					BC    SFR_PORT_DIR,SB_PORT_DIR0
					WAITB WB_PORT_XOR0_1
					BC    SFR_TIMER_CTRL,SB_TMR0_ENABLE
					MOVL  0X0C
					SUB   SFR_TMR0_COUNT,A
					BTSC  SFR_STATUS_REG,SB_FLAG_Z
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					BTSC  SFR_STATUS_REG,SB_FLAG_C
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					INC   EVEN
					CALL  CLK_6
					RET

NEW_WRITE:			WAITB  WB_DATA_MW_SR_1
					MOV   SFR_CTRL_WR,A
					CALL  TIM_INIT
					CLR   EVEN
					BC    SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_PORT_DIR,SB_PORT_DIR0
					MOVL  0X04
					MOVA  VAR
					;MOVIA DATA
					BTSC  FLAG,2
					BS    SFR_STATUS_REG,SB_GP_BIT_X	;START
					CALL  BIT
					BTSS  FLAG,2
					JMP   W_R_DATA
					;MOV   SFR_INDIR_PORT2,A				;ADDR
					MOV   ADDR,A
					MOVA  SFR_DATA_EXCH
					BTSC  SFR_DATA_EXCH,6
					BS    SFR_STATUS_REG,SB_GP_BIT_X	
					CALL  BIT
					BTSC  SFR_DATA_EXCH,5
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,4
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,3
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,2
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,1
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,0
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  FLAG,3
					BS    SFR_STATUS_REG,SB_GP_BIT_X	;WRITE
					CALL  BIT	
W_R_DATA:			MOVIP DATA
					BTSS  FLAG,3
					JMP   READ_DATA				
WRITE_DATA:			MOV   SFR_INDIR_PORT,A
					;MOV   SFR_INDIR_PORT2,A				;32_DATA
					MOVA  SFR_DATA_EXCH
					BTSC  SFR_DATA_EXCH,7
					BS    SFR_STATUS_REG,SB_GP_BIT_X	
					CALL  BIT
					BTSC  SFR_DATA_EXCH,6
					BS    SFR_STATUS_REG,SB_GP_BIT_X	
					CALL  BIT
					BTSC  SFR_DATA_EXCH,5
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,4
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,3
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,2
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,1
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					BTSC  SFR_DATA_EXCH,0
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					DEC   SFR_INDIR_ADDR
					DEC   VAR
					BTSS  SFR_STATUS_REG,SB_FLAG_Z
					JMP   WRITE_DATA
					BTSC  EVEN,0
					BS    SFR_STATUS_REG,SB_GP_BIT_X
					CALL  BIT
					JMP   STOP
READ_DATA:			CLR   SFR_DATA_EXCH
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,7
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,6
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,5
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,4
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,3
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,2
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,1
					CALL  BIT1
					BTSC  SFR_STATUS_REG,SB_GP_BIT_X
					BS    SFR_DATA_EXCH,0
					MOV   SFR_DATA_EXCH,A
					MOVA  SFR_INDIR_PORT
					DEC   SFR_INDIR_ADDR
					;MOVA  SFR_INDIR_PORT2
					BC    SFR_STATUS_REG,SB_GP_BIT_X
					DEC   VAR
					BTSS  SFR_STATUS_REG,SB_FLAG_Z
					JMP   READ_DATA
					CALL  BIT1
					BTSC  EVEN,0
					BS    FLAG,4
STOP:				BS    SFR_PORT_DIR,SB_PORT_DIR0
					BTSC  FLAG,6
					BS    SFR_SYS_CFG,SB_INT_REQ
					BS    FLAG,5
					MOVL  0X02							;STOP
					BTSC  FLAG,0
					ADDL  0X01
					BTSC  FLAG,1
					ADDL  0X06
					CALL  DELAY_US
					JMP   NEW_WRITE

RES:				BS    SFR_PORT_IO,SB_PORT_OUT0
					BS    SFR_PORT_DIR,SB_PORT_DIR0
					MOVL  0XFF
					CALL  DELAY_US
					BC    SFR_PORT_IO,SB_PORT_OUT0
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XFF
					CALL  DELAY_US
					MOVL  0XCC
					CALL  DELAY_US
					BS    SFR_PORT_IO,SB_PORT_OUT0
					MOVL  0X01
					CALL  DELAY_US
					RET

MCU_START:			NOP
					NOP
					CALL  RES
					JMP   NEW_WRITE
					JMP   MCU_START
;
END
;

