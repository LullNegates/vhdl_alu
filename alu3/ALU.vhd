library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
port (
	CLK : in std_logic;
	RST : in std_logic;
	A, B : in std_logic_vector(7 downto 0);
	cmd : in std_logic_vector(3 downto 0);
	f_low : out std_logic_vector(7 downto 0);
	f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic;
	cb : out std_logic;
	ready : out std_logic;
	CAN : out std_logic
);
end ALU;


architecture Behavioral of ALU is
component combinatorics
port(
	CLK : in std_logic;
	A, B : in std_logic_vector(7 downto 0);
	cmd_in : in std_logic_vector(3 downto 0); -- not used in this stage but we need to pass it to subsequent stages to select the result
	cmd_out : out std_logic_vector(3 downto 0);

	-- results out
	add_res_l, sub_res_l, add_lls_res_l, add_lls_lls_res_l, neg_res_l, lls_res_l, lrs_res_l, llr_res_l, lrr_res_l, mul_res_l, nand_res_l, xor_res_l : out std_logic_vector(7 downto 0);	
   add_res_h, sub_res_h, add_lls_res_h, add_lls_lls_res_h, neg_res_h, lls_res_h, lrs_res_h, llr_res_h, lrr_res_h, mul_res_h, nand_res_h, xor_res_h : out std_logic_vector(7 downto 0);

	-- flags out
	add_c_out, add_equal, add_ov, add_sign,
	sub_c_out, sub_equal, sub_ov, sub_sign,
	add_lls_c_out, add_lls_equal, add_lls_ov, add_lls_sign,
	add_lls_lls_c_out, add_lls_lls_equal, add_lls_lls_ov, add_lls_lls_sign,
	neg_c_out, neg_equal, neg_ov, neg_sign,
	lls_c_out, lls_equal, lls_ov, lls_sign,
	lrs_c_out, lrs_equal, lrs_ov, lrs_sign,
	llr_c_out, llr_equal, llr_ov, llr_sign,
	lrr_c_out, lrr_equal, lrr_ov, lrr_sign,
	mul_c_out, mul_equal, mul_ov, mul_sign,
	nand_c_out, nand_equal, nand_ov, nand_sign,
	xor_c_out, xor_equal, xor_ov, xor_sign : out std_logic;

	equal_flag : out std_logic
);
end component;

component resultSelect
port(
	CLK : in std_logic;

	cmd_in : in std_logic_vector(3 downto 0);

	-- results in
	add_res_l, sub_res_l, add_lls_res_l, add_lls_lls_res_l, neg_res_l, lls_res_l, lrs_res_l, llr_res_l, lrr_res_l, mul_res_l, nand_res_l, xor_res_l : in std_logic_vector(7 downto 0);	
   add_res_h, sub_res_h, add_lls_res_h, add_lls_lls_res_h, neg_res_h, lls_res_h, lrs_res_h, llr_res_h, lrr_res_h, mul_res_h, nand_res_h, xor_res_h : in std_logic_vector(7 downto 0);

	-- flags in
	add_c_out, add_equal, add_ov, add_sign,
	sub_c_out, sub_equal, sub_ov, sub_sign,
	add_lls_c_out, add_lls_equal, add_lls_ov, add_lls_sign,
	add_lls_lls_c_out, add_lls_lls_equal, add_lls_lls_ov, add_lls_lls_sign,
	neg_c_out, neg_equal, neg_ov, neg_sign,
	lls_c_out, lls_equal, lls_ov, lls_sign,
	lrs_c_out, lrs_equal, lrs_ov, lrs_sign,
	llr_c_out, llr_equal, llr_ov, llr_sign,
	lrr_c_out, lrr_equal, lrr_ov, lrr_sign,
	mul_c_out, mul_equal, mul_ov, mul_sign,
	nand_c_out, nand_equal, nand_ov, nand_sign,
	xor_c_out, xor_equal, xor_ov, xor_sign : in std_logic;
	
	crc_res : in std_logic_vector(15 downto 0);
	
	equal_flag : std_logic;

	-- selected result and flags
	f_low_res, f_high_res : out std_logic_vector(7 downto 0);
	c_out_res : out std_logic;
	equal_res : out std_logic;
	ov_res : out std_logic;
	sign_res : out std_logic
);
end component;

