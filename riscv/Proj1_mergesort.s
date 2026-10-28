# Proj1_mergesort.s
# Author: Alex Anderson (Team E_08)
# Built from Proj_sort_template.s (Tyler Bibus).
# Top-down recursive merge sort (ascending, signed, stable).
# The sorted values are written back into the original array.

# Note: You MUST put the sorted array back in the SAME memory location as the original array.
#       During grading we will insert our own array and corresponding array_size for testing.
#       The max size will be 512 elements.
.data
    array_size: .word 12
    array: .word 65, 12, 10, 89, 11, 70, 67, 5, 9, 45, 90, 7
    # Scratch buffer for merging. Only the left half of a merge is copied
    # here, so 256 words covers the 512-element maximum. Keeping it small
    # matters: data memory is 1024 words and the stack shares it.
    MergeTemp: .space 1024
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
.globl sort
sort:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi t0, x0, 2
    blt  a1, t0, SortDone      # 0 or 1 element: already sorted
    addi a2, a1, -1             # hi = size - 1
    addi a1, x0, 0              # lo = 0
    jal  ra, Msort              # Msort(array, 0, size - 1)
SortDone:
    lw   ra, 0(sp)
    addi sp, sp, 4
    jalr x0, 0(ra)

# void Msort(int* a0 = array, int a1 = lo, int a2 = hi)
# Sorts array[lo..hi] (inclusive).
Msort:
    bge  a1, a2, MsortRet      # one element (or none): nothing to do
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a1, 8(sp)              # lo
    sw   a2, 4(sp)              # hi
    add  t0, a1, a2
    srai t0, t0, 1              # mid = (lo + hi) / 2
    sw   t0, 0(sp)              # mid

    addi a2, t0, 0
    jal  ra, Msort              # Msort(array, lo, mid)

    lw   a1, 0(sp)
    addi a1, a1, 1
    lw   a2, 4(sp)
    jal  ra, Msort              # Msort(array, mid + 1, hi)

    lw   a1, 8(sp)
    lw   a2, 0(sp)
    lw   a3, 4(sp)
    jal  ra, Merge              # Merge(array, lo, mid, hi)

    lw   ra, 12(sp)
    addi sp, sp, 16
MsortRet:
    jalr x0, 0(ra)

# void Merge(int* a0 = array, int a1 = lo, int a2 = mid, int a3 = hi)
# Copies the left run array[lo..mid] into MergeTemp, then merges it with
# the right run array[mid+1..hi] back into array[lo..hi]. The write index
# never passes the right-run read index, so nothing is overwritten early.
# Leaf function: only uses t registers.
Merge:
    la   t6, MergeTemp
    sub  a4, a2, a1             # a4 = last temp index = mid - lo

    addi t0, x0, 0              # copy left run into temp
    slli t3, a1, 2
    add  t3, a0, t3             # t3 = &array[lo]
MergeSave:
    blt  a4, t0, MergeStart
    slli t4, t0, 2
    add  t5, t3, t4
    lw   t5, 0(t5)
    add  t4, t6, t4
    sw   t5, 0(t4)              # temp[t0] = array[lo + t0]
    addi t0, t0, 1
    j    MergeSave

MergeStart:
    addi t0, x0, 0              # i = 0      (index into temp)
    addi t1, a2, 1              # j = mid + 1 (index into array)
    addi t2, a1, 0              # k = lo      (write index into array)
MergeLoop:
    blt  a4, t0, MergeDone     # left run used up: rest of right run is already in place
    blt  a3, t1, MergeLeft     # right run used up
    slli t3, t0, 2
    add  t3, t6, t3
    lw   t4, 0(t3)              # t4 = temp[i]
    slli t3, t1, 2
    add  t3, a0, t3
    lw   t5, 0(t3)              # t5 = array[j]
    slli t3, t2, 2
    add  t3, a0, t3             # t3 = &array[k]
    blt  t5, t4, TakeRight     # take left on ties (stable)
    sw   t4, 0(t3)              # array[k] = temp[i]
    addi t0, t0, 1
    j    MergeNext
TakeRight:
    sw   t5, 0(t3)              # array[k] = array[j]
    addi t1, t1, 1
MergeNext:
    addi t2, t2, 1
    j    MergeLoop

MergeLeft:                     # copy rest of temp[i..] to array[k..]
    blt  a4, t0, MergeDone
    slli t3, t0, 2
    add  t3, t6, t3
    lw   t4, 0(t3)
    slli t3, t2, 2
    add  t3, a0, t3
    sw   t4, 0(t3)
    addi t0, t0, 1
    addi t2, t2, 1
    j    MergeLeft

MergeDone:
    jalr x0, 0(ra)

# RARS treats wfi as a no-op and only stops at the end of the program,
# so the halt must be the last instruction in the file.
Exit:
    wfi
