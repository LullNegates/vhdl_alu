library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity CAN is
port(
	data_l, data_h : in std_logic_vector(7 downto 0); -- data_l from ram_A, data_h from ram_B
	data_bytes : in std_logic_vector(3 downto 0);
	can_B : in std_logic; -- '0' if mode can 2.0A, '1' if mode can 2.0B
	CLK : in std_logic;
	RST : in std_logic;
	strobe : in std_logic;
	bit_time : in std_logic_vector(12 downto 0); -- how many clocks per bit out to match can frequency, assuming clk period > 2ns: 2^13 > 8000, support 125kHz CAN
	CAN : out std_logic;
	can_ready : out std_logic -- alu is operational during can send, wait is only necessary if we need to send another message
);
end CAN;

architecture Behavioral of CAN is
type state is (
	ready,
	first_data, -- move first two data bytes to registers
	second_data, -- move second two data bytes registers
	assemble_message, -- move identifier and data to out register, calculate message length
	transmit, -- transmit message
	stuff_bit, --transmit stuffing bit
	hold_bit, -- hold out bit for 1000ns
	msg_end -- transmit ACK, EOF and interframe segments
);
signal current_state, next_state : state;
signal can_out_register : std_logic_vector(117 downto 0);
signal message_length : std_logic_vector(6 downto 0);
signal message_index : unsigned(7 downto 0);
signal d_0, d_1, d_2, d_3 : std_logic_vector(7 downto 0);
signal stuffing_counter : std_logic_vector(2 downto 0);
signal prev_bit : std_logic;
signal msg_end_count : std_logic_vector(3 downto 0);
signal bit_cycles : std_logic_vector(12 downto 0);
signal data_bytes_amount : std_logic_vector (1 downto 0);

begin
process(CLK) -- state management
begin
	if rising_edge(CLK) then
		if RST='1' then
			current_state <= ready;
		else
			current_state <= next_state;
		end if;
	end if;
end process;

process(current_state)
begin -- transition management
	case current_state is
		when ready =>
			if strobe='1' then
				next_state <= first_data;
			else
				next_state <= ready;
			end if;

		when first_data =>
			next_state <= second_data;

		when second_data =>
			next_state <= assemble_message;

		when assemble_message =>
			next_state <= transmit;

		when transmit =>
			if stuffing_counter="000" then
				next_state <= stuff_bit;
			elsif unsigned(message_index) > unsigned(message_length) then
				next_state <= msg_end;
			else
				next_state <= hold_bit;
			end if;

		when stuff_bit =>
			next_state <= hold_bit;

		when hold_bit =>
			if bit_cycles="0000000000000" then
				if unsigned(message_index) > unsigned(message_length) then
					next_state <= msg_end;
				else
					next_state <= transmit;
				end if;
			else
				next_state <= hold_bit;
			end if;
			
		when msg_end =>
			if msg_end_count="0000" then
				next_state <= ready;
			else
				next_state <= hold_bit;
			end if;
		end case;

end process;

-- signal current_state, next_state : state;
-- signal can_out_register : std_logic_vector(117 downto 0);
-- signal message_length : std_logic_vector(6 downto 0);
-- signal message_index : unsigned(7 downto 0);
-- signal d_0, d_1, d_2, d_3 : std_logic_vector(7 downto 0);
-- signal stuffing_counter : std_logic_vector(2 downto 0);
-- signal prev_bit : std_logic;
-- signal msg_end_count : std_logic_vector(3 downto 0);
-- can_ready
-- can

process(current_state)
begin
	case current_state is
		when ready =>
			can <= '1';
			can_out_register <= (others => '0');
			message_length <= (others => '0');
			message_index <= (others => '0');
			d_0 <= (others => '0');
			d_1 <= (others => '0');
			d_2 <= (others => '0');
			d_3 <= (others => '0');
			data_bytes_amount <= data_bytes;
			stuffing_counter <= "101";
			prev_bit <= '1';
			msg_end_count <= "1011";
		when first_data =>
			can <= '1';
			can_out_register <= (others => '0');
			message_length <= (others => '0');
			message_index <= (others => '0');
			d_0 <= (others => '0');
			d_1 <= (others => '0');
			d_2 <= data_h;
			d_3 <= data_l;
			data_bytes_amount <= data_bytes_amount;
			stuffing_counter <= "101";
			prev_bit <= '1';
			msg_end_count <= "1011";
		when second_data =>
			can <= '1';
			can_out_register <= (others => '0');
			message_length <= (others => '0');
			message_index <= (others => '0');
			d_0 <= d_0;
			d_1 <= d_1;
			d_2 <= (others => '0');
			d_3 <= (others => '0');
			data_bytes_amount <= data_bytes_amount;
			stuffing_counter <= "101";
			prev_bit <= '1';
			msg_end_count <= "1011";
		when assemble_message =>
			if can_B then
			end if;
	end case;
end process;

end Behavioral;
