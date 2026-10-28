library IEEE;
use IEEE.std_logic_1164.all;

entity writeback_select is
  port (
    alu_result : in  std_logic_vector(31 downto 0);
    mem_data   : in  std_logic_vector(31 downto 0);
    imm        : in  std_logic_vector(31 downto 0);
    funct3     : in  std_logic_vector(2 downto 0);
    MemToReg   : in  std_logic;
    LUI        : in  std_logic;
    pc_plus4   : in  std_logic_vector(31 downto 0);
    Jump       : in  std_logic;
    JumpReg    : in  std_logic;
    wb_data    : out std_logic_vector(31 downto 0)
  );
end entity;

architecture dataflow of writeback_select is
  signal byte_offset : std_logic_vector(1 downto 0);
  signal sel_byte    : std_logic_vector(7 downto 0);
  signal sel_half    : std_logic_vector(15 downto 0);
  signal lb_ext      : std_logic_vector(31 downto 0);
  signal lbu_ext     : std_logic_vector(31 downto 0);
  signal lh_ext      : std_logic_vector(31 downto 0);
  signal lhu_ext     : std_logic_vector(31 downto 0);
  signal load_data   : std_logic_vector(31 downto 0);
  signal alu_or_mem  : std_logic_vector(31 downto 0);
  signal lui_out     : std_logic_vector(31 downto 0);
begin

  byte_offset <= alu_result(1 downto 0);

  -- Select byte based on byte_offset ("00", "01", "10", "11")
  with byte_offset select
    sel_byte <= mem_data(7 downto 0)   when "00",
                mem_data(15 downto 8)  when "01",
                mem_data(23 downto 16) when "10",
                mem_data(31 downto 24) when others;

  -- Select halfword based on byte_offset(1) ('0' = lower 16 bits, '1' = upper 16 bits)
  sel_half <= mem_data(15 downto 0) when byte_offset(1) = '0' else
              mem_data(31 downto 16);

  -- Sign-extend and Zero-extend byte/halfword
  lb_ext  <= (31 downto 8  => sel_byte(7))  & sel_byte;
  lbu_ext <= x"000000"                      & sel_byte;
  lh_ext  <= (31 downto 16 => sel_half(15)) & sel_half;
  lhu_ext <= x"0000"                        & sel_half;

  -- Choose load format based on funct3:
  -- 000 = lb, 001 = lh, 010 = lw, 100 = lbu, 101 = lhu
  with funct3 select
    load_data <= lb_ext   when "000",
                 lh_ext   when "001",
                 mem_data when "010",
                 lbu_ext  when "100",
                 lhu_ext  when "101",
                 mem_data when others;

  alu_or_mem <= load_data when MemToReg = '1' else alu_result;
  lui_out    <= imm       when LUI = '1'      else alu_or_mem;
  wb_data    <= pc_plus4  when (Jump = '1' or JumpReg = '1') else lui_out;

end architecture;
