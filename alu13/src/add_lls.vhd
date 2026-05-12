----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:17:24 05/08/2026 
-- Design Name: 
-- Module Name:    add_lls - Behavioral 
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

entity add_lls is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end add_lls;

architecture Behavioral of add_lls is
	signal sum : std_logic_vector(8 downto 0);
begin
	sum <= std_logic_vector('0' & unsigned(A) + unsigned(B));
	f_low <= (
		7 => sum(6),
		6 => sum(5),
		5 => sum(4),
		4 => sum(3),
		3 => sum(2),
		2 => sum(1),
		1 => sum(0),
		0 => '0'
	);
	f_high <= (
		1 => sum(8),
		0 => sum(7),
		others => '0'
	);
	c_out <= '0';
	ov <= '0';
	sign <= '0';
	equal <= '1' when A = B else '0';
end Behavioral;

