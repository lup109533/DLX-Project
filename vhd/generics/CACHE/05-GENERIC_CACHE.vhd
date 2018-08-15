library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.log2;
use work.utils.max;

entity GENERIC_CACHE is
	generic (
		WORD_SIZE		: natural;
		ADDR_SIZE		: natural;
		CACHE_SIZE		: natural;
		SET_SIZE		: natural;
		TIMESTAMP_SIZE	: natural;
		WB_ON_REPLACE	: boolean := false
	);
	port(
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		DOUT	: out	std_logic_vector(WORD_SIZE-1 downto 0);
		ADDR	: in	std_logic_vector(ADDR_SIZE-1 downto 0);
		MBUS	: inout	std_logic_vector(WORD_SIZE-1 downto 0);
		REQ		: out	std_logic;
		ACK		: in	std_logic;
		HIT		: out	std_logic;
		TMSTMP	: in	std_logic_vector(TIMESTAMP_SIZE-1 downto 0)
	);
end GENERIC_CACHE;

architecture behavioral of GENERIC_CACHE is

	component REG_N
		generic (N : natural);
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic_vector(N-1 downto 0);
			DOUT	: out	std_logic_vector(N-1 downto 0)
		);
	end component;

	constant SET_NUM		: natural := CACHE_SIZE/SET_SIZE;
	constant INDEX_SIZE		: natural := log2(SET_NUM);
	constant TAG_SIZE		: natural := ADDR_SIZE - INDEX_SIZE;

	subtype TAG_BITS	is natural range (ADDR_SIZE - 1)			downto (ADDR_SIZE - TAG_SIZE);
	subtype INDEX_BITS	is natural range (ADDR_SIZE - TAG_SIZE - 1)	downto 0;
	
	signal index			: std_logic_vector(INDEX_SIZE-1 downto 0);
	signal tag				: std_logic_vector(TAG_SIZE-1 downto 0);
	
	signal index_s			: integer;
	signal line_s  			: std_logic_vector(SET_SIZE-1 downto 0);
	signal word_s  			: std_logic_vector(WORD_SIZE-1 downto 0);
	signal min_timestamp_s	: unsigned(TIMESTAMP_SIZE-1 downto 0);
	
	signal hit_s			: std_logic;
	signal write_line_in	: std_logic_vector(INDEX_SIZE-1 downto 0);
	signal write_line		: std_logic_vector(INDEX_SIZE-1 downto 0);
	signal write_line_s		: integer;
	
	type cache_state is (OK, WAIT_ACK, WRITE_BACK, FILL);
	signal state : cache_state;
	
	subtype	cache_line	is std_logic_vector((TAG_SIZE + WORD_SIZE + TIMESTAMP_SIZE + 1)-1 downto 0);
	type	cache_set	is array (SET_SIZE-1 downto 0) of cache_line;
	type	cache_mem	is array (SET_NUM-1  downto 0) of cache_set;
	signal	memory		: cache_mem;
	
	subtype LINE_TAG		is natural range (TAG_SIZE + WORD_SIZE + TIMESTAMP_SIZE + 1)-1	downto (WORD_SIZE + TIMESTAMP_SIZE + 1);
	subtype LINE_WORD		is natural range (WORD_SIZE + TIMESTAMP_SIZE + 1)-1				downto (TIMESTAMP_SIZE + 1);
	subtype LINE_TIMESTAMP	is natural range (TIMESTAMP_SIZE + 1)-1							downto 1;
	subtype LINE_VALID		is natural range 0 												downto 0;
		
