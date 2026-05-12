library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity result_select is
port(
	CLK : in std_logic;
	cmd_in : in std_logic_vector(3 downto 0);

	-- result signals
	add_res_l, sub_res_l, add_lls_res_l, add_lls_lls_res_l, neg_res_l, lls_res_l, lrs_res_l, llr_res_l, lrr_res_l, mul_res_l, nand_res_l, xor_res_l : in std_logic_vector(7 downto 0);	
   add_res_h, sub_res_h, add_lls_res_h, add_lls_lls_res_h, neg_res_h, lls_res_h, lrs_res_h, llr_res_h, lrr_res_h, mul_res_h, nand_res_h, xor_res_h : in std_logic_vector(7 downto 0);

	-- flag signals
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

	-- actual result for given cmd
	f_low_res, f_high_res : out std_logic_vector(7 downto 0);
	c_out_res : out std_logic;
	equal_res : out std_logic;
	ov_res : out std_logic;
	sign_res : out std_logic
);
end result_select;

architecture Behavioral of result_select is
begin


end Behavioral;