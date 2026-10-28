# Alex – Test Log (Team E_08, Project Part 1)

My contract items: **Test programs** (design), **Control logic** (test),
**Barrel shifter** (test), **High-level integration** (test), **Synthesis** (lead).

## Files I added

| File | Purpose |
|---|---|
| `riscv/Proj1_base_test.s` | Every arithmetic/logical instruction plus lui, auipc, and all loads/stores. Expected value commented on each line. |
| `riscv/Proj1_cf_test.s` | beq/bne/blt/bge/bltu/bgeu taken + not taken (incl. equal and signed vs. unsigned), backward branch, jal, jalr with offset, recursive call 8 frames deep. |
| `riscv/Proj1_mergesort.s` | Recursive merge sort on the template. Temp buffer holds only the left half (256 words max). |
| `riscv/Proj1_extrasort.s` | Insertion sort (required third algorithm for a 3-person team). |
| `test/tb_control_unit.vhd` | Self-checking: 46 instruction encodings vs. the expected control table, including the new `AUIPC` output. (Renamed from `TbControlUnit.vhd`.) |
| `test/tb_barrel_shifter.vhd` | Self-checking: hand cases + every shamt 0–31 × 9 patterns × SLL/SRL/SRA (≈900 checks). (Renamed from `TbBarrelShifter.vhd`.) |
| `test/tb_alu.vhd` | Self-checking: 31 hand cases (overflow, borrow, slt vs. sltu, equal operands, shamt = b(4:0), unused code → add) + all 10 ops × 11 × 11 edge-case operand pairs. Zero checked on every case (1241 checks). |
| `test/tb_imm_gen.vhd` | Self-checking: 9 real RARS encodings + edge-case immediates for I/S/B/U/J, each encoded with all other bits 0 and all 1 so leaking fields are caught (105 checks). |
| `test/tb_fetch_logic.vhd` | Self-checking, clocked: reset to 0x00400000 (start and mid-run), PC+4, all 6 branches taken / not taken / backward, Branch = 0 ignores conditions, jal fwd/back, jalr bit-0 clear, jalr over jal, pc_plus4 every cycle. |

Every test program sets `sp = 0x7FFFEFFC` first. That's RARS's reset value, and our
register file resets `sp` to 0, so without this every `sp` write mismatches RARS.

## ⚠ Before running anything: `src/` is out of date

The fixes for auipc, sub-word loads and sb/sh are in the copies at the **folder root**.
The files in **`src/`** are still the old versions, and the toolflow only compiles `src/`.

| File | Root copy (newest) | `src/` copy |
|---|---|---|
| `Control_Unit.vhd` | has `AUIPC` output | no `AUIPC` |
| `writeback_select.vhd` | lb/lh/lbu/lhu extraction (`funct3` port) | full word only |
| `TopLevel/RISCV_Processor.vhd` | ALU-A mux (PC for auipc), sb/sh merge | neither |

Whoever owns these files (integration: Graham) needs to copy the root versions into `src/`.
`TbControlUnit.vhd` uses the newest port list, so it compiles against the root
`Control_Unit.vhd` but **not** against the old `src/` copy (`AUIPC` port missing).

## Review of the new fixes (root copies)

- **auipc:** `U_ALUSRCA_MUX` selects `s_PC` when `AUIPC = 1`, ImmSrc = U, ALUControl = add. Gives PC + imm. ✔
- **Loads:** byte/halfword chosen by `alu_result(1:0)`, then sign/zero-extended by funct3. ✔
- **Stores:** sb/sh merge the new byte/halfword into the current word (`s_DMemOut`) and write it back.
  This works because `mem.vhd` reads asynchronously (`q <= ram(addr)`), so the old word
  is available in the same cycle. ✔
- After these fixes are in `src/`, all four programs should pass the toolflow.
  `Proj1_base_test.s` sections 9–11 cover exactly these three fixes.

## How to run

Unit testbenches (QuestaSim, from the project folder, using the newest design files):

```
vcom -2008 src/Adder_Files/*.vhd src/dffg.vhd src/dffg_set.vhd src/barrel_shifter.vhd src/alu.vhd src/imm_gen.vhd src/fetch_logic.vhd src/Control_Unit.vhd
vcom -2008 test/tb_barrel_shifter.vhd test/tb_control_unit.vhd test/tb_alu.vhd test/tb_imm_gen.vhd test/tb_fetch_logic.vhd
vsim -c work.tb_barrel_shifter -do "run -all; quit"
vsim -c work.tb_control_unit -do "run -all; quit"
vsim -c work.tb_alu -do "run -all; quit"
vsim -c work.tb_imm_gen -do "run -all; quit"
vsim -c work.tb_fetch_logic -do "run -all; quit"
```

