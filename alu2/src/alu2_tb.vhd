library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ASALU_structural_tb is
end entity ASALU_structural_tb;

-- 3-stage pipeline timing (latency = 2 clock cycles):
--   Cycle N  : instruction applied at ports → latched into Stage 1 (ID)
--   Cycle N+1: Stage 2 (EX) computes combinationally from Stage 1 register
--              → result latched into Stage 3 (WB)
--   After N+1: outputs valid
--
-- Pattern for single-cycle ops:
--   apply inputs → wait rising_edge (ID latch) → wait rising_edge (WB latch) → assert
--
-- WriteRAM does NOT stall the pipeline (single-cycle mem op).
-- CRC/CAN stall the pipeline via mc_stall during state-machine execution.
-- Equal is combinational from top-level ports — checked with wait for 1 ns only.

architecture sim of ASALU_structural_tb is

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

  -- Phase 0: can_reg_20a(18..0) all-zero (2.0A mode) = 19 bits
  -- Phase 1: mem[0x00]=0xFF + mem[0x01]=0xAA, MSB first = 16 bits
  constant CAN_EXPECTED : std_logic_vector(34 downto 0) :=
    "0000000000000000000" & "11111111" & "10101010";

begin

  dut : ASALU port map (
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
    -- Reset for 2 cycles, then release and let pipeline settle
    RST <= '1';
    wait until rising_edge(CLK);
    wait until rising_edge(CLK);
    RST <= '0';
    wait until rising_edge(CLK);  -- pipeline fill

    -- ================================================================
    -- Single-cycle ops: 2-cycle latency (ID + WB).
    -- Pattern: apply → wait (ID) → wait (WB) → assert
    -- ================================================================

    -- ---- 0000: ADD ----
    A <= x"0F"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"10" and FHigh = x"00" and Cout = '0' and OV = '0' and Sign = '0'
      report "FAIL 0000 ADD normal" severity failure;

    A <= x"FF"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1' and OV = '0'
      report "FAIL 0000 ADD carry" severity failure;

    A <= x"7F"; B <= x"01"; Cmd <= "0000";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and Cout = '0' and OV = '1' and Sign = '1'
      report "FAIL 0000 ADD signed OV" severity failure;

    -- ---- 0001: SUB ----
    A <= x"10"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0F" and FHigh = x"00" and Cout = '0' and OV = '0' and Sign = '0'
      report "FAIL 0001 SUB normal" severity failure;

    A <= x"00"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"FF" and Cout = '1' and Sign = '1'
      report "FAIL 0001 SUB borrow" severity failure;

    A <= x"80"; B <= x"01"; Cmd <= "0001";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"7F" and OV = '1'
      report "FAIL 0001 SUB signed OV" severity failure;

    -- ---- 0010: (A+B)*2 ----
    A <= x"02"; B <= x"03"; Cmd <= "0010";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0A" and FHigh = x"00" and Cout = '0'
      report "FAIL 0010 MUL2 normal" severity failure;

    A <= x"40"; B <= x"40"; Cmd <= "0010";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0010 MUL2 overflow" severity failure;

    -- ---- 0011: (A+B)*4 ----
    A <= x"02"; B <= x"02"; Cmd <= "0011";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"10" and FHigh = x"00" and Cout = '0'
      report "FAIL 0011 MUL4 normal" severity failure;

    A <= x"20"; B <= x"20"; Cmd <= "0011";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0011 MUL4 overflow" severity failure;

    -- ---- 0100: NEG ----
    A <= x"AA"; B <= x"00"; Cmd <= "0100";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"56" and FHigh = x"00" and Cout = '0' and Sign = '0'
      report "FAIL 0100 NEG positive" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "0100";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and Cout = '1' and Sign = '1'
      report "FAIL 0100 NEG sign" severity failure;

    -- ---- 0101: SLL ----
    A <= x"01"; B <= x"00"; Cmd <= "0101";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"02" and Cout = '0'
      report "FAIL 0101 SLL normal" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "0101";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0101 SLL carry" severity failure;

    -- ---- 0110: SLR ----
    A <= x"80"; B <= x"00"; Cmd <= "0110";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"40" and Cout = '0' and Sign = '0'
      report "FAIL 0110 SLR normal" severity failure;

    A <= x"01"; B <= x"00"; Cmd <= "0110";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Cout = '1'
      report "FAIL 0110 SLR carry" severity failure;

    -- ---- 0111: RLL ----
    A <= x"80"; B <= x"00"; Cmd <= "0111";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"01" and FHigh = x"00"
      report "FAIL 0111 RLL wrap" severity failure;

    A <= x"01"; B <= x"00"; Cmd <= "0111";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"02"
      report "FAIL 0111 RLL normal" severity failure;

    -- ---- 1000: RLR ----
    A <= x"01"; B <= x"00"; Cmd <= "1000";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"80" and FHigh = x"00"
      report "FAIL 1000 RLR wrap" severity failure;

    A <= x"80"; B <= x"00"; Cmd <= "1000";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"40"
      report "FAIL 1000 RLR normal" severity failure;

    -- ---- 1001: MUL ----
    A <= x"03"; B <= x"05"; Cmd <= "1001";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"0F" and FHigh = x"00" and Sign = '0'
      report "FAIL 1001 MUL small" severity failure;

    A <= x"FF"; B <= x"FF"; Cmd <= "1001";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"01" and FHigh = x"FE" and Sign = '1'
      report "FAIL 1001 MUL large" severity failure;

    -- ---- 1010: NAND ----
    A <= x"FF"; B <= x"FF"; Cmd <= "1010";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and FHigh = x"00"
      report "FAIL 1010 NAND all-ones" severity failure;

    A <= x"AA"; B <= x"55"; Cmd <= "1010";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"FF"
      report "FAIL 1010 NAND no-overlap" severity failure;

    -- ---- 1011: XOR ----
    A <= x"FF"; B <= x"0F"; Cmd <= "1011";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"F0" and FHigh = x"00"
      report "FAIL 1011 XOR" severity failure;

    A <= x"FF"; B <= x"FF"; Cmd <= "1011";
    wait until rising_edge(CLK);
    wait until rising_edge(CLK); wait for 1 ns;
    assert Flow = x"00" and Sign = '0'
      report "FAIL 1011 XOR zero" severity failure;

    -- ---- Equal (kombinatorisch — kein CLK, direkt von den Ports) ----
    A <= x"42"; B <= x"42"; Cmd <= "0000";
    wait for 1 ns;
    assert Equal = '1' report "FAIL Equal A=B" severity failure;

    A <= x"42"; B <= x"43"; Cmd <= "0000";
    wait for 1 ns;
    assert Equal = '0' report "FAIL Equal A/=B" severity failure;

    -- ================================================================
    -- 1100 WriteRAM + 1101 CRC_MEM
    --
    -- mem_ctrl reads directly from top-level ports (not pipeline registers).
    -- Each WriteRAM completes in 1 cycle. CRC_MEM starts the state machine
    -- immediately on the next edge. Pattern: apply → wait 1 edge → (active).
    -- ================================================================
    A <= x"FF"; B <= x"00"; Cmd <= "1100";           -- WR1: mem[0x00] <- 0xFF
    wait until rising_edge(CLK);                      -- mem_ctrl executes WR1 directly
    A <= x"AA"; B <= x"01"; Cmd <= "1100";           -- WR2: mem[0x01] <- 0xAA
    wait until rising_edge(CLK);                      -- mem_ctrl executes WR2 directly
    A <= x"00"; B <= x"00"; Cmd <= "1101";           -- CRC_MEM over mem[0x00..0x00]
    wait until rising_edge(CLK); wait for 1 ns;       -- mem_ctrl starts CRC, stall=1
    assert CB = '1' and Ready = '0'
      report "FAIL 1101 CRC not started" severity failure;
    wait until Ready = '1'; wait for 1 ns;
    -- Expected CRC-15 of 0xFF: 0x0095
    assert Flow = x"95" and FHigh = x"00" and CB = '0'
      report "FAIL 1101 CRC result (expected 0x0095 for 0xFF)" severity failure;

    -- ================================================================
    -- 1110 SendCANData
    -- mem[0x00]=0xFF, mem[0x01]=0xAA written above.
    -- 1 setup cycle (mem_ctrl starts CAN_SEND immediately from ports).
    -- Then 35 bits serialised (19 header + 8 + 8), 1 bit per cycle.
    -- ================================================================
    A <= x"00"; B <= x"01"; Cmd <= "1110";
    wait until rising_edge(CLK); wait for 1 ns;       -- mem_ctrl starts CAN_SEND
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

configuration cfg_structural of ASALU_structural_tb is
  for sim
    for dut : ASALU use entity work.ASALU(structural); end for;
  end for;
end configuration cfg_structural;
