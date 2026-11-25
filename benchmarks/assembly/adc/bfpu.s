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
    # x10=checksum, x30=0x400 result pointer
    addi x10, x0, 0
    addi x30, x0, 0x400
    # Program three descriptors: FD0=(offset24,width2), FD1=(0,width5), FD2=(24,width4).
    addi x28, x0, 56       # (1<<5)|24
    .word 0x000E400B   # FDSETI FD0, x28
    addi x28, x0, 128      # (4<<5)|0
    .word 0x000E408B   # FDSETI FD1, x28
    addi x28, x0, 120      # (3<<5)|24
    .word 0x000E410B   # FDSETI FD2, x28
    # Configuration 1: RES=2, CH=9, TRIG=6
    addi x29, x0, 2
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 9
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 6
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 2: RES=1, CH=17, TRIG=3
    addi x29, x0, 1
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 17
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 3
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    andi x6, x6, -2
    # Configuration 3: RES=3, CH=3, TRIG=9
    addi x29, x0, 3
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 3
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 9
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 4: RES=0, CH=28, TRIG=12
    addi x29, x0, 0
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 28
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 12
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    andi x6, x6, -2
    # Configuration 5: RES=2, CH=5, TRIG=4
    addi x29, x0, 2
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 5
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 4
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 6: RES=3, CH=12, TRIG=14
    addi x29, x0, 3
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 12
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 14
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    andi x6, x6, -2
    # Configuration 7: RES=1, CH=21, TRIG=1
    addi x29, x0, 1
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 21
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 1
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
    add  x10, x10, x31
    ori  x6, x6, 1
    # Configuration 8: RES=0, CH=7, TRIG=10
    addi x29, x0, 0
    .word 0x01D2E28B   # PUTF x5, FD0, x29
    addi x29, x0, 7
    .word 0x03D3E38B   # PUTF x7, FD1, x29
    addi x29, x0, 10
    .word 0x05D3630B   # PUTF x6, FD2, x29
    .word 0x05828F8B   # GETFU x31, x5, 24, 2
    add  x10, x10, x31
    .word 0x10038F8B    # GETFU x31, x7, 0, 5
    add  x10, x10, x31
    .word 0x0D830F8B   # GETFU x31, x6, 24, 4
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
