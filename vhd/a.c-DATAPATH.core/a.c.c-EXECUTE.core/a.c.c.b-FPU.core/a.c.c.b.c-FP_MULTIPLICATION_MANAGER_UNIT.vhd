library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use ieee.numeric_std.all;

entity FP_MULTIPLICATION_MANAGER_UNIT is
	generic (
		MANTISSA_SIZE	: natural;
		EXPONENT_SIZE	: natural
	);
	port (
		MANTISSA	: in	std_logic_vector(2*(MANTISSA_SIZE+1)-1 downto 0);
		EXPONENT1	: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
		EXPONENT2	: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
		SIGN		: in	std_logic;
		NAN			: in	std_logic;
		ZERO		: in	std_logic;
		INF			: in	std_logic;
		PACKED		: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
	);
end entity;

architecture structural of FP_MULTIPLICATION_MANAGER_UNIT is

	-- COMPONENTS
	component EXPONENT_ADDER
		generic (EXP_SIZE	: natural);
		port (
			EXP1, EXP2	: in	std_logic_vector(EXP_SIZE-1 downto 0);
			SHIFT		: in	std_logic;
			ROUND		: in	std_logic;
			EXPO		: out	std_logic_vector(EXP_SIZE-1 downto 0);
			OVFL		: out	std_logic;
			UNFL		: out	std_logic
		);
	end component;
	
	component ROUNDING_UNIT
		generic (MANTISSA_SIZE : natural);	-- Actual mantissa size + 1
		port (
			DIN		: in	std_logic_vector(2*MANTISSA_SIZE-1 downto 0);
			SHIFT	: out	std_logic;
			ROUND	: out	std_logic;
			DOUT	: out	std_logic_vector(MANTISSA_SIZE-1 downto 0)
		);
	end component;
	
	-- SIGNALS
	signal expo_s			: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal pack_exp_s		: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal manto_s			: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal pack_mant_s		: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	
	signal ovfl_s			: std_logic;
	signal unfl_s			: std_logic;
	signal shift_s			: std_logic;
	signal round_s			: std_logic;
	signal result_is_nan	: std_logic;
	signal result_is_inf	: std_logic;
	signal result_is_zero	: std_logic;
	
begin

	-- Add exponents
	EXP_ADD: EXPONENT_ADDER generic map (EXPONENT_SIZE) port map (EXPONENT1, EXPONENT2, shift_s, round_s, expo_s, ovfl_s, unfl_s);
	
	-- Round mantissa
	ROUNDER: ROUNDING_UNIT generic map (MANTISSA_SIZE+1) port map (MANTISSA, shift_s, round_s, manto_s);
	
	-- Check for exceptions
	result_is_nan	<= (ZERO and INF) or NAN;
	result_is_inf	<= (INF and not(ZERO) and not(NAN)) or ovfl_s;
	result_is_zero	<= (ZERO and not(INF) and not(NAN)) or unfl_s;
	
	-- Select outputs
	select_output: process (expo_s, manto_s, result_is_nan, result_is_inf, result_is_zero) is
	begin
		if (result_is_nan = '1') then
			pack_mant_s	<= std_logic_vector(to_unsigned(1, MANTISSA_SIZE));
			pack_exp_s	<= (others => '1');
		elsif (result_is_inf = '1') then
			pack_mant_s	<= (others => '0');
			pack_exp_s	<= (others => '1');
		elsif (result_is_zero = '1') then
			pack_mant_s	<= (others => '0');
			pack_exp_s	<= (others => '0');
		else
			pack_mant_s	<= manto_s;
			pack_exp_s	<= expo_s;
		end if;
	end process;
	
	-- Pack output
	PACKED	<= SIGN & pack_exp_s & pack_mant_s;

end architecture;