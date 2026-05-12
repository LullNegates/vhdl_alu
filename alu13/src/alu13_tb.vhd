library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ASALU_structural_v2_tb is
end entity ASALU_structural_v2_tb;

architecture sim of ASALU_structural_v2_tb is

  component ASALU is
    port (
      CLK   : in  std_logic;
      RST   : in  std_logic;
      A     : in  std_logic_vector(7 downto 0);
      B     : in  std_logic_vector(7 downto 0);
      Cmd   : in  std_logic_vector(3 downto 0);
      Flow  : out std_logic_vector(7 downto 0);
      FHigh : out std_logic_vector(7 downto 0);
      Cout  : out std_logic;
      Equal : out std_logic;
      OV    : out std_logic;
      Sign  : out std_logic;
      CB    : out std_logic;
      Ready : out std_logic;
      CAN   : out std_logic
    );
  end component;

  signal CLK   : std_logic := '0';
  signal RST   : std_logic := '0';
  signal A     : std_logic_vector(7 downto 0) := (others => '0');
  signal B     : std_logic_vector(7 downto 0) := (others => '0');
  signal Cmd   : std_logic_vector(3 downto 0) := (others => '0');
  signal Flow  : std_logic_vector(7 downto 0);
  signal FHigh : std_logic_vector(7 downto 0);
  signal Cout  : std_logic;
  signal Equal : std_logic;
  signal OV    : std_logic;
  signal Sign  : std_logic;
  signal CB    : std_logic;
  signal Ready : std_logic;
  signal CAN   : std_logic;

  -- CAN_EXPECTED: 19 header bits (all-zero, 2.0A default) + 0xFF + 0xAA
  constant CAN_EXPECTED : std_logic_vector(34 downto 0) :=
    "0000000000000000000" & "11111111" & "10101010";

