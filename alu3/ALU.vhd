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
component add
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component subtract
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component add_lls
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component add_lls_lls
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component negate
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component lls
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component lrs
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component llr
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component lrr
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component mul
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component bit_nand
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end component;

component bit_xor
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
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
	byte_in : in std_logic_vector(1 downto 0);
	crc_in :in std_logic_vector(15 downto 0);
	crc_out : out std_logic_vector(15 downto 0)
);
end component;

-- arithmetic result signals
signal add_res_l, sub_res_l, add_lls_res_l, add_lls_lls_res_l, neg_res_l, lls_res_l, lrs_res_l, llr_res_l, lrr_res_l, mul_res_l, nand_res_l, xor_res_l : std_logic_vector(7 downto 0);
signal add_res_h, sub_res_h, add_lls_res_h, add_lls_lls_res_h, neg_res_h, lls_res_h, lrs_res_h, llr_res_h, lrr_res_h, mul_res_h, nand_res_h, xor_res_h : std_logic_vector(7 downto 0);

-- arithmetic flag signals
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

-- ram signals
signal WEA, WEB : std_logic;
signal DOA, DOB : std_logic_vector(7 downto 0);
signal ENA, ENB : std_logic;
signal ADDRA, ADDRB : std_logic_vector(8 downto 0);

-- crc signals
signal crc_busy : std_logic;
signal crc_addr : std_logic_vector(7 downto 0);
signal crc_addr_high : std_logic_vector(7 downto 0);
signal crc_out : std_logic_vector(15 downto 0);
signal crc_in : std_logic_vector(15 downto 0);

-- can signals
signal can_B : std_logic;
signal can_sending : std_logic;

begin

add_1 : add
port map (
	A => A,
	B => B,
	f_low => add_res_l,
	f_high => add_res_h,
	c_out => add_c_out,
	equal => add_equal,
	ov => add_ov,
	sign => add_sign
);

sub_1 : subtract
port map (
	A => A,
	B => B,
	f_low => sub_res_l,
	f_high => sub_res_h,
	c_out => sub_c_out,
	equal => sub_equal,
	ov => sub_ov,
	sign => sub_sign
);

add_lls_1 : add_lls
port map (
	A => A,
	B => B,
	f_low => add_lls_res_l,
	f_high => add_lls_res_h,
	c_out => add_lls_c_out,
	equal => add_lls_equal,
	ov => add_lls_ov,
	sign => add_lls_sign
);

add_lls_lls_1 : add_lls_lls
port map (
	A => A,
	B => B,
	f_low => add_lls_lls_res_l,
	f_high => add_lls_lls_res_h,
	c_out => add_lls_lls_c_out,
	equal => add_lls_lls_equal,
	ov => add_lls_lls_ov,
	sign => add_lls_lls_sign
);

neg_1 : negate
port map (
	A => A,
	B => B,
	f_low => neg_res_l,
	f_high => neg_res_h,
	c_out => neg_c_out,
	equal => neg_equal,
	ov => neg_ov,
	sign => neg_sign
);

lls_1 : lls
port map (
	A => A,
	B => B,
	f_low => lls_res_l,
	f_high => lls_res_h,
	c_out => lls_c_out,
	equal => lls_equal,
	ov => lls_ov,
	sign => lls_sign
);

lrs_1 : lrs
port map (
	A => A,
	B => B,
	f_low => lrs_res_l,
	f_high => lrs_res_h,
	c_out => lrs_c_out,
	equal => lrs_equal,
	ov => lrs_ov,
	sign => lrs_sign
);

llr_1 : llr
port map (
	A => A,
	B => B,
	f_low => llr_res_l,
	f_high => llr_res_h,
	c_out => llr_c_out,
	equal => llr_equal,
	ov => llr_ov,
	sign => llr_sign
);

lrr_1 : lrr
port map (
	A => A,
	B => B,
	f_low => lrr_res_l,
	f_high => lrr_res_h,
	c_out => lrr_c_out,
	equal => lrr_equal,
	ov => lrr_ov,
	sign => lrr_sign
);

mul_1 : mul
port map (
	A => A,
	B => B,
	f_low => mul_res_l,
	f_high => mul_res_h,
	c_out => mul_c_out,
	equal => mul_equal,
	ov => mul_ov,
	sign => mul_sign
);

nand_1 : bit_nand
port map (
	A => A,
	B => B,
	f_low => nand_res_l,
	f_high => nand_res_h,
	c_out => nand_c_out,
	equal => nand_equal,
	ov => nand_ov,
	sign => nand_sign
);

xor_1 : bit_xor
port map (
	A => A,
	B => B,
	f_low => xor_res_l,
	f_high => xor_res_h,
	c_out => xor_c_out,
	equal => xor_equal,
	ov => xor_ov,
	sign => xor_sign
);

