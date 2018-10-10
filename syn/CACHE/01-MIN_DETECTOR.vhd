library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.log2;

entity MIN_DETECTOR is
	generic (
		WORD_SIZE	: natural;
		WORD_NUM	: natural
	);
	port (
		DIN		: in	std_logic_vector(WORD_NUM*WORD_SIZE-1 downto 0);
		DOUT	: out	std_logic_vector(log2(WORD_NUM)-1 downto 0)
	);
end entity;

architecture behavioural of MIN_DETECTOR is

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
	
	type din_array	is array (WORD_SIZE-1 downto 0) of std_logic_vector(WORD_NUM-1 downto 0);
	type dout_array	is array (WORD_SIZE-1 downto 0) of std_logic_vector(log2(WORD_NUM)-1 downto 0);
	
	signal din_s	: din_array;
	signal dout_s	: dout_array;
	signal sel_din	: std_logic_vector(WORD_SIZE-1 downto 0);
	signal sel_dout	: std_logic_vector(log2(WORD_SIZE)-1 downto 0);

begin

	din_s_gen_vector: for i in 0 to WORD_SIZE-1 generate
		din_s_gen_bit: for j in 0 to WORD_NUM-1 generate
			din_s(i)(j) <= DIN(WORD_NUM*i + j);
		end generate;
	end generate;

	first_stage_gen: for i in 0 to WORD_SIZE-1 generate
		ENC_FIRST_i: PRIORITY_ENCODER generic map (WORD_NUM, '0') port map (
																		din_s(i),
																		dout_s(i),
																		sel_din(i)
																	);
	end generate;
	
	ENC_SECOND: PRIORITY_ENCODER generic map (WORD_SIZE, '1') port map (sel_din, sel_dout, open);
	
	DOUT <= dout_s(to_integer(unsigned(sel_dout)));

end architecture;