component ram
generic(
	ADDRESSWIDTH : positive := 9;
	DATAWIDTH : positive := 8
);
port(
	CLKA, CLKB : in std_logic;
	DIA, DIB : in  std_logic_vector(DATAWIDTH-1 downto 0);
	DOA, DOB : out std_logic_vector(DATAWIDTH-1 downto 0);
	ADDRA, ADDRB : in  std_logic_vector(ADDRESSWIDTH-1 downto 0);
	ENA, ENB : in std_logic;
	RSTA, RSTB : in std_logic;
	WEA, WEB : in std_logic
);
end component;

component crc_mem
port(
	CLK      : in  std_logic;
	strobe   : in  std_logic;
	data_in  : in  std_logic_vector(7 downto 0);
	crc_out  : out std_logic_vector(15 downto 0);
	ready    : out std_logic
);
end component;

-- result signals
signal add_res_l, sub_res_l, add_lls_res_l, add_lls_lls_res_l, neg_res_l, lls_res_l, lrs_res_l, llr_res_l, lrr_res_l, mul_res_l, nand_res_l, xor_res_l : std_logic_vector(7 downto 0);	
signal add_res_h, sub_res_h, add_lls_res_h, add_lls_lls_res_h, neg_res_h, lls_res_h, lrs_res_h, llr_res_h, lrr_res_h, mul_res_h, nand_res_h, xor_res_h : std_logic_vector(7 downto 0);

-- flag signals
signal add_c_out, add_equal, add_ov, add_sign,
sub_c_out, sub_equal, sub_ov, sub_sign,
add_lls_c_out, add_lls_equal, add_lls_ov, add_lls_sign,
add_lls_lls_c_out, add_lls_lls_equal, add_lls_lls_ov, add_lls_lls_sign,
neg_c_out, neg_equal, neg_ov, neg_sign,
lls_c_out, lls_equal, lls_ov, lls_sign,
lrs_c_out, lrs_equal, lrs_ov, lrs_sign,
llr_c_out, llr_equal, llr_ov, llr_sign,
lrr_c_out, lrr_equal, lrr_ov, lrr_sign,
mul_c_out, mul_equal, mul_ov, mul_sign,
nand_c_out, nand_equal, nand_ov, nand_sign,
xor_c_out, xor_equal, xor_ov, xor_sign : std_logic;

signal equal_flag : std_logic;

-- ram signals
signal WEA, WEB : std_logic;
signal DOA, DOB : std_logic_vector(7 downto 0);
signal ENA, ENB : std_logic;
signal ADDRA, ADDRB : std_logic_vector(8 downto 0);

-- crc signals
signal crc_result : std_logic_vector(15 downto 0);
signal crc_strobe : std_logic;
signal crc_address_high : std_logic_vector(7 downto 0);
signal crc_byte_processed: std_logic;

-- crc fsm control
type crc_state is (idle, ram_init, init, prefetch, fetch, wait_ready);
signal current_crc_state, next_crc_state : crc_state;

-- can signals
signal can_B : std_logic;
signal can_sending : std_logic;

-- pipeline signals
signal cmd_out : std_logic_vector(3 downto 0);
signal xxx : std_logic_vector(3 downto 0);

begin