crc_mem_1 : crc_mem
port map (
	byte_in => DOB(7 downto 6),
	crc_in => crc_in,
	crc_out => crc_out
);

WEA <= '1' when cmd="1100" else '0';
ENA <= '1' when cmd="1100" or cmd="1101" else '0';
ADDRA <= '0' & B;
ADDRB <= '0' & A when crc_busy='0' else '0' & crc_addr;

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

process(CLK)
begin
	if rising_edge(clk) then		
		if rst='1' then
			-- reset internal
			crc_busy <= '0';
			crc_addr <= (others => '0');
			can_B <= '0';
			can_sending <= '0';
			ENB <= '0';
			WEB <= '0';
			
			-- reset output
			f_low <= (others => '0');
			f_high <= (others => '0');
			c_out <= '0';
			equal <= '0';
			ov <= '0';
			sign <= '0';
			CAN <= '1';
			cb <= '0';
			ready <= '1';
		--elsif crc_busy='1' then
		--	if crc_addr=crc_addr_high then
		--		crc_busy<='0';
		--		cb <= '0';
		--	else
		--		crc_addr <= std_logic_vector(unsigned(crc_addr) + 1);
		--	end if;
		--	
		--	crc_in <= crc_out;
		--	f_low <= crc_out(7 downto 0);
		--	f_high <= crc_out(15 downto 8);
		else
			case cmd is
				when "0000" =>
					f_low <= add_res_l;
					f_high <= add_res_h;
					c_out <= add_c_out;
					equal <= add_equal;
					ov <= add_ov;
					sign <= add_sign;
				when "0001" =>
					f_low <= sub_res_l;
					f_high <= sub_res_h;
					c_out <= sub_c_out;
					equal <= sub_equal;
					ov <= sub_ov;
					sign <= sub_sign;
				when "0010" =>
					f_low <= add_lls_res_l;
					f_high <= add_lls_res_h;
					c_out <= add_lls_c_out;
					equal <= add_lls_equal;
					ov <= add_lls_ov;
					sign <= add_lls_sign;
				when "0011" =>
					f_low <= add_lls_lls_res_l;
					f_high <= add_lls_lls_res_h;
					c_out <= add_lls_lls_c_out;
					equal <= add_lls_lls_equal;
					ov <= add_lls_lls_ov;
					sign <= add_lls_lls_sign;
				when "0100" =>
					f_low <= neg_res_l;
					f_high <= neg_res_h;
					c_out <= neg_c_out;
					equal <= neg_equal;
					ov <= neg_ov;
					sign <= neg_sign;
				when "0101" =>
					f_low <= lls_res_l;
					f_high <= lls_res_h;
					c_out <= lls_c_out;
					equal <= lls_equal;
					ov <= lls_ov;
					sign <= lls_sign;
				when "0110" =>
					f_low <= lrs_res_l;
					f_high <= lrs_res_h;
					c_out <= lrs_c_out;
					equal <= lrs_equal;
					ov <= lrs_ov;
					sign <= lrs_sign;
				when "0111" =>
					f_low <= llr_res_l;
					f_high <= llr_res_h;
					c_out <= llr_c_out;
					equal <= llr_equal;
					ov <= llr_ov;
					sign <= llr_sign;
				when "1000" =>
					f_low <= lrr_res_l;
					f_high <= lrr_res_h;
					c_out <= lrr_c_out;
					equal <= lrr_equal;
					ov <= lrr_ov;
					sign <= lrr_sign;
				when "1001" =>
					f_low <= mul_res_l;
					f_high <= mul_res_h;
					c_out <= mul_c_out;
					equal <= mul_equal;
					ov <= mul_ov;
					sign <= mul_sign;
				when "1010" =>
					f_low <= nand_res_l;
					f_high <= nand_res_h;
					c_out <= nand_c_out;
					equal <= nand_equal;
					ov <= nand_ov;
					sign <= nand_sign;
				when "1011" =>
					f_low <= xor_res_l;
					f_high <= xor_res_h;
					c_out <= xor_c_out;
					equal <= xor_equal;
					ov <= xor_ov;
					sign <= xor_sign;
				when "1100" => -- handled at ram definition
				when "1101" =>
					f_low <= crc_out(15 downto 8);
					f_high <= crc_out(7 downto 0);
					crc_busy <= '1';
					crc_addr <= std_logic_vector(unsigned(A) + 1);
					crc_addr_high <= B;
					crc_in <= (others => '0');
				when "1110" =>
					can_sending <= '1';
					ready <= '0';

					
				when "1111" =>
					can_B <= not can_B;
				when others =>
			end case;
		end if;
	end if;

	
end process;


end Behavioral;

