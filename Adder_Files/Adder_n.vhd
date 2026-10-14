--Adder_n
--Andres Garcia

library IEEE;
use IEEE.std_logic_1164.all;
 
entity Adder_N is
  generic(N : integer := 32); -- Generic of type integer for operand width. Default value is 32.
  port(i_A          : in  std_logic_vector(N-1 downto 0);
       i_B          : in  std_logic_vector(N-1 downto 0);
       i_Cin        : in  std_logic;
       o_S          : out std_logic_vector(N-1 downto 0);
       o_Cout       : out std_logic);
end Adder_N;
 
architecture structural of Adder_N is
 
  component FullAdder is
    port(i_A          : in  std_logic;
         i_B          : in  std_logic;
         i_C          : in  std_logic;
         o_S          : out std_logic;
         o_C          : out std_logic);
  end component;
 
  -- Internal carry chain: s_C(0) is the overall carry-in, s_C(N) is the
  -- overall carry-out. s_C(i+1) is the carry produced by stage i.
  signal s_C : std_logic_vector(N downto 0);
 
begin
 
  s_C(0)   <= i_Cin;
  o_Cout   <= s_C(N);
 
  G_NBit_ADD: for i in 0 to N-1 generate
    FAI: FullAdder port map(
              i_A      => i_A(i),    -- ith bit of operand A
              i_B      => i_B(i),    -- ith bit of operand B
              i_C      => s_C(i),    -- carry-in from previous stage (stage 0 gets i_Cin)
              o_S      => o_S(i),    -- ith bit of sum
              o_C      => s_C(i+1)); -- carry-out, feeds next stage's carry-in
  end generate G_NBit_ADD;
 
end structural;