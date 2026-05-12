----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:24:18 05/09/2026 
-- Design Name: 
-- Module Name:    lrr - Behavioral 
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

entity lrr is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end lrr;

architecture Behavioral of lrr is
begin
	f_low <= (
		7 => A(0),
		6 => A(7),
		5 => A(6),
		4 => A(5),
		3 => A(4),
		2 => A(3),
		1 => A(2),
		0 => A(1)
	);
	f_high <= (others => '0');
	c_out <= '0';
	ov <= '0';
	sign <= '0';
	equal <= '0';
end Behavioral;

