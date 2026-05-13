library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
	signal sum : std_logic_vector(8 downto 0);
begin
	sum <= std_logic_vector(unsigned(not ('0' & A)) + 1);
	f_low <= sum(7 downto 0);
	f_high <= (others => '0');
	c_out <= sum(7);
	sign <= sum(7);
	equal <= '0';
	ov <= sum(7) xor not A(7) xor sum(8); -- since B is "00000001", x xor B(7) = x, we can skip the final xor
end Behavioral;
