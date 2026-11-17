    .text
    .globl _start
_start:
    # ---------- valores base ----------
    addi  x1, x0, -1         # 00: x1 = FFFFFFFF (-1)
    addi  x2, x0, 1          # 04: x2 = 1
    addi  x3, x0, 240        # 08: x3 = F0
    addi  x4, x0, 255        # 0C: x4 = FF

    # ---------- R-type ----------
    and   x5, x3, x4         # 10: x5 = F0
    xor   x6, x3, x4         # 14: x6 = 0F
    slt   x7, x1, x2         # 18: x7 = 1        (-1 < 1 con signo)
    sltu  x8, x1, x2         # 1C: x8 = 0        (FFFFFFFF < 1 sin signo: no)
    sll   x9, x2, x4         # 20: x9 = 80000000 (shamt = x4[4:0] = 31)
    srl   x10, x1, x4        # 24: x10 = 1
    sra   x11, x1, x4        # 28: x11 = FFFFFFFF

    # ---------- I-type ----------
    andi  x12, x4, 15        # 2C: x12 = 0F
    xori  x13, x3, -1        # 30: x13 = FFFFFF0F (NOT de F0)
    ori   x14, x3, 15        # 34: x14 = FF
    slti  x15, x1, 0         # 38: x15 = 1       (-1 < 0)
    sltiu x16, x2, -1        # 3C: x16 = 1       (1 < FFFFFFFF sin signo)
    slli  x17, x2, 4         # 40: x17 = 10
    srli  x18, x1, 28        # 44: x18 = F
    srai  x19, x9, 4         # 48: x19 = F8000000 (extiende el signo)

    # ---------- loads / stores ----------
    addi  x20, x0, 64        # 4C: x20 = 40 (base = palabra 16)
    lui   x21, 0x81828       # 50: x21 = 81828000
    addi  x21, x21, 0x384    # 54: x21 = 81828384
    sw    x21, 0(x20)        # 58: mem[16] = 81828384
    lb    x22, 0(x20)        # 5C: x22 = FFFFFF84 (byte 0 = 84, con signo)
    lbu   x23, 0(x20)        # 60: x23 = 84
    lh    x24, 2(x20)        # 64: x24 = FFFF8182 (half alto = 8182, con signo)
    lhu   x25, 2(x20)        # 68: x25 = 8182
    lb    x26, 1(x20)        # 6C: x26 = FFFFFF83 (byte 1)
    sb    x2, 3(x20)         # 70: mem[16] = 01828384 (byte 3 = 01)
    sh    x21, 6(x20)        # 74: mem[17] = 83840000 (half alto = 8384)
    lw    x27, 0(x20)        # 78: x27 = 01828384
    lw    x28, 4(x20)        # 7C: x28 = 83840000

    # ---------- branches ----------
    # tomado esperado:    si falla, se ejecuta el addi x31 (error)
    # no tomado esperado: si funciona, se ejecuta el addi x29 (cuenta OK)
    blt   x1, x2, t1         # 80: -1 < 1         → tomado
    addi  x31, x31, 1        # 84: error
t1:
    bltu  x1, x2, n1         # 88: FFFFFFFF < 1   → no tomado
    addi  x29, x29, 1        # 8C: OK
n1:
    bge   x2, x1, t2         # 90: 1 >= -1        → tomado
    addi  x31, x31, 1        # 94: error
t2:
    bgeu  x2, x1, n2         # 98: 1 >= FFFFFFFF  → no tomado
    addi  x29, x29, 1        # 9C: OK
n2:
    bge   x1, x1, t3         # A0: iguales        → tomado (caso borde)
    addi  x31, x31, 1        # A4: error
t3:
    bltu  x2, x1, t4         # A8: 1 < FFFFFFFF   → tomado
    addi  x31, x31, 1        # AC: error
t4:
end:
    jal   x0, end            # B0: loop infinito