combinatorics_1 : combinatorics
port map (
	CLK               => CLK,
	A                 => A,
	B                 => B,
	cmd_in            => cmd,
	cmd_out           => xxx,

	-- results out
	add_res_l         => add_res_l,
	sub_res_l         => sub_res_l,
	add_lls_res_l     => add_lls_res_l,
	add_lls_lls_res_l => add_lls_lls_res_l,
	neg_res_l         => neg_res_l,
	lls_res_l         => lls_res_l,
	lrs_res_l         => lrs_res_l,
	llr_res_l         => llr_res_l,
	lrr_res_l         => lrr_res_l,
	mul_res_l         => mul_res_l,
	nand_res_l        => nand_res_l,
	xor_res_l         => xor_res_l,

	add_res_h         => add_res_h,
	sub_res_h         => sub_res_h,
	add_lls_res_h     => add_lls_res_h,
	add_lls_lls_res_h => add_lls_lls_res_h,
	neg_res_h         => neg_res_h,
	lls_res_h         => lls_res_h,
	lrs_res_h         => lrs_res_h,
	llr_res_h         => llr_res_h,
	lrr_res_h         => lrr_res_h,
	mul_res_h         => mul_res_h,
	nand_res_h        => nand_res_h,
	xor_res_h         => xor_res_h,

	-- flags out
	add_c_out         => add_c_out,
	add_equal         => add_equal,
	add_ov            => add_ov,
	add_sign          => add_sign,

	sub_c_out         => sub_c_out,
	sub_equal         => sub_equal,
	sub_ov            => sub_ov,
	sub_sign          => sub_sign,

	add_lls_c_out     => add_lls_c_out,
	add_lls_equal     => add_lls_equal,
	add_lls_ov        => add_lls_ov,
	add_lls_sign      => add_lls_sign,

	add_lls_lls_c_out => add_lls_lls_c_out,
	add_lls_lls_equal => add_lls_lls_equal,
	add_lls_lls_ov    => add_lls_lls_ov,
	add_lls_lls_sign  => add_lls_lls_sign,

	neg_c_out         => neg_c_out,
	neg_equal         => neg_equal,
	neg_ov            => neg_ov,
	neg_sign          => neg_sign,

	lls_c_out         => lls_c_out,
	lls_equal         => lls_equal,
	lls_ov            => lls_ov,
	lls_sign          => lls_sign,

	lrs_c_out         => lrs_c_out,
	lrs_equal         => lrs_equal,
	lrs_ov            => lrs_ov,
	lrs_sign          => lrs_sign,

	llr_c_out         => llr_c_out,
	llr_equal         => llr_equal,
	llr_ov            => llr_ov,
	llr_sign          => llr_sign,

	lrr_c_out         => lrr_c_out,
	lrr_equal         => lrr_equal,
	lrr_ov            => lrr_ov,
	lrr_sign          => lrr_sign,

	mul_c_out         => mul_c_out,
	mul_equal         => mul_equal,
	mul_ov            => mul_ov,
	mul_sign          => mul_sign,

	nand_c_out        => nand_c_out,
	nand_equal        => nand_equal,
	nand_ov           => nand_ov,
	nand_sign         => nand_sign,

	xor_c_out         => xor_c_out,
	xor_equal         => xor_equal,
	xor_ov            => xor_ov,
	xor_sign          => xor_sign,
	
	equal_flag        => equal_flag
);

resultSelect_1 : entity resultSelect
port map (
	CLK               => CLK,
	cmd_in            => cmd_out,

	-- results in
	add_res_l         => add_res_l,
	sub_res_l         => sub_res_l,
	add_lls_res_l     => add_lls_res_l,
	add_lls_lls_res_l => add_lls_lls_res_l,
	neg_res_l         => neg_res_l,
	lls_res_l         => lls_res_l,
	lrs_res_l         => lrs_res_l,
	llr_res_l         => llr_res_l,
	lrr_res_l         => lrr_res_l,
	mul_res_l         => mul_res_l,
	nand_res_l        => nand_res_l,
	xor_res_l         => xor_res_l,

	add_res_h         => add_res_h,
	sub_res_h         => sub_res_h,
	add_lls_res_h     => add_lls_res_h,
	add_lls_lls_res_h => add_lls_lls_res_h,
	neg_res_h         => neg_res_h,
	lls_res_h         => lls_res_h,
	lrs_res_h         => lrs_res_h,
	llr_res_h         => llr_res_h,
	lrr_res_h         => lrr_res_h,
	mul_res_h         => mul_res_h,
	nand_res_h        => nand_res_h,
	xor_res_h         => xor_res_h,

	-- flags in
	add_c_out         => add_c_out,
	add_equal         => add_equal,
	add_ov            => add_ov,
	add_sign          => add_sign,

	sub_c_out         => sub_c_out,
	sub_equal         => sub_equal,
	sub_ov            => sub_ov,
	sub_sign          => sub_sign,

	add_lls_c_out     => add_lls_c_out,
	add_lls_equal     => add_lls_equal,
	add_lls_ov        => add_lls_ov,
	add_lls_sign      => add_lls_sign,

	add_lls_lls_c_out => add_lls_lls_c_out,
	add_lls_lls_equal => add_lls_lls_equal,
	add_lls_lls_ov    => add_lls_lls_ov,
	add_lls_lls_sign  => add_lls_lls_sign,

	neg_c_out         => neg_c_out,
	neg_equal         => neg_equal,
	neg_ov            => neg_ov,
	neg_sign          => neg_sign,

	lls_c_out         => lls_c_out,
	lls_equal         => lls_equal,
	lls_ov            => lls_ov,
	lls_sign          => lls_sign,

	lrs_c_out         => lrs_c_out,
	lrs_equal         => lrs_equal,
	lrs_ov            => lrs_ov,
	lrs_sign          => lrs_sign,

	llr_c_out         => llr_c_out,
	llr_equal         => llr_equal,
	llr_ov            => llr_ov,
	llr_sign          => llr_sign,

	lrr_c_out         => lrr_c_out,
	lrr_equal         => lrr_equal,
	lrr_ov            => lrr_ov,
	lrr_sign          => lrr_sign,

	mul_c_out         => mul_c_out,
	mul_equal         => mul_equal,
	mul_ov            => mul_ov,
	mul_sign          => mul_sign,

	nand_c_out        => nand_c_out,
	nand_equal        => nand_equal,
	nand_ov           => nand_ov,
	nand_sign         => nand_sign,

	xor_c_out         => xor_c_out,
	xor_equal         => xor_equal,
	xor_ov            => xor_ov,
	xor_sign          => xor_sign,

	-- selected result and flag
	f_low_res         => f_low,
	f_high_res        => f_high,
	c_out_res         => c_out,
	equal_res         => equal,
	ov_res            => ov,
	sign_res          => sign,
	
	equal_flag        => equal_flag,
	-- crc
	crc_res           => crc_result
);

