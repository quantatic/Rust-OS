MAGIC_NUMBER        equ       0xE85250D6
ARCH_VAL            equ       0x0
HEADER_LEN          equ       header_end - header_start
CHECKSUM            equ       -(MAGIC_NUMBER + ARCH_VAL + HEADER_LEN)

section .multiboot_header
header_start:
          dd        MAGIC_NUMBER
          dd        ARCH_VAL
          dd        HEADER_LEN
          dd        CHECKSUM

          ; additional multiboot tags go here

          ; end tag
          dw        0         ; type
          dw        0         ; flags
          dd        8         ; size
header_end:
