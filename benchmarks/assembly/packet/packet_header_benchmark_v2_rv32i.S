# ================================================================
# RV32I BASELINE
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
    lui x15, 0xFF040    # clear DSCP bits [23:18]
    addi x15, x15, -1
    lui x16, 0xFFFF0    # clear TTL bits [15:8]
    addi x16, x16, 255
    addi x17, x0, -256    # clear protocol bits [7:0]
    addi x18, x0, 0       # checksum
    addi x28, x0, 0x400     # output base, outside code
    addi x29, x0, 1       # PASS
    lui x8, 0x45290    # P0: header word A
    addi x8, x8, 52
    lui x9, 0x40004    # P0: header word B
    addi x9, x9, 6
    srli x5, x8, 28       # version = A[31:28]
    andi x5, x5, 0x0F
    srli x6, x8, 18       # DSCP = A[23:18]
    andi x6, x6, 0x3F
    srli x7, x9, 8        # TTL = B[15:8]
    andi x7, x7, 0xFF
    andi x10, x9, 0xFF # protocol = B[7:0]
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    and x11, x8, x15       # clear DSCP field
    slli x30, x12, 18      # new DSCP field
    or x8, x11, x30
    and x11, x9, x16       # clear TTL field
    slli x30, x13, 8       # new TTL field
    or x9, x11, x30
    and x11, x9, x17       # clear protocol
    or x9, x11, x14
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 8(x28)
    sw x9, 12(x28)
    lui x8, 0x45580    # P1: header word A
    addi x8, x8, 100
    lui x9, 0x20004    # P1: header word B
    addi x9, x9, 273
    srli x5, x8, 28       # version = A[31:28]
    andi x5, x5, 0x0F
    srli x6, x8, 18       # DSCP = A[23:18]
    andi x6, x6, 0x3F
    srli x7, x9, 8        # TTL = B[15:8]
    andi x7, x7, 0xFF
    andi x10, x9, 0xFF # protocol = B[7:0]
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    and x11, x8, x15       # clear DSCP field
    slli x30, x12, 18      # new DSCP field
    or x8, x11, x30
    and x11, x9, x16       # clear TTL field
    slli x30, x13, 8       # new TTL field
    or x9, x11, x30
    and x11, x9, x17       # clear protocol
    or x9, x11, x14
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 16(x28)
    sw x9, 20(x28)
    lui x8, 0x458A0    # P2: header word A
    addi x8, x8, 200
    lui x9, 0x60004    # P2: header word B
    addi x9, x9, -250
    srli x5, x8, 28       # version = A[31:28]
    andi x5, x5, 0x0F
    srli x6, x8, 18       # DSCP = A[23:18]
    andi x6, x6, 0x3F
    srli x7, x9, 8        # TTL = B[15:8]
    andi x7, x7, 0xFF
    andi x10, x9, 0xFF # protocol = B[7:0]
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    and x11, x8, x15       # clear DSCP field
    slli x30, x12, 18      # new DSCP field
    or x8, x11, x30
    and x11, x9, x16       # clear TTL field
    slli x30, x13, 8       # new TTL field
    or x9, x11, x30
    and x11, x9, x17       # clear protocol
    or x9, x11, x14
    add x18, x18, x8
    add x18, x18, x9
    sw x8, 24(x28)
    sw x9, 28(x28)
    lui x8, 0x45BB0    # P3: header word A
    addi x8, x8, 256
    lui x9, 0x00008    # P3: header word B
    addi x9, x9, 17
    srli x5, x8, 28       # version = A[31:28]
    andi x5, x5, 0x0F
    srli x6, x8, 18       # DSCP = A[23:18]
    andi x6, x6, 0x3F
    srli x7, x9, 8        # TTL = B[15:8]
    andi x7, x7, 0xFF
    andi x10, x9, 0xFF # protocol = B[7:0]
    add x18, x18, x5
    add x18, x18, x6
    add x18, x18, x7
    add x18, x18, x10
    and x11, x8, x15       # clear DSCP field
    slli x30, x12, 18      # new DSCP field
    or x8, x11, x30
    and x11, x9, x16       # clear TTL field
    slli x30, x13, 8       # new TTL field
    or x9, x11, x30
    and x11, x9, x17       # clear protocol
    or x9, x11, x14
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
