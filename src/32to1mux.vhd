library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mux32to1 is
  port(
    i_S : in  std_logic_vector(4 downto 0);
    i_D : in  std_logic_vector(1023 downto 0); -- 32 words * 32 bits
    o_Y : out std_logic_vector(31 downto 0)
  );
end mux32to1;

architecture dataflow of mux32to1 is

  type bus_array is array(0 to 31) of std_logic_vector(31 downto 0);
  signal s_words : bus_array;

begin


  G_UNPACK: for i in 0 to 31 generate
    s_words(i) <= i_D(i*32 + 31 downto i*32);
  end generate G_UNPACK;

  o_Y <= s_words(to_integer(unsigned(i_S)));

end dataflow;
