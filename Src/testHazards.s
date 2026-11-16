    .text
    .globl _start
_start:
    addi  x1, x0, 5          # 00: x1 = 5
    addi  x2, x0, 3          # 04: x2 = 3
    add   x3, x1, x2         # 08: x3 = 8      fwd dist 1 y 2
    sub   x4, x3, x1         # 0C: x4 = 3      fwd EX/MEM
    or    x5, x3, x2         # 10: x5 = 11     fwd MEM/WB
    add   x6, x3, x4         # 14: x6 = 11     bypass RF
    addi  x0, x1, 7          # 18: x0 = 0      escribir x0 no hace nada
    add   x7, x0, x1         # 1C: x7 = 5      no fwd de x0
    addi  x8, x0, 4          # 20: x8 = 4
    sw    x8, 0(x8)          # 24: mem[4] = 4  fwd addr y dato
    lw    x9, 0(x8)          # 28: x9 = 4
    add   x10, x9, x9        # 2C: x10 = 8     load-use (dir = dato, no lo detecta)
    beq   x10, x3, taken     # 30: tomado -> 0x3C
    addi  x11, x0, 1         # 34: flush (x11 = 0)
    addi  x11, x0, 2         # 38: saltada
taken:
    bne   x10, x3, fail      # 3C: no tomado
    addi  x12, x0, 9         # 40: x12 = 9
    jal   x13, target        # 44: -> 0x50, x13 = 0x48
link:
    addi  x14, x0, 1         # 48: flush (x14 = 0)
fail:
    addi  x14, x0, 2         # 4C: saltada
target:
    jalr  x15, 16(x13)       # 50: -> 0x58, x15 = 0x54
    addi  x16, x0, 1         # 54: flush (x16 = 0)
    lui   x17, 0x12345       # 58: x17 = 0x12345000
    auipc x18, 0             # 5C: x18 = 0x5C
    addi  x19, x0, 100       # 60: x19 = 100
    sw    x19, 8(x0)         # 64: mem[8] = 100  fwd dato del store (dist 1)
    lw    x20, 8(x0)         # 68: x20 = 100
    add   x21, x20, x20      # 6C: x21 = 200     load-use real (dir 8 ≠ dato 100)
end:
    jal   x0, end            # 70: loop infinito (fin)
