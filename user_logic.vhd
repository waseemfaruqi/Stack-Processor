-- Company: Drexel ECE
-- Engineer: Prawat
-- Module Name: splite (sp lite)
-- Comments: Stack Processor iterative and recursive process capable

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity user_logic is
generic (A : natural := 10);
port (
		run,reset,bus2mem_en,bus2mem_we,ck	: in std_logic;
		bus2mem_addr						: in std_logic_vector(A-1 downto 0);
		bus2mem_data_in						: in std_logic_vector(31 downto 0);
		sp2bus_data_out						: out std_logic_vector(31 downto 0);	
		done								: out std_logic);
end user_logic;

architecture Behavioral of user_logic is
-- bram signals
-- wea is bram port we is processor signal
Signal wea, we  : STD_LOGIC_VECTOR(0 DOWNTO 0);
Signal addra 	: STD_LOGIC_VECTOR(A-1 DOWNTO 0);
Signal dina 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
Signal douta 	: STD_LOGIC_VECTOR(31 DOWNTO 0);
--cast bus2mem_we to std_logic_vector
signal temp_we  : STD_LOGIC_VECTOR(0 DOWNTO 0);

-- pointers
signal sp,pc,mem_addr,b : std_logic_vector(A-1 downto 0);

-- data registers
signal mem_data_in,mem_data_out,ir  : std_logic_vector(31 downto 0);
signal temp1,temp2      			: std_logic_vector(31 downto 0);

-- flags
Signal busy, done_FF							: std_logic;
signal less_than_flag, grtr_than_flag, eq_flag	: std_logic;

type state is (idle,fetch,fetch2,fetch4,fetch5,exe,chill);--fetch3,
Signal n_s: state;
----------------------------------
-- Instruction Definitions
-- Leftmost hex is the step in an instruction
-- higher hex is the code for an instruction,
-- e.g., the steps in SC (constant) instruction 0x01,.., 0x05
-- the steps in sl (load from memory) 0x11 to 0x19
-- When shoter Latency BRAM states are eliminated
-----------------------------------
constant HALT 	: std_logic_vector(31 downto 0) := (x"000000FF");
constant SC 	: std_logic_vector(31 downto 0) := (x"00000001");
constant SC2	: std_logic_vector(31 downto 0) := (x"00000002");
constant SC3	: std_logic_vector(31 downto 0) := (x"00000003");
constant SC4	: std_logic_vector(31 downto 0) := (x"00000004");
constant SC5	: std_logic_vector(31 downto 0) := (x"00000005");

constant sl		: std_logic_vector(31 downto 0) := (x"00000011");
constant sl2	: std_logic_vector(31 downto 0) := (x"00000012");
-- constant sl13: std_logic_vector(31 downto 0) := (x"00000013");
constant sl4	: std_logic_vector(31 downto 0) := (x"00000014");
constant sl5	: std_logic_vector(31 downto 0) := (x"00000015");
constant sl6	: std_logic_vector(31 downto 0) := (x"00000016");
-- constant sl7 : std_logic_vector(31 downto 0) := (x"00000017");
constant sl8	: std_logic_vector(31 downto 0) := (x"00000018");
constant sl9	: std_logic_vector(31 downto 0) := (x"00000019");

constant ss		: std_logic_vector(31 downto 0) := (x"00000021");
constant ss2	: std_logic_vector(31 downto 0) := (x"00000022");
-- constant ss3 : std_logic_vector(31 downto 0) := (x"00000023");
constant ss4	: std_logic_vector(31 downto 0) := (x"00000024");
constant ss5	: std_logic_vector(31 downto 0) := (x"00000025");
constant ss6	: std_logic_vector(31 downto 0) := (x"00000026");

constant sadd	: std_logic_vector(31 downto 0) := (x"00000031");
constant sadd2	: std_logic_vector(31 downto 0) := (x"00000032");
-- constant sadd3	: std_logic_vector(31 downto 0) := (x"00000033");
constant sadd4	: std_logic_vector(31 downto 0) := (x"00000034");
constant sadd5	: std_logic_vector(31 downto 0) := (x"00000035");
constant sadd6	: std_logic_vector(31 downto 0) := (x"00000036");

constant ssub	: std_logic_vector(31 downto 0) := (x"00000041");
constant ssub2	: std_logic_vector(31 downto 0) := (x"00000042");
-- constant ssub3	: std_logic_vector(31 downto 0) := (x"00000043");
constant ssub4	: std_logic_vector(31 downto 0) := (x"00000044");
constant ssub5	: std_logic_vector(31 downto 0) := (x"00000045");
constant ssub6	: std_logic_vector(31 downto 0) := (x"00000046");

