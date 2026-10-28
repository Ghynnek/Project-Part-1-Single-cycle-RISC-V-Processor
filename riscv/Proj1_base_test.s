# Proj1_base_test.s
# Author: Alex Anderson (Team E_08)
# Uses every required arithmetic/logical instruction at least once:
#   add, addi, and, andi, lui, xor, xori, or, ori, slt, slti, sltiu, sltu,
#   sll, srl, sra, slli, srli, srai, sub, auipc
# followed by the memory instructions:
#   sw, lw, lb, lh, lbu, lhu, sb, sh
# Instructions run back-to-back, one per cycle, and most results are read
# by the very next instruction, so a wrong register write shows up quickly.
# Expected results are in the comments next to each instruction.
# Sections are ordered from basic to more advanced so the first mismatch
# reported by the toolflow points at the part of the datapath that broke.

.data
BaseWord0: .word 0x12345678        # bytes (LE): 78 56 34 12
BaseWord1: .word 0xFFFF8080        # bytes (LE): 80 80 FF FF
BaseStore: .word 0                 # sw target
BaseSub:   .word 0                 # sb / sh target

.text
.globl main
main:
    # 1. Immediate arithmetic / lui
    lui   s0, 0x12345               # s0 = 0x12345000
    addi  s0, s0, 0x678             # s0 = 0x12345678 (uses s0 right away)
    addi  t0, x0, -1                # t0 = 0xFFFFFFFF
    addi  t1, x0, 7                 # t1 = 7
    addi  t2, x0, 2047              # t2 = 0x000007FF (largest I-imm)
    addi  t3, x0, -2048             # t3 = 0xFFFFF800 (smallest I-imm)
    addi  t4, x0, 1024              # t4 = 0x400 (imm bit 10 sits where funct7 bit 5 would be)
    lui   t5, 0xFFFFF               # t5 = 0xFFFFF000 (lui with top bit set)

    # 2. Immediate logical
    andi  a0, s0, 0x0FF             # a0 = 0x00000078
    andi  a1, s0, -16               # a1 = 0x12345670 (sign-extended mask)
    ori   a2, a0, 0x700             # a2 = 0x00000778
    ori   a3, x0, -1                # a3 = 0xFFFFFFFF
    xori  a4, a2, -1                # a4 = 0xFFFFF887 (bitwise NOT)
    xori  a5, s0, 0x0F0             # a5 = 0x12345688

    # 3. Immediate compares (signed vs unsigned)
    slti  a6, t3, 0                 # a6 = 1  (-2048 < 0)
    slti  a7, t2, -1                # a7 = 0  (2047 < -1 is false)
    slti  s1, t1, 7                 # s1 = 0  (equal is not less)
    sltiu s2, t1, -1                # s2 = 1  (7 < 0xFFFFFFFF unsigned)
    sltiu s3, t0, 5                 # s3 = 0  (0xFFFFFFFF < 5 is false)
    sltiu s4, x0, 1                 # s4 = 1  (seqz idiom)

    # 4. Immediate shifts
    slli  s5, t1, 4                 # s5 = 0x00000070
    slli  s6, t0, 31                # s6 = 0x80000000
    srli  s7, s6, 31                # s7 = 0x00000001 (zero fill)
    srai  s8, s6, 31                # s8 = 0xFFFFFFFF (sign fill)
    srai  s9, s0, 4                 # s9 = 0x01234567 (positive -> zero fill)
    srli  s10, t0, 0                # s10 = 0xFFFFFFFF (shift by 0)
    srai  s11, t5, 12               # s11 = 0xFFFFFFFF
    srli  s11, t5, 12               # s11 = 0x000FFFFF (same input, logical)
    slli  s11, s11, 1               # s11 = 0x001FFFFE

    # 5. Register-register arithmetic and logic
    add   a0, s0, t1                # a0 = 0x1234567F
    add   a1, t0, t1                # a1 = 6           (-1 + 7, carry out ignored)
    lui   a2, 0x80000               # a2 = 0x80000000
    addi  a2, a2, -1                # a2 = 0x7FFFFFFF
    add   a3, a2, s7                # a3 = 0x80000000  (signed overflow wraps, no trap)
    sub   a4, t1, s0                # a4 = 0xEDCBA98F  (7 - 0x12345678)
    sub   a5, x0, t1                # a5 = 0xFFFFFFF9  (-7)
    sub   a6, s0, s0                # a6 = 0
    and   a7, s0, a4                # a7 = 0x00000008
    or    s1, s5, a0                # s1 = 0x1234567F
    or    s2, a3, t1                # s2 = 0x80000007
    xor   s3, s0, t0                # s3 = 0xEDCBA987
    xor   s4, s3, s3                # s4 = 0

    # 6. Register-register compares
    slt   s5, t3, t1                # s5 = 1  (-2048 < 7)
    slt   s6, t1, t3                # s6 = 0
    slt   s7, a3, a2                # s7 = 1  (0x80000000 is most negative)
    sltu  s8, t1, t3                # s8 = 1  (7 < 0xFFFFF800 unsigned)
    sltu  s9, t3, t1                # s9 = 0
    sltu  s10, a2, a3               # s10 = 1 (0x7FFFFFFF < 0x80000000 unsigned)
    slt   s11, t1, t1               # s11 = 0 (equal)

    # 7. Register-register shifts (only rs2[4:0] is used)
    addi  t2, x0, 33                # t2 = 33 -> shift amount 1
    sll   t4, s0, t1                # t4 = 0x1A2B3C00  (<< 7)
    sll   t4, s0, t2                # t4 = 0x2468ACF0  (<< 1, upper bits of rs2 ignored)
    srl   t5, a4, t1                # t5 = 0x01DB9753  (0xEDCBA98F >>> 7)
    sra   t6, a4, t1                # t6 = 0xFFDB9753  (0xEDCBA98F >> 7)
    sra   t6, s0, t1                # t6 = 0x002468AC  (positive)
    addi  t2, x0, 31
    sra   a0, a3, t2                # a0 = 0xFFFFFFFF
    srl   a1, a3, t2                # a1 = 0x00000001
    sll   a1, a1, t2                # a1 = 0x80000000

    # 8. Word loads and stores
    #    0x10010000 is the start of the RARS .data segment.
    lui   s0, 0x10010               # s0 = &base_word0
    lw    t0, 0(s0)                 # t0 = 0x12345678
    lw    t1, 4(s0)                 # t1 = 0xFFFF8080
    add   t2, t0, t1                # t2 = 0x1233D6F8 (load result used next)
    sw    t2, 8(s0)                 # BaseStore = 0x1233D6F8
    lw    t3, 8(s0)                 # t3 = 0x1233D6F8 (read back what was stored)
    addi  s1, s0, 12                # s1 = &BaseSub
    sw    t1, -4(s1)                # BaseStore = 0xFFFF8080 (negative offset)
    lw    t4, -4(s1)                # t4 = 0xFFFF8080

    # 9. Sub-word loads (every byte / halfword lane)
    lb    a0, 0(s0)                 # a0 = 0x00000078
    lb    a1, 1(s0)                 # a1 = 0x00000056
    lb    a2, 2(s0)                 # a2 = 0x00000034
    lb    a3, 3(s0)                 # a3 = 0x00000012
    lb    a4, 4(s0)                 # a4 = 0xFFFFFF80 (sign extended)
    lbu   a5, 4(s0)                 # a5 = 0x00000080 (zero extended)
    lb    a6, 7(s0)                 # a6 = 0xFFFFFFFF
    lbu   a7, 7(s0)                 # a7 = 0x000000FF
    lh    s2, 0(s0)                 # s2 = 0x00005678
    lh    s3, 2(s0)                 # s3 = 0x00001234
    lh    s4, 4(s0)                 # s4 = 0xFFFF8080
    lhu   s5, 4(s0)                 # s5 = 0x00008080
    lh    s6, 6(s0)                 # s6 = 0xFFFFFFFF
    lhu   s7, 6(s0)                 # s7 = 0x0000FFFF

    # 10. Sub-word stores
    sw    x0, 0(s1)                 # BaseSub = 0x00000000
    addi  t0, x0, 0x0AB
    sb    t0, 0(s1)                 # BaseSub = 0x000000AB
    addi  t0, x0, 0x0CD
    sb    t0, 3(s1)                 # BaseSub = 0xCD0000AB
    lui   t0, 0x12345
    addi  t0, t0, -273              # t0 = 0x12344EEF
    lw    s8, 0(s1)                 # s8 = 0xCD0000AB (only bytes 0 and 3 changed)
    sh    t0, 2(s1)                 # BaseSub upper half = 0x4EEF
    lw    s9, 0(s1)                 # s9 = 0x4EEF00AB
    sh    t0, 0(s1)                 # BaseSub lower half = 0x4EEF
    lw    s9, 0(s1)                 # s9 = 0x4EEF4EEF

    # 11. auipc (PC-relative)
    auipc s10, 0                    # s10 = address of this instruction
    auipc s11, 1                    # s11 = (address of this instruction) + 0x1000
    sub   s11, s11, s10             # s11 = 0x1004

    wfi
