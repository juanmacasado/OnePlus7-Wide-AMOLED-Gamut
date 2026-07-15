    // SPDX-FileCopyrightText: 2026 juanmacasado
    // SPDX-License-Identifier: Apache-2.0
    .text
    .global _start
    .type _start, %function
    .extern insert_mode
    .extern stack_fail
    .extern continue_init
_start:
    mov     w8, #4
    str     w8, [sp, #8]

    movz    x8, #0x5722
    movk    x8, #0x6469, lsl #16
    movk    x8, #0x2065, lsl #32
    movk    x8, #0x4d41, lsl #48
    str     x8, [sp, #0x10]

    movz    x8, #0x4c4f
    movk    x8, #0x4445, lsl #16
    movk    x8, #0x4720, lsl #32
    movk    x8, #0x6d61, lsl #48
    str     x8, [sp, #0x18]

    mov     x8, #0x7475
    str     x8, [sp, #0x20]

    mov     x8, #2
    movk    x8, #3, lsl #32
    str     x8, [sp, #0x28]

    add     x0, sp, #8
    add     x1, sp, #8
    bl      insert_mode

    ldr     x8, [x21, #0x28]
    ldur    x9, [x29, #-8]
    cmp     x8, x9
    b.ne    stack_fail
    b       continue_init