constant sjlt	: std_logic_vector(31 downto 0) := (x"00000051");
constant sjlt2	: std_logic_vector(31 downto 0) := (x"00000052");
-- constant sjlt3	: std_logic_vector(31 downto 0) := (x"00000053");
constant sjlt4	: std_logic_vector(31 downto 0) := (x"00000054");
constant sjlt5	: std_logic_vector(31 downto 0) := (x"00000055");

constant sjgt   : std_logic_vector(31 downto 0) := (x"00000061");
constant sjgt2  : std_logic_vector(31 downto 0) := (x"00000062"); 
-- constant sjgt3: std_logic_vector(31 downto 0) := (x"00000063");
constant sjgt4	: std_logic_vector(31 downto 0) := (x"00000064");
constant sjgt5	: std_logic_vector(31 downto 0) := (x"00000065");

constant sjeq	: std_logic_vector(31 downto 0) := (x"00000071");
constant sjeq2	: std_logic_vector(31 downto 0) := (x"00000072");
-- constant sjeq3: std_logic_vector(31 downto 0) := (x"00000073");
constant sjeq4	: std_logic_vector(31 downto 0) := (x"00000074");
constant sjeq5	: std_logic_vector(31 downto 0) := (x"00000075");

constant sjmp	: std_logic_vector(31 downto 0) := (x"000000E1");
constant sjmp2	: std_logic_vector(31 downto 0) := (x"000000E2");
-- constant sjmp3: std_logic_vector(31 downto 0) := (x"000000E3");
constant sjmp4	: std_logic_vector(31 downto 0) := (x"000000E4");
constant sjmp5	: std_logic_vector(31 downto 0) := (x"000000E5");

constant scmp	: std_logic_vector(31 downto 0) := (x"000000F1");
constant scmp2	: std_logic_vector(31 downto 0) := (x"000000F2");
-- constant scmp3: std_logic_vector(31 downto 0) := (x"000000F3");
constant scmp4	: std_logic_vector(31 downto 0) := (x"000000F4");
constant scmp5	: std_logic_vector(31 downto 0) := (x"000000F5");
constant scmp6	: std_logic_vector(31 downto 0) := (x"000000F6");

constant smul	: std_logic_vector(31 downto 0) := (x"00000101");
constant smul2	: std_logic_vector(31 downto 0) := (x"00000102");
-- constant smul3: std_logic_vector(31 downto 0) := (x"00000103");
constant smul4	: std_logic_vector(31 downto 0) := (x"00000104");
constant smul5	: std_logic_vector(31 downto 0) := (x"00000105");
constant smul6	: std_logic_vector(31 downto 0) := (x"00000106");

constant scall 	: std_logic_vector(31 downto 0) := (x"00000081");
constant scall2	: std_logic_vector(31 downto 0) := (x"00000082");
-- constant scall3: std_logic_vector(31 downto 0) := (x"00000083");
constant scall4	: std_logic_vector(31 downto 0) := (x"00000084");
constant scall5	: std_logic_vector(31 downto 0) := (x"00000085");
constant scall6	: std_logic_vector(31 downto 0) := (x"00000086");
constant scall7	: std_logic_vector(31 downto 0) := (x"00000087");
constant scall8	: std_logic_vector(31 downto 0) := (x"00000088");
constant scall9 : std_logic_vector(31 downto 0) := (x"00000089");
constant scall10: std_logic_vector(31 downto 0) := (x"0000008A");

constant srtn 	: std_logic_vector(31 downto 0) := (x"00000091");
constant srtn2	: std_logic_vector(31 downto 0) := (x"00000092");
constant srtn3	: std_logic_vector(31 downto 0) := (x"00000093");
constant srtn4	: std_logic_vector(31 downto 0) := (x"00000094");
constant srtn5	: std_logic_vector(31 downto 0) := (x"00000095");
constant srtn6	: std_logic_vector(31 downto 0) := (x"00000096");
constant srtn7	: std_logic_vector(31 downto 0) := (x"00000097");
constant srtn8	: std_logic_vector(31 downto 0) := (x"00000098");
constant srtn9	: std_logic_vector(31 downto 0) := (x"00000099");

constant salloc	  : std_logic_vector(31 downto 0) := (x"000000A1");
constant sdealloc : std_logic_vector(31 downto 0) := (x"000000B1");

constant slaa 	: std_logic_vector(31 downto 0) := (x"000000C1");
constant slaa2	: std_logic_vector(31 downto 0) := (x"000000C2");
-- constant slaa3: std_logic_vector(31 downto 0) := (x"000000C3");
constant slaa4: std_logic_vector(31 downto 0) := (x"000000C4");
constant slaa5: std_logic_vector(31 downto 0) := (x"000000C5");
constant slaa6: std_logic_vector(31 downto 0) := (x"000000C6");

