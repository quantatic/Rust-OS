global long_mode_start
extern rust_main

section .text
bits 64
long_mode_start:
          xor ax, ax
          mov ss, ax
          mov ds, ax
          mov es, ax
          mov fs, ax
          mov ss, ax

          call rust_main

          hlt
