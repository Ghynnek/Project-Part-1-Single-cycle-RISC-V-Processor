library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fetch_logic is
  port (
    clk, reset   : in  std_logic;
    imm          : in  std_logic_vector(31 downto 0);
    alu_result   : in  std_logic_vector(31 downto 0); -- rs1+imm for jalr, compare result for branches
    zero         : in  std_logic;
    funct3       : in  std_logic_vector(2 downto 0);
    Branch, Jump, JumpReg : in std_logic;
    pc           : out std_logic_vector(31 downto 0);
    pc_plus4     : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of fetch_logic is
  signal pc_reg, pc4, target, jalr_t, next_pc : std_logic_vector(31 downto 0);
  signal cond, taken : std_logic;
  signal pcsrc : std_logic_vector(1 downto 0);

    component Adder_N
    generic(N : integer := 32);
    port(i_A    : in  std_logic_vector(N-1 downto 0);
         i_B    : in  std_logic_vector(N-1 downto 0);
         i_Cin  : in  std_logic;
         o_S    : out std_logic_vector(N-1 downto 0);
         o_Cout : out std_logic);
    end component;
	signal s_Cout4 : std_logic;
	signal s_CoutImm : std_logic;

     component dffg
    port(i_CLK : in  std_logic;
         i_RST : in  std_logic;
         i_WE  : in  std_logic;
         i_D   : in  std_logic;
         o_Q   : out std_logic);
  end component;

  component dffg_set
    port(i_CLK : in  std_logic;
         i_RST : in  std_logic;
         i_WE  : in  std_logic;
         i_D   : in  std_logic;
         o_Q   : out std_logic);
  end component;
begin
  	 PCADD4: Adder_N
    generic map(N => 32)
    port map(i_A    => pc_reg,
             i_B    => x"00000004",
             i_Cin  => '0',
             o_S    => pc4,
             o_Cout => s_Cout4);
	PCADDIMM: Adder_N
	Generic map(N => 32)
	port map(i_A  => pc_reg,
		i_B => imm,
		i_Cin => '0',
		o_S => target,
		o_Cout => s_CoutImm);
								
  jalr_t <= alu_result(31 downto 1) & '0';

  cond  <= alu_result(0) when funct3(2) = '1' else zero;
  taken <= Branch and (funct3(0) xor cond);

  pcsrc <= "10" when JumpReg = '1' else
           "01" when (Jump = '1' or taken = '1') else
           "00";

  with pcsrc select
    next_pc <= pc4    when "00",
               target when "01",
               jalr_t when others;

 G_PC: for i in 0 to 31 generate

    G_CLR: if i /= 22 generate
      PC_FF: dffg
        port map(i_CLK => clk,
                 i_RST => reset,
                 i_WE  => '1',          -- PC updates every cycle
                 i_D   => next_pc(i),
                 o_Q   => pc_reg(i));
    end generate G_CLR;

    G_set: if i = 22 generate
	pc_FF_SET :dffg_set
	port map (i_CLK => clk,
		i_RST => reset,
                 i_WE  => '1',          
                 i_D   => next_pc(i),
                 o_Q   => pc_reg(i));
 end generate G_set;
  end generate G_PC;

  pc <= pc_reg;  pc_plus4 <= pc4;
end architecture;

