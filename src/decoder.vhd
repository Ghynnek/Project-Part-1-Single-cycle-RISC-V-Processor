-- decoder.vhd

library IEEE;
use IEEE.std_logic_1164.all;

entity decoder is
	port(i_WE : in std_logic;
	     i_A : in std_logic_vector(4 downto 0); -- 5 bit reg select rd
	     o_Y : out std_logic_vector(31 downto 0));
end decoder;

architecture dataflow of decoder is
	signal rd1 : std_logic_vector(31 downto 0);
begin
    with i_A select
	rd1 <= x"00000001" when "00000",  -- Select Reg 0
               x"00000002" when "00001",  -- Select Reg 1
               x"00000004" when "00010",  -- Select Reg 2
               x"00000008" when "00011",  -- Select Reg 3
               x"00000010" when "00100",  -- Select Reg 4
               x"00000020" when "00101",  -- Select Reg 5
               x"00000040" when "00110",  -- Select Reg 6
               x"00000080" when "00111",  -- Select Reg 7
               x"00000100" when "01000",  -- Select Reg 8
               x"00000200" when "01001",  -- Select Reg 9
               x"00000400" when "01010",  -- Select Reg 10
               x"00000800" when "01011",  -- Select Reg 11
               x"00001000" when "01100",  -- Select Reg 12
               x"00002000" when "01101",  -- Select Reg 13
               x"00004000" when "01110",  -- Select Reg 14
               x"00008000" when "01111",  -- Select Reg 15
               x"00010000" when "10000",  -- Select Reg 16
               x"00020000" when "10001",  -- Select Reg 17
               x"00040000" when "10010",  -- Select Reg 18
               x"00080000" when "10011",  -- Select Reg 19
               x"00100000" when "10100",  -- Select Reg 20
               x"00200000" when "10101",  -- Select Reg 21
               x"00400000" when "10110",  -- Select Reg 22
               x"00800000" when "10111",  -- Select Reg 23
               x"01000000" when "11000",  -- Select Reg 24
               x"02000000" when "11001",  -- Select Reg 25
               x"04000000" when "11010",  -- Select Reg 26
               x"08000000" when "11011",  -- Select Reg 27
               x"10000000" when "11100",  -- Select Reg 28
               x"20000000" when "11101",  -- Select Reg 29
               x"40000000" when "11110",  -- Select Reg 30
               x"80000000" when "11111",  -- Select Reg 31
               x"00000000" when others;  

	o_Y <= rd1 when (i_WE = '1') else (others => '0');

end dataflow;

