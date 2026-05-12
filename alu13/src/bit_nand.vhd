----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:42:31 05/09/2026 
-- Design Name: 
-- Module Name:    bit_nand - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bit_nand is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end bit_nand;

architecture Behavioral of bit_nand is
begin
	f_low <= (
		7 => A(7) nand B(7),
		6 => A(6) nand B(6),
		5 => A(5) nand B(5),
		4 => A(4) nand B(4),
		3 => A(3) nand B(3),
		2 => A(2) nand B(2),
		1 => A(1) nand B(1),
		0 => A(0) nand B(0)
	);
	f_high <= (others => '0');
	c_out <= '0';
	ov <= '0';
	equal <= '1' when A = B else '0';
	sign <= '0';
end Behavioral;
