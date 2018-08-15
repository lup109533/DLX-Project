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

	component CACHE_SET
		generic (
			TAG_SIZE		: natural;
			WORD_SIZE		: natural;
			TIMESTAMP_SIZE	: natural;
			SET_SIZE		: natural
		);
		port (
			CLK				: in	std_logic;
			RST				: in	std_logic;
			ENB				: in	std_logic;
			TAG				: in	std_logic_vector(TAG_SIZE-1 downto 0);
			DIN				: in	std_logic_vector(WORD_SIZE-1 downto 0);
			DOUT			: out	std_logic_vector(WORD_SIZE-1 downto 0);
			TMSTMP			: in	std_logic_vector(TIMESTAMP_SIZE-1 downto 0);
			HIT				: out	std_logic;
			REPLACE			: out	std_logic
		);
	end component;

	constant SET_NUM		: natural := CACHE_SIZE/SET_SIZE;
	constant INDEX_SIZE		: natural := log2(SET_NUM);
	constant TAG_SIZE		: natural := ADDR_SIZE - INDEX_SIZE;

	subtype TAG_BITS	is natural range (ADDR_SIZE - 1)			downto (ADDR_SIZE - TAG_SIZE);
	subtype INDEX_BITS	is natural range (ADDR_SIZE - TAG_SIZE - 1)	downto 0;
	
	type dout_array is array (SET_NUM-1 downto 0) of std_logic_vector(WORD_SIZE-1 downto 0);
	
	signal index			: std_logic_vector(INDEX_SIZE-1 downto 0);
	signal tag				: std_logic_vector(TAG_SIZE-1 downto 0);
	signal din_s			: std_logic_vector(WORD_SIZE-1 downto 0);
	signal word_s			: std_logic_vector(WORD_SIZE-1 downto 0);
	signal dout_s			: dout_array;
	signal hit_s			: std_logic;
	signal replace_s		: std_logic;
	signal hit_vector_s		: std_logic_vector(SET_NUM-1 downto 0);
	signal replace_vector_s	: std_logic_vector(SET_NUM-1 downto 0);
	signal index_a			: integer;
	
	type cache_state is (OK, WAIT_ACK, WRITE_BACK, FILL);
	signal state	: cache_state;
		
begin

	index_gen_set_assoc: if (SET_NUM > 1) generate
		index	<= ADDR(INDEX_BITS);
	end generate;
	
	index_gen_fully_assoc: if (SET_NUM = 1) generate
		index	<= (others => '0');
	end generate;
	
	index_a	<= to_integer(unsigned(index));
	tag		<= ADDR(TAG_BITS);

	-- CREATE MEMORY
	cache_set_gen: for i in 0 to SET_NUM-1 generate
		SET_i: CACHE_SET	generic map (TAG_SIZE, WORD_SIZE, TIMESTAMP_SIZE, SET_SIZE)
							port map (
								CLK,
								RST,
								ENB,
								tag,
								din_s,
								dout_s(i),
								TMSTMP,
								hit_vector_s(i),
								replace_vector_s(i)
							);
	end generate;
	
	din_s		<= MBUS when (state = FILL) else (others => 'Z');
	word_s		<= dout_s(index_a);
	hit_s		<= hit_vector_s(index_a);
	replace_s	<= replace_vector_s(index_a);

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
							if (replace_s = '1') and WB_ON_REPLACE then
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
	
	REQ <= '1' when not(state = OK) else '0';
	
	-- BUS MANAGER
	bus_manager: process (state, word_s) is
	begin
		if (state = WRITE_BACK) then
			MBUS <= word_s;
		else
			MBUS <= (others => 'Z');
		end if;
	end process;

end architecture;
