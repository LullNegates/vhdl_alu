library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity alu1_tb is
end entity alu1_tb;

architecture sim of alu1_tb is

  component alu1 is
    port (
      a      : in  std_logic_vector(7 downto 0);
      b      : in  std_logic_vector(7 downto 0);
      opcode : in  std_logic_vector(2 downto 0);
      result : out std_logic_vector(7 downto 0);
      carry  : out std_logic
    );
  end component;

  signal a      : std_logic_vector(7 downto 0) := (others => '0');
  signal b      : std_logic_vector(7 downto 0) := (others => '0');
  signal opcode : std_logic_vector(2 downto 0) := (others => '0');
  signal result : std_logic_vector(7 downto 0);
  signal carry  : std_logic;

  constant SETTLE : time := 20 ns;

begin

  dut : alu1
    port map (
      a      => a,
      b      => b,
      opcode => opcode,
      result => result,
      carry  => carry
    );

  stim : process
  begin

    -- ADD: 0x0F + 0x01 = 0x10, no carry
    a <= x"0F"; b <= x"01"; opcode <= "000"; wait for SETTLE;
    assert result = x"10" and carry = '0'
      report "FAIL ADD normal" severity failure;

    -- ADD: 0xFF + 0x01 = 0x00, carry = 1
    a <= x"FF"; b <= x"01"; opcode <= "000"; wait for SETTLE;
    assert result = x"00" and carry = '1'
      report "FAIL ADD overflow" severity failure;

    -- SUB: 0x10 - 0x01 = 0x0F, no borrow
    a <= x"10"; b <= x"01"; opcode <= "001"; wait for SETTLE;
    assert result = x"0F" and carry = '0'
      report "FAIL SUB normal" severity failure;

    -- SUB: 0x00 - 0x01 = 0xFF, borrow = 1
    a <= x"00"; b <= x"01"; opcode <= "001"; wait for SETTLE;
    assert result = x"FF" and carry = '1'
      report "FAIL SUB underflow" severity failure;

    -- AND: 0xAA and 0x0F = 0x0A
    a <= x"AA"; b <= x"0F"; opcode <= "010"; wait for SETTLE;
    assert result = x"0A" and carry = '0'
      report "FAIL AND" severity failure;

    -- OR: 0xA0 or 0x0F = 0xAF
    a <= x"A0"; b <= x"0F"; opcode <= "011"; wait for SETTLE;
    assert result = x"AF" and carry = '0'
      report "FAIL OR" severity failure;

    -- XOR: 0xFF xor 0x0F = 0xF0
    a <= x"FF"; b <= x"0F"; opcode <= "100"; wait for SETTLE;
    assert result = x"F0" and carry = '0'
      report "FAIL XOR" severity failure;

    -- NOT: not 0xAA = 0x55
    a <= x"AA"; b <= x"00"; opcode <= "101"; wait for SETTLE;
    assert result = x"55" and carry = '0'
      report "FAIL NOT" severity failure;

    -- SHL: 0x01 << 1 = 0x02
    a <= x"01"; b <= x"00"; opcode <= "110"; wait for SETTLE;
    assert result = x"02" and carry = '0'
      report "FAIL SHL" severity failure;

    -- SHR: 0x80 >> 1 = 0x40
    a <= x"80"; b <= x"00"; opcode <= "111"; wait for SETTLE;
    assert result = x"40" and carry = '0'
      report "FAIL SHR" severity failure;

    report "Simulation complete -- all assertions passed";
    wait;
  end process stim;

end architecture sim;
