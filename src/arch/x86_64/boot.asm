; Errors table
; 0  - multiboot magic number mismatch
; 1  - cpuid functionality missing
; 2  - long mode functionality missing

MULTIBOOT_MAGIC_VAL equ       0x36D76289

global start
extern long_mode_start

section .text
bits 32
start:
          mov esp, stack_bottom ; initialize stack pointer

          call check_multiboot
          call check_cpuid
          call check_long_mode
          call setup_page_table
          call enable_paging

          ; print 'OK' to the screen
          mov dword [0xb8000], 0x2f4b2f4f

          lgdt [gdt64.pointer]
          jmp gdt64.code:long_mode_start

          hlt

; Prints 'ERR: X` where X is the given error code, then hangs.
; Error code (in ascii) given in al
error:
          mov dword [0xb8000], 0x4f524f45         ; "ER"
          mov dword [0xb8004], 0x4f3a4f52         ; "R:"
          mov dword [0xb8008], 0x4f204f20         ; "_ "
          mov byte  [0xb800a], al                 ; "X"
          hlt

check_multiboot:
          cmp eax, MULTIBOOT_MAGIC_VAL            ; eax should contain this magic value when actually started via multiboot
          jne .no_multiboot
          ret
.no_multiboot:
          mov al, "0"
          jmp error

check_cpuid:
          ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
          ; in the FLAGS register. If we can flip it, CPUID is available.

          ; Copy FLAGS in to EAX via stack
          pushfd
          pop eax

          ; Copy to ECX as well for comparing later on
          mov ecx, eax

          ; Flip the ID bit
          xor eax, 1 << 21

          ; Copy EAX to FLAGS via the stack
          push eax
          popfd

          ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
          pushfd
          pop eax

          ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
          ; ID bit back if it was ever flipped).
          push ecx
          popfd

          ; Compare EAX and ECX. If they are equal then that means the bit
          ; wasn't flipped, and CPUID isn't supported.
          cmp eax, ecx
          je .no_cpuid
          ret
.no_cpuid:
          mov al, "1"
          jmp error

check_long_mode:
          ; test if extended processor info in available
          mov eax, 0x80000000    ; implicit argument for cpuid
          cpuid                  ; get highest supported argument
          cmp eax, 0x80000001    ; it needs to be at least 0x80000001
          jb .no_long_mode       ; if it's less, the CPU is too old for long mode

          ; use extended info to test if long mode is available
          mov eax, 0x80000001    ; argument for extended processor info
          cpuid                  ; returns various feature bits in ecx and edx
          test edx, 1 << 29      ; test if the LM-bit is set in the D-register
          jz .no_long_mode       ; If it's not set, there is no long mode
          ret
.no_long_mode:
          mov al, "2"
          jmp error

setup_page_table:
          mov eax, p3_table
          or eax, 0b11                  ; present + writable
          mov [p4_table], eax

          mov eax, p2_table
          or eax, 0b11                  ; present + writable
          mov [p3_table], eax

          mov eax, p1_table
          or eax, 0b11                  ; present + writable
          mov [p2_table], eax

          xor ecx, ecx
.map_p1_table:
          mov eax, 0x1000               ; 2 KiB pages
          mul ecx                       ; start address of ecx-th page
          or eax, 0b11                  ; present + writable
          mov [p1_table + ecx * 8], eax ; actually map this page in p1
          
          inc ecx
          cmp ecx, 0x200                ; 512 entries in p1 page table
          jne .map_p1_table

          ret

enable_paging:
          mov eax, p4_table
          mov cr3, eax        ; load cr3 with page table base

          mov eax, cr4
          or eax, 1 << 5      ; enable PAE flag (Physical Address Extension)
          mov cr4, eax

          mov ecx, 0xC0000080 ; EFER MSR ID
          rdmsr
          or eax, 1 << 8      ; set long mode bit
          wrmsr

          mov eax, cr0
          or eax, 1 << 31     ; enable paging bit
          mov cr0, eax
          
          ret

section .bss
align 4096
p4_table:
          resb 0x1000
p3_table:
          resb 0x1000
p2_table:
          resb 0x1000
p1_table:
          resb 0x1000
stack_top:
          resb 0x10000
stack_bottom:

section .rodata
gdt64:
          dq        0                                                 ; zero entry
.code:    equ       $ - gdt64
          dq        (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)     ; code segment descriptor
.pointer:
          dw        $ - gdt64 - 1                                     ; gdt length - 1
          dq        gdt64                                             ; gdt start address
