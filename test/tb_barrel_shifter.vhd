-- tb_barrel_shifter.vhd
-- Author: Alex Anderson (Team E_08)
-- Testbench for the barrel shifter.
-- Checks some hand picked shifts, then every shift amount 0-31 for
-- sll, srl and sra on a list of test values.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture Behavior of tb_barrel_shifter is

  constant Delay : time := 10 ns;

  signal DataIn     : std_logic_vector(31 downto 0) := (others => '0');
  signal ShiftAmt   : std_logic_vector(4 downto 0)  := (others => '0');
  signal ShiftRight : std_logic := '0';
  signal Arithmetic : std_logic := '0';
  signal DataOut    : std_logic_vector(31 downto 0);
  signal Expected   : std_logic_vector(31 downto 0) := (others => '0');

  type PatternArray is array (natural range <>) of std_logic_vector(31 downto 0);
  constant Patterns : PatternArray := (
    x"80000000", x"00000001", x"FFFFFFFF", x"00000000", x"7FFFFFFF",
    x"AAAAAAAA", x"55555555", x"12345678", x"87654321");

  -- 32-bit value to hex text for error messages (works without VHDL-2008).
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

begin

  DUT: entity work.barrel_shifter
    port map(
      data_in     => DataIn,
      shamt       => ShiftAmt,
      shift_right => ShiftRight,
      arithmetic  => Arithmetic,
      data_out    => DataOut
    );

  TestProcess: process
    variable ErrorCount : integer := 0;
    variable TestCount  : integer := 0;

    -- Mode: "sll", "srl" or "sra"
    procedure Check(Data   : in std_logic_vector(31 downto 0);
                    Amount : in integer;
                    Mode   : in string;
                    Arith  : in std_logic;
                    Answer : in std_logic_vector(31 downto 0)) is
    begin
      DataIn   <= Data;
      ShiftAmt <= std_logic_vector(to_unsigned(Amount, 5));
      if Mode = "sll" then
        ShiftRight <= '0';
      else
        ShiftRight <= '1';
      end if;
      Arithmetic <= Arith;
      Expected   <= Answer;
      wait for Delay;
      TestCount := TestCount + 1;
      if DataOut /= Answer then
        ErrorCount := ErrorCount + 1;
        report Mode & " by " & integer'image(Amount) & " failed for input " &
               Hex(Data) & ": got " & Hex(DataOut) &
               ", expected " & Hex(Answer) severity error;
      end if;
    end procedure;

    variable Pattern : std_logic_vector(31 downto 0);
  begin

    -- 1. Hand-picked cases
    Check(x"00000001",  0, "sll", '0', x"00000001");   -- shift by 0 is a pass-through
    Check(x"00000001",  1, "sll", '0', x"00000002");
    Check(x"00000001", 31, "sll", '0', x"80000000");   -- max shift
    Check(x"12345678",  4, "sll", '0', x"23456780");
    Check(x"12345678", 16, "sll", '0', x"56780000");   -- only the 16 stage
    Check(x"FFFFFFFF", 31, "sll", '0', x"80000000");

    Check(x"80000000",  1, "srl", '0', x"40000000");   -- zero fill
    Check(x"80000000", 31, "srl", '0', x"00000001");
    Check(x"12345678",  4, "srl", '0', x"01234567");
    Check(x"FFFFFFFF", 16, "srl", '0', x"0000FFFF");
    Check(x"F0000000", 28, "srl", '0', x"0000000F");

    Check(x"80000000",  1, "sra", '1', x"C0000000");   -- sign fill
    Check(x"80000000", 31, "sra", '1', x"FFFFFFFF");
    Check(x"7FFFFFFF", 31, "sra", '1', x"00000000");   -- positive, zero fill
    Check(x"87654321",  4, "sra", '1', x"F8765432");
    Check(x"87654321",  0, "sra", '1', x"87654321");
    Check(x"12345678",  8, "sra", '1', x"00123456");

    -- 2. Every shift amount, every pattern
    for P in Patterns'range loop
      Pattern := Patterns(P);
      for Amount in 0 to 31 loop
        Check(Pattern, Amount, "sll", '0',
              std_logic_vector(shift_left(unsigned(Pattern), Amount)));
        Check(Pattern, Amount, "srl", '0',
              std_logic_vector(shift_right(unsigned(Pattern), Amount)));
        Check(Pattern, Amount, "sra", '1',
              std_logic_vector(shift_right(signed(Pattern), Amount)));
      end loop;
    end loop;

    -- 3. Arithmetic must not affect left shifts
    for Amount in 0 to 31 loop
      Check(x"87654321", Amount, "sll", '1',
            std_logic_vector(shift_left(unsigned(std_logic_vector'(x"87654321")), Amount)));
    end loop;

    if ErrorCount = 0 then
      report "tb_barrel_shifter: ALL " & integer'image(TestCount) & " TESTS PASSED" severity note;
    else
      report "tb_barrel_shifter: " & integer'image(ErrorCount) & " of " &
             integer'image(TestCount) & " TESTS FAILED" severity error;
    end if;
    wait;
  end process;

end Behavior;
