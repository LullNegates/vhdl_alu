LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY alu_tb IS
END alu_tb;
 
ARCHITECTURE behavior OF alu_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ALU
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         A : IN  std_logic_vector(7 downto 0);
         B : IN  std_logic_vector(7 downto 0);
         cmd : IN  std_logic_vector(3 downto 0);
         f_low : OUT  std_logic_vector(7 downto 0);
         f_high : OUT  std_logic_vector(7 downto 0);
         c_out : OUT  std_logic;
         equal : OUT  std_logic;
         ov : OUT  std_logic;
         sign : OUT  std_logic;
         cb : OUT  std_logic;
         ready : OUT  std_logic;
         CAN : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '0';
   signal A : std_logic_vector(7 downto 0) := (others => '0');
   signal B : std_logic_vector(7 downto 0) := (others => '0');
   signal cmd : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal f_low : std_logic_vector(7 downto 0);
   signal f_high : std_logic_vector(7 downto 0);
   signal c_out : std_logic;
   signal equal : std_logic;
   signal ov : std_logic;
   signal sign : std_logic;
   signal cb : std_logic;
   signal ready : std_logic;
   signal CAN : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ALU PORT MAP (
          CLK => CLK,
          RST => RST,
          A => A,
          B => B,
          cmd => cmd,
          f_low => f_low,
          f_high => f_high,
          c_out => c_out,
          equal => equal,
          ov => ov,
          sign => sign,
          cb => cb,
          ready => ready,
          CAN => CAN
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst <= '1';
      wait for 100 ns;	
		rst <= '0';
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');
		assert(cb='0');
		assert(ready='1');
		assert(can='1');
		
		-- add
		cmd <= "0000";
		A <= "10101010";
		B <= "01010101";
		wait for clk_period;
		assert(f_low="11111111");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='1');

		A <= (others => '0');
		wait for clk_period;
		assert(f_low="01010101");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');
		
		-- sub interspersed
		cmd <= "0001";
		-- 0 - (-1) = 1
		A <= "00000000";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="00000001");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='0');
		assert(sign='0');

		-- add
		cmd <= "0000";
		A <= "10000000";
		B <= "10000000";
		wait for clk_period;
		assert(f_low="00000000");
		assert(ov='1');
		assert(c_out='1');
		assert(equal='1');
		assert(sign='0');

		-- subtract
		cmd <= "0001";
		-- 0 - (-1) = 1
		A <= "00000000";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="00000001");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='0');
		assert(sign='0');

		A <= "01111111";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="10000000");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='1');
		assert(sign='1');

		A <= "01111110";
		B <= "01111111";
		wait for clk_period;
		assert(f_low="11111111");
		assert(c_out='1');
		assert(equal='0');
		assert(ov='0');
		assert(sign='1');
		
		-- add * 2
		cmd <= "0010";
		A <= "10101010";
		B <= "01010101";
		wait for clk_period;
		assert(f_high="00000001");
		assert(f_low="11111110");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= (others => '0');
		wait for clk_period;
		assert(f_high="00000000");
		assert(f_low="10101010");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= "10000000";
		B <= "10000000";
		wait for clk_period;
		assert(f_high="00000010");
		assert(f_low="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='1');
		assert(sign='0');

		-- add * 4
		cmd <= "0011";
		A <= "10101010";
		B <= "01010101";
		wait for clk_period;
		assert(f_high="00000011");
		assert(f_low="11111100");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= (others => '0');
		wait for clk_period;
		assert(f_high="00000001");
		assert(f_low="01010100");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= "10000000";
		B <= "10000000";
		wait for clk_period;
		assert(f_high="00000100");
		assert(f_low="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='1');
		assert(sign='0');

		-- negate
		cmd <= "0100";
		A <= "00000000";
		wait for clk_period;
		assert(f_low="11111111");
		assert(f_high="00000000");
		assert(c_out='1');
		assert(sign='1');
		assert(ov='0');
		assert(equal='0');

		A <= "11111111";
		wait for clk_period;
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		A <= "10101010";
		wait for clk_period;
		assert(f_low="01010101");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		A <= "01010101";
		wait for clk_period;
		assert(f_low="10101010");
		assert(f_high="00000000");
		assert(c_out='1');
		assert(sign='1');
		assert(ov='0');
		assert(equal='0');

		-- shift left
		cmd <= "0101";
		A <= "00000001";
		wait for clk_period;
		assert(f_low="00000010");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		A <= "10000000";
		wait for clk_period;
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(c_out='1');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		-- shift right
		cmd <= "0110";
		A <= "00000001";
		wait for clk_period;
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(c_out='1');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		A <= "10000000";
		wait for clk_period;
		assert(f_low="01000000");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		-- rotate left
		cmd <= "0111";
		A <= "00000001";
		wait for clk_period;
		assert(f_low="00000010");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		A <= "10000000";
		wait for clk_period;
		assert(f_low="00000001");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		-- rotate right
		cmd <= "1000";
		A <= "00000001";
		wait for clk_period;
		assert(f_low="10000000");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		A <= "10000000";
		wait for clk_period;
		assert(f_low="01000000");
		assert(f_high="00000000");
		assert(c_out='0');
		assert(sign='0');
		assert(ov='0');
		assert(equal='0');

		-- mul
		cmd <= "1001";
		A <= "00000001";
		B <= "11110000";
		wait for clk_period;
		assert(f_low="11110000");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= "00000001";
		B <= "00000000";
		wait for clk_period;
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= "00000001";
		B <= "00000001";
		wait for clk_period;
		assert(f_low="00000001");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='1');
		assert(sign='0');

		A <= "10000001";
		B <= "10000000";
		wait for clk_period;
		assert(f_low="10000000");
		assert(f_high="01000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		A <= "11111111";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="00000001");
		assert(f_high="11111110");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='1');
		assert(sign='0');

		-- nand
		cmd <= "1010";
		A <= "11111111";
		B <= "11111111";
		wait for clk_period;
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='1');
		assert(sign='0');

		A <= "00110011";
		B <= "01010101";
		wait for clk_period;
		assert(f_low="11101110");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		-- xor
		cmd <= "1011";
		A <= "11111111";
		B <= "11111111";
		wait for clk_period*2;
		assert(f_low="00000000");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='1');
		assert(sign='0');

		A <= "00110011";
		B <= "01010101";
		wait for clk_period;
		assert(f_low="01100110");
		assert(f_high="00000000");
		assert(ov='0');
		assert(c_out='0');
		assert(equal='0');
		assert(sign='0');

		-- write ram
		cmd <= "1100";
		A <= "11110000";
		B <= "11001100";
		wait for clk_period;
		A <= "01010101";
		B <= "11111111";
		wait for clk_period;
--		cmd <= "1111";
--		B <= "11001100";
--		wait for clk_period;
--		assert(f_low="11110000");
--		B <= "11111111";
--		wait for clk_period;
--		assert(f_low="01010101");
		wait;
   end process;
END;
