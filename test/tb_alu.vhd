-- tb_alu.vhd
-- Testbench for the ALU.
-- Checks every ALUControl op with some edge cases, then runs every op on a
-- list of test values and compares against numeric_std.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_alu is
end tb_alu;

architecture Behavior of tb_alu is

  constant Delay : time := 10 ns;

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

  signal OperandA   : std_logic_vector(31 downto 0) := (others => '0');
  signal OperandB   : std_logic_vector(31 downto 0) := (others => '0');
  signal AluControl : std_logic_vector(3 downto 0)  := (others => '0');
  signal Result     : std_logic_vector(31 downto 0);
  signal Zero       : std_logic;
  signal Expected   : std_logic_vector(31 downto 0) := (others => '0');

  -- op name for the wave window
  signal OpName     : string(1 to 4) := "    ";

  type PatternArray is array (natural range <>) of std_logic_vector(31 downto 0);
  constant Patterns : PatternArray := (
    x"00000000", x"00000001", x"FFFFFFFF", x"7FFFFFFF", x"80000000",
    x"AAAAAAAA", x"55555555", x"12345678", x"87654321", x"0000001F",
    x"00000020");

  type OpArray is array (natural range <>) of std_logic_vector(3 downto 0);
  constant Ops : OpArray := (
    AluAdd, AluSub, AluAnd, AluOr, AluXor,
    AluSll, AluSrl, AluSra, AluSlt, AluSltu);

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

  function Name(Op : std_logic_vector(3 downto 0)) return string is
  begin
    case Op is
      when AluAdd  => return "add ";
      when AluSub  => return "sub ";
      when AluAnd  => return "and ";
      when AluOr   => return "or  ";
      when AluXor  => return "xor ";
      when AluSll  => return "sll ";
      when AluSrl  => return "srl ";
      when AluSra  => return "sra ";
      when AluSlt  => return "slt ";
      when AluSltu => return "sltu";
      when others  => return "????";
    end case;
  end function;

  -- expected answer for each op
  function Model(Op : std_logic_vector(3 downto 0);
                 A  : std_logic_vector(31 downto 0);
                 B  : std_logic_vector(31 downto 0))
    return std_logic_vector is
    variable Shamt : natural;
  begin
    Shamt := to_integer(unsigned(B(4 downto 0)));
    case Op is
      when AluSub  => return std_logic_vector(unsigned(A) - unsigned(B));
      when AluAnd  => return A and B;
      when AluOr   => return A or B;
      when AluXor  => return A xor B;
      when AluSll  => return std_logic_vector(shift_left(unsigned(A), Shamt));
      when AluSrl  => return std_logic_vector(shift_right(unsigned(A), Shamt));
      when AluSra  => return std_logic_vector(shift_right(signed(A), Shamt));
      when AluSlt  =>
        if signed(A) < signed(B) then return x"00000001"; else return x"00000000"; end if;
      when AluSltu =>
        if unsigned(A) < unsigned(B) then return x"00000001"; else return x"00000000"; end if;
      when others  => return std_logic_vector(unsigned(A) + unsigned(B));
    end case;
  end function;

