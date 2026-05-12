----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:03:35 05/09/2026 
-- Design Name: 
-- Module Name:    negate - Behavioral 
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

entity negate is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end negate;

architecture Behavioral of negate is
	signal negated : std_logic_vector(7 downto 0);
begin
	negated <= not A;
	f_low <= negated;
	f_high <= (others => '0');
	c_out <= negated(7);
	sign <= negated(7);
	equal <= '0';
	ov <= '0';
end Behavioral;
