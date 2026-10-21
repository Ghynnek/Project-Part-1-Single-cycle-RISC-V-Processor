library IEEE;
use IEEE.std_logic_1164.all;

entity writeback_select is
  port (
    alu_result : in  std_logic_vector(31 downto 0);
    mem_data   : in  std_logic_vector(31 downto 0);
    imm        : in  std_logic_vector(31 downto 0);
    MemToReg   : in  std_logic;
    LUI        : in  std_logic;
    pc_plus4   : in  std_logic_vector(31 downto 0);
    Jump       : in  std_logic;
    JumpReg    : in  std_logic;
    wb_data    : out std_logic_vector(31 downto 0)
  );
end entity;

architecture dataflow of writeback_select is
  signal alu_or_mem : std_logic_vector(31 downto 0);
  signal lui_out    : std_logic_vector(31 downto 0);
begin

  alu_or_mem <= mem_data when MemToReg = '1' else alu_result;
   lui_out <= imm when LUI = '1' else alu_or_mem;
    wb_data <= pc_plus4 when (Jump = '1' or JumpReg = '1') else lui_out;

end architecture;
