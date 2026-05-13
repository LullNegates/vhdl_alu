library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity combinatorics is
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
end combinatorics;

architecture Behavioral of combinatorics is
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

-- result signals
signal add_reg_l, sub_reg_l, add_lls_reg_l, add_lls_lls_reg_l, neg_reg_l, lls_reg_l, lrs_reg_l, llr_reg_l, lrr_reg_l, mul_reg_l, nand_reg_l, xor_reg_l : std_logic_vector(7 downto 0);	
signal add_reg_h, sub_reg_h, add_lls_reg_h, add_lls_lls_reg_h, neg_reg_h, lls_reg_h, lrs_reg_h, llr_reg_h, lrr_reg_h, mul_reg_h, nand_reg_h, xor_reg_h : std_logic_vector(7 downto 0);

-- flag signals
signal add_reg_c_out, add_reg_equal, add_reg_ov, add_reg_sign,
sub_reg_c_out, sub_reg_equal, sub_reg_ov, sub_reg_sign,
add_lls_reg_c_out, add_lls_reg_equal, add_lls_reg_ov, add_lls_reg_sign,
add_lls_lls_reg_c_out, add_lls_lls_reg_equal, add_lls_lls_reg_ov, add_lls_lls_reg_sign,
neg_reg_c_out, neg_reg_equal, neg_reg_ov, neg_reg_sign,
lls_reg_c_out, lls_reg_equal, lls_reg_ov, lls_reg_sign,
lrs_reg_c_out, lrs_reg_equal, lrs_reg_ov, lrs_reg_sign,
llr_reg_c_out, llr_reg_equal, llr_reg_ov, llr_reg_sign,
lrr_reg_c_out, lrr_reg_equal, lrr_reg_ov, lrr_reg_sign,
mul_reg_c_out, mul_reg_equal, mul_reg_ov, mul_reg_sign,
nand_reg_c_out, nand_reg_equal, nand_reg_ov, nand_reg_sign,
xor_reg_c_out, xor_reg_equal, xor_reg_ov, xor_reg_sign : std_logic;

begin

add_1 : add
port map (
	A => A,
	B => B,
	f_low => add_reg_l,
	f_high => add_reg_h,
	c_out => add_reg_c_out,
	equal => add_reg_equal,
	ov => add_reg_ov,
	sign => add_reg_sign
);

sub_1 : subtract
port map (
	A => A,
	B => B,
	f_low => sub_reg_l,
	f_high => sub_reg_h,
	c_out => sub_reg_c_out,
	equal => sub_reg_equal,
	ov => sub_reg_ov,
	sign => sub_reg_sign
);

add_lls_1 : add_lls
port map (
	A => A,
	B => B,
	f_low => add_lls_reg_l,
	f_high => add_lls_reg_h,
	c_out => add_lls_reg_c_out,
	equal => add_lls_reg_equal,
	ov => add_lls_reg_ov,
	sign => add_lls_reg_sign
);

add_lls_lls_1 : add_lls_lls
port map (
	A => A,
	B => B,
	f_low => add_lls_lls_reg_l,
	f_high => add_lls_lls_reg_h,
	c_out => add_lls_lls_reg_c_out,
	equal => add_lls_lls_reg_equal,
	ov => add_lls_lls_reg_ov,
	sign => add_lls_lls_reg_sign
);

neg_1 : negate
port map (
	A => A,
	B => B,
	f_low => neg_reg_l,
	f_high => neg_reg_h,
	c_out => neg_reg_c_out,
	equal => neg_reg_equal,
	ov => neg_reg_ov,
	sign => neg_reg_sign
);

lls_1 : lls
port map (
	A => A,
	B => B,
	f_low => lls_reg_l,
	f_high => lls_reg_h,
	c_out => lls_reg_c_out,
	equal => lls_reg_equal,
	ov => lls_reg_ov,
	sign => lls_reg_sign
);

lrs_1 : lrs
port map (
	A => A,
	B => B,
	f_low => lrs_reg_l,
	f_high => lrs_reg_h,
	c_out => lrs_reg_c_out,
	equal => lrs_reg_equal,
	ov => lrs_reg_ov,
	sign => lrs_reg_sign
);

llr_1 : llr
port map (
	A => A,
	B => B,
	f_low => llr_reg_l,
	f_high => llr_reg_h,
	c_out => llr_reg_c_out,
	equal => llr_reg_equal,
	ov => llr_reg_ov,
	sign => llr_reg_sign
);

lrr_1 : lrr
port map (
	A => A,
	B => B,
	f_low => lrr_reg_l,
	f_high => lrr_reg_h,
	c_out => lrr_reg_c_out,
	equal => lrr_reg_equal,
	ov => lrr_reg_ov,
	sign => lrr_reg_sign
);

