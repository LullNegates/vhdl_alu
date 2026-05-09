library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================
-- arith_unit: ADD, SUB, (A+B)x2, (A+B)x4, NEG — all concurrent
-- ============================================================
entity arith_unit is
  port (
    A        : in  std_logic_vector(7 downto 0);
    B        : in  std_logic_vector(7 downto 0);
    sum9     : out std_logic_vector(8 downto 0);
    diff9    : out std_logic_vector(8 downto 0);
    res_mul2 : out std_logic_vector(7 downto 0);
    res_mul4 : out std_logic_vector(7 downto 0);
    res_neg  : out std_logic_vector(7 downto 0)
  );
end entity arith_unit;

architecture rtl of arith_unit is
  signal s9 : std_logic_vector(8 downto 0);
begin
  s9       <= std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
  sum9     <= s9;
  diff9    <= std_logic_vector(unsigned('0' & A) - unsigned('0' & B));
  res_mul2 <= s9(6 downto 0) & '0';
  res_mul4 <= s9(5 downto 0) & "00";
  res_neg  <= std_logic_vector(-signed(A));
end architecture rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================
-- mul_unit: 8x8 -> 16-bit unsigned multiplier
-- ============================================================
entity mul_unit is
  port (
    A       : in  std_logic_vector(7 downto 0);
    B       : in  std_logic_vector(7 downto 0);
    product : out std_logic_vector(15 downto 0)
  );
end entity mul_unit;

architecture rtl of mul_unit is
begin
  product <= std_logic_vector(unsigned(A) * unsigned(B));
end architecture rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================
-- shift_unit: SLL, SLR, RLL, RLR — all concurrent
-- ============================================================
entity shift_unit is
  port (
    A       : in  std_logic_vector(7 downto 0);
    res_sll : out std_logic_vector(7 downto 0);
    res_slr : out std_logic_vector(7 downto 0);
    res_rll : out std_logic_vector(7 downto 0);
    res_rlr : out std_logic_vector(7 downto 0)
  );
end entity shift_unit;

architecture rtl of shift_unit is
begin
  res_sll <= A(6 downto 0) & '0';
  res_slr <= '0' & A(7 downto 1);
  res_rll <= A(6 downto 0) & A(7);
  res_rlr <= A(0) & A(7 downto 1);
end architecture rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================
-- logic_unit: NAND, XOR — both concurrent
-- ============================================================
entity logic_unit is
  port (
    A        : in  std_logic_vector(7 downto 0);
    B        : in  std_logic_vector(7 downto 0);
    res_nand : out std_logic_vector(7 downto 0);
    res_xor  : out std_logic_vector(7 downto 0)
  );
end entity logic_unit;

architecture rtl of logic_unit is
begin
  res_nand <= not (A and B);
  res_xor  <= A xor B;
end architecture rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================
-- result_mux: selects Flow/FHigh for single-cycle ops (Cmd 0000-1011)
-- ============================================================
entity result_mux is
  port (
    Cmd       : in  std_logic_vector(3 downto 0);
    sum9      : in  std_logic_vector(8 downto 0);
    diff9     : in  std_logic_vector(8 downto 0);
    res_mul2  : in  std_logic_vector(7 downto 0);
    res_mul4  : in  std_logic_vector(7 downto 0);
    res_neg   : in  std_logic_vector(7 downto 0);
    product   : in  std_logic_vector(15 downto 0);
    res_sll   : in  std_logic_vector(7 downto 0);
    res_slr   : in  std_logic_vector(7 downto 0);
    res_rll   : in  std_logic_vector(7 downto 0);
    res_rlr   : in  std_logic_vector(7 downto 0);
    res_nand  : in  std_logic_vector(7 downto 0);
    res_xor   : in  std_logic_vector(7 downto 0);
    flow_out  : out std_logic_vector(7 downto 0);
    fhigh_out : out std_logic_vector(7 downto 0)
  );
end entity result_mux;