constant slla : std_logic_vector(31 downto 0) := (x"000000D1");
constant slla2: std_logic_vector(31 downto 0) := (x"000000D2");
-- constant slla3: std_logic_vector(31 downto 0) := (x"000000D3");
constant slla4: std_logic_vector(31 downto 0) := (x"000000D4");
constant slla5: std_logic_vector(31 downto 0) := (x"000000D5");

constant sma    : std_logic_vector(31 downto 0) := (x"00000111");
constant sma2   : std_logic_vector(31 downto 0) := (x"00000112");
constant sma3   : std_logic_vector(31 downto 0) := (x"00000113");
constant sma4   : std_logic_vector(31 downto 0) := (x"00000114");
constant sma5   : std_logic_vector(31 downto 0) := (x"00000115");
constant sma6   : std_logic_vector(31 downto 0) := (x"00000116");

constant scp    : std_logic_vector(31 downto 0) := (x"00000c01");
constant scp2   : std_logic_vector(31 downto 0) := (x"00000c02");
--constant scp3   : std_logic_vector(31 downto 0) := (x"00000c03");
constant scp4   : std_logic_vector(31 downto 0) := (x"00000c04");
constant scp5   : std_logic_vector(31 downto 0) := (x"00000c05");
constant scp6   : std_logic_vector(31 downto 0) := (x"00000c06");
--constant scp7   : std_logic_vector(31 downto 0) := (x"00000c07");
constant scp8   : std_logic_vector(31 downto 0) := (x"00000c08");
constant scp9   : std_logic_vector(31 downto 0) := (x"00000c09");

