library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ASALU_behavioral_tb is
end entity ASALU_behavioral_tb;

architecture sim of ASALU_behavioral_tb is


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

  -- Phase 0: can_reg_20a(18..0) all-zero (default, 2.0A mode) = 19 bits
  -- Phase 1: mem[0x00]=0xFF + mem[0x01]=0xAA, each MSB first = 16 bits
  constant CAN_EXPECTED : std_logic_vector(34 downto 0) :=
    "0000000000000000000" & "11111111" & "10101010";

begin

  dut : entity work.ASALU(behavioral)
    port map (
      CLK   => CLK,
      RST   => RST,
      A     => A,
      B     => B,
      Cmd   => Cmd,
      Flow  => Flow,
      FHigh => FHigh,
      Cout  => Cout,
      Equal => Equal,
      OV    => OV,
      Sign  => Sign,
      CB    => CB,
      Ready => Ready,
      CAN   => CAN
    );

  clk_proc : process
  begin
    CLK <= '0'; wait for 5 ns;
    CLK <= '1'; wait for 5 ns;
  end process;

  stim : process
  begin
    -- Reset for 2 cycles, then release
    RST <= '1';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '0';
    wait until rising_edge(CLK);  -- sync

    -- ---- 0000: F = A + B ----
    A <= x"0F"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"10" and FHigh = x"00" and Cout = '0' and OV = '0' and Sign = '0'
      report "FAIL 0000 ADD normal" severity failure;

    -- carry
    A <= x"FF"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1' and OV = '0'
      report "FAIL 0000 ADD overflow" severity failure;

    -- signed overflow: 0x7F + 0x01 = 0x80 -> OV=1, Sign=1
    A <= x"7F"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and Cout = '0' and OV = '1' and Sign = '1'
      report "FAIL 0000 ADD signed OV" severity failure;

    -- ---- 0001: F = A - B ----
    A <= x"10"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0F" and FHigh = x"00" and Cout = '0' and OV = '0' and Sign = '0'
      report "FAIL 0001 SUB normal" severity failure;

    -- borrow
    A <= x"00"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"FF" and Cout = '1' and Sign = '1'
      report "FAIL 0001 SUB underflow" severity failure;

    -- signed overflow: 0x80 - 0x01 = 0x7F -> OV=1
    A <= x"80"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"7F" and OV = '1'
      report "FAIL 0001 SUB signed OV" severity failure;

    -- ---- 0010: F = (A+B) * 2 ----
    A <= x"02"; B <= x"03"; Cmd <= "0010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0A" and FHigh = x"00" and Cout = '0'
      report "FAIL 0010 MUL2 normal" severity failure;

    -- overflow: sum bit7 set -> Cout=1
    A <= x"40"; B <= x"40"; Cmd <= "0010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0010 MUL2 overflow" severity failure;

    -- ---- 0011: F = (A+B) * 4 ----
    A <= x"02"; B <= x"02"; Cmd <= "0011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"10" and FHigh = x"00" and Cout = '0'
      report "FAIL 0011 MUL4 normal" severity failure;

    -- overflow: sum bit6 set -> Cout=1
    A <= x"20"; B <= x"20"; Cmd <= "0011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0011 MUL4 overflow" severity failure;

    -- ---- 0100: F = -A  (Cout = sign) ----
    A <= x"AA"; B <= x"00"; Cmd <= "0100";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"56" and FHigh = x"00" and Cout = '0' and Sign = '0'
      report "FAIL 0100 NEG positive" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "0100";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and Cout = '1' and Sign = '1'
      report "FAIL 0100 NEG sign" severity failure;

    -- ---- 0101: F = sll(A) ----
    A <= x"01"; B <= x"00"; Cmd <= "0101";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"02" and Cout = '0'
      report "FAIL 0101 SLL normal" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "0101";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0101 SLL carry" severity failure;

    -- ---- 0110: F = slr(A) ----
    A <= x"80"; B <= x"00"; Cmd <= "0110";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"40" and Cout = '0' and Sign = '0'
      report "FAIL 0110 SLR normal" severity failure;

    A <= x"01"; B <= x"00"; Cmd <= "0110";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0110 SLR carry" severity failure;

    -- ---- 0111: F = rll(A) ----
    A <= x"80"; B <= x"00"; Cmd <= "0111";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"01" and FHigh = x"00"
      report "FAIL 0111 RLL wrap" severity failure;

    A <= x"01"; B <= x"00"; Cmd <= "0111";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"02"
      report "FAIL 0111 RLL normal" severity failure;

    -- ---- 1000: F = rlr(A) ----
    A <= x"01"; B <= x"00"; Cmd <= "1000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and FHigh = x"00"
      report "FAIL 1000 RLR wrap" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "1000";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"40"
      report "FAIL 1000 RLR normal" severity failure;

    -- ---- 1001: F = A * B (16-bit) ----
    A <= x"03"; B <= x"05"; Cmd <= "1001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0F" and FHigh = x"00" and Sign = '0'
      report "FAIL 1001 MUL small" severity failure;

    -- 0xFF * 0xFF = 0xFE01
    A <= x"FF"; B <= x"FF"; Cmd <= "1001";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"01" and FHigh = x"FE" and Sign = '1'
      report "FAIL 1001 MUL large" severity failure;

    -- ---- 1010: F = NAND(A, B) ----
    A <= x"FF"; B <= x"FF"; Cmd <= "1010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and FHigh = x"00"
      report "FAIL 1010 NAND all-ones" severity failure;

    A <= x"AA"; B <= x"55"; Cmd <= "1010";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"FF"
      report "FAIL 1010 NAND no-overlap" severity failure;

    -- ---- 1011: F = XOR(A, B) ----
    A <= x"FF"; B <= x"0F"; Cmd <= "1011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"F0" and FHigh = x"00"
      report "FAIL 1011 XOR" severity failure;

    A <= x"FF"; B <= x"FF"; Cmd <= "1011";
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Sign = '0'
      report "FAIL 1011 XOR zero" severity failure;

    -- ---- Equal flag (combinational) ----
    A <= x"42"; B <= x"42"; Cmd <= "0000";
    wait for 1 ns;
    assert Equal = '1' report "FAIL Equal A=B" severity failure;

    A <= x"42"; B <= x"43"; Cmd <= "0000";
    wait for 1 ns;
    assert Equal = '0' report "FAIL Equal A/=B" severity failure;

    -- ---- 1100: WriteRAM + 1101: CRC_MEM ----
    -- Write 0xFF to address 0x00
    A <= x"FF"; B <= x"00"; Cmd <= "1100";
    wait until rising_edge(CLK); wait for 1 ns;

    -- Write 0xAA to address 0x01
    A <= x"AA"; B <= x"01"; Cmd <= "1100";
    wait until rising_edge(CLK); wait for 1 ns;

    -- CRC_MEM over Mem[0x00..0x00] (1 byte = 0xFF)
    -- Expected CRC-15: 0x0095 -> Flow=0x95, FHigh=0x00
    A <= x"00"; B <= x"00"; Cmd <= "1101";
    wait until rising_edge(CLK); wait for 1 ns;
    assert CB = '1' and Ready = '0'
      report "FAIL 1101 CRC not started" severity failure;
    wait until Ready = '1'; wait for 1 ns;
    assert Flow = x"95" and FHigh = x"00" and CB = '0'
      report "FAIL 1101 CRC result (expected 0x0095 for 0xFF)" severity failure;

    -- ---- 1111: ToggleCAN (2.0A <-> 2.0B) ----
    Cmd <= "1111"; A <= x"00"; B <= x"00";
    wait until rising_edge(CLK); wait for 1 ns;  -- toggle to 2.0B
    Cmd <= "1111";
    wait until rising_edge(CLK); wait for 1 ns;  -- toggle back to 2.0A
    assert Ready = '1' report "FAIL 1111 ToggleCAN" severity failure;

    -- ---- 1110: SendCANData (bit-by-bit) ----
    -- 35 bits: 19 header (all-zero, 2.0A) + 0xFF + 0xAA, verified per clock
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

