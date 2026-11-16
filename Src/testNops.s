    .text
    .globl _start
_start:
    addi  x1, x0, 5          # 00
    addi  x2, x0, 3          # 04
    nop                      # 08
    nop                      # 0C
    nop                      # 10
    add   x3, x1, x2         # 14: x3 = 8
    nop                      # 18
    nop                      # 1C
    nop                      # 20
    sub   x4, x3, x1         # 24: x4 = 3
    or    x5, x3, x2         # 28: x5 = 11
    nop                      # 2C
    nop                      # 30
    nop                      # 34
    add   x6, x3, x4         # 38: x6 = 11
    addi  x0, x1, 7          # 3C: x0 sigue en 0
    add   x7, x0, x1         # 40: x7 = 5
    addi  x8, x0, 4          # 44: x8 = 4
    nop                      # 48
    nop                      # 4C
    nop                      # 50
    sw    x8, 0(x8)          # 54: mem[4] = 4
    lw    x9, 0(x8)          # 58: x9 = 4
    nop                      # 5C
    nop                      # 60
    nop                      # 64
    add   x10, x9, x9        # 68: x10 = 8
    nop                      # 6C
    nop                      # 70
    nop                      # 74
    beq   x10, x3, taken     # 78: tomado -> 0x8C
    nop                      # 7C  (slot de branch)
    nop                      # 80  (slot de branch)
    addi  x11, x0, 1         # 84: saltada
    addi  x11, x0, 2         # 88: saltada
taken:
    bne   x10, x3, fail      # 8C: no tomado
    nop                      # 90
    nop                      # 94
    addi  x12, x0, 9         # 98: x12 = 9
    jal   x13, target        # 9C: -> 0xB0, x13 = 0xA0
    nop                      # A0  (slot)
    nop                      # A4  (slot)
    addi  x14, x0, 1         # A8: saltada
fail:
    addi  x14, x0, 2         # AC: saltada
target:
    nop                      # B0  (x13 todavía no está escrito)
    nop                      # B4
    nop                      # B8
    jalr  x15, 44(x13)       # BC: -> 0xA0 + 44 = 0xCC, x15 = 0xC0
    nop                      # C0  (slot)
    nop                      # C4  (slot)
    addi  x16, x0, 1         # C8: saltada
dest:
    lui   x17, 0x12345       # CC: x17 = 0x12345000
    auipc x18, 0             # D0: x18 = 0xD0
end:
    jal   x0, end            # D4: loop infinito
