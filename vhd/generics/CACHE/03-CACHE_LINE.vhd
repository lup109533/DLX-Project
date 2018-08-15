library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.and_reduce;

entity CACHE_LINE is
	generic (
		TAG_SIZE		: natural;
		WORD_SIZE		: natural;
		TIMESTAMP_SIZE	: natural
	);
	port (
		CLK			: in	std_logic;
		RST			: in	std_logic;
		ENB			: in	std_logic;
		WRT			: in	std_logic;
		TAG			: in	std_logic_vector(TAG_SIZE-1 downto 0);
		DIN			: in	std_logic_vector(WORD_SIZE-1 downto 0);
		DOUT		: out	std_logic_vector(WORD_SIZE-1 downto 0);
		TMSTMP		: in	std_logic_vector(TIMESTAMP_SIZE-1 downto 0);
		TMSTMP_OUT	: out	std_logic_vector(TIMESTAMP_SIZE-1 downto 0);
		HIT			: out	std_logic;
		VALID_IN	: in	std_logic;
		VALID_OUT	: out	std_logic
	);
end entity;

architecture structural of CACHE_LINE is

	component FF
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic;
			DOUT	: out	std_logic
		);
	end component;

	component CACHE_MEMCELL
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			WRT		: in	std_logic;
			TAG		: in	std_logic;
			DIN		: in	std_logic;
			DOUT	: out	std_logic;
			HIT		: out	std_logic
		);
	end component;

	signal hit_s : std_logic_vector(TAG_SIZE-1 downto 0);
	
begin

	tag_gen: for i in 0 to TAG_SIZE-1 generate
		tag_cell_i: CACHE_MEMCELL port map (CLK, RST, ENB, WRT, TAG(i), TAG(i), open, hit_s(i));
	end generate;
	HIT <= and_reduce(hit_s);
	
	word_gen: for i in 0 to WORD_SIZE-1 generate
		word_ff_i: FF port map (CLK, RST, ENB, DIN(i), DOUT(i));
	end generate;
	
	timestamp_gen: for i in 0 to TIMESTAMP_SIZE-1 generate
		word_ff_i: FF port map (CLK, RST, ENB, TMSTMP(i), TMSTMP_OUT(i));
	end generate;
	
	valid_ff: FF port map (CLK, RST, ENB, VALID_IN, VALID_OUT);

end architecture;