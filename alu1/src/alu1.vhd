library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Architecture 1: Verhaltensbeschreibung (behavioral, TopLevel)
-- All 16 operations from Befehlstabelle 1+2, clocked design.
-- Multi-cycle ops (CRC_MEM, SendCANData) use a state machine; Ready='0' while busy.
architecture behavioral of ASALU is

  type ram_t is array(0 to 255) of std_logic_vector(7 downto 0);
  signal mem : ram_t := (others => (others => '0'));

  type state_t is (IDLE, CRC_COMPUTE, CAN_SEND);
  signal state : state_t := IDLE;

  signal crc_reg  : std_logic_vector(14 downto 0) := (others => '0');
  signal crc_addr : unsigned(7 downto 0);
  signal crc_end  : unsigned(7 downto 0);

  -- CAN frame header registers (ISO 11898)
  signal can_reg_20a : std_logic_vector(18 downto 0) := (others => '0');  -- 2.0A: 19-bit standard frame header
  signal can_reg_20b : std_logic_vector(38 downto 0) := (others => '0');  -- 2.0B: 39-bit extended frame header
  signal can_mode    : std_logic := '0';  -- '0' = 2.0A, '1' = 2.0B

  signal can_addr    : unsigned(7 downto 0);
  signal can_end     : unsigned(7 downto 0);
  signal can_byte    : std_logic_vector(7 downto 0);
  signal can_bit     : integer range 0 to 7;
  signal can_phase   : std_logic;           -- '0' = serializing header reg, '1' = serializing mem
  signal can_reg_ptr : integer range 0 to 38;

