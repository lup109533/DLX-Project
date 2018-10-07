library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.log2;
use work.utils.max;

entity REGISTER_FILE is
	generic (
		WORD_SIZE			: natural;
		GLOBAL_REGISTER_NUM	: natural;
		IO_REGISTER_NUM		: natural;
		LOCAL_REGISTER_NUM	: natural;
		WINDOWS_NUM			: natural;
		SYSTEM_ADDR_SIZE	: natural
	);
	port (
		CLK			: in	std_logic;
		RST			: in	std_logic;
		ENB			: in	std_logic;
		HEAP_ADDR	: in	std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
		RD1			: in	std_logic;
		RD2			: in	std_logic;
		WR			: in	std_logic;
		DIN			: in	std_logic_vector(WORD_SIZE-1 downto 0);
		DOUT1		: out	std_logic_vector(WORD_SIZE-1 downto 0);
		DOUT2		: out	std_logic_vector(WORD_SIZE-1 downto 0);
		ADDR_IN		: in	std_logic_vector(log2(GLOBAL_REGISTER_NUM + 2*IO_REGISTER_NUM + LOCAL_REGISTER_NUM)-1 downto 0);
		ADDR_OUT1	: in	std_logic_vector(log2(GLOBAL_REGISTER_NUM + 2*IO_REGISTER_NUM + LOCAL_REGISTER_NUM)-1 downto 0);
		ADDR_OUT2	: in	std_logic_vector(log2(GLOBAL_REGISTER_NUM + 2*IO_REGISTER_NUM + LOCAL_REGISTER_NUM)-1 downto 0);
		CALL		: in 	std_logic;
		RETN		: in 	std_logic;
		SPILL		: out 	std_logic;
		FILL		: out	std_logic;
		SWP			: out	std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
		MBUS		: inout	std_logic_vector(max(log2(SYSTEM_ADDR_SIZE), WORD_SIZE)-1 downto 0);
		ACK			: in	std_logic;
		RF_OK		: out	std_logic
	);
end entity;

architecture behavioral of REGISTER_FILE is

	component CIRCULAR_BUFFER
		generic (N : integer);
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			INIT	: in	std_logic_vector(N-1 downto 0);
			SHR		: in	std_logic;
			SHL		: in	std_logic;
			OVFL	: out	std_logic;
			UNFL	: out	std_logic;
			DOUT	: out	std_logic_vector(N-1 downto 0)
		);
	end component;		

	constant RF_ADDR_SIZE			: natural := log2(GLOBAL_REGISTER_NUM + 2*IO_REGISTER_NUM + LOCAL_REGISTER_NUM);
	constant WINDOW_SIZE			: natural := IO_REGISTER_NUM + LOCAL_REGISTER_NUM;
	constant PHYSICAL_RF_SIZE		: natural := GLOBAL_REGISTER_NUM + WINDOWS_NUM*(IO_REGISTER_NUM + LOCAL_REGISTER_NUM);
	
	type   mem_array is array (0 to PHYSICAL_RF_SIZE-1) of std_logic_vector(WORD_SIZE-1 downto 0);
	signal memory					: mem_array;
	
	signal translated_addr_in_s		: integer range 0 to RF_ADDR_SIZE-1;
	signal translated_addr_out1_s	: integer range 0 to RF_ADDR_SIZE-1;
	signal translated_addr_out2_s	: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_in_s				: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_out1_s				: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_out2_s				: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_in_index			: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_out1_index			: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_out2_index			: integer range 0 to RF_ADDR_SIZE-1;
	
	signal cwp_init					: std_logic_vector(WINDOWS_NUM*2-1 downto 0);
	signal cwp_s					: std_logic_vector(WINDOWS_NUM*2-1 downto 0);
	signal io_cwp_s					: std_logic_vector(WINDOWS_NUM-1 downto 0);
	signal local_cwp_s				: std_logic_vector(WINDOWS_NUM-1 downto 0);
	
	signal global_enable			: std_logic;
	signal spill_s					: std_logic;
	signal fill_s					: std_logic;
	
	signal in_offset_sel			: integer range 0 to WINDOWS_NUM-1;
	signal local_offset_sel			: integer range 0 to WINDOWS_NUM-1;
	signal out_offset_sel			: integer range 0 to WINDOWS_NUM-1;
	
	type   offset_array	is array (0 to WINDOWS_NUM-1) of integer range 0 to PHYSICAL_RF_SIZE-1;
	signal offset					: offset_array;
	
	type   rf_state is (OK, SPILL_WAIT_ACK, RF_SPILL, FILL_WAIT_ACK, RF_FILL, UPDATE_SWP);
	signal state					: rf_state;
	
	signal spill_fill_counter		: integer range 0 to WINDOW_SIZE-1;
	signal swp_reg					: std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
	signal swp_s					: std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
	
