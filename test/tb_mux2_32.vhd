library IEEE;
use IEEE.std_logic_1164.all;

entity tb_mux2_32 is
end tb_mux2_32;

architecture behavior of tb_mux2_32 is
  signal s_d0 : std_logic_vector(31 downto 0) := x"AAAAAAAA";
  signal s_d1 : std_logic_vector(31 downto 0) := x"55555555";
  signal s_s  : std_logic := '0';
  signal s_y  : std_logic_vector(31 downto 0);
begin
  DUT: entity work.mux2_32
    port map(
      d0 => s_d0,
      d1 => s_d1,
      s  => s_s,
      y  => s_y
    );

  process
  begin
    s_s <= '0';
    wait for 10 ns;
    s_s <= '1';
    wait for 10 ns;
    wait;
  end process;
end behavior;
