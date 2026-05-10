library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ASALU is
  port (
    CLK   : in  std_logic;
    A     : in  std_logic_vector(7 downto 0);
    B     : in  std_logic_vector(7 downto 0);
    Cmd   : in  std_logic_vector(3 downto 0);
    Flow  : out std_logic_vector(7 downto 0);
    FHigh : out std_logic_vector(7 downto 0);
    Cout  : out std_logic;
    Equal : out std_logic;
    OV    : out std_logic;
    Sign  : out std_logic;
    CB    : out std_logic;
    Ready : out std_logic;
    CAN   : out std_logic
  );
end entity ASALU;
