# Proj1_cf_test.s
# Author: Alex Anderson (Team E_08)
# Uses every required control-flow instruction:
#   beq, bne, blt, bge, bltu, bgeu, jal, jalr
# Each conditional branch is checked both taken and not taken, including
# the equal case and signed vs unsigned operands. A recursive function
# then builds a call chain 8 activation records deep (requirement: >= 5).
# s0 counts every check that went the right way. If the processor takes a
# wrong path it jumps to "Fail", which writes 0xFFFFFFFF into s11 - a
# register write RARS never makes, so the toolflow flags it immediately.

.data
.text
.globl main
main:
    # Match the RARS reset value of sp; our register file resets sp to 0.
    lui   sp, 0x7FFFF
    addi  sp, sp, -4                # sp = 0x7FFFEFFC

    addi  s0, x0, 0                 # pass counter
    addi  t0, x0, -5                # t0 = 0xFFFFFFFB
    addi  t1, x0, 3
    addi  t2, x0, 3

    # beq
    beq   t1, t2, BeqTaken         # 3 == 3 -> taken
    j     Fail
BeqTaken:
    addi  s0, s0, 1                 # s0 = 1
    beq   t0, t1, Fail              # -5 == 3 -> not taken
    addi  s0, s0, 1                 # s0 = 2

    # bne
    bne   t0, t1, BneTaken         # -5 != 3 -> taken
    j     Fail
BneTaken:
    addi  s0, s0, 1                 # s0 = 3
    bne   t1, t2, Fail              # 3 != 3 -> not taken
    addi  s0, s0, 1                 # s0 = 4

    # blt (signed)
    blt   t0, t1, BltTaken         # -5 < 3 -> taken
    j     Fail
BltTaken:
    addi  s0, s0, 1                 # s0 = 5
    blt   t1, t0, Fail              # 3 < -5 -> not taken
    blt   t1, t2, Fail              # 3 < 3 -> not taken (equal)
    addi  s0, s0, 1                 # s0 = 6

    # bge (signed)
    bge   t1, t0, BgeTaken         # 3 >= -5 -> taken
    j     Fail
BgeTaken:
    addi  s0, s0, 1                 # s0 = 7
    bge   t1, t2, BgeEq            # 3 >= 3 -> taken (equal)
    j     Fail
BgeEq:
    addi  s0, s0, 1                 # s0 = 8
    bge   t0, t1, Fail              # -5 >= 3 -> not taken
    addi  s0, s0, 1                 # s0 = 9

    # bltu (unsigned)
    bltu  t1, t0, BltuTaken        # 3 < 0xFFFFFFFB -> taken (opposite of blt)
    j     Fail
BltuTaken:
    addi  s0, s0, 1                 # s0 = 10
    bltu  t0, t1, Fail              # 0xFFFFFFFB < 3 -> not taken
    bltu  t1, t2, Fail              # 3 < 3 -> not taken (equal)
    addi  s0, s0, 1                 # s0 = 11

    # bgeu (unsigned)
    bgeu  t0, t1, BgeuTaken        # 0xFFFFFFFB >= 3 -> taken (opposite of bge)
    j     Fail
BgeuTaken:
    addi  s0, s0, 1                 # s0 = 12
    bgeu  t1, t2, BgeuEq           # 3 >= 3 -> taken (equal)
    j     Fail
BgeuEq:
    addi  s0, s0, 1                 # s0 = 13
    bgeu  t1, t0, Fail              # 3 >= 0xFFFFFFFB -> not taken
    addi  s0, s0, 1                 # s0 = 14

    # backward branch (loop)
    addi  t3, x0, 4                 # loop 4 times
    addi  t4, x0, 0
Loop:
    addi  t4, t4, 2                 # t4 = 2, 4, 6, 8
    addi  t3, t3, -1
    bne   t3, x0, Loop              # backward branch, taken 3 times
    addi  s0, s0, 1                 # s0 = 15

    # jal / jalr
    jal   t5, JalTarget            # forward jal, link into t5 (not ra)
    j     Fail                      # JalTarget returns past this line
JalTarget:
    addi  s0, s0, 1                 # s0 = 16
    la    t6, JalrBase             # t6 = &JalrBase
    jalr  ra, 8(t6)                 # jump to JalrBase + 8 = JalrFunc
    addi  s0, s0, 1                 # s0 = 18 (after JalrFunc returns)
    j     CallTest

JalrBase:
    j     Fail                      # skipped by the +8 offset
    j     Fail
JalrFunc:
    addi  s0, s0, 1                 # s0 = 17
    jalr  x0, 0(ra)                 # return (jr ra)

    # call depth
CallTest:
    addi  a0, x0, 7
    jal   ra, Rsum                  # a0 = 7+6+5+4+3+2+1+0 = 28, 8 frames deep
    addi  t0, x0, 28
    bne   a0, t0, Fail
    addi  s0, s0, 1                 # s0 = 19

    # Stack must be back where it started.
    lui   t1, 0x7FFFF
    addi  t1, t1, -4
    bne   sp, t1, Fail
    addi  s0, s0, 1                 # s0 = 20
    j     Done

Fail:
    addi  s11, x0, -1               # never reached on a correct processor
    j     Done

# int Rsum(int n): returns n + (n-1) + ... + 0 recursively.
# Each call pushes ra and n, so Rsum(7) has 8 activation records on the stack.
Rsum:
    addi  sp, sp, -8
    sw    ra, 4(sp)
    sw    a0, 0(sp)
    beq   a0, x0, RsumBase         # Rsum(0) = 0
    addi  a0, a0, -1
    jal   ra, Rsum                  # a0 = Rsum(n - 1)
    lw    t0, 0(sp)                 # t0 = n
    add   a0, a0, t0
RsumBase:
    lw    ra, 4(sp)
    addi  sp, sp, 8
    jalr  x0, 0(ra)

# RARS treats wfi as a no-op and only stops at the end of the program,
# so the halt must be the last instruction in the file.
Done:
    wfi
