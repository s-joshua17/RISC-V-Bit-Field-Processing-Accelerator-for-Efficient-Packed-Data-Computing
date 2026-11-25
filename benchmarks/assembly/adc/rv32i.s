/* Benchmark 4: Repeated ADC field configure + readback.
 * Derived from the supplied ADC configuration benchmark, extended
 * into a deterministic multi-configuration firmware workload.
 * No external input memory is required. Result area starts at 0x400
 * so it cannot overwrite the instruction stream (the earlier failure mode).
 */
    .section .text
    .globl _start
    .align 2
_start:
    # x5=ADC_CR1, x6=ADC_CR2, x7=ADC_SQR3
    lui  x5, 0xA5C00
    lui  x6, 0x12000
    addi x7, x0, 20
    # x8=~(0x3<<24), x9=~(0xF<<24), x18=~0x1F
    lui  x8, 0xFD000
    addi x8, x8, -1
    lui  x9, 0xF1000
    addi x9, x9, -1
    lui  x18, 0xFFFFF
    addi x18, x18, -32
    # x10=checksum, x30=0x400 result pointer
    addi x10, x0, 0
    addi x30, x0, 0x400
    # Configuration 1: RES=2, CH=9, TRIG=6
    addi x29, x0, 2
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 9
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 6
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 2: RES=1, CH=17, TRIG=3
    addi x29, x0, 1
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 17
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 3
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    andi x6, x6, -2
    # Configuration 3: RES=3, CH=3, TRIG=9
    addi x29, x0, 3
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 3
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 9
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 4: RES=0, CH=28, TRIG=12
    addi x29, x0, 0
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 28
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 12
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    andi x6, x6, -2
    # Configuration 5: RES=2, CH=5, TRIG=4
    addi x29, x0, 2
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 5
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 4
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 6: RES=3, CH=12, TRIG=14
    addi x29, x0, 3
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 12
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 14
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    andi x6, x6, -2
    # Configuration 7: RES=1, CH=21, TRIG=1
    addi x29, x0, 1
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 21
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 1
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 8: RES=0, CH=7, TRIG=10
    addi x29, x0, 0
    andi x29, x29, 3
    slli x29, x29, 24
    and  x5, x5, x8
    or   x5, x5, x29
    addi x29, x0, 7
    andi x29, x29, 31
    and  x7, x7, x18
    or   x7, x7, x29
    addi x29, x0, 10
    andi x29, x29, 15
    slli x29, x29, 24
    and  x6, x6, x9
    or   x6, x6, x29
    srli x31, x5, 24
    andi x31, x31, 3
    add  x10, x10, x31
    andi x31, x7, 31
    add  x10, x10, x31
    srli x31, x6, 24
    andi x31, x31, 15
    add  x10, x10, x31
    andi x6, x6, -2
    # Include final register images in checksum and publish deterministic results.
    add  x10, x10, x5
    add  x10, x10, x6
    add  x10, x10, x7
    sw   x10, 0(x30)
    addi x11, x0, 1
    sw   x11, 4(x30)
    sw   x5,  8(x30)
    sw   x6,  12(x30)
    sw   x7,  16(x30)
done:
    jal  x0, 0
