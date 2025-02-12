.section .text
.align 2
.globl _start
// -------------------------------------------------------------------------------------
// Name:        Lab_2.S
// Purpose:     This code will convert a string of ASCII chracters into Morse code
//              and flash a single LED (Led Bar LED_7) in Morse code with a time base
//		of approximately 500ms.
// Author:      Julius Olajos
// -------------------------------------------------------------------------------------
_start:
// -------------------------------------------------------------------------------------
// GPIO Control Registers Memory Mapping
    .equ GPIO_BASE_CTRL_ADDR, 0x10012000    // Base address for the GPIO control registers
    .equ GPIO_OUTPUT_EN,      0x08          // address offset for enabling GPIO outputs
    .equ GPIO_OUTPUT_VAL,     0x0C          // Address offset for writing to GPIO outputs
    .equ GPIO_OUTPUT_XOR,     0x40          // Address offset for GPIO Outputs XOR
// -------------------------------------------------------------------------------------
// 8 LEDS, 7 Segment LED Display Pins Register Address Mapping
    .equ GPIO_7SEGLED_PINS, 0x0000023F      // Seven Segment LED Display Pins (7)
    .equ GPIO_LEDBAR_PINS,  0x00FC0C00      // LED Bar Pins (8)
    .equ GPIO_ALL_LED_PINS, 0x00FC0E3F      // All LED Pins (15)
    .equ GPIO_LEDBAR_LED_1, 0x00000800      // LEDBAR LED1
    .equ GPIO_LEDBAR_LED_7, 0x00800000      // LEDBAR LED7
// -------------------------------------------------------------------------------------
// Initialize the GPIO control registers
// -------------------------------------------------------------------------------------
    li t0, GPIO_BASE_CTRL_ADDR          // Load Base Address for GPIO Control Registers
    li t1, GPIO_ALL_LED_PINS            // Load GPIO Register to set GPIO_OUTPUT_EN and GPIO_OUTPUT_XOR registers for all GPIO LED Pins
    sw t1, GPIO_OUTPUT_EN(t0)           // Enable outputs on all GPIO LED Pins
    li t2, 0xFF03F1C0
    sw t2, GPIO_OUTPUT_VAL(t0)          // Set all LED pins to zero to turn off all LEDS.
// Reset s1 to the starting address of the input string
ResetLUT:
    la s1, InputLUT           // assign s1 to the address at label LUT
// Start processing each character byte by byte
NextChar:
    lbu a0, 0(s1)             // Read a character to convert to Morse
    addi s1, s1, 1            // point to next value for number of delays, jump by 1 byte
    snez a1, a0               // If we hit 0 (null at end of the string) then reset to the start of lookup table
    bnez a1, ProcessChar      // If we have a character process it
    jal ra, DELAY_2000MS
    j ResetLUT
// Display the converted character to the LED BAR LED_7
ProcessChar:
    jal ra, CHAR2MORSE        // convert ASCII to Morse pattern in a1
   
//    .....Insert Your Code Here.....
    li t4, 0x8000      // this the mask we wre using to read bits
   loop_1: 
        and t3, t4, a1
        beq t3, t4, loop_2
        srli t4, t4, 1
        j loop_1
    loop_2:
        beqz t4, exitd
        and t3, t4, a1
        
        beq t3,t4, ON
        bne t3,t4, OFF
    ON:
        jal ra, LED_ON
        jal ra, DELAY_GENERAL
        srli t4, t4, 1
        j loop_2 
    OFF:
        jal ra, LED_OFF
        jal ra, DELAY_GENERAL
        srli t4, t4, 1
        j loop_2 
   
exitd:
    jal ra, LED_OFF
    jal ra, DELAY_1500MS 
    j NextChar
// Turn the LED On
LED_ON:
    addi sp, sp, -16
    sw ra, 12(sp)
    li t3, GPIO_LEDBAR_LED_7 
    or t3, t3, t5                       //Turn LED7 on
    sw t3, GPIO_OUTPUT_VAL(t0)          // Store this new value in GPIO output register
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
// Turn the LED Off
LED_OFF:
    addi sp, sp, -16
    sw ra, 12(sp)
    and t5, t5, x0                      //Turn LED7 off
    sw t5, GPIO_OUTPUT_VAL(t0)          // Store this new value in GPIO output register
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
DELAY_GENERAL:  
    addi sp, sp, -16
    sw ra, 12(sp)
    li t6, 4000000                      // Start counter
loop1:
    addi t6, t6, -1                     // Counts down the counter
    bne t6, zero, loop1                 // Checks if the counter is 0 if not go back to start of loop
    lw ra, 12(sp)
    addi sp, sp, 16
    ret 
DELAY_1500MS:
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, DELAY_GENERAL
    jal ra, DELAY_GENERAL
    jal ra, DELAY_GENERAL
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
DELAY_2000MS:
    addi sp, sp, -16
    sw ra, 12(sp)
    jal ra, DELAY_GENERAL
    jal ra, DELAY_GENERAL
    jal ra, DELAY_GENERAL
    jal ra, DELAY_GENERAL
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
// Subroutines
// Convert ASCII character to Morse pattern
// Pass ASCII character in a0, output in a1
// Index into MorseLUT must be by steps of 2 bytes
// Convert the ASCII character to Morse Code
CHAR2MORSE:
    addi sp, sp, -16		// Set-up the stack
    sw ra, 12(sp)
    addi a0, a0, -0x41  // Convert ASCII letter to index (A=0, B=1, ...)
    slli a0, a0, 1      // Multiply by 2 to get byte offset
    la t3, MorseLUT     // Load address of MorseLUT
    add t3, t3, a0      // Compute memory address for the Morse pattern
    lhu a1, 0(t3)        // Load Morse pattern into a1
    lw ra, 12(sp)		// read stack
    addi sp, sp, 16		
    ret
// Data used in the program
.align 2
// Character input string
InputLUT:
    .asciz "DWARK"
// Morse Code Look Up Table
.align 2
MorseLUT:
    .half 0x17, 0x1D5, 0x75D, 0x75   // A, B, C, D
    .half 0x1, 0x15D, 0x1DD, 0x55    // E, F, G, H
    .half 0x5, 0x1777, 0x1D7, 0x175  // I, J, K, L
    .half 0x77, 0x1D, 0x777, 0x5DD   // M, N, O, P
    .half 0x1DD7, 0x5D, 0x15, 0x7    // Q, R, S, T
    .half 0x57, 0x157, 0x177, 0x757  // U, V, W, X
    .half 0x1D77, 0x775              // Y, Z
End:
  .end
