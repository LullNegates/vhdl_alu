library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity alu1 is
  port (
    a      : in  std_logic_vector(7 downto 0);
    b      : in  std_logic_vector(7 downto 0);
    opcode : in  std_logic_vector(2 downto 0);
    result : out std_logic_vector(7 downto 0);
    carry  : out std_logic
  );
end entity alu1;

-- Pure dataflow architecture — Maximale Nebenlaeufikeit (G5).
-- Every operation is computed simultaneously as a concurrent signal
-- assignment. A with/select mux picks the result. No process blocks.
architecture rtl of alu1 is

  signal res_add : std_logic_vector(8 downto 0);
  signal res_sub : std_logic_vector(8 downto 0);
  signal res_and : std_logic_vector(7 downto 0);
  signal res_or  : std_logic_vector(7 downto 0);
  signal res_xor : std_logic_vector(7 downto 0);
  signal res_not : std_logic_vector(7 downto 0);
  signal res_shl : std_logic_vector(7 downto 0);
  signal res_shr : std_logic_vector(7 downto 0);

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

  -- Result mux: opcode selects from pre-computed results
  with opcode select result <=
    res_add(7 downto 0) when "000",  -- ADD
    res_sub(7 downto 0) when "001",  -- SUB
    res_and             when "010",  -- AND
    res_or              when "011",  -- OR
    res_xor             when "100",  -- XOR
    res_not             when "101",  -- NOT a
    res_shl             when "110",  -- SHL
    res_shr             when "111",  -- SHR
    (others => '0')     when others;

  -- Carry: meaningful only for ADD (overflow) and SUB (borrow)
  with opcode select carry <=
    res_add(8) when "000",
    res_sub(8) when "001",
    '0'        when others;

end architecture rtl;
