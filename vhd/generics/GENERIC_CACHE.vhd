library ieee;
use ieee.std_logic_1164.all;
use work.utils.log2;
use work.utils.max;
use work.utils.CLK_FREQ;

entity GENERIC_CACHE is
	generic (word_size, virtual_addr_bits, addr_bits, set_size, rtc_size : natural);
	port(
		CLK	:	in	std_logic;
		RTC	:	in	std_logic(rtc_size-1 downto 0);
		MBUS	:	inout	std_logic_vector(word_size-1 downto 0);
		RD	:	in	std_logic; --Read
		HM	:	out	std_logic; --Hit/Miss
		ADDR	:	in	std_logic_vector(virtual_addr_bits-1 downto 0);
		ACK	:	in	std_logic;
		REQ	:	out	std_logic
	);
end GENERIC_CACHE;

architecture behavioral of GENERIC_CACHE is

-- CONSTANTS
	constant HIT			: std_logic := '0';
	constant MISS			: std_logic := '1';

	constant MAX_ADDR		: natural := 2**addr_bits;

	constant SET_NUM		: natural := (MAX_ADDR) / set_size;
	constant INDEX_BITS		: natural := log2(SET_NUM);
	constant TAG_BITS		: natural := virtual_addr_bits - INDEX_BITS;
	
	constant CACHE_ENTRY_SIZE	: natural := word_size + TAG_BITS + rtc_size + 1; -- Tag + Word + Timestamp + Valid bit
	constant MAX_INDEX		: natural := 2**INDEX_BITS;

-- SIGNALS
	subtype entry_t     is std_logic_vector(CACHE_ENTRY_SIZE-1 downto 0);
	subtype tag_t       is std_logic_vector(TAG_BITS-1 downto 0);
	subtype index_t     is std_logic_vector(max(INDEX_BITS,1)-1 downto 0);
	subtype word_t      is std_logic_vector(word_size-1 downto 0);
	subtype timestamp_t is std_logic_vector(rtc_size-1 downto 0);
	subtype line_addr_t is std_logic_vector(log2(set_size)-1 downto 0);
	type cache_set is array (set_size-1 downto 0) of entry_t;
	type mem_array is array (natural range <>) of cache_set;

	-- CACHE_ENTRY = (TAG)_(WORD)_(TIMESTAMP)_(VALID BIT)
	type TAG_PORTION       is integer range CACHE_ENTRY_SIZE-1 downto (word_size + 1);
	type WORD_PORTION      is integer range (word_size + 1)-1  downto (rtc_size + 1);
	type TIMESTAMP_PORTION is integer range (rtc_size + 1)-1   downto 1;

	signal tag		: tag_t;
	signal index		: index_t;
	signal word		: word_t;
	signal set		: cache_set;
	signal timestamp	: timestamp_t;
	signal set_line_addr	: line_addr_t;
	signal set_line_addr_in	: line_addr_t;
	signal memory		: mem_array(MAX_INDEX-1 downto 0);

	type cache_state is (OK, CACHE_MISS, READ_BUS);
	signal state : cache_state;

	signal cache_hit : std_logic;

begin

-- BUS DRIVER
	bus_driver: process(state, word, RD, cache_hit) is begin
		if (state = OK) and (RD = '1') and (cache_hit = '1') then
			MBUS <= word;
		else
			MBUS <= (others => 'Z');
		end if;
	end process;

-- ADDRESS CONVERSION
	-- Direct mapping and set associative, many sets, set address is index
	addr_conv_not_fully: if (INDEX_BITS != 0) generate
		tag	<= ADDR(virtual_addr_bits-1 downto INDEX_BITS);
		index	<= ADDR(INDEX_BITS-1 downto 0);
	end generate;

	-- Fully associative, only one set
	addr_conv_fully_assoc: if (INDEX_BITS = 0) generate
		tag	<= ADDR;
		index	<= (others => '0');
	end generate;

