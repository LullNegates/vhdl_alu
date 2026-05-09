library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity alu2_tb is
end entity alu2_tb;

architecture sim of alu2_tb is

  component alu2 is
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
  end component;

  signal a      : std_logic_vector(7 downto 0) := (others => '0');
  signal b      : std_logic_vector(7 downto 0) := (others => '0');
  signal opcode : std_logic_vector(2 downto 0) := (others => '0');
  signal result : std_logic_vector(7 downto 0);
  signal c, z, n, v : std_logic;

  constant SETTLE : time := 20 ns;

begin

  dut : alu2
    port map (
      a      => a,
      b      => b,
      opcode => opcode,
      result => result,
      c      => c,
      z      => z,
      n      => n,
      v      => v
    );

  stim : process
  begin

    -- ADD normal: 0x0F + 0x01 = 0x10, no flags
    a <= x"0F"; b <= x"01"; opcode <= "000"; wait for SETTLE;
    assert result = x"10" and c = '0' and z = '0' and n = '0' and v = '0'
      report "FAIL ADD normal" severity failure;

    -- ADD unsigned overflow: 0xFF + 0x01 = 0x00, C=1, Z=1
    a <= x"FF"; b <= x"01"; opcode <= "000"; wait for SETTLE;
    assert result = x"00" and c = '1' and z = '1' and n = '0' and v = '0'
      report "FAIL ADD unsigned overflow" severity failure;

    -- ADD signed overflow: 0x7F + 0x01 = 0x80, N=1, V=1
    a <= x"7F"; b <= x"01"; opcode <= "000"; wait for SETTLE;
    assert result = x"80" and c = '0' and z = '0' and n = '1' and v = '1'
      report "FAIL ADD signed overflow" severity failure;

    -- SUB normal: 0x10 - 0x01 = 0x0F, no flags
    a <= x"10"; b <= x"01"; opcode <= "001"; wait for SETTLE;
    assert result = x"0F" and c = '0' and z = '0' and n = '0' and v = '0'
      report "FAIL SUB normal" severity failure;

    -- SUB borrow: 0x00 - 0x01 = 0xFF, C=1, N=1
    a <= x"00"; b <= x"01"; opcode <= "001"; wait for SETTLE;
    assert result = x"FF" and c = '1' and z = '0' and n = '1' and v = '0'
      report "FAIL SUB borrow" severity failure;

    -- SUB signed overflow: 0x80 - 0x01 = 0x7F, V=1
    a <= x"80"; b <= x"01"; opcode <= "001"; wait for SETTLE;
    assert result = x"7F" and c = '0' and z = '0' and n = '0' and v = '1'
      report "FAIL SUB signed overflow" severity failure;

    -- AND: 0xAA and 0x0F = 0x0A
    a <= x"AA"; b <= x"0F"; opcode <= "010"; wait for SETTLE;
    assert result = x"0A" and c = '0' and z = '0' and n = '0' and v = '0'
      report "FAIL AND" severity failure;

    -- AND N=1: 0xFF and 0xFF = 0xFF
    a <= x"FF"; b <= x"FF"; opcode <= "010"; wait for SETTLE;
    assert result = x"FF" and c = '0' and z = '0' and n = '1' and v = '0'
      report "FAIL AND N=1" severity failure;

    -- OR N=1: 0xA0 or 0x0F = 0xAF
    a <= x"A0"; b <= x"0F"; opcode <= "011"; wait for SETTLE;
    assert result = x"AF" and c = '0' and z = '0' and n = '1' and v = '0'
      report "FAIL OR" severity failure;

    -- XOR N=1: 0xFF xor 0x0F = 0xF0
    a <= x"FF"; b <= x"0F"; opcode <= "100"; wait for SETTLE;
    assert result = x"F0" and c = '0' and z = '0' and n = '1' and v = '0'
      report "FAIL XOR N=1" severity failure;

    -- XOR Z=1: 0xFF xor 0xFF = 0x00
    a <= x"FF"; b <= x"FF"; opcode <= "100"; wait for SETTLE;
    assert result = x"00" and c = '0' and z = '1' and n = '0' and v = '0'
      report "FAIL XOR Z=1" severity failure;

    -- NOT: not 0xAA = 0x55
    a <= x"AA"; b <= x"00"; opcode <= "101"; wait for SETTLE;
    assert result = x"55" and c = '0' and z = '0' and n = '0' and v = '0'
      report "FAIL NOT" severity failure;

    -- NOT Z=1: not 0xFF = 0x00
    a <= x"FF"; b <= x"00"; opcode <= "101"; wait for SETTLE;
    assert result = x"00" and c = '0' and z = '1' and n = '0' and v = '0'
      report "FAIL NOT Z=1" severity failure;

    -- SHL MSB lost, Z=1: 0x80 << 1 = 0x00
    a <= x"80"; b <= x"00"; opcode <= "110"; wait for SETTLE;
    assert result = x"00" and c = '0' and z = '1' and n = '0' and v = '0'
      report "FAIL SHL Z=1" severity failure;

    -- SHR LSB lost, Z=1: 0x01 >> 1 = 0x00
    a <= x"01"; b <= x"00"; opcode <= "111"; wait for SETTLE;
    assert result = x"00" and c = '0' and z = '1' and n = '0' and v = '0'
      report "FAIL SHR Z=1" severity failure;

    report "Simulation complete -- all assertions passed";
    wait;
  end process stim;

end architecture sim;