architecture rtl of result_mux is
begin
  with Cmd select flow_out <=
    sum9(7 downto 0)    when "0000",
    diff9(7 downto 0)   when "0001",
    res_mul2            when "0010",
    res_mul4            when "0011",
    res_neg             when "0100",
    res_sll             when "0101",
    res_slr             when "0110",
    res_rll             when "0111",
    res_rlr             when "1000",
    product(7 downto 0) when "1001",
    res_nand            when "1010",
    res_xor             when "1011",
    (others => '0')     when others;

  with Cmd select fhigh_out <=
    product(15 downto 8) when "1001",
    (others => '0')      when others;
end architecture rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================
-- flag_gen: Cout, OV, Sign for single-cycle ops (Cmd 0000-1011)
-- ============================================================
entity flag_gen is
  port (
    Cmd      : in  std_logic_vector(3 downto 0);
    A        : in  std_logic_vector(7 downto 0);
    B        : in  std_logic_vector(7 downto 0);
    sum9     : in  std_logic_vector(8 downto 0);
    diff9    : in  std_logic_vector(8 downto 0);
    res_neg  : in  std_logic_vector(7 downto 0);
    product  : in  std_logic_vector(15 downto 0);
    flow_out : in  std_logic_vector(7 downto 0);
    cout_out : out std_logic;
    ov_out   : out std_logic;
    sign_out : out std_logic
  );
end entity flag_gen;

architecture rtl of flag_gen is
begin
  cout_out <=
    sum9(8)                       when Cmd = "0000" else
    diff9(8)                      when Cmd = "0001" else
    sum9(8) or sum9(7)            when Cmd = "0010" else
    sum9(8) or sum9(7) or sum9(6) when Cmd = "0011" else
    res_neg(7)                    when Cmd = "0100" else
    A(7)                          when Cmd = "0101" else
    A(0)                          when Cmd = "0110" else
    '0';

  ov_out <=
    ((not A(7)) and (not B(7)) and sum9(7)) or (A(7) and B(7) and (not sum9(7)))
      when Cmd = "0000" else
    ((not A(7)) and B(7) and diff9(7)) or (A(7) and (not B(7)) and (not diff9(7)))
      when Cmd = "0001" else
    '0';

  sign_out <=
    '0'         when Cmd = "0110" else
    product(15) when Cmd = "1001" else
    flow_out(7);
end architecture rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================
-- mem_ctrl: RAM 256x8, CRC-15 engine, CAN serializer
-- Handles Cmd 1100 (WriteRAM), 1101 (CRC_MEM), 1110 (SendCANData).
-- CAN frame header registers: can_reg_20a (19-bit, 2.0A),
--                              can_reg_20b (39-bit, 2.0B).
-- Registers are initialized directly in simulation (no write command).
-- mc_active: '1' whenever this unit drives the top-level outputs.
-- ============================================================
entity mem_ctrl is
  port (
    CLK       : in  std_logic;
    A         : in  std_logic_vector(7 downto 0);
    B         : in  std_logic_vector(7 downto 0);
    Cmd       : in  std_logic_vector(3 downto 0);
    mc_flow   : out std_logic_vector(7 downto 0);
    mc_fhigh  : out std_logic_vector(7 downto 0);
    mc_cout   : out std_logic;
    mc_ov     : out std_logic;
    mc_sign   : out std_logic;
    mc_cb     : out std_logic;
    mc_ready  : out std_logic;
    mc_can    : out std_logic;
    mc_active : out std_logic
  );
end entity mem_ctrl;

architecture rtl of mem_ctrl is

  type ram_t is array(0 to 255) of std_logic_vector(7 downto 0);
  signal mem : ram_t := (others => (others => '0'));

  type state_t is (IDLE, CRC_COMPUTE, CAN_SEND);
  signal state : state_t := IDLE;

  signal crc_reg  : std_logic_vector(14 downto 0) := (others => '0');
  signal crc_addr : unsigned(7 downto 0);
  signal crc_end  : unsigned(7 downto 0);

  signal can_reg_20a : std_logic_vector(18 downto 0) := (others => '0');
  signal can_reg_20b : std_logic_vector(38 downto 0) := (others => '0');
  signal can_mode    : std_logic := '0';  -- '0' = 2.0A (19-bit), '1' = 2.0B (39-bit)

  signal can_addr    : unsigned(7 downto 0);
  signal can_end     : unsigned(7 downto 0);
  signal can_byte    : std_logic_vector(7 downto 0);
  signal can_bit     : integer range 0 to 7;
  signal can_phase   : std_logic;           -- '0' = header reg, '1' = mem bytes
  signal can_reg_ptr : integer range 0 to 38;

