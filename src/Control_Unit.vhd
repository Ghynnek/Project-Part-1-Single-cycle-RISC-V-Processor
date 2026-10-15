library IEEE;
use IEEE.std_logic_1164.all;

entity control_unit is
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
end entity;

architecture dataflow of control_unit is

    signal opcode : std_logic_vector(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal funct7 : std_logic_vector(6 downto 0);

    signal is_rtype  : std_logic;
    signal is_itype  : std_logic;
    signal is_load   : std_logic;
    signal is_store  : std_logic;
    signal is_branch : std_logic;
    signal is_lui    : std_logic;
    signal is_auipc  : std_logic;
    signal is_jal    : std_logic;
    signal is_jalr   : std_logic;

begin

    opcode <= instruction(6 downto 0);
    funct3 <= instruction(14 downto 12);
    funct7 <= instruction(31 downto 25);

    is_rtype  <= '1' when opcode = "0110011" else '0';
    is_itype  <= '1' when opcode = "0010011" else '0';
    is_load   <= '1' when opcode = "0000011" else '0';
    is_store  <= '1' when opcode = "0100011" else '0';
    is_branch <= '1' when opcode = "1100011" else '0';
    is_lui    <= '1' when opcode = "0110111" else '0';
    is_auipc  <= '1' when opcode = "0010111" else '0';
    is_jal    <= '1' when opcode = "1101111" else '0';
    is_jalr   <= '1' when opcode = "1100111" else '0';

    RegWrite <= '1' when
                    is_rtype = '1' or
                    is_itype = '1' or
                    is_load  = '1' or
                    is_lui   = '1' or
                    is_auipc = '1' or
                    is_jal   = '1' or
                    is_jalr  = '1'
                else '0';

    MemWrite <= is_store;
    MemRead  <= is_load;
    ALUSrc   <= '1' when
                    is_itype = '1' or
                    is_load  = '1' or
                    is_store = '1' or
                    is_jalr  = '1' or
                    is_lui   = '1' or
                    is_auipc = '1'
                else '0';
    MemToReg <= is_load;

-- PC/fetch controls.
    Branch  <= is_branch;
    Jump    <= is_jal;
    JumpReg <= is_jalr;
    LUI     <= is_lui;
    -- 000 = I-type, 001 = S-type, 010 = B-type,
    -- 011 = U-type, 100 = J-type.
    ImmSrc <= "001" when is_store  = '1' else
              "010" when is_branch = '1' else
              "011" when is_lui    = '1' or is_auipc = '1' else
              "100" when is_jal    = '1' else
              "000";
    -- 0000 add, 0001 sub, 0010 and, 0011 or, 0100 xor,
    -- 0101 sll, 0110 srl, 0111 sra, 1000 slt, 1001 sltu.
    -- Loads/stores intentionally fall through to add for address calculation.
    ALUControl <= "0001" when is_branch = '1' and (funct3 = "000" or funct3 = "001") else
                  "1000" when is_branch = '1' and (funct3 = "100" or funct3 = "101") else
                  "1001" when is_branch = '1' and (funct3 = "110" or funct3 = "111") else
                  "0001" when is_rtype = '1' and funct3 = "000" and funct7 = "0100000" else -- For sub funct7 is "0100000" ALUControl = "0001" (subtract). For add, funct7 is "0000000", falls through "0000" (add)
                  "0101" when (is_rtype = '1' or is_itype = '1') and funct3 = "001" else
                  "0111" when (is_rtype = '1' or is_itype = '1') and funct3 = "101" and funct7 = "0100000" else
                  "0110" when (is_rtype = '1' or is_itype = '1') and funct3 = "101" else
                  "0100" when (is_rtype = '1' or is_itype = '1') and funct3 = "100" else
                  "0011" when (is_rtype = '1' or is_itype = '1') and funct3 = "110" else
                  "0010" when (is_rtype = '1' or is_itype = '1') and funct3 = "111" else
                  "1000" when (is_rtype = '1' or is_itype = '1') and funct3 = "010" else
                  "1001" when (is_rtype = '1' or is_itype = '1') and funct3 = "011" else
                  "0000";

end architecture;

