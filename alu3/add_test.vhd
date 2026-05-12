--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   08:51:47 05/07/2026
-- Design Name:   
-- Module Name:   /projects/ALU/add_test.vhd
-- Project Name:  ALU
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: adder
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
 
ENTITY add_test IS
END add_test;
 
ARCHITECTURE behavior OF add_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT adder
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
	
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: adder PORT MAP (
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
		A <= "10101010";
		B <= "01010101";
		wait for clk_period;
		assert(f_low="11111111");
		assert(f_high="00000000");
		assert(ov='0');
		
		
      wait;
   end process;

END;
