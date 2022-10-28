// ===============================================================
// 
// Megaprocessor
// =============
// This file holds definitions useful for writing assembler
// programs for the Megaprocessor.
//
// This version : 15th May 2016
//
// ================================================================
//
// Coding
// =======
// definition for interrupt enable bit
PS_INT_ENABLE_BIT               equ     0x01;
PS_INT_CARRY_BIT                equ     0x05;

// ================================================================
//
// External RAM:
EXT_RAM_START                   equ     0x0000;
EXT_RAM_LEN                     equ     0x8000;

// ================================================================
//
// To handle the 256 bytes of RAM built from discrete components:
INT_RAM_START                   equ     0xA000;
INT_RAM_LEN                     equ     0x0100;

INT_RAM_BYTES_ACROSS            equ     4;
INT_RAM_BYTES_HEIGHT_AS_SHIFT   equ     6;
INT_RAM_BYTES_HEIGHT            equ     64;// 1 << INT_RAM_BYTES_HEIGHT_AS_SHIFT

// ================================================================
//
// To handle the peripherals:
PERIPHERALS_BASE                equ     0x8000;
TIMER_BASE                      equ     PERIPHERALS_BASE + 0x00;
UART_BASE                       equ     PERIPHERALS_BASE + 0x10;
INTERRUPT_BASE                  equ     PERIPHERALS_BASE + 0x20;
GEN_IO_BASE                     equ     PERIPHERALS_BASE + 0x30;

// register locations for the GPIO...
GEN_IO_OUTPUT                   equ     GEN_IO_BASE + 0;
GEN_IO_INPUT                    equ     GEN_IO_BASE + 2;
GEN_IO_CTR                      equ     GEN_IO_BASE + 4;

// register locations for the Timer...
TIME_BLK_COUNTER                equ     TIMER_BASE + 0x00;
TIME_BLK_TIMER                  equ     TIMER_BASE + 0x02;
TIME_BLK_TIMER_CTRL             equ     TIMER_BASE + 0x04;
// bit definitions for timer control register
TIME_BLK_TIMER_CTRL_EN_TIMER    equ     0x01;
TIME_BLK_TIMER_CTRL_CLR_COUNT   equ     0x02;
TIME_BLK_TIMER_CTRL_CLR_TIMER   equ     0x04;

// masks for selecting switch value on Venom Arcade Stick
// (Switches are HIGH by "default", and go LOW on being pressed).
IO_SWITCH_FLAG_UP               EQU     0x0001;
IO_SWITCH_FLAG_DOWN             EQU     0x0002;
IO_SWITCH_FLAG_LEFT             EQU     0x0004;
IO_SWITCH_FLAG_RIGHT            EQU     0x0008;
IO_SWITCH_FLAG_SQUARE           EQU     0x0010;
IO_SWITCH_FLAG_TRIANGLE         EQU     0x0020;
IO_SWITCH_FLAG_CIRCLE           EQU     0x0040;
IO_SWITCH_FLAG_CROSS            EQU     0x0080;
IO_SWITCH_FLAG_L1               EQU     0x0100;
IO_SWITCH_FLAG_L2               EQU     0x0200;
IO_SWITCH_FLAG_R1               EQU     0x0400;
IO_SWITCH_FLAG_R2               EQU     0x0800;

// register locations for the Interrupt controller...
INTERRUPT_SOURCE                EQU     INTERRUPT_BASE + 0x00;
INTERRUPT_MASK                  EQU     INTERRUPT_BASE + 0x01;

// interrupt souurce enable/value bit masks
INTERRUPT_BIT_USER              EQU     0x01;
INTERRUPT_BIT_UART_SPACE        EQU     0x02;
INTERRUPT_BIT_UART_RX_DATA      EQU     0x04;
INTERRUPT_BIT_TIMER             EQU     0x08;
INTERRUPT_BIT_COUNTER           EQU     0x10;
INTERRUPT_BIT_INPUT_CHANGE      EQU     0x20;
