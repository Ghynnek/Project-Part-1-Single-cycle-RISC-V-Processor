.data
.text
.globl main
main:
  # lui: put 0x10010000 in x5
  lui x5, 0x10010
  # addi: put positive and negative into x6 and x7
  addi x6, x0, 25
  addi x7, x0, -10
  # add and sub tests
  add x8, x6, x7
  sub x9, x6, x7
  # sw: Store Values to the Data memory at offset of zero and 4 
  sw x8, 0(x5)      # Mem[0x10010000] = 15
  sw x9, 4(x5)      # Mem[0x10010004] = 35
  # lw: load values back from data memory
  lw x10, 0(x5)
  lw x11, 4(x5)

  wfi