begin

  -- Equal is purely combinational (independent of Cmd and CLK)
  Equal <= '1' when A = B else '0';

  process(CLK)
    variable sum9    : std_logic_vector(8 downto 0);
    variable diff9   : std_logic_vector(8 downto 0);
    variable mul16   : std_logic_vector(15 downto 0);
    variable res8    : std_logic_vector(7 downto 0);
    variable crc_v   : std_logic_vector(14 downto 0);
    variable crc_b   : std_logic_vector(7 downto 0);
    variable crc_bit : std_logic;
  begin
    if rising_edge(CLK) then

      -- Driven every cycle; overridden in multi-cycle states below
      CB    <= '0';
      Ready <= '1';
      CAN   <= '0';

      case state is

        -- ----------------------------------------------------------------
        when IDLE =>

          case Cmd is

            when "0000" =>  -- F = A + B
              sum9  := std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
              Flow  <= sum9(7 downto 0);
              FHigh <= (others => '0');
              Cout  <= sum9(8);
              OV    <= (not A(7) and not B(7) and     sum9(7)) or
                       (    A(7) and     B(7) and not sum9(7));
              Sign  <= sum9(7);

            when "0001" =>  -- F = A - B
              diff9 := std_logic_vector(unsigned('0' & A) - unsigned('0' & B));
              Flow  <= diff9(7 downto 0);
              FHigh <= (others => '0');
              Cout  <= diff9(8);
              OV    <= (not A(7) and     B(7) and     diff9(7)) or
                       (    A(7) and not B(7) and not diff9(7));
              Sign  <= diff9(7);

            when "0010" =>  -- F = (A+B) * 2
              sum9 := std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
              res8 := sum9(6 downto 0) & '0';
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= sum9(8) or sum9(7);
              OV    <= '0';
              Sign  <= res8(7);

            when "0011" =>  -- F = (A+B) * 4
              sum9 := std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
              res8 := sum9(5 downto 0) & "00";
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= sum9(8) or sum9(7) or sum9(6);
              OV    <= '0';
              Sign  <= res8(7);

            when "0100" =>  -- F = -A  (Cout = sign per spec)
              res8 := std_logic_vector(-signed(A));
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= res8(7);
              OV    <= '0';
              Sign  <= res8(7);

            when "0101" =>  -- F = sll(A)
              res8 := A(6 downto 0) & '0';
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= A(7);
              OV    <= '0';
              Sign  <= res8(7);

            when "0110" =>  -- F = slr(A)
              res8 := '0' & A(7 downto 1);
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= A(0);
              OV    <= '0';
              Sign  <= '0';

            when "0111" =>  -- F = rll(A)
              res8 := A(6 downto 0) & A(7);
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= '0';
              OV    <= '0';
              Sign  <= res8(7);

            when "1000" =>  -- F = rlr(A)
              res8 := A(0) & A(7 downto 1);
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= '0';
              OV    <= '0';
              Sign  <= res8(7);

            when "1001" =>  -- F = A * B  (16-bit unsigned)
              mul16 := std_logic_vector(unsigned(A) * unsigned(B));
              Flow  <= mul16(7 downto 0);
              FHigh <= mul16(15 downto 8);
              Cout  <= '0';
              OV    <= '0';
              Sign  <= mul16(15);

            when "1010" =>  -- F = NAND(A, B)
              res8 := not (A and B);
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= '0';
              OV    <= '0';
              Sign  <= res8(7);

            when "1011" =>  -- F = XOR(A, B)
              res8 := A xor B;
              Flow  <= res8;
              FHigh <= (others => '0');
              Cout  <= '0';
              OV    <= '0';
              Sign  <= res8(7);

            when "1100" =>  -- WriteRAM: A -> Mem(Adr B)
              mem(to_integer(unsigned(B))) <= A;
              Flow  <= A;
              FHigh <= (others => '0');
              Cout  <= '0';
              OV    <= '0';
              Sign  <= '0';

            when "1101" =>  -- CRC_MEM(A,B): CAN-CRC-15 of Mem[A..B] -> F
              crc_reg  <= (others => '0');
              crc_addr <= unsigned(A);
              crc_end  <= unsigned(B);
              CB       <= '1';
              Ready    <= '0';
              state    <= CRC_COMPUTE;

            when "1110" =>  -- SendCANData(A,B): Reg + Mem[A..B] serially on CAN
              can_addr    <= unsigned(A);
              can_end     <= unsigned(B);
              can_phase   <= '0';
              if can_mode = '0' then
                can_reg_ptr <= 18;
              else
                can_reg_ptr <= 38;
              end if;
              Ready       <= '0';
              state       <= CAN_SEND;

            when others =>  -- 1111: Reserved
              Flow  <= (others => '0');
              FHigh <= (others => '0');
              Cout  <= '0';
              OV    <= '0';
              Sign  <= '0';

          end case;

        -- ----------------------------------------------------------------
        -- CRC_COMPUTE: processes one memory byte per clock cycle.
        -- CAN CRC-15 polynomial: x^15+x^14+x^10+x^8+x^7+x^4+x^3+1 = 0x4599
        when CRC_COMPUTE =>
          CB    <= '1';
          Ready <= '0';
          crc_v := crc_reg;
          crc_b := mem(to_integer(crc_addr));
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

        -- ----------------------------------------------------------------
        -- CAN_SEND: phase 0 = serialize header register (MSB first),
        --           phase 1 = serialize Mem[A..B] bytes (MSB first).
        when CAN_SEND =>
          Ready <= '0';
          if can_phase = '0' then
            if can_mode = '0' then
              CAN <= can_reg_20a(can_reg_ptr);
            else
              CAN <= can_reg_20b(can_reg_ptr);
            end if;
            if can_reg_ptr = 0 then
              can_phase <= '1';
              can_byte  <= mem(to_integer(can_addr));
              can_bit   <= 7;
            else
              can_reg_ptr <= can_reg_ptr - 1;
            end if;
          else
            CAN <= can_byte(can_bit);
            if can_bit = 0 then
              if can_addr = can_end then
                Ready <= '1';
                state <= IDLE;
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

end architecture behavioral;
