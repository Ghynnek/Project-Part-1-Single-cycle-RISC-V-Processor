-- tb_imm_gen.vhd
-- Testbench for the immediate generator.
-- Checks a few real instructions, then puts test immediates into each
-- format (I, S, B, U, J) and checks the sign extended output.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_imm_gen is
end tb_imm_gen;

architecture Behavior of tb_imm_gen is

  constant Delay : time := 10 ns;

  constant ImmI : std_logic_vector(2 downto 0) := "000";
  constant ImmS : std_logic_vector(2 downto 0) := "001";
  constant ImmB : std_logic_vector(2 downto 0) := "010";
  constant ImmU : std_logic_vector(2 downto 0) := "011";
  constant ImmJ : std_logic_vector(2 downto 0) := "100";

  signal InstIn   : std_logic_vector(31 downto 0) := (others => '0');
  signal ImmSrc   : std_logic_vector(2 downto 0)  := (others => '0');
  signal ImmOut   : std_logic_vector(31 downto 0);
  signal Expected : std_logic_vector(31 downto 0) := (others => '0');

  type PatternArray is array (natural range <>) of std_logic_vector(31 downto 0);

  -- test immediates for each format
  constant ImmsIS : PatternArray := (
    x"00000000", x"00000001", x"FFFFFFFF", x"000007FF", x"FFFFF800",
    x"00000400", x"0000001F", x"FFFFFFE0", x"00000555", x"FFFFFAAA");
  constant ImmsB : PatternArray := (
    x"00000000", x"00000002", x"FFFFFFFE", x"00000FFE", x"FFFFF000",
    x"00000800", x"0000001E", x"FFFFFFE0", x"00000554", x"FFFFFAAA");
  constant ImmsU : PatternArray := (
    x"00000000", x"00001000", x"FFFFF000", x"7FFFF000", x"80000000",
    x"12345000", x"55555000", x"AAAAA000");
  constant ImmsJ : PatternArray := (
    x"00000000", x"00000002", x"FFFFFFFE", x"000FFFFE", x"FFF00000",
    x"00000800", x"00001000", x"000007FE", x"00055554", x"FFFAAAAA");

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

  function FormatName(Src : std_logic_vector(2 downto 0)) return string is
  begin
    if Src = ImmS then
      return "S";
    elsif Src = ImmB then
      return "B";
    elsif Src = ImmU then
      return "U";
    elsif Src = ImmJ then
      return "J";
    else
      return "I";
    end if;
  end function;

  -- puts the immediate bits into an instruction
  function Encode(Src    : std_logic_vector(2 downto 0);
                  Imm    : std_logic_vector(31 downto 0);
                  Filler : std_logic_vector(31 downto 0))
    return std_logic_vector is
    variable Inst : std_logic_vector(31 downto 0);
  begin
    Inst := Filler;
    if Src = ImmS then
      Inst(31 downto 25) := Imm(11 downto 5);
      Inst(11 downto 7)  := Imm(4 downto 0);
    elsif Src = ImmB then
      Inst(31)           := Imm(12);
      Inst(30 downto 25) := Imm(10 downto 5);
      Inst(11 downto 8)  := Imm(4 downto 1);
      Inst(7)            := Imm(11);
    elsif Src = ImmU then
      Inst(31 downto 12) := Imm(31 downto 12);
    elsif Src = ImmJ then
      Inst(31)           := Imm(20);
      Inst(30 downto 21) := Imm(10 downto 1);
      Inst(20)           := Imm(11);
      Inst(19 downto 12) := Imm(19 downto 12);
    else
      Inst(31 downto 20) := Imm(11 downto 0);
    end if;
    return Inst;
  end function;

begin

  DUT: entity work.imm_gen
    port map(
      instruction => InstIn,
      ImmSrc      => ImmSrc,
      imm         => ImmOut
    );

  TestProcess: process
    variable ErrorCount : integer := 0;
    variable TestCount  : integer := 0;

    procedure Check(Src    : in std_logic_vector(2 downto 0);
                    Inst   : in std_logic_vector(31 downto 0);
                    Answer : in std_logic_vector(31 downto 0)) is
    begin
      InstIn   <= Inst;
      ImmSrc   <= Src;
      Expected <= Answer;
      wait for Delay;
      TestCount := TestCount + 1;
      if ImmOut /= Answer then
        ErrorCount := ErrorCount + 1;
        report FormatName(Src) & "-type immediate of " & Hex(Inst) &
               ": got " & Hex(ImmOut) & ", expected " & Hex(Answer)
               severity error;
      end if;
    end procedure;

    -- check each immediate with the other bits all 0 and all 1
    procedure CheckAll(Src  : in std_logic_vector(2 downto 0);
                       Imms : in PatternArray) is
    begin
      for I in Imms'range loop
        Check(Src, Encode(Src, Imms(I), x"00000000"), Imms(I));
        Check(Src, Encode(Src, Imms(I), x"FFFFFFFF"), Imms(I));
      end loop;
    end procedure;

  begin

    -- real instructions
    Check(ImmI, x"FFF00093", x"FFFFFFFF");  -- addi x1, x0, -1
    Check(ImmI, x"00842283", x"00000008");  -- lw x5, 8(x8)
    Check(ImmS, x"FE712E23", x"FFFFFFFC");  -- sw x7, -4(x2)
    Check(ImmB, x"00730463", x"00000008");  -- beq x6, x7, 8
    Check(ImmB, x"FE029CE3", x"FFFFFFF8");  -- bne x5, x0, -8
    Check(ImmU, x"10010437", x"10010000");  -- lui x8, 0x10010
    Check(ImmJ, x"010000EF", x"00000010");  -- jal x1, 16
    Check(ImmJ, x"FFDFF06F", x"FFFFFFFC");  -- jal x0, -4
    Check("111", x"FFF00093", x"FFFFFFFF"); -- unused ImmSrc should give I

    -- test immediates for each format
    CheckAll(ImmI, ImmsIS);
    CheckAll(ImmS, ImmsIS);
    CheckAll(ImmB, ImmsB);
    CheckAll(ImmU, ImmsU);
    CheckAll(ImmJ, ImmsJ);

    if ErrorCount = 0 then
      report "tb_imm_gen: ALL " & integer'image(TestCount) & " TESTS PASSED" severity note;
    else
      report "tb_imm_gen: " & integer'image(ErrorCount) & " of " &
             integer'image(TestCount) & " TESTS FAILED" severity error;
    end if;
    wait;
  end process;

end Behavior;