mul_1 : mul
port map (
	A => A,
	B => B,
	f_low => mul_reg_l,
	f_high => mul_reg_h,
	c_out => mul_reg_c_out,
	equal => mul_reg_equal,
	ov => mul_reg_ov,
	sign => mul_reg_sign
);

nand_1 : bit_nand
port map (
	A => A,
	B => B,
	f_low => nand_reg_l,
	f_high => nand_reg_h,
	c_out => nand_reg_c_out,
	equal => nand_reg_equal,
	ov => nand_reg_ov,
	sign => nand_reg_sign
);

xor_1 : bit_xor
port map (
	A => A,
	B => B,
	f_low => xor_reg_l,
	f_high => xor_reg_h,
	c_out => xor_reg_c_out,
	equal => xor_reg_equal,
	ov => xor_reg_ov,
	sign => xor_reg_sign
);

process(CLK)
begin
if rising_edge(CLK) then
	if A=B then
		equal_flag <= '1';
	else
		equal_flag <= '0';
	end if;
	-- pass on command
	cmd_out <= cmd_in;

	-- results
	add_res_l         <= add_reg_l;
	sub_res_l         <= sub_reg_l;
	add_lls_res_l     <= add_lls_reg_l;
	add_lls_lls_res_l <= add_lls_lls_reg_l;
	neg_res_l         <= neg_reg_l;
	lls_res_l         <= lls_reg_l;
	lrs_res_l         <= lrs_reg_l;
	llr_res_l         <= llr_reg_l;
	lrr_res_l         <= lrr_reg_l;
	mul_res_l         <= mul_reg_l;
	nand_res_l        <= nand_reg_l;
	xor_res_l         <= xor_reg_l;

	add_res_h         <= add_reg_h;
	sub_res_h         <= sub_reg_h;
	add_lls_res_h     <= add_lls_reg_h;
	add_lls_lls_res_h <= add_lls_lls_reg_h;
	neg_res_h         <= neg_reg_h;
	lls_res_h         <= lls_reg_h;
	lrs_res_h         <= lrs_reg_h;
	llr_res_h         <= llr_reg_h;
	lrr_res_h         <= lrr_reg_h;
	mul_res_h         <= mul_reg_h;
	nand_res_h        <= nand_reg_h;
	xor_res_h         <= xor_reg_h;

	-- flags
	add_c_out         <= add_reg_c_out;
	add_equal         <= add_reg_equal;
	add_ov            <= add_reg_ov;
	add_sign          <= add_reg_sign;

	sub_c_out         <= sub_reg_c_out;
	sub_equal         <= sub_reg_equal;
	sub_ov            <= sub_reg_ov;
	sub_sign          <= sub_reg_sign;

	add_lls_c_out     <= add_lls_reg_c_out;
	add_lls_equal     <= add_lls_reg_equal;
	add_lls_ov        <= add_lls_reg_ov;
	add_lls_sign      <= add_lls_reg_sign;

	add_lls_lls_c_out <= add_lls_lls_reg_c_out;
	add_lls_lls_equal <= add_lls_lls_reg_equal;
	add_lls_lls_ov    <= add_lls_lls_reg_ov;
	add_lls_lls_sign  <= add_lls_lls_reg_sign;

	neg_c_out         <= neg_reg_c_out;
	neg_equal         <= neg_reg_equal;
	neg_ov            <= neg_reg_ov;
	neg_sign          <= neg_reg_sign;

	lls_c_out         <= lls_reg_c_out;
	lls_equal         <= lls_reg_equal;
	lls_ov            <= lls_reg_ov;
	lls_sign          <= lls_reg_sign;

	lrs_c_out         <= lrs_reg_c_out;
	lrs_equal         <= lrs_reg_equal;
	lrs_ov            <= lrs_reg_ov;
	lrs_sign          <= lrs_reg_sign;

	llr_c_out         <= llr_reg_c_out;
	llr_equal         <= llr_reg_equal;
	llr_ov            <= llr_reg_ov;
	llr_sign          <= llr_reg_sign;

	lrr_c_out         <= lrr_reg_c_out;
	lrr_equal         <= lrr_reg_equal;
	lrr_ov            <= lrr_reg_ov;
	lrr_sign          <= lrr_reg_sign;

	mul_c_out         <= mul_reg_c_out;
	mul_equal         <= mul_reg_equal;
	mul_ov            <= mul_reg_ov;
	mul_sign          <= mul_reg_sign;

	nand_c_out        <= nand_reg_c_out;
	nand_equal        <= nand_reg_equal;
	nand_ov           <= nand_reg_ov;
	nand_sign         <= nand_reg_sign;

	xor_c_out         <= xor_reg_c_out;
	xor_equal         <= xor_reg_equal;
	xor_ov            <= xor_reg_ov;
	xor_sign          <= xor_reg_sign;
end if;
end process;

end Behavioral;