crc_mem_1 : crc_mem
port map (
	CLK      => CLK,
	strobe   => crc_strobe,
	data_in  => DOB,
	crc_out  => crc_result,
	ready    => crc_byte_processed
);

WEA <= '1' when cmd="1100" else '0';
ADDRA <= '0' & B;

ram_1 : ram
port map (
	CLKA => not CLK,
	CLKB => not CLK,
	WEA => WEA,
	WEB => WEB,
	DIA => A,
	DIB => A,
	DOA => DOA,
	DOB => DOB,
	ADDRA => ADDRA,
	ADDRB => ADDRB,
	ENA => '1',
	ENB => '1',
	RSTA => rst,
	RSTB => rst
);

-- FSM for crc_controller - RAM bridge
process(CLK)
begin -- state and reset
	if rising_edge(clk) then
		if RST='1' then
			current_crc_state <= idle;
		else
			current_crc_state <= next_crc_state;
		end if;
  end if;
end process;

process(current_crc_state, cmd, A, B)
begin -- next state logic
	case current_crc_state is
		when idle =>
			if cmd = "1101" then
				next_crc_state <= ram_init;
			else
				next_crc_state <= idle;
			end if;

		when ram_init =>
			next_crc_state <= init;
		
		when init =>
			next_crc_state <= wait_ready;

		when prefetch =>
			next_crc_state <= fetch;

		when fetch =>
			next_crc_state <= wait_ready;

		when wait_ready =>
			if crc_byte_processed='1' then
				if ADDRB = crc_address_high then
					next_crc_state <= idle;
				else
					next_crc_state <= prefetch;
				end if;
			else
				next_crc_state <= wait_ready;
			end if;

		when others =>
			next_crc_state <= idle;
		end case;
end process;


output_logic : process(current_crc_state, DOB, crc_byte_processed)
begin -- output logic
	cb           <= '0';
	crc_strobe  <= '0';
	ADDRB        <= ADDRB;
	crc_address_high <= crc_address_high;

	case current_crc_state is
		when idle =>
			cb <= '0';
			crc_address_high <= B;
		
		when ram_init =>
			cb <= '1';
		
		when init =>
			 cb         <= '1';
			 crc_strobe <= '1';

		when prefetch =>
			cb <= '1';

		when FETCH =>
			 cb <= '1';

		when WAIT_READY =>
			 cb <= '1';
			 
			 if crc_byte_processed='1' then
				ADDRB <= '0' & std_logic_vector(unsigned(ADDRB) + 1);
			end if;
	end case;
end process;

process(CLK)
begin
	if rising_edge(CLK) then
		cmd_out <= cmd;

		case cmd is
			when "1111" =>
				can_B <= not can_B;
			when others =>
		end case;
	end if;
end process;

end Behavioral;