begin

  mc_active <= '1' when (state /= IDLE) or
                        (Cmd = "1100" or Cmd = "1101" or Cmd = "1110")
               else '0';

  process(CLK)
    variable crc_v     : std_logic_vector(14 downto 0);
    variable crc_b     : std_logic_vector(7 downto 0);
    variable crc_bit_v : std_logic;
  begin
    if rising_edge(CLK) then
      mc_cb    <= '0';
      mc_ready <= '1';
      mc_can   <= '0';
      mc_cout  <= '0';
      mc_ov    <= '0';
      mc_sign  <= '0';
      mc_flow  <= (others => '0');
      mc_fhigh <= (others => '0');

      case state is

        when IDLE =>
          case Cmd is
            when "1100" =>  -- WriteRAM: A -> mem[B]
              mem(to_integer(unsigned(B))) <= A;
              mc_flow <= A;

            when "1101" =>  -- CRC_MEM(A,B): CAN-CRC-15 of mem[A..B]
              crc_reg  <= (others => '0');
              crc_addr <= unsigned(A);
              crc_end  <= unsigned(B);
              mc_cb    <= '1';
              mc_ready <= '0';
              state    <= CRC_COMPUTE;

            when "1110" =>  -- SendCANData(A,B): Reg + mem[A..B] via CAN
              can_addr    <= unsigned(A);
              can_end     <= unsigned(B);
              can_phase   <= '0';
              if can_mode = '0' then
                can_reg_ptr <= 18;
              else
                can_reg_ptr <= 38;
              end if;
              mc_ready    <= '0';
              state       <= CAN_SEND;

            when others => null;
          end case;

        -- CAN CRC-15: x^15+x^14+x^10+x^8+x^7+x^4+x^3+1 = 0x4599, 1 byte/cycle
        when CRC_COMPUTE =>
          mc_cb    <= '1';
          mc_ready <= '0';
          crc_v := crc_reg;
          crc_b := mem(to_integer(crc_addr));
          for i in 7 downto 0 loop
            crc_bit_v := crc_v(14) xor crc_b(i);
            crc_v     := crc_v(13 downto 0) & '0';
            if crc_bit_v = '1' then
              crc_v := crc_v xor "100010110011001";
            end if;
          end loop;
          crc_reg <= crc_v;
          if crc_addr = crc_end then
            mc_flow  <= crc_v(7 downto 0);
            mc_fhigh <= '0' & crc_v(14 downto 8);
            mc_sign  <= crc_v(14);
            mc_cb    <= '0';
            mc_ready <= '1';
            state    <= IDLE;
          else
            crc_addr <= crc_addr + 1;
          end if;

        -- CAN_SEND phase 0: serialize header register (MSB first)
        --          phase 1: serialize mem[A..B] bytes (MSB first)
        when CAN_SEND =>
          mc_ready <= '0';
          if can_phase = '0' then
            if can_mode = '0' then
              mc_can <= can_reg_20a(can_reg_ptr);
            else
              mc_can <= can_reg_20b(can_reg_ptr);
            end if;
            if can_reg_ptr = 0 then
              can_phase <= '1';
              can_byte  <= mem(to_integer(can_addr));
              can_bit   <= 7;
            else
              can_reg_ptr <= can_reg_ptr - 1;
            end if;
          else
            mc_can <= can_byte(can_bit);
            if can_bit = 0 then
              if can_addr = can_end then
                mc_ready <= '1';
                state    <= IDLE;
              else
                can_addr <= can_addr + 1;
                can_byte <= mem(to_integer(can_addr + 1));
                can_bit  <= 7;
              end if;
            else
              can_bit <= can_bit - 1;
            end if;
          end if;

      end case;
    end if;
  end process;

