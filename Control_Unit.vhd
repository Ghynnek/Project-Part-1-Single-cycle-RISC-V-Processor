library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
  port (
    opcode   : in  std_logic_vector(6 downto 0);
    funct3   : in  std_logic_vector(2 downto 0);
    funct7   : in  std_logic_vector(6 downto 0);
    RegWrite, ALUSrcB, ALUSrcA, MemWrite, MemRead : out std_logic;
    WBSel    : out std_logic_vector(1 downto 0);
    ImmSel   : out std_logic_vector(2 downto 0);
    ALUCtl   : out std_logic_vector(3 downto 0);
    Branch, Jump, JumpReg : out std_logic
  );
end entity;

architecture dataflow of control_unit is
  signal instr : std_logic_vector(16 downto 0);
  -- order: RW,B,A,MW,MR,WB(2),Imm(3),ALU(4),Br,J,JR = 17 bits
  signal ctrl  : std_logic_vector(16 downto 0);
begin
  instr <= funct7 & funct3 & opcode;

  with instr select?
    ctrl <=
      -- add
      "1" & "0" & "0" & "0" & "0" & "00" & "000" & "0000" & "0" & "0" & "0"
        when "0000000" & "000" & "0110011",
      -- sub
      "1" & "0" & "0" & "0" & "0" & "00" & "000" & "0001" & "0" & "0" & "0"
        when "0000000" & "000" & "0110011",  -- fix: funct7 = 0100000 for sub
      -- addi (funct7 don't care)
      "10000" & "00" & "000" & "0000" & "000"
        when "-------" & "000" & "0010011",
      -- ... one line per instruction ...
      (others => '0') when others;

  RegWrite <= ctrl(16);  ALUSrcB <= ctrl(15);  ALUSrcA <= ctrl(14);
  MemWrite <= ctrl(13);  MemRead <= ctrl(12);
  WBSel    <= ctrl(11 downto 10);
  ImmSel   <= ctrl(9 downto 7);
  ALUCtl   <= ctrl(6 downto 3);
  Branch   <= ctrl(2);   Jump <= ctrl(1);   JumpReg <= ctrl(0);
end architecture;