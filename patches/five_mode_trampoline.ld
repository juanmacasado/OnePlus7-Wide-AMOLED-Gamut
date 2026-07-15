/* SPDX-FileCopyrightText: 2026 juanmacasado */
/* SPDX-License-Identifier: Apache-2.0 */
insert_mode = 0x83a0;
stack_fail = 0x8904;
continue_init = 0x88d8;
SECTIONS {
  . = 0x9f00;
  .text : { *(.text) }
}