begin

	addr_in_s	<= to_integer(unsigned(ADDR_IN));
	addr_out1_s	<= to_integer(unsigned(ADDR_OUT1));
	addr_out2_s	<= to_integer(unsigned(ADDR_OUT2));

	rf_manager: process (CLK, RST) is
	begin
		if (RST = '0') then
			-- Reset memory
			for i in 0 to PHYSICAL_RF_SIZE loop
				memory(i) <= (others => '0');
			end loop;
		elsif (ENB = '1' and rising_edge(CLK) and global_enable = '1') then
			-- Write to memory
			if (WR = '1') then
				memory(addr_in_index) <= DIN;
			end if;
			-- Read1 from memory
			if (RD1 = '1') then
				DOUT1 <= memory(addr_out1_index);
			else
				DOUT1 <= (others => '0');
			end if;
			-- Read2 from memory
			if (RD2 = '1') then
				DOUT2 <= memory(addr_out2_index);
			else
				DOUT2 <= (others => '0');
			end if;
		end if;
	end process;
	
	addr_in_index	<= translated_addr_in_s;
	addr_out1_index <= spill_fill_counter when (state = RF_SPILL or state = RF_FILL) else translated_addr_out1_s;
	addr_out2_index <= translated_addr_out2_s;
	
	addr_translator: process (addr_in_s, addr_out1_s, addr_out2_s, offset, in_offset_sel, local_offset_sel, out_offset_sel) is
	begin
		-- ADDR_IN
		if (addr_in_s < GLOBAL_REGISTER_NUM) then
			translated_addr_in_s <= addr_in_s;
		elsif (addr_in_s < GLOBAL_REGISTER_NUM + IO_REGISTER_NUM) then
			translated_addr_in_s <= addr_in_s + offset(in_offset_sel);
		elsif (addr_in_s < GLOBAL_REGISTER_NUM + IO_REGISTER_NUM + LOCAL_REGISTER_NUM) then
			translated_addr_in_s <= addr_in_s + offset(local_offset_sel);
		else
			translated_addr_in_s <= addr_in_s + offset(out_offset_sel);
		end if;
		-- ADDR_OUT1
		if (addr_out1_s < GLOBAL_REGISTER_NUM) then
			translated_addr_out1_s <= addr_out1_s;
		elsif (addr_out1_s < GLOBAL_REGISTER_NUM + IO_REGISTER_NUM) then
			translated_addr_out1_s <= addr_out1_s + offset(in_offset_sel);
		elsif (addr_out1_s < GLOBAL_REGISTER_NUM + IO_REGISTER_NUM + LOCAL_REGISTER_NUM) then
			translated_addr_out1_s <= addr_out1_s + offset(local_offset_sel);
		else
			translated_addr_out1_s <= addr_out1_s + offset(out_offset_sel);
		end if;
		-- ADDR_OUT2
		if (addr_out2_s < GLOBAL_REGISTER_NUM) then
			translated_addr_out2_s <= addr_out2_s;
		elsif (addr_out2_s < GLOBAL_REGISTER_NUM + IO_REGISTER_NUM) then
			translated_addr_out2_s <= addr_out2_s + offset(in_offset_sel);
		elsif (addr_out2_s < GLOBAL_REGISTER_NUM + IO_REGISTER_NUM + LOCAL_REGISTER_NUM) then
			translated_addr_out2_s <= addr_out2_s + offset(local_offset_sel);
		else
			translated_addr_out2_s <= addr_out2_s + offset(out_offset_sel);
		end if;
	end process;
	
	cwp_init(2 downto 0)				<= "111";
	cwp_init(2*WINDOWS_NUM-1 downto 3)	<= (others => '0');
	CWP: CIRCULAR_BUFFER	generic map (N => 2*WINDOWS_NUM)
							port map (
								CLK  => CLK,
								RST  => RST,
								ENB  => global_enable,
								INIT => cwp_init,
								SHR  => CALL,
								SHL	 => RETN,
								OVFL => spill_s,
								UNFL => fill_s,
								DOUT => cwp_s
							);
	cwp_proc: process (cwp_s) is
	begin
		for i in 0 to WINDOWS_NUM-2 loop
			io_cwp_s(i) <= cwp_s(2*i);
		end loop;
		
		for i in 0 to WINDOWS_NUM-2 loop
			local_cwp_s(i) <= cwp_s(2*i+1);
		end loop;
	end process;
	
	offset_sel_proc: process (io_cwp_s, local_cwp_s) is
		variable i : integer;
	begin
		if (io_cwp_s(0) = '1' and io_cwp_s(WINDOWS_NUM-1) = '1') then
			in_offset_sel	<= WINDOWS_NUM-1;
			out_offset_sel	<= 0;
		else
			for i in 0 to WINDOWS_NUM-1 loop
				if (io_cwp_s(i) = '1') then
					exit;
				end if;
			end loop;
			in_offset_sel	<= i;
			out_offset_sel	<= i+1;
		end if;
		for i in 0 to WINDOWS_NUM-1 loop
			if (local_cwp_s(i) = '1') then
				exit;
			end if;
		end loop;
		local_offset_sel	<= i;
	end process;
	
	offset_proc: process (offset) is
	begin
		for i in 0 to WINDOWS_NUM-1 loop
			offset(i) <= WINDOW_SIZE*i;
		end loop;
	end process;
	
	fsm_proc: process (CLK, RST) is
	begin
		if (RST = '0') then
			state <= OK;
		elsif (ENB = '1' and rising_edge(CLK)) then
			case state is
				when OK =>
					if (spill_s = '1') then
						state <= SPILL_WAIT_ACK;
					elsif (fill_s = '1') then
						state <= FILL_WAIT_ACK;
					else
						state <= OK;
					end if;
					
				when SPILL_WAIT_ACK =>
					if (ACK = '1') then
						state <= RF_SPILL;
					else
						state <= SPILL_WAIT_ACK;
					end if;
					
				when RF_SPILL =>
					if (ACK = '0') then
						state <= UPDATE_SWP;
					else
						state <= RF_SPILL;
					end if;
					
				when FILL_WAIT_ACK =>
					if (ACK = '1') then
						state <= RF_FILL;
					else
						state <= FILL_WAIT_ACK;
					end if;
					
				when RF_FILL =>
					if (ACK = '0') then
						state <= UPDATE_SWP;
					else
						state <= RF_FILL;
					end if;
				
				when UPDATE_SWP =>
					state <= OK;
			end case;
		end if;
	end process;
	SPILL			<= spill_s;
	FILL			<= fill_s;
	global_enable	<= '1' when (state = OK and spill_s = '0' and fill_s = '0') else '0';
	RF_OK			<= global_enable;
	
	bus_manager: process (state) is
	begin
		if (state = RF_SPILL) then
			MBUS(WORD_SIZE-1 downto 0) <= memory(addr_out1_index);
		elsif (state = RF_FILL) then
			memory(addr_out1_index) <= MBUS(WORD_SIZE-1 downto 0);
		else
			MBUS <= (others => 'Z');
		end if;
	end process;
	
	swp_manager: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			swp_reg <= (others => '0');
		elsif (ENB = '1' and rising_edge(CLK)) then
			swp_reg <= swp_s;
		end if;
	end process;
	swp_s <= MBUS(log2(SYSTEM_ADDR_SIZE)-1 downto 0) when (state = UPDATE_SWP) else swp_reg;
	SWP   <= swp_s;
	
	spill_fill_counter_manager: process (CLK, RST) is
	begin
		if (RST = '0') then
			spill_fill_counter <= 0;
		elsif (rising_edge(CLK)) then
			if (state = SPILL_WAIT_ACK or state = FILL_WAIT_ACK) then
				spill_fill_counter <= offset(in_offset_sel);
			elsif (state = RF_SPILL or state = RF_FILL) then
				spill_fill_counter <= spill_fill_counter + 1;
			else
				spill_fill_counter <= 0;
			end if;
		end if;
	end process;

end architecture;