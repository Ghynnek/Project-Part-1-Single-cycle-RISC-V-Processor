-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- RISCV_Processor.vhd
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
  generic(N : integer := DATA_WIDTH);
  port(iCLK            : in std_logic;
       iRST            : in std_logic;
       iInstLd         : in std_logic;
       iInstAddr       : in std_logic_vector(N-1 downto 0);
       iInstExt        : in std_logic_vector(N-1 downto 0);
       oALUOut         : out std_logic_vector(N-1 downto 0));
end RISCV_Processor;


architecture structure of RISCV_Processor is

  -- Required data memory signals
  signal s_DMemWr       : std_logic;
  signal s_DMemAddr     : std_logic_vector(N-1 downto 0);
  signal s_DMemData     : std_logic_vector(N-1 downto 0);
  signal s_DMemOut      : std_logic_vector(N-1 downto 0);
 
  -- Required register file signals 
  signal s_RegWr        : std_logic;
  signal s_RegWrAddr    : std_logic_vector(4 downto 0);
  signal s_RegWrData    : std_logic_vector(N-1 downto 0);

  -- Required instruction memory signals
  signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_PC instead
  signal s_PC           : std_logic_vector(N-1 downto 0);
  signal s_Inst         : std_logic_vector(N-1 downto 0);

  -- Required halt signal -- for simulation
  signal s_Halt         : std_logic;

  -- Required overflow signal -- for overflow exception detection
  signal s_Ovfl         : std_logic;

  component mem is
    generic(ADDR_WIDTH : integer;
            DATA_WIDTH : integer);
    port(
          clk          : in std_logic;
          addr         : in std_logic_vector((ADDR_WIDTH-1) downto 0);
          data         : in std_logic_vector((DATA_WIDTH-1) downto 0);
          we           : in std_logic := '1';
          q            : out std_logic_vector((DATA_WIDTH -1) downto 0));
  end component;

  -- =========================================================================
  -- Submodule Component Declarations
  -- =========================================================================
  component fetch_logic is
    port (
      clk, reset            : in  std_logic;
      imm                   : in  std_logic_vector(31 downto 0);
      alu_result            : in  std_logic_vector(31 downto 0);
      zero                  : in  std_logic;
      funct3                : in  std_logic_vector(2 downto 0);
      Branch, Jump, JumpReg : in  std_logic;
      pc                    : out std_logic_vector(31 downto 0);
      pc_plus4              : out std_logic_vector(31 downto 0)
    );
  end component;

  component control_unit is
    port (
      instruction : in  std_logic_vector(31 downto 0);
      RegWrite    : out std_logic;
      MemWrite    : out std_logic;
      MemRead     : out std_logic;
      ALUSrc      : out std_logic;
      MemToReg    : out std_logic;
      Branch      : out std_logic;
      Jump        : out std_logic;
      JumpReg     : out std_logic;
      LUI         : out std_logic;
      ImmSrc      : out std_logic_vector(2 downto 0);
      ALUControl  : out std_logic_vector(3 downto 0)
    );
  end component;

  component reg_file is
    port (
      i_clk    : in  std_logic;
      i_rst    : in  std_logic;
      i_we     : in  std_logic;
      i_rd     : in  std_logic_vector(4 downto 0);
      i_wdata  : in  std_logic_vector(31 downto 0);
      i_rs1    : in  std_logic_vector(4 downto 0);
      i_rs2    : in  std_logic_vector(4 downto 0);
      o_rdata1 : out std_logic_vector(31 downto 0);
      o_rdata2 : out std_logic_vector(31 downto 0)
    );
  end component;

  component imm_gen is
    port (
      instruction : in  std_logic_vector(31 downto 0);
      ImmSrc      : in  std_logic_vector(2 downto 0);
      imm         : out std_logic_vector(31 downto 0)
    );
  end component;

  component mux2_32 is
    port (
      d0 : in  std_logic_vector(31 downto 0);
      d1 : in  std_logic_vector(31 downto 0);
      s  : in  std_logic;
      y  : out std_logic_vector(31 downto 0)
    );
  end component;

  component alu is
    port (
      a          : in  std_logic_vector(31 downto 0);
      b          : in  std_logic_vector(31 downto 0);
      ALUControl : in  std_logic_vector(3 downto 0);
      result     : out std_logic_vector(31 downto 0);
      zero       : out std_logic
    );
  end component;

  component writeback_select is
    port (
      alu_result : in  std_logic_vector(31 downto 0);
      mem_data   : in  std_logic_vector(31 downto 0);
      imm        : in  std_logic_vector(31 downto 0);
      MemToReg   : in  std_logic;
      LUI        : in  std_logic;
      wb_data    : out std_logic_vector(31 downto 0)
    );
  end component;

  -- =========================================================================
  -- Internal Datapath Signals
  -- =========================================================================
  signal s_PCPlus4    : std_logic_vector(31 downto 0);
  signal s_Imm        : std_logic_vector(31 downto 0);
  signal s_RegRead1   : std_logic_vector(31 downto 0);
  signal s_RegRead2   : std_logic_vector(31 downto 0);
  signal s_ALUB       : std_logic_vector(31 downto 0);
  signal s_ALUResult  : std_logic_vector(31 downto 0);
  signal s_Zero       : std_logic;

  -- Control Unit Signals
  signal s_MemRead    : std_logic;
  signal s_ALUSrc     : std_logic;
  signal s_MemToReg   : std_logic;
  signal s_Branch     : std_logic;
  signal s_Jump       : std_logic;
  signal s_JumpReg    : std_logic;
  signal s_LUI        : std_logic;
  signal s_ImmSrc     : std_logic_vector(2 downto 0);
  signal s_ALUControl : std_logic_vector(3 downto 0);

