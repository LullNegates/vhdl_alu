library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CRC_MEM is
port (
	CLK : in std_logic;
	strobe : in std_logic;
	crc_in: in std_logic_vector(15 downto 0);
	byte_in: in std_logic_vector(7 downto 0);
	crc_out: out std_logic_vector(15 downto 0)
);
end entity CRC_MEM;

architecture Behavioral of CRC_MEM is
	signal x : std_logic_vector(15 downto 0);
	signal byte : std_logic_Vector(7 downto 0);
	signal count : std_logic_vector(2 downto 0);
begin
process(CLK)
begin
	if strobe='1' then
		byte <= byte_in;
	else
		count <= std_logic_vector(unsigned(count) + 1);
		x <= (
			15 => x(14) xor x(15),
			14 => x(13) xor x(15),
			13 => x(12) xor x(15),
			12 => x(11) xor x(15),
			11 => x(10) xor x(15),
			10 => x(9) xor x(15),
			9 => x(8) xor x(15),
			8 => x(7) xor x(15),
			7 => x(6) xor x(15),
			6 => x(5) xor x(15),
			5 => x(4) xor x(15),
			4 => x(3) xor x(15),
			3 => x(2) xor x(15),
			2 => x(1) xor x(15),
			1 => x(0) xor x(15),
			0 => byte(7)
		);

		byte <= byte(6 downto 0) & 0;
	end if;
end process;
end architecture Behavioral;

