--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:01:31 05/08/2026
-- Design Name:   
-- Module Name:   /projects/ALU/subtract_tb.vhd
-- Project Name:  ALU
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: subtract
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY subtract_tb IS
END subtract_tb;
 
ARCHITECTURE behavior OF subtract_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT subtract
    PORT(
         A : IN  std_logic_vector(7 downto 0);
         B : IN  std_logic_vector(7 downto 0);
         f_low : OUT  std_logic_vector(7 downto 0);
         f_high : OUT  std_logic_vector(7 downto 0);
         c_out : OUT  std_logic;
         equal : OUT  std_logic;
         ov : OUT  std_logic;
         sign : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal A : std_logic_vector(7 downto 0) := (others => '0');
   signal B : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal f_low : std_logic_vector(7 downto 0);
   signal f_high : std_logic_vector(7 downto 0);
   signal c_out : std_logic;
   signal equal : std_logic;
   signal ov : std_logic;
   signal sign : std_logic;
   -- No clocks detected in port list. Replace <clock> below with 
   -- appropriate port name 
 
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: subtract PORT MAP (
          A => A,
          B => B,
          f_low => f_low,
          f_high => f_high,
          c_out => c_out,
          equal => equal,
          ov => ov,
          sign => sign
        );

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 
		-- 0 - (-1) = 1
		A <= "00000000";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="00000001");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='0');
		assert(sign='0');
		
		-- 127 - (-1) = -128, overflow
		A <= "01111111";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="10000000");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='1');
		assert(sign='1');
		
		-- 126 - 127 = -1
		A <= "01111110";
		B <= "01111111";
		wait for clk_period;
		assert(f_low="11111111");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='0');
		assert(sign='1');
		
      wait;
   end process;

END;
