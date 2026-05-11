----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:44:32 05/08/2026 
-- Design Name: 
-- Module Name:    subtract - Behavioral 
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

entity subtract is
port(
	A, B : in std_logic_vector(7 downto 0);
	f_low, f_high : out std_logic_vector(7 downto 0);
	c_out : out std_logic;
	equal : out std_logic;
	ov : out std_logic;
	sign : out std_logic
);
end subtract;

architecture Behavioral of subtract is
	signal diff : std_logic_vector(8 downto 0);
begin
	diff <= std_logic_vector('0' & unsigned(A) - unsigned(B));
	f_low <= diff(7 downto 0);
	f_high <= (others => '0');
	c_out <= diff(8);
	ov <= A(7) xor B(7) xor diff(7) xor diff(8);
	sign <= diff(7);
	equal <= '1' when A = B else '0';
end Behavioral;