begin

  s_Ovfl <= '0'; -- RISC-V does not have hardware overflow detection.

  with iInstLd select
    s_IMemAddr <= s_PC when '0',
      iInstAddr when others;

  IMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_IMemAddr(11 downto 2),
             data => iInstExt,
             we   => iInstLd,
             q    => s_Inst);
  
  DMem: mem
    generic map(ADDR_WIDTH => ADDR_WIDTH,
                DATA_WIDTH => N)
    port map(clk  => iCLK,
             addr => s_DMemAddr(11 downto 2),
             data => s_DMemData,
             we   => s_DMemWr,
             q    => s_DMemOut);

  -- =========================================================================
  -- Halt Signal Decode (WFI: Opcode = 1110011, funct3 = 000, funct12 = 000100000101)
  -- =========================================================================
  s_Halt <= '1' when (s_Inst(6 downto 0)   = "1110011" and
                      s_Inst(14 downto 12) = "000"     and
                      s_Inst(31 downto 20) = "000100000101")
            else '0';

  -- =========================================================================
  -- Required Toolflow Signal Hookups
  -- =========================================================================
  s_RegWrAddr <= s_Inst(11 downto 7);
  s_DMemAddr  <= s_ALUResult;
  s_DMemData  <= s_RegRead2;
  oALUOut     <= s_ALUResult;

  -- =========================================================================
  -- Processor Datapath Instantiations
  -- =========================================================================

  U_FETCH: fetch_logic
    port map (
      clk        => iCLK,
      reset      => iRST,
      imm        => s_Imm,
      alu_result => s_ALUResult,
      zero       => s_Zero,
      funct3     => s_Inst(14 downto 12),
      Branch     => s_Branch,
      Jump       => s_Jump,
      JumpReg    => s_JumpReg,
      pc         => s_PC,
      pc_plus4   => s_PCPlus4
    );

  U_CONTROL: control_unit
    port map (
      instruction => s_Inst,
      RegWrite    => s_RegWr,
      MemWrite    => s_DMemWr,
      MemRead     => s_MemRead,
      ALUSrc      => s_ALUSrc,
      MemToReg    => s_MemToReg,
      Branch      => s_Branch,
      Jump        => s_Jump,
      JumpReg     => s_JumpReg,
      LUI         => s_LUI,
      ImmSrc      => s_ImmSrc,
      ALUControl  => s_ALUControl
    );

  U_REGFILE: reg_file
    port map (
      i_clk    => iCLK,
      i_rst    => iRST,
      i_we     => s_RegWr,
      i_rd     => s_RegWrAddr,
      i_wdata  => s_RegWrData,
      i_rs1    => s_Inst(19 downto 15),
      i_rs2    => s_Inst(24 downto 20),
      o_rdata1 => s_RegRead1,
      o_rdata2 => s_RegRead2
    );

  U_IMMGEN: imm_gen
    port map (
      instruction => s_Inst,
      ImmSrc      => s_ImmSrc,
      imm         => s_Imm
    );

  U_ALUSRC_MUX: mux2_32
    port map (
      d0 => s_RegRead2,
      d1 => s_Imm,
      s  => s_ALUSrc,
      y  => s_ALUB
    );

  U_ALU: alu
    port map (
      a          => s_RegRead1,
      b          => s_ALUB,
      ALUControl => s_ALUControl,
      result     => s_ALUResult,
      zero       => s_Zero
    );

  U_WB_SELECT: writeback_select
    port map (
      alu_result => s_ALUResult,
      mem_data   => s_DMemOut,
      imm        => s_Imm,
      MemToReg   => s_MemToReg,
      LUI        => s_LUI,
      wb_data    => s_RegWrData
    );

end structure;
