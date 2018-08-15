library ieee;
use ieee.std_logic_1164.all;
use work.utils.log2;

entity CACHE_SET is
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
		TAG				: in	std_logic_vector(SET_SIZE*TAG_SIZE-1 downto 0);
		DIN				: in	std_logic_vector(SET_SIZE*WORD_SIZE-1 downto 0);
		DOUT			: out	std_logic_vector(SET_SIZE*WORD_SIZE-1 downto 0);
		TMSTMP			: in	std_logic_vector(SET_SIZE*TIMESTAMP_SIZE-1 downto 0);
		HIT				: out	std_logic;
		VALID_IN		: in	std_logic_vector(SET_SIZE-1 downto 0);
		HIT_LINE_ADDR	: out	std_logic_vector(log2(SET_SIZE)-1 downto 0);
		WRITE_LINE_ADDR	: out	std_logic_vector(log2(SET_SIZE)-1 downto 0)
	);
end entity;

architecture structural of CACHE_SET is

	component CACHE_LINE
		generic (
			TAG_SIZE		: natural;
			WORD_SIZE		: natural;
			TIMESTAMP_SIZE	: natural
		);
		port (
			CLK			: in	std_logic;
			RST			: in	std_logic;
			ENB			: in	std_logic;
			TAG			: in	std_logic_vector(TAG_SIZE-1 downto 0);
			DIN			: in	std_logic_vector(WORD_SIZE-1 downto 0);
			DOUT		: out	std_logic_vector(WORD_SIZE-1 downto 0);
			TMSTMP		: in	std_logic_vector(TIMESTAMP_SIZE-1 downto 0);
			TMSTMP_OUT	: out	std_logic_vector(TIMESTAMP_SIZE-1 downto 0);
			HIT			: out	std_logic;
			VALID_IN	: in	std_logic;
			VALID_OUT	: out	std_logic
		);
	end component;
	
	component PRIORITY_ENCODER
		generic (
			DIN_SIZE		: natural;
			PRIORITY_TYPE	: std_logic
		);
		port (
			DIN			: in	std_logic_vector(DIN_SIZE-1 downto 0);
			DOUT		: out	std_logic_vector(log2(DIN_SIZE)-1 downto 0);
			NO_PRIORITY	: out	std_logic
		);
	end component;
	
	component MIN_DETECTOR
		generic (
			WORD_SIZE	: natural;
			WORD_NUM	: natural
		);
		port (
			DIN		: in	std_logic_vector(WORD_NUM*WORD_SIZE-1 downto 0);
			DOUT	: out	std_logic_vector(log2(WORD_NUM)-1 downto 0)
		);
	end component;
	
	signal hit_s				: std_logic_vector(SET_SIZE-1 downto 0);
	signal valid_s				: std_logic_vector(SET_SIZE-1 downto 0);
	signal tmstmp_s				: std_logic_vector(SET_SIZE*TIMESTAMP_SIZE-1 downto 0);
	signal min_time_line_s		: std_logic_vector(log2(SET_SIZE)-1 downto 0);
	signal free_line_s			: std_logic_vector(log2(SET_SIZE)-1 downto 0);
	signal found_free_line_s	: std_logic;

begin

	line_gen: for i in 0 to SET_SIZE-1 generate
		line_i: CACHE_LINE generic map(TAG_SIZE, WORD_SIZE, TIMESTAMP_SIZE) port map (
																				CLK,
																				RST,
																				ENB,
																				TAG((i+1)*TAG_SIZE-1 downto i*TAG_SIZE),
																				DIN((i+1)*WORD_SIZE-1 downto i*WORD_SIZE),
																				DOUT((i+1)*WORD_SIZE-1 downto i*WORD_SIZE),
																				TMSTMP((i+1)*TIMESTAMP_SIZE-1 downto i*TIMESTAMP_SIZE),
																				tmstmp_s((i+1)*TIMESTAMP_SIZE-1 downto i*TIMESTAMP_SIZE),
																				hit_s(i),
																				VALID_IN(i),
																				valid_s(i)
																			);
	end generate;
	hit_line_encoder:	PRIORITY_ENCODER	generic map (SET_SIZE, '1')				port map (hit_s, HIT_LINE_ADDR, open);
	min_time_detector:	MIN_DETECTOR		generic map (TIMESTAMP_SIZE, SET_SIZE)	port map (tmstmp_s, min_time_line_s);
	valid_detector:		PRIORITY_ENCODER	generic map (SET_SIZE, '0')				port map (valid_s, free_line_s, found_free_line_s);
	
	WRITE_LINE_ADDR <= free_line_s when (found_free_line_s = '0') else min_time_line_s;

end architecture;