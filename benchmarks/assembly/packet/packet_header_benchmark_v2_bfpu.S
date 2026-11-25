# ================================================================
# BFPU-ENABLED
# Embedded networking packet-header field-processing benchmark
#
# Data/output RAM (byte addresses):
#   0x400 : checksum
#   0x404 : PASS/FAIL
#   0x408..0x42C : final packet A/B words
#
# Output area is deliberately outside the program text.
# ================================================================

    .option norvc
    .text
    .align 2
    .globl _start

_start:

    addi x12, x0, 42       # new DSCP = 42
    addi x13, x0, 64       # new TTL = 64
    addi x14, x0, 17       # new protocol = 17
    addi x5, x0, 0xB2      # FD0 = DSCP offset18 width6
    .word 0x0002C00B   # FDSETI FD0, x5
    addi x5, x0, 0xE8      # FD1 = TTL offset8 width8
    .word 0x0002C08B   # FDSETI FD1, x5
    addi x5, x0, 0xE0      # FD2 = protocol offset0 width8
    .word 0x0002C10B   # FDSETI FD2, x5
    addi x18, x0, 0       # checksum
    addi x28, x0, 0x400     # output base, outside code
    addi x29, x0, 1       # PASS
    lui x8, 0x45290    # P0: header word A
    addi x8, x8, 52
    lui x9, 0x40004    # P0: header word B
    addi x9, x9, 6
    .word 0x0DC4028B   # GETFU x5, x8, 28, 4 (version)
    .word 0x1524030B   # GETFU x6, x8, 18, 6 (DSCP)
    .word 0x1C84838B   # GETFU x7, x9, 8, 8 (TTL)
    .word 0x1C04850B   # GETFU x10, x9, 0, 8 (protocol)
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    .word 0x00C4640B   # PUTF x8, FD0, x12 (DSCP=42)
    .word 0x02D4E48B   # PUTF x9, FD1, x13 (TTL=64)
    .word 0x04E4E48B   # PUTF x9, FD2, x14 (protocol=17)
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 8(x28)
    sw x9, 12(x28)
    lui x8, 0x45580    # P1: header word A
    addi x8, x8, 100
    lui x9, 0x20004    # P1: header word B
    addi x9, x9, 273
    .word 0x0DC4028B   # GETFU x5, x8, 28, 4 (version)
    .word 0x1524030B   # GETFU x6, x8, 18, 6 (DSCP)
    .word 0x1C84838B   # GETFU x7, x9, 8, 8 (TTL)
    .word 0x1C04850B   # GETFU x10, x9, 0, 8 (protocol)
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    .word 0x00C4640B   # PUTF x8, FD0, x12 (DSCP=42)
    .word 0x02D4E48B   # PUTF x9, FD1, x13 (TTL=64)
    .word 0x04E4E48B   # PUTF x9, FD2, x14 (protocol=17)
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 16(x28)
    sw x9, 20(x28)
    lui x8, 0x458A0    # P2: header word A
    addi x8, x8, 200
    lui x9, 0x60004    # P2: header word B
    addi x9, x9, -250
    .word 0x0DC4028B   # GETFU x5, x8, 28, 4 (version)
    .word 0x1524030B   # GETFU x6, x8, 18, 6 (DSCP)
    .word 0x1C84838B   # GETFU x7, x9, 8, 8 (TTL)
    .word 0x1C04850B   # GETFU x10, x9, 0, 8 (protocol)
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    .word 0x00C4640B   # PUTF x8, FD0, x12 (DSCP=42)
    .word 0x02D4E48B   # PUTF x9, FD1, x13 (TTL=64)
    .word 0x04E4E48B   # PUTF x9, FD2, x14 (protocol=17)
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 24(x28)
    sw x9, 28(x28)
    lui x8, 0x45BB0    # P3: header word A
    addi x8, x8, 256
    lui x9, 0x00008    # P3: header word B
    addi x9, x9, 17
    .word 0x0DC4028B   # GETFU x5, x8, 28, 4 (version)
    .word 0x1524030B   # GETFU x6, x8, 18, 6 (DSCP)
    .word 0x1C84838B   # GETFU x7, x9, 8, 8 (TTL)
    .word 0x1C04850B   # GETFU x10, x9, 0, 8 (protocol)
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    .word 0x00C4640B   # PUTF x8, FD0, x12 (DSCP=42)
    .word 0x02D4E48B   # PUTF x9, FD1, x13 (TTL=64)
    .word 0x04E4E48B   # PUTF x9, FD2, x14 (protocol=17)
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 32(x28)
    sw x9, 36(x28)
    sw x18, 0(x28)      # checksum
    lui x30, 0xD6A70    # expected checksum
    addi x30, x30, 1170
    bne x18, x30, fail      # fail offset 8
    sw x29, 4(x28)      # PASS=1
    jal x0, 0              # PASS loop
fail:
    addi x29, x0, 0       # FAIL=0
    sw x29, 4(x28)      # FAIL=0
    jal x0, 0              # FAIL loop
