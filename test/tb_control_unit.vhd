-- tb_control_unit.vhd
-- Author: Alex Anderson (Team E_08)
-- Testbench for the control unit.
-- Gives it one instruction of every type and checks all the control outputs.
-- ImmSrc: 000 I, 001 S, 010 B, 011 U, 100 J
-- ALUControl: 0000 add, 0001 sub, 0010 and, 0011 or, 0100 xor,
--             0101 sll, 0110 srl, 0111 sra, 1000 slt, 1001 sltu

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_control_unit is
end tb_control_unit;

architecture Behavior of tb_control_unit is

  constant Delay : time := 10 ns;

  -- Opcodes
  constant OpR      : std_logic_vector(6 downto 0) := "0110011";
  constant OpI      : std_logic_vector(6 downto 0) := "0010011";
  constant OpLoad   : std_logic_vector(6 downto 0) := "0000011";
  constant OpStore  : std_logic_vector(6 downto 0) := "0100011";
  constant OpBranch : std_logic_vector(6 downto 0) := "1100011";
  constant OpLui    : std_logic_vector(6 downto 0) := "0110111";
  constant OpAuipc  : std_logic_vector(6 downto 0) := "0010111";
  constant OpJal    : std_logic_vector(6 downto 0) := "1101111";
  constant OpJalr   : std_logic_vector(6 downto 0) := "1100111";

  -- ALUControl values
  constant AluAdd  : std_logic_vector(3 downto 0) := "0000";
  constant AluSub  : std_logic_vector(3 downto 0) := "0001";
  constant AluAnd  : std_logic_vector(3 downto 0) := "0010";
  constant AluOr   : std_logic_vector(3 downto 0) := "0011";
  constant AluXor  : std_logic_vector(3 downto 0) := "0100";
  constant AluSll  : std_logic_vector(3 downto 0) := "0101";
  constant AluSrl  : std_logic_vector(3 downto 0) := "0110";
  constant AluSra  : std_logic_vector(3 downto 0) := "0111";
  constant AluSlt  : std_logic_vector(3 downto 0) := "1000";
  constant AluSltu : std_logic_vector(3 downto 0) := "1001";

  -- ImmSrc values
  constant ImmI : std_logic_vector(2 downto 0) := "000";
  constant ImmS : std_logic_vector(2 downto 0) := "001";
  constant ImmB : std_logic_vector(2 downto 0) := "010";
  constant ImmU : std_logic_vector(2 downto 0) := "011";
  constant ImmJ : std_logic_vector(2 downto 0) := "100";

  -- Build an instruction from fields. Register and immediate bits are
  -- filled with non-zero patterns so the decoder is not relying on them
  -- being zero.
  function MakeInst(Funct7 : std_logic_vector(6 downto 0);
                    Funct3 : std_logic_vector(2 downto 0);
                    Opcode : std_logic_vector(6 downto 0))
    return std_logic_vector is
  begin
    --      funct7 / imm  rs2      rs1      funct3   rd       opcode
    return Funct7 & "00011" & "00010" & Funct3 & "00101" & Opcode;
  end function;

  signal InstIn        : std_logic_vector(31 downto 0) := (others => '0');
  signal RegWriteOut   : std_logic;
  signal MemWriteOut   : std_logic;
  signal MemReadOut    : std_logic;
  signal AluSrcOut     : std_logic;
  signal MemToRegOut   : std_logic;
  signal BranchOut     : std_logic;
  signal JumpOut       : std_logic;
  signal JumpRegOut    : std_logic;
  signal LuiOut        : std_logic;
  signal AuipcOut      : std_logic;
  signal ImmSrcOut     : std_logic_vector(2 downto 0);
  signal AluControlOut : std_logic_vector(3 downto 0);

  -- Name of the instruction currently applied (shows up in the wave window).
  signal InstName      : string(1 to 6) := "      ";