begin

  dut : ASALU
    port map (
      CLK => CLK, RST => RST, A => A, B => B, Cmd => Cmd,
      Flow => Flow, FHigh => FHigh, Cout => Cout, Equal => Equal,
      OV => OV, Sign => Sign, CB => CB, Ready => Ready, CAN => CAN
    );

  clk_proc : process
  begin
    CLK <= '0'; wait for 5 ns;
    CLK <= '1'; wait for 5 ns;
  end process;

  stim : process
  begin
    RST <= '1';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '0';
    wait until rising_edge(CLK);

    -- ---- 0000: ADD ----
    A <= x"0F"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"10" and FHigh = x"00" and Cout = '0' and OV = '0' and Sign = '0'
      report "FAIL 0000 ADD normal" severity failure;

    A <= x"FF"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1' and OV = '0'
      report "FAIL 0000 ADD carry" severity failure;

    A <= x"7F"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and Cout = '0' and OV = '1' and Sign = '1'
      report "FAIL 0000 ADD signed OV" severity failure;

    -- ---- 0001: SUB ----
    A <= x"10"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0F" and FHigh = x"00" and Cout = '0' and OV = '0' and Sign = '0'
      report "FAIL 0001 SUB normal" severity failure;

    A <= x"00"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"FF" and Cout = '1' and Sign = '1'
      report "FAIL 0001 SUB underflow" severity failure;

    A <= x"80"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"7F" and OV = '1'
      report "FAIL 0001 SUB signed OV" severity failure;

    -- ---- 0010: MUL2 = (A+B)*2  [ALU3 semantics: 16-bit result in FHigh:Flow] ----
    A <= x"02"; B <= x"03"; Cmd <= "0010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0A" and FHigh = x"00" and Cout = '0'
      report "FAIL 0010 MUL2 normal" severity failure;

    -- (0x40+0x40)*2 = 0x100: overflow into FHigh
    A <= x"40"; B <= x"40"; Cmd <= "0010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and FHigh = x"01" and Cout = '0'
      report "FAIL 0010 MUL2 overflow" severity failure;

    -- ---- 0011: MUL4 = (A+B)*4  [ALU3 semantics: 16-bit result in FHigh:Flow] ----
    A <= x"02"; B <= x"02"; Cmd <= "0011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"10" and FHigh = x"00" and Cout = '0'
      report "FAIL 0011 MUL4 normal" severity failure;

    -- (0x20+0x20)*4 = 0x100: overflow into FHigh
    A <= x"20"; B <= x"20"; Cmd <= "0011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and FHigh = x"01" and Cout = '0'
      report "FAIL 0011 MUL4 overflow" severity failure;

    -- ---- 0100: NEG  [ALU3 semantics: bitwise NOT, not two's complement] ----
    -- NOT(0xAA) = 0x55, MSB=0 -> Cout=0, Sign=0
    A <= x"AA"; B <= x"00"; Cmd <= "0100";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"55" and FHigh = x"00" and Cout = '0' and Sign = '0'
      report "FAIL 0100 NEG (NOT 0xAA)" severity failure;

    -- NOT(0x80) = 0x7F, MSB=0 -> Cout=0, Sign=0
    A <= x"80"; B <= x"00"; Cmd <= "0100";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"7F" and Cout = '0' and Sign = '0'
      report "FAIL 0100 NEG (NOT 0x80)" severity failure;

    -- ---- 0101: SLL ----
    A <= x"01"; B <= x"00"; Cmd <= "0101";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"02" and Cout = '0'
      report "FAIL 0101 SLL normal" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "0101";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0101 SLL carry" severity failure;

    -- ---- 0110: SLR ----
    A <= x"80"; B <= x"00"; Cmd <= "0110";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"40" and Cout = '0' and Sign = '0'
      report "FAIL 0110 SLR normal" severity failure;

    A <= x"01"; B <= x"00"; Cmd <= "0110";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0110 SLR carry" severity failure;

    -- ---- 0111: RLL ----
    A <= x"80"; B <= x"00"; Cmd <= "0111";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"01" and FHigh = x"00"
      report "FAIL 0111 RLL wrap" severity failure;

    A <= x"01"; B <= x"00"; Cmd <= "0111";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"02"
      report "FAIL 0111 RLL normal" severity failure;

    -- ---- 1000: RLR ----
    A <= x"01"; B <= x"00"; Cmd <= "1000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and FHigh = x"00"
      report "FAIL 1000 RLR wrap" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "1000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"40"
      report "FAIL 1000 RLR normal" severity failure;

    -- ---- 1001: MUL (16-bit) ----
    A <= x"03"; B <= x"05"; Cmd <= "1001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0F" and FHigh = x"00" and Sign = '0'
      report "FAIL 1001 MUL small" severity failure;

    -- ALU3 mul.vhd: sign <= '0' hardcoded (ALU1 drove sign from product MSB)
    A <= x"FF"; B <= x"FF"; Cmd <= "1001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"01" and FHigh = x"FE"
      report "FAIL 1001 MUL large" severity failure;

    -- ---- 1010: NAND ----
    A <= x"FF"; B <= x"FF"; Cmd <= "1010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and FHigh = x"00"
      report "FAIL 1010 NAND all-ones" severity failure;

    A <= x"AA"; B <= x"55"; Cmd <= "1010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"FF"
      report "FAIL 1010 NAND no-overlap" severity failure;

    -- ---- 1011: XOR ----
    A <= x"FF"; B <= x"0F"; Cmd <= "1011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"F0" and FHigh = x"00"
      report "FAIL 1011 XOR" severity failure;

    A <= x"FF"; B <= x"FF"; Cmd <= "1011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Sign = '0'
      report "FAIL 1011 XOR zero" severity failure;

    -- ---- Equal flag (combinational — no clock edge needed) ----
    A <= x"42"; B <= x"42"; Cmd <= "0000";
    wait for 1 ns;
    assert Equal = '1' report "FAIL Equal A=B" severity failure;

    A <= x"42"; B <= x"43";
    wait for 1 ns;
    assert Equal = '0' report "FAIL Equal A/=B" severity failure;

    -- ---- 1100: WriteRAM + 1101: CRC_MEM ----
    A <= x"FF"; B <= x"00"; Cmd <= "1100";
    wait until rising_edge(CLK); wait for 1 ns;

    A <= x"AA"; B <= x"01"; Cmd <= "1100";
    wait until rising_edge(CLK); wait for 1 ns;

    -- CRC-15 of 0xFF = 0x0095
    A <= x"00"; B <= x"00"; Cmd <= "1101";
    wait until rising_edge(CLK); wait for 1 ns;
    assert CB = '1' and Ready = '0'
      report "FAIL 1101 CRC not started" severity failure;
    wait until Ready = '1'; wait for 1 ns;
    assert Flow = x"95" and FHigh = x"00" and CB = '0'
      report "FAIL 1101 CRC result (expected 0x0095 for 0xFF)" severity failure;

    -- ---- 1110: SendCANData ----
    A <= x"00"; B <= x"01"; Cmd <= "1110";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Ready = '0' report "FAIL 1110 SendCAN not started" severity failure;
    for i in 34 downto 0 loop
      wait until rising_edge(CLK); wait for 1 ns;
      assert CAN = CAN_EXPECTED(i)
        report "FAIL 1110 CAN bit " & integer'image(34 - i) severity failure;
    end loop;
    assert Ready = '1' report "FAIL 1110 SendCAN not done" severity failure;

    report "Simulation complete -- all assertions passed";
    wait;
  end process stim;

end architecture sim;

configuration cfg_structural_v2 of ASALU_structural_v2_tb is
  for sim
    for dut : ASALU use entity work.ASALU(structural_v2); end for;
  end for;
end configuration cfg_structural_v2;