-- READ MANAGER
	-- Scan every line in the set and compare tag and valid bit (check if address is in cache) and write result to cache_hit.
	procedure scan_set (
		signal in_set		: in	cache_set;
		signal in_tag		: in	tag_t;
		signal out_word		: out	word_t;
		signal cache_hit	: out	std_logic)
	is
		signal tag	: tag_t;
		signal word	: word_t;
		signal valid	: std_logic;
		signal entry	: entry_t;
		
		variable found	: boolean := false;
	begin
		for i in 0 to set_size-1 loop
			entry	<= in_set(i);
			tag	<= entry(TAG_PORTION);
			word	<= entry(WORD_PORTION);
			valid	<= entry(0);
			if (tag = in_tag) and (valid = '1') then
				found := true;
				exit;
			end if;
		end loop;
		out_word  <= word;
		cache_hit <= '1' when found else '0';
	end procedure;

	read_manager: process(CLK, RST, index, tag) is begin
		if rising_edge(CLK) then
			if (RST = '0') then
				word      <= memory(index)(0)(WORD_PORTION);
				cache_hit <= '1';
			else
				set <= memory(index);
				scan_set(set, tag, word, cache_hit);
			end if;
		end if;
	end procedure;

-- WRITE MANAGER
	procedure get_set_line_addr (
		signal in_set		: in	cache_set;
		signal set_line_addr	: out	line_addr_t)
	is
		signal valid : std_logic;

		variable free_line	: boolean := false;
		variable oldest_time	: integer := 2**rtc_size-1;
		variable curr_time	: integer;
	begin
		for i in 0 to set_size-1 loop
			set_line_addr	<= std_logic_vector(to_unsigned(i, set_line_addr'length));
			valid		<= in_set(i)(0);
			if (valid = '0') then
				free_line := true;
				exit;
			end if;
		end loop;
		if not(free_line) then
			for i in 0 to set_size-1 loop
				timestamp <= in_set(i)(TIMESTAMP_PORTION);
				curr_time := to_integer(unsigned(timestamp));
				if (curr_time < oldest_time) then
					set_line_addr <= std_logic_vector(to_unsigned(i, set_line_addr'length));
					oldest_time := curr_time;
				end if;
			end loop;
		end if;
	end procedure;

	procedure write_entry (
		signal in_set	: in	cache_set;
		signal in_tag	: in	tag_t;
		signal in_word	: in	word_t;
		signal in_time	: in	timestamp_t;
		signal line_reg	: in	line_addr_t)
	is
	begin
		in_set(line_reg) <= in_tag & in_word & in_time & '1';
	end procedure;

	write_manager: process(CLK, RST, state) is begin
		if rising_edge(CLK) then
			if (RST = '0') then
				-- Reset memory
				for i in 0 to MAX_INDEX-1 loop
					for j in 0 to set_size-1 loop
						memory(i)(j) <= (others => '0');
					end loop;
				end loop;
			elsif (state = CACHE_MISS) then
				-- Prepare correct line (LRU policy)
				get_set_line_addr(memory(index), set_line_addr_in);
			elsif (state = READ_BUS) then
				-- Read word from bus and store in memory
				word <= MBUS;
				write_entry(set, tag, word, timestamp, set_line_addr);
			else
				line_reg_in <= (others => '0');
			end if;
		end if;
	end process;
	
	-- Register to store line on which to write address
	set_line_addr_reg: process(CLK,RST) is begin
		if rising_edge(CLK) then
			if (RST = '0') then
				set_line_addr <= (others => '0');
			else
				set_line_addr <= set_line_addr_in;
			end if;
		end if;
	end process;

	-- Timestamp
	timestamp <= RTC;

-- STATE MACHINE
	-- State logic
	fsm: process(CLK, RST) is begin
		if rising_edge(CLK) then
			if (RST = '0') then
				state <= OK;
			else
				case state is
					-- Normal operation, return word matching tag
					when OK =>
						if (cache_hit = '0') and (RD = '1') then
							state <= CACHE_MISS;
						else
							state <= OK;
						end if;
					-- Cache miss, raise HM and REQ and wait for ACK
					when CACHE_MISS =>
						if (ACK = '1') then
							state <= READ_BUS;
						else
							state <= CACHE_MISS;
						end if;
					-- ACK received, read from bus
					when READ_BUS =>
						state <= OK;
				end case;
			end if;
		end if;
	end process;

	-- I/O logic
	HM	<= '1' when not(state = OK) else '0';
	REQ	<= '1' when not(state = OK) else '0';

end architecture;