end architecture rtl;


-- ============================================================
-- ASALU — architecture structural (ALU 2, G5: Maximale Nebenlaeufikeit)
-- All single-cycle ops computed simultaneously as sub-entity instances.
-- mem_ctrl handles multi-cycle ops (WriteRAM, CRC_MEM, SendCANData).
-- Output routing: mc_active selects mem_ctrl outputs over combinational.
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ASALU is
  port (
    CLK   : in  std_logic;
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
end entity ASALU;

architecture structural of ASALU is

  component arith_unit is
    port (
      A : in std_logic_vector(7 downto 0); B : in std_logic_vector(7 downto 0);
      sum9 : out std_logic_vector(8 downto 0); diff9 : out std_logic_vector(8 downto 0);
      res_mul2 : out std_logic_vector(7 downto 0); res_mul4 : out std_logic_vector(7 downto 0);
      res_neg : out std_logic_vector(7 downto 0)
    );
  end component;

  component mul_unit is
    port (
      A : in std_logic_vector(7 downto 0); B : in std_logic_vector(7 downto 0);
      product : out std_logic_vector(15 downto 0)
    );
  end component;

  component shift_unit is
    port (
      A : in std_logic_vector(7 downto 0);
      res_sll : out std_logic_vector(7 downto 0); res_slr : out std_logic_vector(7 downto 0);
      res_rll : out std_logic_vector(7 downto 0); res_rlr : out std_logic_vector(7 downto 0)
    );
  end component;

  component logic_unit is
    port (
      A : in std_logic_vector(7 downto 0); B : in std_logic_vector(7 downto 0);
      res_nand : out std_logic_vector(7 downto 0); res_xor : out std_logic_vector(7 downto 0)
    );
  end component;

  component result_mux is
    port (
      Cmd : in std_logic_vector(3 downto 0);
      sum9 : in std_logic_vector(8 downto 0); diff9 : in std_logic_vector(8 downto 0);
      res_mul2 : in std_logic_vector(7 downto 0); res_mul4 : in std_logic_vector(7 downto 0);
      res_neg : in std_logic_vector(7 downto 0); product : in std_logic_vector(15 downto 0);
      res_sll : in std_logic_vector(7 downto 0); res_slr : in std_logic_vector(7 downto 0);
      res_rll : in std_logic_vector(7 downto 0); res_rlr : in std_logic_vector(7 downto 0);
      res_nand : in std_logic_vector(7 downto 0); res_xor : in std_logic_vector(7 downto 0);
      flow_out : out std_logic_vector(7 downto 0); fhigh_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component flag_gen is
    port (
      Cmd : in std_logic_vector(3 downto 0);
      A : in std_logic_vector(7 downto 0); B : in std_logic_vector(7 downto 0);
      sum9 : in std_logic_vector(8 downto 0); diff9 : in std_logic_vector(8 downto 0);
      res_neg : in std_logic_vector(7 downto 0); product : in std_logic_vector(15 downto 0);
      flow_out : in std_logic_vector(7 downto 0);
      cout_out : out std_logic; ov_out : out std_logic; sign_out : out std_logic
    );
  end component;

  component mem_ctrl is
    port (
      CLK : in std_logic; A : in std_logic_vector(7 downto 0); B : in std_logic_vector(7 downto 0);
      Cmd : in std_logic_vector(3 downto 0);
      mc_flow : out std_logic_vector(7 downto 0); mc_fhigh : out std_logic_vector(7 downto 0);
      mc_cout : out std_logic; mc_ov : out std_logic; mc_sign : out std_logic;
      mc_cb : out std_logic; mc_ready : out std_logic; mc_can : out std_logic;
      mc_active : out std_logic
    );
  end component;

  -- Signals from combinational sub-units
  signal s_sum9     : std_logic_vector(8 downto 0);
  signal s_diff9    : std_logic_vector(8 downto 0);
  signal s_res_mul2 : std_logic_vector(7 downto 0);
  signal s_res_mul4 : std_logic_vector(7 downto 0);
  signal s_res_neg  : std_logic_vector(7 downto 0);
  signal s_product  : std_logic_vector(15 downto 0);
  signal s_res_sll  : std_logic_vector(7 downto 0);
  signal s_res_slr  : std_logic_vector(7 downto 0);
  signal s_res_rll  : std_logic_vector(7 downto 0);
  signal s_res_rlr  : std_logic_vector(7 downto 0);
  signal s_res_nand : std_logic_vector(7 downto 0);
  signal s_res_xor  : std_logic_vector(7 downto 0);
  signal s_flow     : std_logic_vector(7 downto 0);
  signal s_fhigh    : std_logic_vector(7 downto 0);
  signal s_cout     : std_logic;
  signal s_ov       : std_logic;
  signal s_sign     : std_logic;

  -- Signals from mem_ctrl
  signal mc_flow    : std_logic_vector(7 downto 0);
  signal mc_fhigh   : std_logic_vector(7 downto 0);
  signal mc_cout    : std_logic;
  signal mc_ov      : std_logic;
  signal mc_sign    : std_logic;
  signal mc_cb      : std_logic;
  signal mc_ready   : std_logic;
  signal mc_can     : std_logic;
  signal mc_active  : std_logic;

begin

  -- Equal: purely combinational, independent of CLK
  Equal <= '1' when A = B else '0';

  -- CB, Ready, CAN always from mem_ctrl (defaults to 0/1/0 for non-memory ops)
  CB    <= mc_cb;
  Ready <= mc_ready;
  CAN   <= mc_can;

  -- mem_ctrl takes priority when active (Cmd 1100-1110 or state machine running)
  Flow  <= mc_flow  when mc_active = '1' else s_flow;
  FHigh <= mc_fhigh when mc_active = '1' else s_fhigh;
  Cout  <= mc_cout  when mc_active = '1' else s_cout;
  OV    <= mc_ov    when mc_active = '1' else s_ov;
  Sign  <= mc_sign  when mc_active = '1' else s_sign;

  u_arith : arith_unit port map (
    A => A, B => B,
    sum9 => s_sum9, diff9 => s_diff9,
    res_mul2 => s_res_mul2, res_mul4 => s_res_mul4, res_neg => s_res_neg
  );

  u_mul : mul_unit port map (
    A => A, B => B, product => s_product
  );

  u_shift : shift_unit port map (
    A => A,
    res_sll => s_res_sll, res_slr => s_res_slr,
    res_rll => s_res_rll, res_rlr => s_res_rlr
  );

  u_logic : logic_unit port map (
    A => A, B => B,
    res_nand => s_res_nand, res_xor => s_res_xor
  );

  u_mux : result_mux port map (
    Cmd => Cmd,
    sum9 => s_sum9, diff9 => s_diff9,
    res_mul2 => s_res_mul2, res_mul4 => s_res_mul4, res_neg => s_res_neg,
    product => s_product,
    res_sll => s_res_sll, res_slr => s_res_slr,
    res_rll => s_res_rll, res_rlr => s_res_rlr,
    res_nand => s_res_nand, res_xor => s_res_xor,
    flow_out => s_flow, fhigh_out => s_fhigh
  );

  u_flags : flag_gen port map (
    Cmd => Cmd, A => A, B => B,
    sum9 => s_sum9, diff9 => s_diff9,
    res_neg => s_res_neg, product => s_product,
    flow_out => s_flow,
    cout_out => s_cout, ov_out => s_ov, sign_out => s_sign
  );

  u_mem : mem_ctrl port map (
    CLK => CLK, A => A, B => B, Cmd => Cmd,
    mc_flow => mc_flow, mc_fhigh => mc_fhigh,
    mc_cout => mc_cout, mc_ov => mc_ov, mc_sign => mc_sign,
    mc_cb => mc_cb, mc_ready => mc_ready,
    mc_can => mc_can, mc_active => mc_active
  );

end architecture structural;
