library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity resultSelect is
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
	
	equal_flag : in std_logic;
	
	-- crc
	crc_res : in std_logic_vector(15 downto 0);

	-- actual result for given cmd
	f_low_res, f_high_res : out std_logic_vector(7 downto 0);
	c_out_res : out std_logic;
	equal_res : out std_logic;
	ov_res : out std_logic;
	sign_res : out std_logic
);
end resultSelect;

architecture Behavioral of resultSelect is
begin
process(CLK)
begin
	if rising_edge(CLK) then
		f_high_res <= (others => '0');
		equal_res <= equal_flag;
		case cmd_in is
			when "0000" =>
				f_low_res <= add_res_l;
				c_out_res <= add_c_out;
				ov_res <= add_ov;
				sign_res <= add_sign;
			when "0001" =>
				f_low_res <= sub_res_l;
				c_out_res <= sub_c_out;
				ov_res <= sub_ov;
				sign_res <= sub_sign;
			when "0010" =>
				f_low_res <= add_lls_res_l;
				f_high_res <= add_lls_res_h;
				c_out_res <= add_lls_c_out;
				ov_res <= add_lls_ov;
				sign_res <= add_lls_sign;
			when "0011" =>
				f_low_res <= add_lls_lls_res_l;
				f_high_res <= add_lls_lls_res_h;
				c_out_res <= add_lls_lls_c_out;
				ov_res <= add_lls_lls_ov;
				sign_res <= add_lls_lls_sign;
			when "0100" =>
				f_low_res <= neg_res_l;
				c_out_res <= neg_c_out;
				ov_res <= neg_ov;
				sign_res <= neg_sign;
			when "0101" =>
				f_low_res <= lls_res_l;
				c_out_res <= lls_c_out;
				ov_res <= lls_ov;
				sign_res <= lls_sign;
			when "0110" =>
				f_low_res <= lrs_res_l;
				c_out_res <= lrs_c_out;
				ov_res <= lrs_ov;
				sign_res <= lrs_sign;
			when "0111" =>
				f_low_res <= llr_res_l;
				c_out_res <= llr_c_out;
				ov_res <= llr_ov;
				sign_res <= llr_sign;
			when "1000" =>
				f_low_res <= lrr_res_l;
				c_out_res <= lrr_c_out;
				ov_res <= lrr_ov;
				sign_res <= lrr_sign;
			when "1001" =>
				f_low_res <= mul_res_l;
				f_high_res <= mul_res_h;
				c_out_res <= mul_c_out;
				ov_res <= mul_ov;
				sign_res <= mul_sign;
			when "1010" =>
				f_low_res <= nand_res_l;
				c_out_res <= nand_c_out;
				ov_res <= nand_ov;
				sign_res <= nand_sign;
			when "1011" =>
				f_low_res <= xor_res_l;
				c_out_res <= xor_c_out;
				ov_res <= xor_ov;
				sign_res <= xor_sign;
			when others =>
				f_low_res <= crc_res (7 downto 0);
				f_high_res <= crc_res (15 downto 8);
				c_out_res <= '0';
				equal_res <= '0';
				ov_res <= '0';
				sign_res <= '0';
		end case;
	end if;
end process;
end Behavioral;