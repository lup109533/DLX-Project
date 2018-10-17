library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.log2;
use work.utils.max;

entity REGISTER_FILE is
	generic (
		FIXED_R0			: boolean := false;
		WORD_SIZE			: natural;
		REGISTER_NUM		: natural;
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
		ADDR_IN		: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
		ADDR_OUT1	: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
		ADDR_OUT2	: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
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

	constant RF_ADDR_SIZE			: natural := REGISTER_NUM;
	constant WINDOW_SIZE			: natural := REGISTER_NUM;
	constant PHYSICAL_RF_SIZE		: natural := REGISTER_NUM * WINDOWS_NUM;
	constant PHYSICAL_RF_ADDR_SIZE	: natural := PHYSICAL_RF_SIZE;
	
	type   mem_array is array (0 to PHYSICAL_RF_SIZE-1) of std_logic_vector(WORD_SIZE-1 downto 0);
	signal memory					: mem_array;
	
	signal memory_in				: std_logic_vector(WORD_SIZE-1 downto 0);
	
	signal addr_in_s				: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_out1_s				: integer range 0 to RF_ADDR_SIZE-1;
	signal addr_out2_s				: integer range 0 to RF_ADDR_SIZE-1;
	signal translated_addr_in_s		: integer range 0 to PHYSICAL_RF_ADDR_SIZE-1;
	signal translated_addr_out1_s	: integer range 0 to PHYSICAL_RF_ADDR_SIZE-1;
	signal translated_addr_out2_s	: integer range 0 to PHYSICAL_RF_ADDR_SIZE-1;
	signal addr_in_index			: integer range 0 to PHYSICAL_RF_ADDR_SIZE-1;
	signal addr_out1_index			: integer range 0 to PHYSICAL_RF_ADDR_SIZE-1;
	signal addr_out2_index			: integer range 0 to PHYSICAL_RF_ADDR_SIZE-1;
	
	signal cwp_init					: std_logic_vector(WINDOWS_NUM-1 downto 0);
	signal cwp_s					: std_logic_vector(WINDOWS_NUM-1 downto 0);
	
	signal memory_enable			: std_logic;
	signal spill_s					: std_logic;
	signal fill_s					: std_logic;
	
	signal offset_sel				: integer range 0 to WINDOWS_NUM-1;
	
	type   offset_array	is array (0 to WINDOWS_NUM-1) of integer range 0 to PHYSICAL_RF_SIZE-1;
	signal offset					: offset_array;
	
	type   rf_state is (OK, SPILL_WAIT_ACK, RF_SPILL, FILL_WAIT_ACK, RF_FILL, UPDATE_SWP);
	signal state					: rf_state;
	
	signal spill_fill_counter		: integer range 0 to PHYSICAL_RF_ADDR_SIZE;
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
			for i in 0 to PHYSICAL_RF_SIZE-1 loop
				memory(i) <= (others => '0');
			end loop;
		elsif (ENB = '1' and rising_edge(CLK) and memory_enable = '1') then
			-- Write to memory
			if (WR = '1') then
				memory(addr_in_index) <= memory_in;
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
	
	has_not_fixed_r0: if not(FIXED_R0) generate
		memory_in <= MBUS(WORD_SIZE-1 downto 0) when (state = RF_FILL) else DIN;
	end generate;
	
	has_fixed_r0: if (FIXED_R0) generate
		memory_in	<= MBUS(WORD_SIZE-1 downto 0) when (state = RF_FILL)   else
					   (others => '0')            when (addr_in_index = 0) else
					   DIN;
	end generate;
	
	
	addr_in_index	<= spill_fill_counter when (state = RF_FILL)  else translated_addr_in_s;
	addr_out1_index <= spill_fill_counter when (state = RF_SPILL) else translated_addr_out1_s;
	addr_out2_index <= translated_addr_out2_s;
	
	translated_addr_in_s	<= addr_in_s   + offset(offset_sel);
	translated_addr_out1_s	<= addr_out1_s + offset(offset_sel);
	translated_addr_out2_s	<= addr_out2_s + offset(offset_sel);
	
	cwp_init(0 downto 0)				<= "1";
	cwp_init(WINDOWS_NUM-1 downto 1)	<= (others => '0');
	CWP: CIRCULAR_BUFFER	generic map (N => WINDOWS_NUM)
							port map (
								CLK  => CLK,
								RST  => RST,
								ENB  => memory_enable,
								INIT => cwp_init,
								SHR  => CALL,
								SHL	 => RETN,
								OVFL => spill_s,
								UNFL => fill_s,
								DOUT => cwp_s
							);
	
	offset_sel_proc: process (cwp_s) is
		variable i : integer range 0 to WINDOWS_NUM-1;
	begin
		for i in 0 to WINDOWS_NUM-1 loop
			if (cwp_s(i) = '1') then
				offset_sel <= i;
				exit;
			end if;
		end loop;
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
	memory_enable	<= '1' when (state = OK and spill_s = '0' and fill_s = '0') else '0';
	RF_OK			<= memory_enable;
	
	bus_manager: process (spill_fill_counter, state) is
	begin
		if (state = RF_SPILL) then
			MBUS(WORD_SIZE-1 downto 0) <= memory(spill_fill_counter);
		else
			MBUS <= (others => 'Z');
		end if;
	end process;
	
	swp_manager: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			swp_reg <= HEAP_ADDR;
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
			if (state = RF_SPILL or state = RF_FILL) then
				spill_fill_counter <= spill_fill_counter + 1;
			else
				spill_fill_counter <= 0;
			end if;
		end if;
	end process;

end architecture;