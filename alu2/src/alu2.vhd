library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity alu2 is
  port (
    a      : in  std_logic_vector(7 downto 0);
    b      : in  std_logic_vector(7 downto 0);
    opcode : in  std_logic_vector(2 downto 0);
    result : out std_logic_vector(7 downto 0);
    c      : out std_logic;
    z      : out std_logic;
    n      : out std_logic;
    v      : out std_logic
  );
end entity alu2;

-- Pure dataflow architecture — Maximale Nebenlaeufikeit (G5).
-- All operations computed simultaneously as concurrent signal assignments.
-- result_i holds the mux output so Z, N, V can read it without a feedback
-- loop on the output port. No process blocks.
architecture rtl of alu2 is

  signal res_add : std_logic_vector(8 downto 0);
  signal res_sub : std_logic_vector(8 downto 0);
  signal res_and : std_logic_vector(7 downto 0);
  signal res_or  : std_logic_vector(7 downto 0);
  signal res_xor : std_logic_vector(7 downto 0);
  signal res_not : std_logic_vector(7 downto 0);
  signal res_shl : std_logic_vector(7 downto 0);
  signal res_shr : std_logic_vector(7 downto 0);
  signal result_i : std_logic_vector(7 downto 0);
  signal ovf_add  : std_logic;
  signal ovf_sub  : std_logic;

begin

  -- All operations computed in parallel (concurrent signal assignments)
  res_add <= std_logic_vector(unsigned('0' & a) + unsigned('0' & b));
  res_sub <= std_logic_vector(unsigned('0' & a) - unsigned('0' & b));
  res_and <= a and b;
  res_or  <= a or  b;
  res_xor <= a xor b;
  res_not <= not a;
  res_shl <= a(6 downto 0) & '0';
  res_shr <= '0' & a(7 downto 1);

  -- Result mux
  with opcode select result_i <=
    res_add(7 downto 0) when "000",
    res_sub(7 downto 0) when "001",
    res_and             when "010",
    res_or              when "011",
    res_xor             when "100",
    res_not             when "101",
    res_shl             when "110",
    res_shr             when "111",
    (others => '0')     when others;

  result <= result_i;

  -- C: carry for ADD, borrow for SUB, '0' otherwise
  with opcode select c <=
    res_add(8) when "000",
    res_sub(8) when "001",
    '0'        when others;

  -- Z: high when result is zero
  z <= '1' when result_i = x"00" else '0';

  -- N: MSB of result (sign bit)
  n <= result_i(7);

  -- V: signed overflow — intermediate signals keep the with/select clean
  ovf_add <= (not a(7) and not b(7) and     result_i(7))
          or (    a(7) and     b(7) and not result_i(7));

  ovf_sub <= (not a(7) and     b(7) and     result_i(7))
          or (    a(7) and not b(7) and not result_i(7));

  with opcode select v <=
    ovf_add when "000",
    ovf_sub when "001",
    '0'     when others;

end architecture rtl;