begin

	-- ADDRESS UNPACKING
	addr_unpack_direct_mapping: if (SET_NUM = CACHE_SIZE) generate
		tag		<= ADDR(TAG_BITS);
		index	<= ADDR(INDEX_BITS);
	end generate;
	
	addr_unpack_fully_assoc: if (SET_NUM = 1) generate
		tag		<= ADDR(TAG_BITS);
		index	<= (others => '0');
	end generate;
	
	addr_unpack_set_assoc: if (SET_NUM > 1) and (SET_NUM < CACHE_SIZE) generate
		tag		<= ADDR(TAG_BITS);
		index	<= ADDR(INDEX_BITS);
	end generate;
	
	index_s <= to_integer(unsigned(index));
	
	-- CACHE MANAGER
	read_proc: process (ENB, index_s, tag) is
		variable found : boolean := false;
	begin
		if (ENB = '1') then
			for line_v in 0 to SET_SIZE-1 loop
				if (memory(index_s)(line_v)(LINE_TAG) = tag) and (memory(index_s)(line_v)(LINE_VALID) = "1") then
					found	:= true;
					word_s	<= memory(index_s)(line_v)(LINE_WORD);
					exit;
				end if;
			end loop;
			
			if found then
				hit_s <= '1';
				DOUT  <= word_s;
			else
				hit_s <= '0';
				DOUT  <= (others => '0');
			end if;
		end if;
	end process;
	HIT	<= hit_s;
	
	write_proc: process (CLK, RST, ENB, state, write_line, write_line_s, tag, index_s) is
		variable found : boolean := false;
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				for i in 0 to SET_NUM-1 loop
					for j in 0 to SET_SIZE-1 loop
						memory(i)(j) <= (others => '0');
					end loop;
				end loop;
				
			elsif (ENB = '1') then
				if (state = WAIT_ACK) then
					for line_v in 0 to SET_SIZE-1 loop
						if (memory(index_s)(line_v)(LINE_VALID) = "0") then
							found	:= true;
							line_s	<= std_logic_vector(to_unsigned(line_v, line_s'length));
						end if;
					end loop;
					
					if not found then
						min_timestamp_s <= unsigned(memory(index_s)(0)(LINE_TIMESTAMP));
						for line_v in 0 to SET_SIZE-1 loop
							if (unsigned(memory(index_s)(line_v)(LINE_TIMESTAMP)) < min_timestamp_s) then
								min_timestamp_s <= unsigned(memory(index_s)(line_v)(LINE_TIMESTAMP));
								line_s	<= std_logic_vector(to_unsigned(line_v, line_s'length));
							end if;
						end loop;
					end if;
						
					write_line_in <= line_s;
					
				elsif (state = WRITE_BACK) then
					write_line_in <= write_line;
					
				elsif (state = FILL) then
					memory(index_s)(write_line_s)(LINE_TIMESTAMP)	<= TMSTMP;
					memory(index_s)(write_line_s)(LINE_TAG)			<= tag;
					memory(index_s)(write_line_s)(LINE_VALID)		<= "1";
					memory(index_s)(write_line_s)(LINE_WORD)		<= MBUS;
					
					write_line_in <= write_line;
					
				else
					write_line_in <= write_line;
					
				end if;
				
			end if;
		end if;	
	end process;
	
	WRITE_LINE_REG: REG_N generic map (write_line'length) port map (CLK, RST, ENB, write_line_in, write_line);
	write_line_s <= to_integer(unsigned(write_line));
	
	-- FSM
	fsm_proc: process (CLK, RST, ENB) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				state <= OK;
				
			elsif (ENB = '1') then
				case (state) is
					when OK =>
						if (hit_s = '0') then
							state <= WAIT_ACK;
						else
							state <= OK;
						end if;
						
					when WAIT_ACK =>
						if (ACK = '1') then
							if (memory(index_s)(write_line_s)(LINE_VALID) = "1") and WB_ON_REPLACE then
								state <= WRITE_BACK;
							else
								state <= FILL;
							end if;
						else
							state <= WAIT_ACK;
						end if;
						
					when WRITE_BACK =>
						state <= FILL;
						
					when FILL =>
						state <= OK;
						
				end case;	
			end if;
		end if;
	end process;
	
	-- I/O
	REQ <= '1' when not(state = OK) else '0';
	
	-- BUS MANAGER
	bus_manager: process (state, index, write_line_s) is
	begin
		if (state = WRITE_BACK) then
			MBUS <= memory(index_s)(write_line_s)(LINE_WORD);
		else
			MBUS <= (others => 'Z');
		end if;
	end process;

end architecture;