begin

  DUT: entity work.alu
    port map(
      a          => OperandA,
      b          => OperandB,
      ALUControl => AluControl,
      result     => Result,
      zero       => Zero
    );

  TestProcess: process
    variable ErrorCount : integer := 0;
    variable TestCount  : integer := 0;

    procedure Check(Op     : in std_logic_vector(3 downto 0);
                    A      : in std_logic_vector(31 downto 0);
                    B      : in std_logic_vector(31 downto 0);
                    Answer : in std_logic_vector(31 downto 0)) is
      variable ZeroAnswer : std_logic;
    begin
      OperandA   <= A;
      OperandB   <= B;
      AluControl <= Op;
      OpName     <= Name(Op);
      Expected   <= Answer;
      wait for Delay;
      TestCount := TestCount + 1;

      if Answer = x"00000000" then
        ZeroAnswer := '1';
      else
        ZeroAnswer := '0';
      end if;

      if Result /= Answer then
        ErrorCount := ErrorCount + 1;
        report Name(Op) & " " & Hex(A) & ", " & Hex(B) & ": got " &
               Hex(Result) & ", expected " & Hex(Answer) severity error;
      elsif Zero /= ZeroAnswer then
        ErrorCount := ErrorCount + 1;
        report Name(Op) & " " & Hex(A) & ", " & Hex(B) & ": Zero = " &
               std_logic'image(Zero) & ", expected " &
               std_logic'image(ZeroAnswer) severity error;
      end if;
    end procedure;

  begin

    -- hand picked cases
    -- add
    Check(AluAdd,  x"00000005", x"00000007", x"0000000C");
    Check(AluAdd,  x"FFFFFFFF", x"00000001", x"00000000");
    Check(AluAdd,  x"7FFFFFFF", x"00000001", x"80000000");
    Check(AluAdd,  x"12345678", x"FFFFF800", x"12344E78");
    -- sub
    Check(AluSub,  x"0000000A", x"00000003", x"00000007");
    Check(AluSub,  x"00000003", x"0000000A", x"FFFFFFF9");
    Check(AluSub,  x"00000000", x"00000001", x"FFFFFFFF");
    Check(AluSub,  x"80000000", x"00000001", x"7FFFFFFF");
    Check(AluSub,  x"12345678", x"12345678", x"00000000");
    -- logic
    Check(AluAnd,  x"F0F0F0F0", x"FF00FF00", x"F000F000");
    Check(AluAnd,  x"AAAAAAAA", x"55555555", x"00000000");
    Check(AluOr,   x"F0F0F0F0", x"0F0F0F0F", x"FFFFFFFF");
    Check(AluOr,   x"00000000", x"00000000", x"00000000");
    Check(AluXor,  x"FFFFFFFF", x"12345678", x"EDCBA987");
    Check(AluXor,  x"12345678", x"12345678", x"00000000");
    -- shifts (only b(4:0) is used)
    Check(AluSll,  x"00000001", x"0000001F", x"80000000");
    Check(AluSll,  x"12345678", x"00000021", x"2468ACF0");
    Check(AluSrl,  x"80000000", x"0000001F", x"00000001");
    Check(AluSrl,  x"EDCBA98F", x"00000007", x"01DB9753");
    Check(AluSra,  x"80000000", x"0000001F", x"FFFFFFFF");
    Check(AluSra,  x"EDCBA98F", x"00000007", x"FFDB9753");
    Check(AluSra,  x"7FFFFFFF", x"0000001F", x"00000000");
    Check(AluSra,  x"87654321", x"00000000", x"87654321");
    -- slt / sltu: same operands, different answers
    Check(AluSlt,  x"FFFFFFFF", x"00000001", x"00000001");
    Check(AluSltu, x"FFFFFFFF", x"00000001", x"00000000");
    Check(AluSlt,  x"80000000", x"7FFFFFFF", x"00000001");
    Check(AluSltu, x"80000000", x"7FFFFFFF", x"00000000");
    Check(AluSlt,  x"00000007", x"00000007", x"00000000");
    Check(AluSltu, x"00000007", x"00000007", x"00000000");
    Check(AluSltu, x"00000000", x"00000001", x"00000001");
    -- unused control code must fall through to add
    Check("1111",  x"00000002", x"00000003", x"00000005");

    -- every op on every pair of test values
    for Op in Ops'range loop
      for I in Patterns'range loop
        for J in Patterns'range loop
          Check(Ops(Op), Patterns(I), Patterns(J),
                Model(Ops(Op), Patterns(I), Patterns(J)));
        end loop;
      end loop;
    end loop;

    if ErrorCount = 0 then
      report "tb_alu: ALL " & integer'image(TestCount) & " TESTS PASSED" severity note;
    else
      report "tb_alu: " & integer'image(ErrorCount) & " of " &
             integer'image(TestCount) & " TESTS FAILED" severity error;
    end if;
    wait;
  end process;

end Behavior;
