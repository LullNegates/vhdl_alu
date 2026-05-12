library IEEE;
use IEEE.std_logic_1164.all;

entity crc is
	port (
	  crc_in: in std_logic_vector(15 downto 0);
	  data_in: in std_logic_vector(7 downto 0);
	  crc_out: out std_logic_vector(15 downto 0)
	);
end entity crc;

architecture Behavioral of crc is
begin
	crc_out(0) <= crc_in(1) xor crc_in(4) xor crc_in(5) xor crc_in(7) xor crc_in(8) xor data_in(1) xor data_in(4) xor data_in(5) xor data_in(7);
	crc_out(1) <= crc_in(1) xor crc_in(2) xor crc_in(4) xor crc_in(6) xor crc_in(7) xor crc_in(9) xor data_in(1) xor data_in(2) xor data_in(4) xor data_in(6) xor data_in(7);
	crc_out(2) <= crc_in(1) xor crc_in(2) xor crc_in(3) xor crc_in(4) xor crc_in(10) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4);
	crc_out(3) <= crc_in(0) xor crc_in(2) xor crc_in(3) xor crc_in(4) xor crc_in(5) xor crc_in(11) xor data_in(0) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5);
	crc_out(4) <= crc_in(0) xor crc_in(1) xor crc_in(3) xor crc_in(4) xor crc_in(5) xor crc_in(6) xor crc_in(12) xor data_in(0) xor data_in(1) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(6);
	crc_out(5) <= crc_in(1) xor crc_in(2) xor crc_in(4) xor crc_in(5) xor crc_in(6) xor crc_in(7) xor crc_in(13) xor data_in(1) xor data_in(2) xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
	crc_out(6) <= crc_in(0) xor crc_in(1) xor crc_in(2) xor crc_in(3) xor crc_in(4) xor crc_in(6) xor crc_in(14) xor data_in(0) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(6);
	crc_out(7) <= crc_in(1) xor crc_in(2) xor crc_in(3) xor crc_in(4) xor crc_in(5) xor crc_in(7) xor crc_in(15) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(7);
	crc_out(8) <= crc_in(1) xor crc_in(2) xor crc_in(3) xor crc_in(6) xor crc_in(7) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(6) xor data_in(7);
	crc_out(9) <= crc_in(1) xor crc_in(2) xor crc_in(3) xor crc_in(5) xor data_in(1) xor data_in(2) xor data_in(3) xor data_in(5);
	crc_out(10) <= crc_in(2) xor crc_in(3) xor crc_in(4) xor crc_in(6) xor data_in(2) xor data_in(3) xor data_in(4) xor data_in(6);
	crc_out(11) <= crc_in(3) xor crc_in(4) xor crc_in(5) xor crc_in(7) xor data_in(3) xor data_in(4) xor data_in(5) xor data_in(7);
	crc_out(12) <= crc_in(1) xor crc_in(6) xor crc_in(7) xor data_in(1) xor data_in(6) xor data_in(7);
	crc_out(13) <= crc_in(1) xor crc_in(2) xor crc_in(4) xor crc_in(5) xor data_in(1) xor data_in(2) xor data_in(4) xor data_in(5);
	crc_out(14) <= crc_in(2) xor crc_in(3) xor crc_in(5) xor crc_in(6) xor data_in(2) xor data_in(3) xor data_in(5) xor data_in(6);
	crc_out(15) <= crc_in(0) xor crc_in(3) xor crc_in(4) xor crc_in(6) xor crc_in(7) xor data_in(0) xor data_in(3) xor data_in(4) xor data_in(6) xor data_in(7);
end architecture Behavioral;
