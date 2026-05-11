library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity ram is
  generic(
    ADDRESSWIDTH : positive := 9;
    DATAWIDTH    : positive := 8
  );

  port(
    CLKA, CLKB : in std_logic;
    DIA, DIB : in  std_logic_vector(DATAWIDTH-1 downto 0);
    DOA, DOB : out std_logic_vector(DATAWIDTH-1 downto 0);
    ADDRA, ADDRB : in  std_logic_vector(ADDRESSWIDTH-1 downto 0);
    ENA, ENB : in std_logic;
    RSTA, RSTB : in std_logic;
    WEA, WEB : in std_logic
  );
end ram;

architecture Behavioral of ram is

begin
   RAMB4_S8_S8_inst : RAMB4_S8_S8
   port map (
      DOA => DOA,     -- Port A 8-bit data output
      DOB => DOB,     -- Port B 8-bit data output
      ADDRA => ADDRA, -- Port A 8-bit address input
      ADDRB => ADDRB, -- Port B 8-bit address input
      CLKA => CLKA,   -- Port A clock input
      CLKB => CLKB,   -- Port B clock input
      DIA => DIA,     -- Port A 8-bit data input
      DIB => DIB,     -- Port B 8-bit data input
      ENA => ENA,     -- Port A RAM enable input
      ENB => ENB,     -- Port B RAM enable input
      RSTA => RSTA,   -- Port A Synchronous reset input
      RSTB => RSTB,   -- Port B Synchronous reset input
      WEA => WEA,     -- Port A RAM write enable input
      WEB => WEB      -- Port B RAM write enable input
   );
end Behavioral;