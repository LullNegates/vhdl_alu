library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Architecture structural_v2: ALU3 arithmetic sub-entities + ALU1 CRC/CAN logic.
-- RAM: RAMB4_S8_S8 Xilinx Block RAM via ram component (ALU3/RAM.vhd).
--      Simulation: ISim only (UNISIM primitive, GHDL not supported).
--      CLKA = CLKB = CLK: beide Ports auf der steigenden Flanke.
--      Read-Latenz (1 Takt) ist durch ADDRB-Vorausladung im IDLE-Zustand pipelined:
--      ADDRB = '0'&A im IDLE-Takt (Cmd=1101) -> DOB = mem[A] im ersten CRC_COMPUTE-Takt.
--      CLK_N / BUFG wurden entfernt: ISims UNISIM-Modell von RAMB4_S8_S8 simuliert
--      anti-korrelierte Takte (CLK / NOT CLK) auf Port A/B nicht korrekt.
-- Pipeline: 2-stage arithmetic (Cmd 0x0–0xB).
--   Stage 1 (p1_pipe): sub-entity results + Cmd latched in p1_* registers each cycle.
--   Stage 2 (IDLE mux): p1_cmd selects result → output registers (Flow, FHigh, flags).
--   FSM ops (CRC_MEM, SendCAN, WriteRAM) bypass pipeline — use raw Cmd, latency unchanged.
--   Arithmetic throughput: 1 result/cycle; latency: 2 cycles (testbench updated accordingly).
-- CRC: CAN CRC-15 / ISO 11898, polynomial 0x4599, 1 byte/cycle (variable for-loop).
-- CAN: two-phase serializer (header register MSB-first, then mem[A..B]).
--      ADDRB pre-fetches next byte during current byte serialization -> no inter-byte gap.
--
-- OPEN SEMANTICS (resolve with team before final submission):
--   NEG (0100): bitwise NOT via ALU3 negate.vhd  (NOT A, not two's complement -A)
--   MUL2/MUL4 (0010/0011): 16-bit result in FHigh:Flow via ALU3 sub-entities
--   MUL Sign flag: hardcoded '0' in ALU3 mul.vhd
architecture structural_v2 of ASALU is

  -- ALU3 arithmetic sub-entity components (port names match alu3/*.vhd exactly)
  component add         port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component subtract    port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component add_lls     port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component add_lls_lls port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component negate      port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component lls         port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component lrs         port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component llr         port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component lrr         port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component mul         port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component bit_nand    port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;
  component bit_xor     port(A,B: in std_logic_vector(7 downto 0); f_low,f_high: out std_logic_vector(7 downto 0); c_out,equal,ov,sign: out std_logic); end component;


  -- RAMB4_S8_S8 dual-port block RAM (from alu3/RAM.vhd)
  component ram
    generic(ADDRESSWIDTH : positive := 9; DATAWIDTH : positive := 8);
    port(
      CLKA, CLKB : in  std_logic;
      DIA,  DIB  : in  std_logic_vector(DATAWIDTH-1 downto 0);
      DOA,  DOB  : out std_logic_vector(DATAWIDTH-1 downto 0);
      ADDRA, ADDRB : in std_logic_vector(ADDRESSWIDTH-1 downto 0);
      ENA,  ENB  : in  std_logic;
      RSTA, RSTB : in  std_logic;
      WEA,  WEB  : in  std_logic
    );
  end component;

  -- Sub-entity result buses
  signal add_res_l, sub_res_l, alls_res_l, allls_res_l,
         neg_res_l, lls_res_l, lrs_res_l, llr_res_l, lrr_res_l,
         mul_res_l, nand_res_l, xor_res_l  : std_logic_vector(7 downto 0);
  signal add_res_h, sub_res_h, alls_res_h, allls_res_h,
         neg_res_h, lls_res_h, lrs_res_h, llr_res_h, lrr_res_h,
         mul_res_h, nand_res_h, xor_res_h  : std_logic_vector(7 downto 0);
  signal add_co, sub_co, alls_co, allls_co,
         neg_co, lls_co, lrs_co, llr_co, lrr_co,
         mul_co, nand_co, xor_co            : std_logic;
  signal add_ov_s, sub_ov_s, neg_ov_s,
         mul_ov_s, nand_ov_s, xor_ov_s      : std_logic;
  signal add_sg, sub_sg, neg_sg,
         lls_sg, lrs_sg, llr_sg, lrr_sg,
         mul_sg, nand_sg, xor_sg             : std_logic;


  -- RAM port signals (Port A = write, Port B = read)
  signal ADDRA : std_logic_vector(8 downto 0);
  signal ADDRB : std_logic_vector(8 downto 0);
  signal DIA   : std_logic_vector(7 downto 0);
  signal DOB   : std_logic_vector(7 downto 0);
  signal WEA   : std_logic;

  -- State machine
  type state_t is (IDLE, CRC_COMPUTE, CAN_SEND);
  signal state : state_t := IDLE;

  -- CAN Baudratengenerator: CAN_DIV+1 Systemtakte pro CAN-Bit.
  -- ALU.ucf: PERIOD "CLK" 2 ns -> 500 MHz. Für 1 Mbit/s: 1000 ns / 2 ns = 500 Takte -> CAN_DIV = 499.
  constant CAN_DIV : integer := 499;

  -- CRC state (CAN CRC-15 / ISO 11898, poly 0x4599)
  signal crc_reg  : std_logic_vector(14 downto 0) := (others => '0');
  signal crc_addr : unsigned(7 downto 0);
  signal crc_end  : unsigned(7 downto 0);

  -- CAN state (ISO 11898 frame)
  signal can_reg_20a : std_logic_vector(18 downto 0) := (others => '0');
  signal can_reg_20b : std_logic_vector(38 downto 0) := (others => '0');
  signal can_mode    : std_logic := '0';  -- '0'=2.0A (19-bit), '1'=2.0B (39-bit)
  signal can_addr    : unsigned(7 downto 0);  -- current byte being serialized
  signal can_end_s   : unsigned(7 downto 0);
  signal can_byte    : std_logic_vector(7 downto 0);
  signal can_bit     : integer range 0 to 7;
  signal can_phase   : std_logic;
  signal can_reg_ptr  : integer range 0 to 38;
  signal can_out      : std_logic := '0';
  signal can_baud_cnt : integer range 0 to 499 := 0;

  -- Pipeline stage 1: registered sub-entity outputs (arithmetic datapath)
  signal p1_cmd                                          : std_logic_vector(3 downto 0);
  signal p1_add_l,  p1_sub_l,  p1_alls_l,  p1_allls_l,
         p1_neg_l,  p1_lls_l,  p1_lrs_l,   p1_llr_l,
         p1_lrr_l,  p1_mul_l,  p1_nand_l,  p1_xor_l    : std_logic_vector(7 downto 0);
  signal p1_add_h,  p1_sub_h,  p1_alls_h,  p1_allls_h,
         p1_neg_h,  p1_lls_h,  p1_lrs_h,   p1_llr_h,
         p1_lrr_h,  p1_mul_h,  p1_nand_h,  p1_xor_h    : std_logic_vector(7 downto 0);
  signal p1_add_co, p1_sub_co, p1_alls_co, p1_allls_co,
         p1_neg_co, p1_lls_co, p1_lrs_co,  p1_llr_co,
         p1_lrr_co, p1_mul_co, p1_nand_co, p1_xor_co    : std_logic;
  signal p1_add_ov, p1_sub_ov, p1_neg_ov,
         p1_mul_ov, p1_nand_ov, p1_xor_ov               : std_logic;
  signal p1_add_sg, p1_sub_sg, p1_neg_sg,
         p1_lls_sg, p1_lrs_sg, p1_llr_sg, p1_lrr_sg,
         p1_mul_sg, p1_nand_sg, p1_xor_sg               : std_logic;

begin

  Equal <= '1' when A = B else '0';

  -- Port A: write (WriteRAM). WEA driven combinatorially from Cmd.
  ADDRA <= '0' & B;
  DIA   <= A;
  WEA   <= '1' when Cmd = "1100" else '0';

  -- Port B ADDRB mux:
  --   CRC_COMPUTE : follows crc_addr (sequential read, 1-cycle latency pipelined)
  --   CAN_SEND ph0: follows can_addr (pre-fetching first data byte during header output)
  --   CAN_SEND ph1: follows can_addr+1 (pre-fetching NEXT byte while serializing current)
  --   IDLE        : default A (harmless; read not used)
  ADDRB <= '0' & std_logic_vector(crc_addr)         when state = CRC_COMPUTE
      else '0' & std_logic_vector(can_addr + 1)     when state = CAN_SEND and can_phase = '1'
      else '0' & std_logic_vector(can_addr)          when state = CAN_SEND
      else '0' & A;

  u_ram : ram
    generic map(ADDRESSWIDTH => 9, DATAWIDTH => 8)
    port map(
      -- CLKA = CLKB = CLK: beide Ports auf steigender CLK-Flanke.
      -- ADDRB wird im IDLE-Takt (Cmd=1101) als '0'&A vorausgeladen —
      -- DOB = mem[A] ist damit im ersten CRC_COMPUTE-Takt gültig (1 Takt Latenz).
      CLKA  => CLK,     CLKB  => CLK,
      DIA   => DIA,
      -- DIB: Port B wird nur lesend genutzt. x"00" statt (others=>'0') weil XST
      -- in Port Maps keine uneingeschränkte Aggregat-Syntax unterstützt
      -- (XST:779 'Others' is in unconstrained array aggregate).
      DIB   => x"00",
      -- DOA: Port A Leseausgang wird nicht benötigt (nur Schreiben über Port A).
      DOA   => open,    DOB   => DOB,
      ADDRA => ADDRA,   ADDRB => ADDRB,
      ENA   => '1',     ENB   => '1',
      RSTA  => RST,     RSTB  => RST,
      WEA   => WEA,
      -- WEB: Port B ist read-only, Schreibfreigabe dauerhaft deaktiviert.
      WEB   => '0'
    );

  -- ALU3 sub-entity instantiations (equal output unused — driven combinatorially above)
  u_add   : add         port map(A,B, add_res_l,   add_res_h,   add_co,   open, add_ov_s,  add_sg);
  u_sub   : subtract    port map(A,B, sub_res_l,   sub_res_h,   sub_co,   open, sub_ov_s,  sub_sg);
  u_alls  : add_lls     port map(A,B, alls_res_l,  alls_res_h,  alls_co,  open, open,      open);
  u_allls : add_lls_lls port map(A,B, allls_res_l, allls_res_h, allls_co, open, open,      open);
  u_neg   : negate      port map(A,B, neg_res_l,   neg_res_h,   neg_co,   open, neg_ov_s,  neg_sg);
  u_lls   : lls         port map(A,B, lls_res_l,   lls_res_h,   lls_co,   open, open,      lls_sg);
  u_lrs   : lrs         port map(A,B, lrs_res_l,   lrs_res_h,   lrs_co,   open, open,      lrs_sg);
  u_llr   : llr         port map(A,B, llr_res_l,   llr_res_h,   llr_co,   open, open,      llr_sg);
  u_lrr   : lrr         port map(A,B, lrr_res_l,   lrr_res_h,   lrr_co,   open, open,      lrr_sg);
  u_mul   : mul         port map(A,B, mul_res_l,   mul_res_h,   mul_co,   open, mul_ov_s,  mul_sg);
  u_nand  : bit_nand    port map(A,B, nand_res_l,  nand_res_h,  nand_co,  open, nand_ov_s, nand_sg);
  u_xor   : bit_xor     port map(A,B, xor_res_l,   xor_res_h,   xor_co,   open, xor_ov_s,  xor_sg);

  -- Pipeline stage 1: latch all sub-entity combinatorial outputs + Cmd each cycle
  p1_pipe : process(CLK)
  begin
    if rising_edge(CLK) then
      p1_cmd      <= Cmd;
      p1_add_l    <= add_res_l;   p1_add_h    <= add_res_h;
      p1_sub_l    <= sub_res_l;   p1_sub_h    <= sub_res_h;
      p1_alls_l   <= alls_res_l;  p1_alls_h   <= alls_res_h;
      p1_allls_l  <= allls_res_l; p1_allls_h  <= allls_res_h;
      p1_neg_l    <= neg_res_l;   p1_neg_h    <= neg_res_h;
      p1_lls_l    <= lls_res_l;   p1_lls_h    <= lls_res_h;
      p1_lrs_l    <= lrs_res_l;   p1_lrs_h    <= lrs_res_h;
      p1_llr_l    <= llr_res_l;   p1_llr_h    <= llr_res_h;
      p1_lrr_l    <= lrr_res_l;   p1_lrr_h    <= lrr_res_h;
      p1_mul_l    <= mul_res_l;   p1_mul_h    <= mul_res_h;
      p1_nand_l   <= nand_res_l;  p1_nand_h   <= nand_res_h;
      p1_xor_l    <= xor_res_l;   p1_xor_h    <= xor_res_h;
      p1_add_co   <= add_co;      p1_sub_co   <= sub_co;
      p1_alls_co  <= alls_co;     p1_allls_co <= allls_co;
      p1_neg_co   <= neg_co;      p1_lls_co   <= lls_co;
      p1_lrs_co   <= lrs_co;      p1_llr_co   <= llr_co;
      p1_lrr_co   <= lrr_co;      p1_mul_co   <= mul_co;
      p1_nand_co  <= nand_co;     p1_xor_co   <= xor_co;
      p1_add_ov   <= add_ov_s;    p1_sub_ov   <= sub_ov_s;
      p1_neg_ov   <= neg_ov_s;    p1_mul_ov   <= mul_ov_s;
      p1_nand_ov  <= nand_ov_s;   p1_xor_ov   <= xor_ov_s;
      p1_add_sg   <= add_sg;      p1_sub_sg   <= sub_sg;
      p1_neg_sg   <= neg_sg;      p1_lls_sg   <= lls_sg;
      p1_lrs_sg   <= lrs_sg;      p1_llr_sg   <= llr_sg;
      p1_lrr_sg   <= lrr_sg;      p1_mul_sg   <= mul_sg;
      p1_nand_sg  <= nand_sg;     p1_xor_sg   <= xor_sg;
    end if;
  end process p1_pipe;

  process(CLK)
    variable crc_v   : std_logic_vector(14 downto 0);
    variable crc_b   : std_logic_vector(7 downto 0);
    variable crc_bit : std_logic;
  begin
    if rising_edge(CLK) then

      if RST = '1' then
        state       <= IDLE;
        Flow        <= (others => '0');
        FHigh       <= (others => '0');
        Cout        <= '0';
        OV          <= '0';
        Sign        <= '0';
        CB          <= '0';
        Ready       <= '1';
        CAN         <= '0';
        crc_reg     <= (others => '0');
        can_reg_20a  <= (others => '0');
        can_reg_20b  <= (others => '0');
        can_mode     <= '0';
        can_out      <= '0';
        can_baud_cnt <= 0;
      else

        CB    <= '0';
        Ready <= '1';
        CAN   <= '0';

        case state is

          -- ------------------------------------------------------------
          when IDLE =>
            -- Stage 2: mux pipeline stage 1 result based on p1_cmd (Cmd delayed 1 cycle).
            -- Arithmetic latency = 2 cycles. FSM ops (CRC/CAN/WriteRAM) use raw Cmd below.
            case p1_cmd is
              when "0000" => Flow<=p1_add_l;   FHigh<=p1_add_h;   Cout<=p1_add_co;   OV<=p1_add_ov;   Sign<=p1_add_sg;
              when "0001" => Flow<=p1_sub_l;   FHigh<=p1_sub_h;   Cout<=p1_sub_co;   OV<=p1_sub_ov;   Sign<=p1_sub_sg;
              when "0010" => Flow<=p1_alls_l;  FHigh<=p1_alls_h;  Cout<=p1_alls_co;  OV<='0';         Sign<='0';
              when "0011" => Flow<=p1_allls_l; FHigh<=p1_allls_h; Cout<=p1_allls_co; OV<='0';         Sign<='0';
              when "0100" => Flow<=p1_neg_l;   FHigh<=p1_neg_h;   Cout<=p1_neg_co;   OV<=p1_neg_ov;   Sign<=p1_neg_sg;
              when "0101" => Flow<=p1_lls_l;   FHigh<=p1_lls_h;   Cout<=p1_lls_co;   OV<='0';         Sign<=p1_lls_sg;
              when "0110" => Flow<=p1_lrs_l;   FHigh<=p1_lrs_h;   Cout<=p1_lrs_co;   OV<='0';         Sign<=p1_lrs_sg;
              when "0111" => Flow<=p1_llr_l;   FHigh<=p1_llr_h;   Cout<=p1_llr_co;   OV<='0';         Sign<=p1_llr_sg;
              when "1000" => Flow<=p1_lrr_l;   FHigh<=p1_lrr_h;   Cout<=p1_lrr_co;   OV<='0';         Sign<=p1_lrr_sg;
              when "1001" => Flow<=p1_mul_l;   FHigh<=p1_mul_h;   Cout<=p1_mul_co;   OV<=p1_mul_ov;   Sign<=p1_mul_sg;
              when "1010" => Flow<=p1_nand_l;  FHigh<=p1_nand_h;  Cout<=p1_nand_co;  OV<=p1_nand_ov;  Sign<=p1_nand_sg;
              when "1011" => Flow<=p1_xor_l;   FHigh<=p1_xor_h;   Cout<=p1_xor_co;   OV<=p1_xor_ov;   Sign<=p1_xor_sg;
              when others => null;
            end case;
            -- FSM control: react to current Cmd without pipeline delay
            case Cmd is
              when "1101" =>  -- CRC_MEM(A,B): CAN CRC-15 over mem[A..B]
                crc_reg  <= (others => '0');
                crc_addr <= unsigned(A);
                crc_end  <= unsigned(B);
                CB       <= '1';
                Ready    <= '0';
                state    <= CRC_COMPUTE;
              when "1110" =>  -- SendCANData(A,B): header reg + mem[A..B] on CAN pin
                can_addr     <= unsigned(A);
                can_end_s    <= unsigned(B);
                can_phase    <= '0';
                can_baud_cnt <= 0;
                if can_mode = '0' then
                  can_reg_ptr <= 18;
                  can_out     <= can_reg_20a(18);
                else
                  can_reg_ptr <= 38;
                  can_out     <= can_reg_20b(38);
                end if;
                Ready        <= '0';
                state        <= CAN_SEND;
              when others => null;
            end case;

          -- ------------------------------------------------------------
          -- CRC_COMPUTE: reads DOB (= mem[crc_addr], latched at previous falling CLK).
          -- 1 byte/cycle: all 8 bits processed via variable for-loop (combinatorial chain).
          -- Polynomial: x^15+x^14+x^10+x^8+x^7+x^4+x^3+1 = 0x4599
          when CRC_COMPUTE =>
            CB    <= '1';
            Ready <= '0';
            crc_v := crc_reg;
            crc_b := DOB;  -- mem[crc_addr] latched by RAMB4 at previous falling CLK
            for i in 7 downto 0 loop
              crc_bit := crc_v(14) xor crc_b(i);
              crc_v   := crc_v(13 downto 0) & '0';
              if crc_bit = '1' then
                crc_v := crc_v xor "100010110011001";
              end if;
            end loop;
            crc_reg <= crc_v;
            if crc_addr = crc_end then
              Flow  <= crc_v(7 downto 0);
              FHigh <= '0' & crc_v(14 downto 8);
              Sign  <= crc_v(14);
              Cout  <= '0';
              OV    <= '0';
              CB    <= '0';
              Ready <= '1';
              state <= IDLE;
            else
              crc_addr <= crc_addr + 1;
            end if;

          -- ------------------------------------------------------------
          -- CAN_SEND: jedes Bit wird CAN_DIV+1 = 500 Takte gehalten (1 Mbit/s @ 500 MHz).
          --   can_out hält das aktuelle Bit stabil; Automat schreitet nur beim Zählerablauf weiter.
          --   Phase 0: Header MSB-first. Phase 1: Datenbytes MSB-first.
          when CAN_SEND =>
            Ready <= '0';
            CAN   <= can_out;
            if can_baud_cnt < CAN_DIV then
              can_baud_cnt <= can_baud_cnt + 1;
            else
              can_baud_cnt <= 0;
              if can_phase = '0' then
                if can_reg_ptr = 0 then
                  -- Letztes Header-Bit: DOB = mem[can_addr] ist bereit (vorausgelesen)
                  can_phase <= '1';
                  can_byte  <= DOB;
                  can_bit   <= 7;
                  can_out   <= DOB(7);
                else
                  can_reg_ptr <= can_reg_ptr - 1;
                  if can_mode = '0' then
                    can_out <= can_reg_20a(can_reg_ptr - 1);
                  else
                    can_out <= can_reg_20b(can_reg_ptr - 1);
                  end if;
                end if;
              else
                if can_bit = 0 then
                  if can_addr = can_end_s then
                    Ready   <= '1';
                    can_out <= '0';
                    state   <= IDLE;
                  else
                    -- DOB = mem[can_addr+1] wurde während 500 Takten vorausgelesen
                    can_byte <= DOB;
                    can_addr <= can_addr + 1;
                    can_bit  <= 7;
                    can_out  <= DOB(7);
                  end if;
                else
                  can_bit <= can_bit - 1;
                  can_out <= can_byte(can_bit - 1);
                end if;
              end if;
            end if;

        end case;
      end if;
    end if;
  end process;

end architecture structural_v2;