-- components
COMPONENT blk_mem_gen_0
PORT(
		clka	: IN STD_LOGIC;
		wea		: IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		addra	: IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		dina	: IN STD_LOGIC_VECTOR(31 DOWNTO 0);	
		douta	: OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;
-- MEM bridge multiplexes BUS or processor signals to bram.
-- It also flags busy signal.
component bus_ip_mem_bridge is
generic (A: natural := 10);
port(ip2mem_data_in,bus2mem_data_in : in std_logic_vector(31 downto 0);
	 ip2mem_addr,bus2mem_addr 		: in std_logic_vector(A-1 downto 0);
	 bus2mem_we,ip2mem_we 			: in std_logic_vector(0 downto 0);
	 bus2mem_en 					: in std_logic;
	 addra 							: out std_logic_vector(A-1 downto 0);
	 dina 							: out std_logic_vector(31 downto 0);
	 wea 							: out std_logic_vector(0 downto 0);
	 busy 							: out std_logic);
end component;

begin

temp_we(0) <= bus2mem_we; -- wire bus2mem_we to an std_logic_vector

-- MEM bridge multiplexes BUS or processor signals to bram.
bridge: bus_ip_mem_bridge -- It also flags busy signal to processor.
generic map(A)
port map(
		bus2mem_addr 	=> bus2mem_addr,
		bus2mem_data_in => bus2mem_data_in,
		ip2mem_addr 	=> mem_addr,
		ip2mem_data_in 	=> mem_data_in,
		bus2mem_we 		=> temp_we,
		ip2mem_we 		=> we,
		bus2mem_en 		=> bus2mem_en,
		addra 			=> addra,
		dina 			=> dina,
		wea 			=> wea,
		busy 			=> busy);

-- main memory
mm : blk_mem_gen_0 PORT MAP (clka 	=> ck,
							 wea 	=> wea,
							 addra 	=> addra,
							 dina 	=> dina,
							 douta 	=> douta);

-- memory data out register always get new douta
process(ck)
begin
	if ck='1' and ck'event then
		if reset = '1' then mem_data_out <= (others => '0');
		else mem_data_out <= douta;
		end if;
	end if;
end process;

-- wire to output ports sp2bus_data_out
sp2bus_data_out <= mem_data_out; done <= done_FF;

process(ck)
-- temp signal for multiply instruction
variable temp_mult:std_logic_vector(63 downto 0);
begin
	if ck='1' and ck'event then
		if reset='1' then n_s <= idle; else
	-- Machine State Diagram
			case n_s is -- run halt
				when chill =>--reset~~>(idle)-->(fetch)-->(exe)-->(chill)
					null; 	-- 						   |		|
							-- 					   | 		v
							-- 						<----(case ir)

				when idle =>
					pc 		 	<= (others => '0');
					sp 		 	<= (7 => '1', others => '0'); -- stack base 128
					ir 		 	<= (others => '0');
					temp1    	<= (others => '0'); temp2 	<= (others => '0');
					mem_addr 	<= (others => '0');
					mem_data_in <= (others => '0');
					we 			<= "0"; done_FF <= '0';

					-- poll on run and not busy
					if run='1' and busy='0' then n_s <= fetch; end if;

				when fetch => 					-- "init" means to initiate an action
					mem_addr <= pc; pc <= pc+1;	--init load pe to mem_addr
					we 		 <= "0"; 			-- enable read next state
					n_s 	 <= fetch2;	
				when fetch2 => 					-- mem_addr valid, pc advanced
					we <= "0"; 			 -- read   			 --------
					n_s <= fetch4;   						  ----- mem_addr
--				 when fetch3 =>      -- mem read latency=1 	|   register
--					 we <= "0";      --read 				 --------
--					 n_s <= fetch4;  --				     | BRAM |
				when fetch4 => 		   -- douta valid        --------
					we <= "0"; 		   -- read 					| dout
					n_s <= fetch5; 	   -- 					  -----
				when fetch5 => 		   -- mem_data_out valid  ----- mem_data_out
					we <= "0"; 		   -- read 					|   register
					ir <= mem_data_out;-- init ir load
					n_s <= exe;
				when exe => 		   -- ir loaded
					case ir is 				-- Machine Instructions
						when halt => 		-- signal done output and go to chill
							done_FF <= '1'; n_s <= chill;
						-- Stack Constant, init load constant pointed to by pce
						when sc =>
							mem_addr <= pc; 	--pe points at constant
							pc 		 <= pc+1;	--advance to next instruction
							we 		 <= "0"; 	--enable read next state
							ir 	     <= sc2;
						when sc2 => 			-- mem_addr valid
							we 		<= "0"; 	-- read
							ir 		<= sc4;
--						 when sc3 => 			-- douta not valid latency 1
--							 we <= "0"; 		-- read
--							 ir <= sc4;
						when sc4 => 			-- douta valid
							we 		<= "0"; 	-- read
							ir 		<= sc5;
						when sc5 => 			-- mem_data_out valid
							mem_addr 	<= sp; sp <= sp+1;
							mem_data_in <= mem_data_out;
							we 			<= "1"; -- write enable next state
							n_s 		<= fetch;
						--Load data from memory:pop address,read and stack data
						when sl =>
							mem_addr <= sp-1; sp <= sp-1;	--init pop data address
							we <= "0"; 						-- enable read next state
							ir <= sl2;
						when sl2 => 	-- mem_addr updated
							we <= "0"; 	-- read
							ir <= sl4;
						-- when s13 => -- douta not valid latency 1
							-- we <= "0"; 	-- read
							-- ir <= s14;
						when sl4 => -- douta valid
							we <= "0"; -- read
							ir <= sl5;
						when sl5 => -- mem_data_out valid
							mem_addr <= mem_data_out(A-1 downto 0);	--data Address
							we 		 <= "0"; 						-- read
							ir 		 <= sl6;
						when sl6 => 	-- mem_addr updated
							we <= "0"; -- read
							ir <= sl8;
						-- when sl7 => -- douta not valid latency 1
							-- we <= "0"; -- read
							-- ir <= s18;
						when sl8 => -- douta valid
							we <= "0"; -- read
							ir <= sl9;
						when sl9 => -- mem_data_out valid
							mem_addr 	<= sp; sp <= sp+1;
							mem_data_in <= mem_data_out;--data read
							we 			<= "1"; -- write enable in next state
							n_s 		<= fetch;
						--Store data to memory:pop data,address,write to memory
						when ss =>
							mem_addr <= sp-1; sp <= sp-1;--initl pop data
							we 		 <= "0"; -- read
							ir 		 <= ss2;
						when ss2 => -- mem_addr updated1l
							mem_addr <= sp-1; sp <= sp-1;--init2 pop address
							we 		 <= "0"; -- read
							ir 		 <= ss4;
						-- when ss3 => --doutal not valid latency 1,
							-- we <= "0"; -- mem_addr updated2
							-- ir <= ss4;
						when ss4 => -- douta validl,
							we <= "0"; --douta2 not valid latency 1
							ir <= ss5;
						when ss5 => --douta valid2, mem_data_out validl
							we <= "0"; -- read
							temp1 <= mem_data_out;--temp <= data
							ir <= ss6;
						when ss6 => -- mem _data_out valid2
							mem_addr 	<= mem_data_out(A-1 downto 0);--init write
							mem_data_in <= temp1; --data in templ
							we 			<= "1"; -- write enable in next state
							n_s 		<= fetch;
						-- Add - pop operands add and push
						when sadd =>
							mem_addr <= sp-1;sp <= sp-1;--initl pop operand1l
							we 		 <= "0"; -- read
							ir 		 <= sadd2;
						when sadd2 => -- mem_addr updated1
							mem_addr <= sp-1; sp <= sp-1;--init2 pop operand2
							we 		 <= "0"; -- read
							ir 		 <= sadd4;
						-- when sadd3 =>--doutal not valid latency 1,mem_addr updated2
							-- we <= "0"; -- read
							-- ir <= sadd4;
						when sadd4 => -- douta validl, douta2 not valid
							we <= "0"; -- read
							ir <= sadd5;
						when sadd5 => -- douta valid2, mem_data_out validl
							we 		<= "0"; -- read
							temp1 	<= mem_data_out;--templ <= operandl
							ir 		<= sadd6;
						when sadd6 => -- mem _data_out valid2
							mem_addr <= sp; sp <= sp+1; -- init push
							mem_data_in <= temp1+mem_data_out;--operand1+operand2
							we <= "1"; -- write enable in next state
							n_s <= fetch;
                        --copy instruction
                        when scp =>
                            mem_addr <= sp-1; sp <= sp-1;--initl pop source address
                            we          <= "0"; -- read
                            ir          <= scp2;
                        when scp2 =>
                            mem_addr <= sp-1; sp <= sp-1;--initl pop destination address
                            we          <= "0"; -- read
                            ir          <= scp4;
--                        when scp3 =>
--                            we          <= "0"; -- read
--                            ir          <= scp4;
                        when scp4 =>
                            we          <= "0"; -- read
                            ir          <= scp5;
                        when scp5 =>
                            we          <= "0"; -- read
                            mem_addr    <= mem_data_out(A-1 downto 0);    --address = source address
                            ir          <= scp6;
                        when scp6 =>
                            we          <= "0"; -- read
                            temp1       <= mem_data_out;    --temp1 = dest address
                            ir          <= scp8;
--                        when scp7 =>
--                            we          <= "0"; -- read
--                            ir          <= scp8;
                        when scp8 =>
                            we          <= "0"; -- read
                            ir          <= scp9;
                        when scp9 =>
                            mem_addr    <= temp1(A-1 downto 0);
                            mem_data_in <= mem_data_out;
                            we          <= "1"; -- read
                            n_s         <= fetch;
                        --pop 3 operands, multiply the last two, and add with the top one
						when sma  =>
                            mem_addr <= sp-1;sp <= sp-1;--initl pop operandl
                            we       <= "0"; -- read
                            ir       <= sma2;
                        when sma2  =>
                            mem_addr <= sp-1;sp <= sp-1;--initl pop operand2
                            we       <= "0"; -- read
                            ir       <= sma3;
                        when sma3  =>
                            mem_addr <= sp-1;sp <= sp-1;--initl pop operand3
                            we       <= "0"; -- read
                            ir       <= sma4;
                        when sma4  =>
                            we       <= "0"; -- read
                            temp1 	 <= mem_data_out;--templ <= operandl
                            ir       <= sma5;
                        when sma5  =>
                            we       <= "0"; -- read
                            temp_mult := temp1*mem_data_out;
                            temp2 <= temp_mult(31 downto 0);--temp2 <= operandl * operand2
                            ir       <= sma6;
                        when sma6  =>
                            mem_addr    <= sp; sp <= sp+1;      -- init push
                            we          <= "1";                 -- write enable in next state
                            mem_data_in <= temp2+mem_data_out;  -- temp2 + operand3
                            n_s         <= fetch;         
						-- Substract - pop operands, subtract and push, and set flags
						when ssub =>
							mem_addr <= sp-1; sp <= sp-1;--init pop operand1l
							we 		 <= "0"; -- read
							ir 		 <= ssub2;
						when ssub2 => -- mem_addr updated1
							mem_addr 	<= sp-1; sp <= sp-1;--init pop operand2
							we 			<= "0"; -- read
							ir 			<= ssub4;
						-- when ssub3 => -- doutal not valid latency 1, mem_addr updated2
							-- we <= "0"; -- read
							-- ir <= ssub4;
						when ssub4 => -- doutal validl, douta2 not valid
							we <= "0"; -- mem_addr updated2
							ir <= ssub5;
						when ssub5 => -- douta valid2, mem_data_out valid1l
							we 		<= "0"; -- read
							temp1 	<= mem_data_out;--templ <= operandl
							ir 		<= ssub6;
						when ssub6 => -- mem _data_out valid2
							mem_addr 	<= sp; sp <= sp+1; -- init push
							mem_data_in <= temp1-mem_data_out;--operand1-operand2
							we 			<= "1"; -- write enable in next state
							if mem_data_out<temp1 then less_than_flag<='1';else less_than_flag<='0';end if;
							if mem_data_out>temp1 then grtr_than_flag<='1';else grtr_than_flag<='0';end if;
							if mem_data_out=temp1 then eq_flag<='1';else eq_flag<='0';end if;
							n_s <= fetch;
						-- Multiply - pop operands multiply and push
						when smul =>
							mem_addr 	<= sp-1; sp <= sp-1;--initl pop operand1
							we 			<= "0"; -- read
							ir 			<= smul2;
						when smul2 => -- mem_addr updated1
							mem_addr 	<= sp-1; sp <= sp-1;--init2 pop operand2
							we 			<= "0"; -- read
							ir 			<= smul4;
						-- when smul3 => -- doutal not valid latency 1, mem_addr updated2
							-- we <= "0"; -- read
							-- ir <= smul4;
						when smul4 => -- douta validl, douta2 not valid
							we <= "0"; -- read
							ir <= smul5;
						when smul5 => -- douta valid2, mem_data_out validl
							we <= "0"; -- read
							temp1 <= mem_data_out;--templ <= operand1
							ir <= smul6;
						when smul6 => -- mem_data_out valid2
							mem_addr 	<= sp; sp <= sp+1; -- init push
							temp_mult 	:= temp1*mem_data_out;
							mem_data_in <= temp_mult(31 downto 0);--operand1*operand2
							temp2 		<= temp_mult(63 downto 32);--High 32bits assigned for sanity check
							we <= "1"; 		-- write enable in next state
							n_s <= fetch;
						-- Compare - pop operands, subtract and set flags
						when scmp =>
							mem_addr <= sp-1; sp <= sp-1;--init pop operand1l
							we 		 <= "0"; -- read
							ir 		 <= scmp2;
						when scmp2 => -- mem_addr updated1
							mem_addr <= sp-1; sp <= sp-1;--init pop operand2
							we 		 <= "0"; -- read
							ir 		 <= scmp4;
						-- when scmp3 => -- doutal not valid latency 1, mem_addr updated2
							-- we <= "0"; -- read
							-- ir <= scmp4;
						when scmp4 => -- douta validl, douta2 not valid
							we <= "0"; -- read
							ir <= scmp5;
						when scmp5 => -- douta valid2, mem_data_out validl
							we 	  <= "0"; -- read
							temp1 <= mem_data_out;--templ <= operandl
							ir 	  <= scmp6;
						when scmp6 => -- mem _data_out valid2
							if mem_data_out<temp1 then less_than_flag<='1';else less_than_flag<='0';end if;
							if mem_data_out>temp1 then grtr_than_flag<='1';else grtr_than_flag<='0';end if;
							if mem_data_out=temp1 then eq_flag<='1';else eq_flag<='0';end if;
							n_s <= fetch;
						-- Jump - pop address, pe <= address
						when sjmp =>
							mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
							we <= "0"; -- read
							ir <= sjmp2;
						when sjmp2 => -- mem_addr updated
							we <= "0"; -- read
							ir <= sjmp4;
						-- when sjmp3 => -- douta not valid latency 1
							-- we <= "0"; -- read
							-- ir <= sjmp4;
						when sjmp4 => -- douta valid
							we <= "0"; -- read
							ir <= sjmp5;
						when sjmp5 => -- mem_data_out valid
							we  <= "0"; -- read
							pc  <= mem_data_out(A-1 downto 0);
							n_s <= fetch;
						-- Jump Less Than -pop address,pc<=address on less than flag
						when sjlt =>
							mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
							we 		 <= "0"; -- read
							ir 		 <= sjlt2;
						when sjlt2 => -- mem_addr updated
							we <= "0"; -- read
							ir <= sjlt4;
						-- when sjlt3 => -- douta not valid latency 1
							-- we <= "0"; -- read
							-- ir <= sj1t4;
						when sjlt4 => -- douta valid
							we <= "0"; -- read
							ir <= sjlt5;
						when sjlt5 => -- mem_data_out valid
							we <= "0"; -- read
							if less_than_flag='1' then pc <=mem_data_out(A-1 downto 0);end if;
							n_s <= fetch;
						-- Jump greater Than -pop address,pce<=address on grtr_than_flag
						when sjgt =>
							mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
							we <= "0"; -- read
							ir <= sjgt2;
						when sjgt2 => -- mem_addr updated
							we <= "0"; -- read
							ir <= sjgt4;
						-- when sjgt3 => -- douta not valid latency 1
							-- we <= "0"; -- read
							-- ir <= sjgt4;
						when sjgt4 => -- douta valid
							we <= "0"; -- read
							ir <= sjgt5;
						when sjgt5 => -- mem _data_out valid
							we <= "0"; -- read
							if grtr_than_flag='1' then pc <=mem_data_out(A-1 downto 0);end if;
							n_s <= fetch;
						-- Jump Equal - pop address, pe <= address on eq flag
						when sjeq =>
							mem_addr <= sp-1; sp <= sp-1;-- init pop jump-to address
							we 		 <= "0"; -- read
							ir 		 <= sjeq2;
						when sjeq2 => -- mem_addr updated
							we <= "0"; -- read
							ir <= sjeq4;
						-- when sjeq3 => -- douta not valid latency 1
							-- we <= "0"; -- read
							-- ir <= sjeq4;
						when sjeq4 => -- douta valid
							we <= "0"; -- read
							ir <= sjeq5;
						when sjeq5 => -- mem _data_out valid
							we <= "0"; -- read
							if eq_flag='1' then pc <= mem_data_out(A-1 downto 0);end if;
							n_s <= fetch;
						-- stack frame before executing scall instruction
						-- |agr0 	 | <- oldSP before subroutine call involing
						-- |agrl 	 |	pushing args, #args and subroutine address
						-- |agrN-1	 |
						-- |#args	 |
						-- |sub addr |
						-- |	***  | <- sp

						-- stack frame after executing scall instruction
						-- | agr0 	| <- oldSP before subroutine call involing
						-- | agrl 	| pushing args, #args and subroutine address
						-- | agrN-1	|
						-- | oldPc	|
						-- | oldSP 	| oldSP <= currentSP-N-1
						-- | old B	|
						-- | Flags	|
						-- | blank 	| <- B
						-- | Topofs | <- SP(local variable 0)

						-- Subroutine call, build stack frame
						-- before scall instruction - arguments,
						-- # of Args and subroutine address on the stack
						when scall =>
							mem_addr <= sp-1; sp <= sp-1;-- initl pop jump-to address
							we <= "0"; -- read
							ir <= scall2;
						when scall2 => -- mem_addr updated1
							mem_addr <= sp-1; sp <= sp-1;-- init2 pop # of args
							we <= "0"; -- read
							ir <= scall4;
						-- when scall3 => -- doutal not valid latency 1, mem_addr updated2
							-- we <= "0"; -- read
							-- ir <= sceall4;
						when scall4 => -- douta validl, douta2 not valid
							we <= "0"; -- read
							ir <= scall5;
						when scall5 => -- douta valid2, mem_data_out validl
							temp1 <= mem_data_out;--subroutine address
							we <= "0"; -- read
							ir <= scall6;
						when scall6 => -- mem _data_out valid2
							temp2 <= mem_data_out;--#args
							mem_addr <= sp; sp <= sp+1; -- init push
							mem_data_in <= "0000000000000000000000"&pc; --save pe to be on stack frame
							we <= "1";  -- write enable in next state
							ir <= scall7;
						when scall7 =>
							mem_addr <= sp; sp <= sp+1; -- init push, old sp (where arg0 is) to be on stack frame
							mem_data_in <= "0000000000000000000000" &sp-temp2-1;--displacement is #args+l
							we <= "1";  -- write enable in next state
							ir <= scall8;
						when scall8 =>-- save Base pointer
							mem_addr <= sp; sp <= sp+1;
							mem_data_in <= "0000000000000000000000"&B;
							we <= "1"; -- enable write in next state
							ir <= scall9;
						when scall9 =>-- save flags
							mem_addr <= sp; sp <= sp+1; -- sp will point at
							mem_data_in <= (0=>less_than_flag,1=>grtr_than_flag,2=>eq_flag,others=>'0');
							we <= "1"; -- enable write in next state
							ir <= scall10;
						when scall10 =>
							B <=sp; sp<=sp+1;			--new B points at blank and SP after blank,
							pc <= temp1(A-1 downto 0); 	-- jump subroutine (address in temp1)
							we <= "0"; 					-- disable write in next state
							n_s <= fetch;

						--stack frame at return instruction
						--| agrO 	| <- oldSP before calling subroutine
						--| agr1 	|
						--| agrN-1 	|
						--| oldPc 	|
						--| oldsP 	| oldSP<=SP-N-1
						--| old B 	|
						--| Flags 	|
						--| blank 	| <- B
						--| result	|
						--|  ***	| <- SP

						-- Return from subroutine call, deallocate stack frame

						when srtn =>
							mem_addr <= sp-1 ; sp <= sp-1;-- initl pop result
							we <= "0"; -- read
							ir <= srtn2;
						when srtn2 => -- init2 pop flags, mem_addr updated1l
							mem_addr <= sp-2; sp <= sp-2;
							we <= "0"; -- read
							ir <= srtn4;
						--when srtn3 => -- init3 pop o1dB, mem_addr updated2,douta not validl(latency)
						--	mem_addr <= sp-1l; sp<=sp-1;
						--	we <= "0"; -- read
						--	ir <= srtn5;
						when srtn4 => -- init3 pop oldB, mem_addr updated2,douta validl(result)
							mem_addr <= sp-1; sp <= sp-1;
							we <= "0"; -- read
							ir <= srtn5;
						when srtn5 => --init4 pop oldSP,mem_addr updated3(B) ,doutvalid2(flags),mem_data_out validl(result)
							mem_addr <= sp-1; sp <= sp-1;
							temp1 <= mem_data_out;-- result in templ
							we 	  <= "0"; -- read
							ir 	  <= srtn6;
						when srtn6 => --init5 pop oldPC,mem_addr updated4(sp),doutavalid3(B),mem_data_out valid2(flags)
							mem_addr 		<= sp-1; sp<=sp-1;
							we 				<= "0"; -- read
							eq_flag 		<= mem_data_out(2); -- flags restored
							grtr_than_flag 	<= mem_data_out(1);
							less_than_flag 	<= mem_data_out(0);
							ir <= srtn7;
						when srtn7 => -- mem_addr updated5(pc), douta valid4(sp), mem_data_out valid3(B)
							we 	<= "0"; -- read
							B 	<= mem_data_out(A-1 downto 0); -- B restored
							ir 	<= srtn8;
						when srtn8 => -- douta valid5(PC), mem_data_out valid4(SP)
							sp <= mem_data_out(A-1 downto 0); -- sp restored
							we <= "0"; -- read
							ir <= srtn9;
						when srtn9 => -- mem _data_out valid5(pc)
							mem_addr <= sp; sp <= sp+1;
							mem_data_in <= temp1;--return result on stack
							we <= "1"; -- write enable in next state
							pc <= mem_data_out(A-1 downto 0); -- PC restored
							n_s <= fetch;
						-- Allocate space on stack
						when salloc =>
							we <= "0"; -- read
							sp <= sp+1;
							n_s <= fetch;
						-- Deallocate space on stack
						when sdealloc =>
							we <= "0"; -- read
							sp <= sp-1;
							n_s <= fetch;
						-- Load Argument Address - pop displacement, push Arg address = oldSPtdispl
						when slaa =>
							mem_addr <= sp-1; sp <= sp-1; -- initl pop displacement
							we <= "0"; -- read
							ir <= slaa2;
						when slaa2 => -- mem_addrl updated
							mem_addr <= B-3; --init2 pop old SP pointed to by B-3
							we <= "0"; -- read
							ir <= slaa4;
						-- when slaa3 => -- doutal not valid latency 1, mem_addr2 updated
							-- we <= "0"; -- read
							-- ir <= slaa4;
						when slaa4 => -- doutal valid, mem_addr2 updated
							we <= "0"; -- read
							ir <= slaa5;
						when slaa5 => -- douta2 valid, mem_data_outl valid
							we <= "0"; -- read
							temp1 <= mem_data_out; --templ gets displacement
							ir <= slaa6;
						when slaa6 => -- mem_data_out2 valid
							mem_addr <= sp; sp <= sp+1;
							mem_data_in <= mem_data_out+temp1;--32-bit_extended_oldSP+displ
							we <= "1"; -- enable write next state
							n_s <= fetch;
						-- Load Local Address: pop displacement, push local address = Btdispl
						when slla =>
							mem_addr <= sp-1; sp <= sp-1; -- initl pop displacement
							we <= "0"; -- read
							ir <= slaa2;
						when slla2 => -- mem_addr updated
							we <= "0"; -- read
							ir <= slla4;
						-- when slla3 => -- doutal not valid latency 1
							-- we <= "0"; -- read
							-- ir <= slla4;
						when slla4 => -- douta valid
							we <= "0"; -- read
							ir <= slla5;
						when slla5 => -- mem_data_out valid
							mem_addr <= sp; sp <= sp+1;--local_ variable 0 starts at Btl
							mem_data_in <= "0000000000000000000000"&B + 1 + mem_data_out;
							we <= "1";--enable write next state
							n_s <= fetch;
						when others =>null;
					end case; -- instructions
			end case; -- fetch-execute
		end if; -- reset fence
	end if; -- clock fence
end process;
end Behavioral;
