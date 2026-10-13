library IEEE;
use IEEE.std_logic_1164.all;

entity reg_file is
  port(
    i_clk    : in  std_logic;
    i_rst    : in  std_logic;
    i_we     : in  std_logic;                       -- RegWrite
    i_rd     : in  std_logic_vector(4 downto 0);    -- Write destination register
    i_wdata  : in  std_logic_vector(31 downto 0);   -- Write data
    i_rs1    : in  std_logic_vector(4 downto 0);    -- Read register 1 source
    i_rs2    : in  std_logic_vector(4 downto 0);    -- Read register 2 source
    o_rdata1 : out std_logic_vector(31 downto 0);   -- Read data 1 output
    o_rdata2 : out std_logic_vector(31 downto 0)    -- Read data 2 output
  );
end reg_file;

architecture structural of reg_file is

  component decoder is
    port(
      i_WE : in  std_logic;
      i_A  : in  std_logic_vector(4 downto 0);
      o_Y  : out std_logic_vector(31 downto 0)
    );
  end component;

  component reg_n is
    generic(N : integer := 32);
    port(
      i_CLK : in  std_logic;
      i_RST : in  std_logic;
      i_WE  : in  std_logic;
      i_D   : in  std_logic_vector(N-1 downto 0);
      o_Q   : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component mux32to1 is
    port(
      i_S : in  std_logic_vector(4 downto 0);
      i_D : in  std_logic_vector(1023 downto 0);
      o_Y : out std_logic_vector(31 downto 0)
    );
  end component;

  signal s_we_lines  : std_logic_vector(31 downto 0);
  signal s_bus_1024  : std_logic_vector(1023 downto 0);

  -- Type to hold outputs of registers 0 to 31
  type reg_out_array is array(0 to 31) of std_logic_vector(31 downto 0);
  signal s_reg_out   : reg_out_array;

begin

  DECODER: decoder_5to32
    port map(
      i_WE => i_we,
      i_A  => i_rd,
      o_Y  => s_we_lines
    );


  s_reg_out(0) <= (others => '0');


  G_REGISTERS: for i in 1 to 31 generate
    REG_I: reg_n
      generic map(N => 32)
      port map(
        i_CLK => i_clk,
        i_RST => i_rst,
        i_WE  => s_we_lines(i),
        i_D   => i_wdata,
        o_Q   => s_reg_out(i)
      );
  end generate G_REGISTERS;


  G_PACK_BUS: for i in 0 to 31 generate
    s_bus_1024(i*32 + 31 downto i*32) <= s_reg_out(i);
  end generate G_PACK_BUS;

  MUX_READ1: mux32to1
    port map(
      i_S => i_rs1,
      i_D => s_bus_1024,
      o_Y => o_rdata1
    );

  MUX_READ2: mux32to1
    port map(
      i_S => i_rs2,
      i_D => s_bus_1024,
      o_Y => o_rdata2
    );

end structural;