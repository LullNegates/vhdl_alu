----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:17:24 05/08/2026 
-- Design Name: 
-- Module Name:    add_lls_lls - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity add_lls_lls is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end add_lls_lls;

architecture Behavioral of add_lls_lls is
	signal sum : std_logic_vector(8 downto 0);
begin
	sum <= std_logic_vector('0' & unsigned(A) + unsigned(B));
	f_low <= (
		7 => sum(5),
		6 => sum(4),
		5 => sum(3),
		4 => sum(2),
		3 => sum(1),
		2 => sum(0),
		1 => '0',
		0 => '0'
	);
	f_high <= (
		2 => sum(8),
		1 => sum(7),
		0 => sum(6),
		others => '0'
	);
	c_out <= '0';
	ov <= '0';
	sign <= '0';
	equal <= '1' when A = B else '0';
end Behavioral;

