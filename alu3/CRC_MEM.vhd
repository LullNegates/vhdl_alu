library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CRC_MEM is
    port (
        clk      : in  std_logic;
        strobe   : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        crc_out  : out std_logic_vector(15 downto 0);
        ready    : out std_logic
    );
end entity CRC_MEM;

architecture Behavioral of CRC_MEM is
component crc is
port (
	crc_in  : in  std_logic_vector(15 downto 0);
	data_in : in  std_logic_vector(7 downto 0);
	crc_out : out std_logic_vector(15 downto 0)
);
end component;

    signal current_crc : std_logic_vector(15 downto 0);
    signal next_crc    : std_logic_vector(15 downto 0);
    signal count       : unsigned(1 downto 0);

begin
crc_1 : crc
port map (
	crc_in  => current_crc,
	data_in => data_in,
	crc_out => next_crc
);

process(clk)
begin 
	if rising_edge(clk) then
		if strobe = '1' then
			current_crc <= (others => '1'); 
			count <= (others => '0');
			ready <= '0';
		else
			count <= count + 1;
			if count = "11" then
				current_crc <= next_crc;
				ready <= '1';
			else
				ready <= '0';
			end if;
		end if;
  end if;
end process;
crc_out <= current_crc;

end architecture Behavioral;