For report waveforms, drop `-c`, `add wave *`, then `run -all`. Each testbench has a
name signal (`OpName`, `StepName`, `InstName`) and an `Expected` signal next to the output.

Each testbench ends with `ALL n TESTS PASSED` or reports every failing case.

Processor tests (toolflow, after `src/` is updated):

```
./3810_tf.sh test riscv/Proj1_base_test.s
./3810_tf.sh test riscv/Proj1_cf_test.s
./3810_tf.sh test riscv/Proj1_mergesort.s
./3810_tf.sh test riscv/Proj1_extrasort.s
```

## Pre-check of the programs (done without hardware)

I checked all four programs with a small RV32I reference simulator before using them on the processor:
- Every `# reg = value` comment in `Proj1_base_test.s` matches.
- `Proj1_cf_test.s` reaches `done` with s0 = 20 and never reaches `fail`.
- Both sorts were correct on 39 arrays: empty, 1 element, duplicates, INT_MIN/INT_MAX, sorted/reversed 512, and random sizes up to 512.
  None of them made data and stack overlap in the 1024-word data memory.
- Worst-case dynamic instruction count: merge sort about 100k, insertion sort about 1.05M (reversed 512-element array).

**RARS (RARS_CPRE3810.jar, command line):** all four programs assemble and finish cleanly.
- Base test: all 31 final register values and memory words match the expected comments (98 instructions).
- CF test: s0 = 20, s11 = 0 (never reached `fail`), a0 = 28, sp restored (155 instructions).
- Both sorts: default array sorts to 5, 7, 9, 10, 11, 12, 45, 65, 67, 70, 89, 90. They also pass
  empty, 1, 2, duplicates, INT_MIN/INT_MAX, reversed 100, random 200 and random 512 (insertion sort: 300).
- RARS treats `wfi` as a no-op and only stops when it runs off the end of the program. Each program
  therefore ends with its single `wfi` as the last instruction in the file. The sorts' `main` does
  `j exit` instead of the template's inline `wfi`; otherwise RARS would keep running into `sort`.

## Status

- [x] Test programs written and pre-checked
- [x] Control unit testbench written (updated for `AUIPC`)
- [x] Barrel shifter testbench written
- [x] Integration review of the new auipc / load / store fixes
- [x] Root design files copied into `src/` (checked 10/28/2026: root and `src/` copies are identical)
- [x] `tb_alu.vhd`, `tb_imm_gen.vhd`, `tb_fetch_logic.vhd` written (10/28/2026), not yet run in QuestaSim
- [x] All four programs re-run in RARS 10/28/2026: base 98 instr, cf s0 = 20 / s11 = 0, both sorts give 5 7 9 10 11 12 45 65 67 70 89 90
- [x] Run testbenches in QuestaSim (Questa Sim-64 2026.2), capture waveforms for the report:
      `TbBarrelShifter: ALL 913 TESTS PASSED`, `TbControlUnit: ALL 46 TESTS PASSED` (10/26/2026)
- [ ] Run the 4 programs through the toolflow
- [ ] Synthesis: `./3810_tf.sh synth`. Record Fmax and the critical path for the report.

## Synthesis checklist (needs the toolflow + Quartus: Coover 2050 or VDI)

1. Only after all 4 programs pass `./3810_tf.sh test`.
2. Put the `src/` folder from this branch into the toolflow project's `proj/src/` (no `.bak` files needed).
3. Run `./3810_tf.sh synth` in the background (50+ min on Coover, 2.5+ h on VDI).
4. From the timing report record: **Fmax** (MHz) and the **worst-case path** (from-node → to-node).
5. Expected critical path for this design: PC register → instruction memory → register file read →
   ALU (32-bit compare/add) → data memory (lw) → writeback mux → register file write.
   Draw it on the top-level schematic.
6. To improve Fmax, look at: the ALU adder/comparators (`alu.vhd` uses numeric_std `+`, `-`, `<`),
   the ripple-carry `Adder_N` in fetch (PC + imm), and the memory read path.
