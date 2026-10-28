# Proj1_extrasort.s
# Author: Alex Anderson (Team E_08)
# Built from Proj_sort_template.s (Tyler Bibus).
# Insertion sort (ascending, signed). Required extra algorithm for teams of 3
# (not Bubble Sort or Merge Sort). It sorts in place, so it needs no scratch
# memory and no recursion, which keeps it safe for the 512-element maximum.

# Note: You MUST put the sorted array back in the SAME memory location as the original array.
#       During grading we will insert our own array and corresponding array_size for testing.
#       The max size will be 512 elements.
.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
.text
.globl main

main:
    # Match the RARS reset value of sp; our register file resets sp to 0.
    lui sp, 0x7FFFF
    addi sp, sp, -4

    # Save return address
    addi sp, sp, -4
    sw ra, 0(sp)

    # Call sorting function
    la a0, array
    lw a1, array_size
    jal ra, sort

    # restore stack
    lw ra, 0(sp)
    addi sp, sp, 4

    # Exit program (the wfi is at the end of the file)
    j Exit

# void sort(int* array, int size);
# for (i = 1; i < size; i++) {
#     key = array[i];
#     j = i - 1;
#     while (j >= 0 && array[j] > key) { array[j+1] = array[j]; j--; }
#     array[j+1] = key;
# }
.globl sort
sort:
    addi t0, x0, 1              # i = 1
OuterLoop:
    bge  t0, a1, SortDone      # i >= size -> done
    slli t3, t0, 2
    add  t3, a0, t3
    lw   t2, 0(t3)              # key = array[i]
    addi t1, t0, -1             # j = i - 1
InnerLoop:
    blt  t1, x0, Insert         # j < 0 -> stop
    slli t3, t1, 2
    add  t3, a0, t3             # t3 = &array[j]
    lw   t4, 0(t3)              # t4 = array[j]
    bge  t2, t4, Insert         # array[j] <= key -> stop (keeps it stable)
    sw   t4, 4(t3)              # array[j+1] = array[j]
    addi t1, t1, -1             # j--
    j    InnerLoop
Insert:
    slli t3, t1, 2
    add  t3, a0, t3
    sw   t2, 4(t3)              # array[j+1] = key
    addi t0, t0, 1              # i++
    j    OuterLoop
SortDone:
    jalr x0, 0(ra)

# RARS treats wfi as a no-op and only stops at the end of the program,
# so the halt must be the last instruction in the file.
Exit:
    wfi