begin

  DUT: entity work.control_unit
    port map(
      instruction => InstIn,
      RegWrite    => RegWriteOut,
      MemWrite    => MemWriteOut,
      MemRead     => MemReadOut,
      ALUSrc      => AluSrcOut,
      MemToReg    => MemToRegOut,
      Branch      => BranchOut,
      Jump        => JumpOut,
      JumpReg     => JumpRegOut,
      LUI         => LuiOut,
      AUIPC       => AuipcOut,
      ImmSrc      => ImmSrcOut,
      ALUControl  => AluControlOut
    );

  TestProcess: process
    variable ErrorCount : integer := 0;
    variable TestCount  : integer := 0;

    -- Apply one instruction and check every control output.
    -- Expected flags are given in this order:
    --   RegWrite MemWrite MemRead ALUSrc MemToReg Branch Jump JumpReg LUI AUIPC
    procedure Check(Name       : in string;
                    Inst       : in std_logic_vector(31 downto 0);
                    Flags      : in std_logic_vector(9 downto 0);
                    ImmSrc     : in std_logic_vector(2 downto 0);
                    AluControl : in std_logic_vector(3 downto 0)) is
      variable PaddedName : string(1 to 6) := "      ";
      variable Got        : std_logic_vector(9 downto 0);
      variable Ok         : boolean := true;
    begin
      PaddedName(1 to Name'length) := Name;
      InstName <= PaddedName;
      InstIn   <= Inst;
      wait for Delay;
      TestCount := TestCount + 1;
      Got := RegWriteOut & MemWriteOut & MemReadOut & AluSrcOut & MemToRegOut &
             BranchOut & JumpOut & JumpRegOut & LuiOut & AuipcOut;
      if Got(9) /= Flags(9) then report Name & ": RegWrite wrong" severity error; Ok := false; end if;
      if Got(8) /= Flags(8) then report Name & ": MemWrite wrong" severity error; Ok := false; end if;
      if Got(7) /= Flags(7) then report Name & ": MemRead wrong"  severity error; Ok := false; end if;
      if Got(6) /= Flags(6) then report Name & ": ALUSrc wrong"   severity error; Ok := false; end if;
      if Got(5) /= Flags(5) then report Name & ": MemToReg wrong" severity error; Ok := false; end if;
      if Got(4) /= Flags(4) then report Name & ": Branch wrong"   severity error; Ok := false; end if;
      if Got(3) /= Flags(3) then report Name & ": Jump wrong"     severity error; Ok := false; end if;
      if Got(2) /= Flags(2) then report Name & ": JumpReg wrong"  severity error; Ok := false; end if;
      if Got(1) /= Flags(1) then report Name & ": LUI wrong"      severity error; Ok := false; end if;
      if Got(0) /= Flags(0) then report Name & ": AUIPC wrong"    severity error; Ok := false; end if;
      if ImmSrcOut /= ImmSrc then
        report Name & ": ImmSrc wrong" severity error; Ok := false;
      end if;
      if AluControlOut /= AluControl then
        report Name & ": ALUControl wrong" severity error; Ok := false;
      end if;
      if not Ok then
        ErrorCount := ErrorCount + 1;
      end if;
    end procedure;

    -- Expected flag rows (RegWrite MemWrite MemRead ALUSrc MemToReg Branch Jump JumpReg LUI AUIPC)
    constant FlagsRType  : std_logic_vector(9 downto 0) := "1000000000";
    constant FlagsIType  : std_logic_vector(9 downto 0) := "1001000000";
    constant FlagsLoad   : std_logic_vector(9 downto 0) := "1011100000";
    constant FlagsStore  : std_logic_vector(9 downto 0) := "0101000000";
    constant FlagsBranch : std_logic_vector(9 downto 0) := "0000010000";
    constant FlagsLui    : std_logic_vector(9 downto 0) := "1001000010";
    constant FlagsAuipc  : std_logic_vector(9 downto 0) := "1001000001";
    constant FlagsJal    : std_logic_vector(9 downto 0) := "1000001000";
    constant FlagsJalr   : std_logic_vector(9 downto 0) := "1001000100";
    constant FlagsNone   : std_logic_vector(9 downto 0) := "0000000000";

    constant Funct7Zero : std_logic_vector(6 downto 0) := "0000000";
    constant Funct7Alt  : std_logic_vector(6 downto 0) := "0100000";
    constant Funct7Ones : std_logic_vector(6 downto 0) := "1111111";
  begin

    -- R-type
    Check("add",    MakeInst(Funct7Zero, "000", OpR), FlagsRType, ImmI, AluAdd);
    Check("sub",    MakeInst(Funct7Alt,  "000", OpR), FlagsRType, ImmI, AluSub);
    Check("sll",    MakeInst(Funct7Zero, "001", OpR), FlagsRType, ImmI, AluSll);
    Check("slt",    MakeInst(Funct7Zero, "010", OpR), FlagsRType, ImmI, AluSlt);
    Check("sltu",   MakeInst(Funct7Zero, "011", OpR), FlagsRType, ImmI, AluSltu);
    Check("xor",    MakeInst(Funct7Zero, "100", OpR), FlagsRType, ImmI, AluXor);
    Check("srl",    MakeInst(Funct7Zero, "101", OpR), FlagsRType, ImmI, AluSrl);
    Check("sra",    MakeInst(Funct7Alt,  "101", OpR), FlagsRType, ImmI, AluSra);
    Check("or",     MakeInst(Funct7Zero, "110", OpR), FlagsRType, ImmI, AluOr);
    Check("and",    MakeInst(Funct7Zero, "111", OpR), FlagsRType, ImmI, AluAnd);

    -- I-type ALU
    Check("addi",   MakeInst(Funct7Zero, "000", OpI), FlagsIType, ImmI, AluAdd);
    -- addi with imm bit 10 set: same bits as sub's funct7, must still add.
    Check("addi10", MakeInst(Funct7Alt,  "000", OpI), FlagsIType, ImmI, AluAdd);
    -- addi with a negative immediate (all upper bits set).
    Check("addin",  MakeInst(Funct7Ones, "000", OpI), FlagsIType, ImmI, AluAdd);
    Check("slti",   MakeInst(Funct7Zero, "010", OpI), FlagsIType, ImmI, AluSlt);
    Check("sltiu",  MakeInst(Funct7Zero, "011", OpI), FlagsIType, ImmI, AluSltu);
    Check("xori",   MakeInst(Funct7Zero, "100", OpI), FlagsIType, ImmI, AluXor);
    Check("ori",    MakeInst(Funct7Zero, "110", OpI), FlagsIType, ImmI, AluOr);
    Check("andi",   MakeInst(Funct7Zero, "111", OpI), FlagsIType, ImmI, AluAnd);
    Check("slli",   MakeInst(Funct7Zero, "001", OpI), FlagsIType, ImmI, AluSll);
    Check("srli",   MakeInst(Funct7Zero, "101", OpI), FlagsIType, ImmI, AluSrl);
    Check("srai",   MakeInst(Funct7Alt,  "101", OpI), FlagsIType, ImmI, AluSra);

    -- Loads (address = rs1 + imm)
    Check("lb",     MakeInst(Funct7Zero, "000", OpLoad), FlagsLoad, ImmI, AluAdd);
    Check("lh",     MakeInst(Funct7Zero, "001", OpLoad), FlagsLoad, ImmI, AluAdd);
    Check("lw",     MakeInst(Funct7Zero, "010", OpLoad), FlagsLoad, ImmI, AluAdd);
    Check("lbu",    MakeInst(Funct7Zero, "100", OpLoad), FlagsLoad, ImmI, AluAdd);
    Check("lhu",    MakeInst(Funct7Zero, "101", OpLoad), FlagsLoad, ImmI, AluAdd);
    -- Negative offset (imm[11:5] = 1111111) must not change the decode.
    Check("lwneg",  MakeInst(Funct7Ones, "010", OpLoad), FlagsLoad, ImmI, AluAdd);

    -- Stores
    Check("sb",     MakeInst(Funct7Zero, "000", OpStore), FlagsStore, ImmS, AluAdd);
    Check("sh",     MakeInst(Funct7Zero, "001", OpStore), FlagsStore, ImmS, AluAdd);
    Check("sw",     MakeInst(Funct7Zero, "010", OpStore), FlagsStore, ImmS, AluAdd);
    Check("swneg",  MakeInst(Funct7Ones, "010", OpStore), FlagsStore, ImmS, AluAdd);

    -- Branches
    -- beq/bne compare with sub (zero flag); blt/bge use slt; bltu/bgeu use sltu.
    Check("beq",    MakeInst(Funct7Zero, "000", OpBranch), FlagsBranch, ImmB, AluSub);
    Check("bne",    MakeInst(Funct7Zero, "001", OpBranch), FlagsBranch, ImmB, AluSub);
    Check("blt",    MakeInst(Funct7Zero, "100", OpBranch), FlagsBranch, ImmB, AluSlt);
    Check("bge",    MakeInst(Funct7Zero, "101", OpBranch), FlagsBranch, ImmB, AluSlt);
    Check("bltu",   MakeInst(Funct7Zero, "110", OpBranch), FlagsBranch, ImmB, AluSltu);
    Check("bgeu",   MakeInst(Funct7Zero, "111", OpBranch), FlagsBranch, ImmB, AluSltu);
    -- Backward branch (imm sign bit set) must decode the same way.
    Check("bneneg", MakeInst(Funct7Ones, "001", OpBranch), FlagsBranch, ImmB, AluSub);

    -- Upper immediates
    Check("lui",    MakeInst(Funct7Zero, "000", OpLui),   FlagsLui,   ImmU, AluAdd);
    Check("lui20",  MakeInst(Funct7Alt,  "101", OpLui),   FlagsLui,   ImmU, AluAdd);
    Check("auipc",  MakeInst(Funct7Zero, "000", OpAuipc), FlagsAuipc, ImmU, AluAdd);

    -- Jumps
    Check("jal",    MakeInst(Funct7Zero, "000", OpJal),  FlagsJal,  ImmJ, AluAdd);
    Check("jalneg", MakeInst(Funct7Ones, "111", OpJal),  FlagsJal,  ImmJ, AluAdd);
    Check("jalr",   MakeInst(Funct7Zero, "000", OpJalr), FlagsJalr, ImmI, AluAdd);

    -- wfi (halt): nothing may be written
    Check("wfi",    x"10500073", FlagsNone, ImmI, AluAdd);

    -- Unused opcode / all zeros: no side effects
    Check("zero",   x"00000000", FlagsNone, ImmI, AluAdd);

    if ErrorCount = 0 then
      report "tb_control_unit: ALL " & integer'image(TestCount) & " TESTS PASSED" severity note;
    else
      report "tb_control_unit: " & integer'image(ErrorCount) & " of " &
             integer'image(TestCount) & " TESTS FAILED" severity error;
    end if;
    wait;
  end process;

end Behavior;
