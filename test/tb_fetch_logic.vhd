-- tb_fetch_logic.vhd
-- Testbench for the fetch logic.
-- Checks reset, PC+4, every branch taken and not taken, jal, and jalr.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_fetch_logic is
end tb_fetch_logic;

architecture Behavior of tb_fetch_logic is

  constant ClockPeriod : time := 10 ns;
  constant ResetPC     : std_logic_vector(31 downto 0) := x"00400000";

  constant F3Beq  : std_logic_vector(2 downto 0) := "000";
  constant F3Bne  : std_logic_vector(2 downto 0) := "001";
  constant F3Blt  : std_logic_vector(2 downto 0) := "100";
  constant F3Bge  : std_logic_vector(2 downto 0) := "101";
  constant F3Bltu : std_logic_vector(2 downto 0) := "110";
  constant F3Bgeu : std_logic_vector(2 downto 0) := "111";

  -- what the next PC should be
  type NextKind is (Seq, Target, Reg);

  signal Clk       : std_logic := '0';
  signal Done      : boolean := false;
  signal Reset     : std_logic := '0';
  signal Imm       : std_logic_vector(31 downto 0) := (others => '0');
  signal AluResult : std_logic_vector(31 downto 0) := (others => '0');
  signal Zero      : std_logic := '0';
  signal Funct3    : std_logic_vector(2 downto 0) := (others => '0');
  signal Branch    : std_logic := '0';
  signal Jump      : std_logic := '0';
  signal JumpReg   : std_logic := '0';
  signal PC        : std_logic_vector(31 downto 0);
  signal PCPlus4   : std_logic_vector(31 downto 0);
  signal ExpectedPC : std_logic_vector(31 downto 0) := ResetPC;

  -- step name for the wave window
  signal StepName  : string(1 to 16) := (others => ' ');

  -- prints a value as hex
  function Hex(Value : std_logic_vector(31 downto 0)) return string is
    constant Digits : string(1 to 16) := "0123456789ABCDEF";
    variable HexText : string(1 to 8);
    variable Nibble : std_logic_vector(3 downto 0);
  begin
    for I in 0 to 7 loop
      Nibble := Value(31 - 4*I downto 28 - 4*I);
      if is_x(Nibble) then
        HexText(I + 1) := 'X';
      else
        HexText(I + 1) := Digits(to_integer(unsigned(Nibble)) + 1);
      end if;
    end loop;
    return "0x" & HexText;
  end function;

  function Pad(Text : string) return string is
    variable Padded : string(1 to 16) := (others => ' ');
  begin
    for I in 1 to Text'length loop
      if I <= 16 then
        Padded(I) := Text(Text'low + I - 1);
      end if;
    end loop;
    return Padded;
  end function;

  function Add(A : std_logic_vector(31 downto 0);
               B : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(A) + unsigned(B));
  end function;

begin

  Clk <= not Clk after ClockPeriod / 2 when not Done else '0';

  DUT: entity work.fetch_logic
    port map(
      clk        => Clk,
      reset      => Reset,
      imm        => Imm,
      alu_result => AluResult,
      zero       => Zero,
      funct3     => Funct3,
      Branch     => Branch,
      Jump       => Jump,
      JumpReg    => JumpReg,
      pc         => PC,
      pc_plus4   => PCPlus4
    );

  TestProcess: process
    variable ErrorCount : integer := 0;
    variable TestCount  : integer := 0;
    variable ModelPC    : std_logic_vector(31 downto 0) := ResetPC;

    -- set inputs, clock once, check the PC
    procedure Step(Name   : in string;
                   Br     : in std_logic;
                   J      : in std_logic;
                   JR     : in std_logic;
                   F3     : in std_logic_vector(2 downto 0);
                   Z      : in std_logic;
                   AluRes : in std_logic_vector(31 downto 0);
                   Offset : in std_logic_vector(31 downto 0);
                   Kind   : in NextKind) is
      variable NextPC : std_logic_vector(31 downto 0);
    begin
      StepName  <= Pad(Name);
      Branch    <= Br;
      Jump      <= J;
      JumpReg   <= JR;
      Funct3    <= F3;
      Zero      <= Z;
      AluResult <= AluRes;
      Imm       <= Offset;

      case Kind is
        when Seq    => NextPC := Add(ModelPC, x"00000004");
        when Target => NextPC := Add(ModelPC, Offset);
        when Reg    => NextPC := AluRes(31 downto 1) & '0';
      end case;
      ExpectedPC <= NextPC;

      wait for 1 ns;
      TestCount := TestCount + 1;
      if PCPlus4 /= Add(ModelPC, x"00000004") then
        ErrorCount := ErrorCount + 1;
        report Name & ": pc_plus4 = " & Hex(PCPlus4) & ", expected " &
               Hex(Add(ModelPC, x"00000004")) severity error;
      end if;

      wait until rising_edge(Clk);
      wait for 1 ns;
      TestCount := TestCount + 1;
      if PC /= NextPC then
        ErrorCount := ErrorCount + 1;
        report Name & ": PC went from " & Hex(ModelPC) & " to " & Hex(PC) &
               ", expected " & Hex(NextPC) severity error;
      end if;
      ModelPC := NextPC;
      -- end on a falling edge so the next step starts before the next rising edge
      wait until falling_edge(Clk);
    end procedure;

    -- normal instruction
    procedure StepSeq(Name : in string) is
    begin
      Step(Name, '0', '0', '0', "000", '0', x"00000000", x"00000000", Seq);
    end procedure;

    procedure CheckReset is
    begin
      StepName <= Pad("reset");
      Reset    <= '1';
      Branch   <= '0';
      Jump     <= '0';
      JumpReg  <= '0';
      ExpectedPC <= ResetPC;
      wait for 1 ns;
      TestCount := TestCount + 1;
      if PC /= ResetPC then
        ErrorCount := ErrorCount + 1;
        report "reset: PC = " & Hex(PC) & ", expected " & Hex(ResetPC) severity error;
      end if;
      wait until rising_edge(Clk);
      wait for 1 ns;
      TestCount := TestCount + 1;
      if PC /= ResetPC then
        ErrorCount := ErrorCount + 1;
        report "reset held: PC = " & Hex(PC) & ", expected " & Hex(ResetPC) severity error;
      end if;
      wait until falling_edge(Clk);
      Reset <= '0';
      ModelPC := ResetPC;
    end procedure;

  begin

    -- reset
    CheckReset;

    -- pc + 4
    StepSeq("seq 1");
    StepSeq("seq 2");
    StepSeq("seq 3");

    -- branches
    Step("beq taken",      '1', '0', '0', F3Beq,  '1', x"00000000", x"00000010", Target);
    Step("beq not taken",  '1', '0', '0', F3Beq,  '0', x"00000005", x"00000010", Seq);
    Step("beq back",       '1', '0', '0', F3Beq,  '1', x"00000000", x"FFFFFFF8", Target);
    -- bne
    Step("bne taken",      '1', '0', '0', F3Bne,  '0', x"FFFFFFF8", x"00000020", Target);
    Step("bne not taken",  '1', '0', '0', F3Bne,  '1', x"00000000", x"00000020", Seq);
    Step("bne back",       '1', '0', '0', F3Bne,  '0', x"00000003", x"FFFFFFF0", Target);
    -- blt/bge use alu_result(0), not zero
    Step("blt taken",      '1', '0', '0', F3Blt,  '0', x"00000001", x"00000008", Target);
    Step("blt not taken",  '1', '0', '0', F3Blt,  '1', x"00000000", x"00000008", Seq);
    Step("blt zero ignr",  '1', '0', '0', F3Blt,  '1', x"00000001", x"FFFFFFFC", Target);
    -- bge
    Step("bge taken",      '1', '0', '0', F3Bge,  '1', x"00000000", x"0000000C", Target);
    Step("bge not taken",  '1', '0', '0', F3Bge,  '0', x"00000001", x"0000000C", Seq);
    Step("bge zero ignr",  '1', '0', '0', F3Bge,  '0', x"00000000", x"FFFFFFF4", Target);
    Step("bltu taken",     '1', '0', '0', F3Bltu, '0', x"00000001", x"00000040", Target);
    Step("bltu not taken", '1', '0', '0', F3Bltu, '1', x"00000000", x"00000040", Seq);
    -- bgeu
    Step("bgeu taken",     '1', '0', '0', F3Bgeu, '1', x"00000000", x"FFFFFFC0", Target);
    Step("bgeu not taken", '1', '0', '0', F3Bgeu, '0', x"00000001", x"FFFFFFC0", Seq);

    -- Branch = 0 so nothing should happen
    Step("sub, zero=1",    '0', '0', '0', F3Beq,  '1', x"00000000", x"00000100", Seq);
    Step("slt, res=1",     '0', '0', '0', F3Blt,  '0', x"00000001", x"00000100", Seq);

    -- jal
    Step("jal fwd",        '0', '1', '0', "000",  '0', x"00000000", x"00000400", Target);
    Step("jal back",       '0', '1', '0', "000",  '0', x"00000000", x"FFFFFC00", Target);
    Step("jal br-nt",      '0', '1', '0', F3Bne,  '1', x"00000000", x"00000010", Target);

    -- jalr
    Step("jalr",           '0', '0', '1', "000",  '0', x"00400100", x"00000000", Reg);
    Step("jalr odd",       '0', '0', '1', "000",  '0', x"00400123", x"00000004", Reg);
    Step("jalr over jal",  '0', '1', '1', "000",  '0', x"00400200", x"00000800", Reg);
    StepSeq("after jalr");

    -- reset again
    CheckReset;
    StepSeq("seq after rst");

    if ErrorCount = 0 then
      report "tb_fetch_logic: ALL " & integer'image(TestCount) & " TESTS PASSED" severity note;
    else
      report "tb_fetch_logic: " & integer'image(ErrorCount) & " of " &
             integer'image(TestCount) & " TESTS FAILED" severity error;
    end if;
    Done <= true;
    wait;
  end process;

end Behavior;
