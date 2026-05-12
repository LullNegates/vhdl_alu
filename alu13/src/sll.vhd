----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:17:04 05/09/2026 
-- Design Name: 
-- Module Name:    sll - Behavioral 
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

entity lls is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end lls;

architecture Behavioral of lls is
begin
	f_low <= (
		7 => A(6),
		6 => A(5),
		5 => A(4),
		4 => A(3),
		3 => A(2),
		2 => A(1),
		1 => A(0),
		0 => '0'
	);
	f_high <= (others => '0');
	c_out <= A(7);
	ov <= '0';
	sign <= '0';
	equal <= '0';
end Behavioral;
