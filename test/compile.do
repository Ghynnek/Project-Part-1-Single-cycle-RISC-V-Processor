# compile.do
# Compiles the design files and all testbenches.
# Run from the project folder (the one with src/ and test/ in it):
#   do test/compile.do

vlib work

vcom -2008 src/Adder_Files/andg2.vhd
vcom -2008 src/Adder_Files/org2.vhd
vcom -2008 src/Adder_Files/xorg2.vhd
vcom -2008 src/Adder_Files/FullAdder.vhd
vcom -2008 src/Adder_Files/Adder_n.vhd
vcom -2008 src/dffg.vhd
vcom -2008 src/dffg_set.vhd
vcom -2008 src/mux2_32.vhd
vcom -2008 src/barrel_shifter.vhd
vcom -2008 src/alu.vhd
vcom -2008 src/imm_gen.vhd
vcom -2008 src/fetch_logic.vhd
vcom -2008 src/Control_Unit.vhd

vcom -2008 test/tb_control_unit.vhd
vcom -2008 test/tb_fetch_logic.vhd
vcom -2008 test/tb_barrel_shifter.vhd
vcom -2008 test/tb_imm_gen.vhd
vcom -2008 test/tb_alu.vhd
vcom -2008 test/tb_mux2_32.vhd
