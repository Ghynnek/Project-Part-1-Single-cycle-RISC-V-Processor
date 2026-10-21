--FullAdder
--Andres Garcia

library IEEE;
use IEEE.std_logic_1164.all;
 
entity FullAdder is
  port(i_A          : in  std_logic;
       i_B          : in  std_logic;
       i_C          : in  std_logic;   -- carry-in
       o_S          : out std_logic;   -- sum
       o_C          : out std_logic);  -- carry-out
end FullAdder;
 
architecture structural of FullAdder is
 
  component xorg2 is
    port(i_A          : in  std_logic;
         i_B          : in  std_logic;
         o_F          : out std_logic);
  end component;
 
  component andg2 is
    port(i_A          : in  std_logic;
         i_B          : in  std_logic;
         o_F          : out std_logic);
  end component;
 
  component org2 is
    port(i_A          : in  std_logic;
         i_B          : in  std_logic;
         o_F          : out std_logic);
  end component;
 
  signal s_AxorB    : std_logic;  -- i_A xor i_B
  signal s_AandB    : std_logic;  -- i_A . i_B
  signal s_AxorBandC: std_logic;  -- (i_A xor i_B) . i_C
 
begin
 
  G_XOR0: xorg2 port map(
              i_A      => i_A,
              i_B      => i_B,
              o_F      => s_AxorB);
 
  G_XOR1: xorg2 port map(
              i_A      => s_AxorB,
              i_B      => i_C,
              o_F      => o_S);
 
  G_AND0: andg2 port map(
              i_A      => i_A,
              i_B      => i_B,
              o_F      => s_AandB);
 
  G_AND1: andg2 port map(
              i_A      => s_AxorB,
              i_B      => i_C,
              o_F      => s_AxorBandC);
 
  G_OR0: org2 port map(
              i_A      => s_AandB,
              i_B      => s_AxorBandC,
              o_F      => o_C);
 
end structural;