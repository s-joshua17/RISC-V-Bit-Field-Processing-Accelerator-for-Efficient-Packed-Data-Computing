/* Benchmark 3: RGB888 -> RGB565 graphics/display workload (BFPU)
 * 1024 deterministic RGB888 pixels -> RGB565.
 * Output: 0x400 checksum, 0x404 PASS, 0x408 last RGB565, 0x40C pixel count.
 * No external input buffer: pixel stream is generated deterministically in registers.
 */
    .section .text
    .globl _start
    .align 2
_start:
    addi x5, x0, 13
    addi x6, x0, 29
    addi x7, x0, 47
    addi x8, x0, 37
    addi x9, x0, 73
    addi x18, x0, 109
    addi x20, x0, 1024
    addi x21, x0, 1024
    addi x22, x0, 0
    addi x28, x0, 139
    .word 0x000E400B   # FDSETI FD0, x28
    addi x28, x0, 165
    .word 0x000E408B   # FDSETI FD1, x28
    addi x28, x0, 128
    .word 0x000E410B   # FDSETI FD2, x28
loop:
    slli x17, x5, 16
    slli x28, x6, 8
    or   x17, x17, x28
    or   x17, x17, x7
    .word 0x11388C0B   # GETFU x24, x17, 19, 5
    .word 0x14A88C8B   # GETFU x25, x17, 10, 6
    .word 0x10388D0B   # GETFU x26, x17, 3, 5
    addi x23, x0, 0
    .word 0x018BEB8B   # PUTF x23, FD0, x24
    .word 0x039BEB8B   # PUTF x23, FD1, x25
    .word 0x05ABEB8B   # PUTF x23, FD2, x26
    add  x22, x22, x23
    add  x5, x5, x8
    andi x5, x5, 255
    add  x6, x6, x9
    andi x6, x6, 255
    add  x7, x7, x18
    andi x7, x7, 255
    addi x20, x20, -1
    bne  x20, x0, loop
    lui  x27, 8192
    addi x27, x27, -512
    xor  x28, x22, x27
    sltiu x28, x28, 1
    lui  x27, 15
    addi x27, x27, -328
    xor  x29, x23, x27
    sltiu x29, x29, 1
    and  x11, x28, x29
    sw   x22, 0(x21)
    sw   x23, 8(x21)
    addi x28, x0, 1024
    sw   x28, 12(x21)
    sw   x11, 4(x21)
done:
    jal  x0, done
