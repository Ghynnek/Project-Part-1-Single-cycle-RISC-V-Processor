library IEEE;
use IEEE.std_logic_1164.all;

entity mux2_32 is
  port (
    d0 : in  std_logic_vector(31 downto 0);
    d1 : in  std_logic_vector(31 downto 0);
    s  : in  std_logic;
    y  : out std_logic_vector(31 downto 0)
  );
end entity;

architecture dataflow of mux2_32 is
begin
  y <= d1 when s = '1' else d0;
end architecture;
