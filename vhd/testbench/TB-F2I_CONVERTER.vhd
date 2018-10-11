library ieee;
use ieee.std_logic_1164.all;

entity TB_F2I_CONVERTER is
end entity;

architecture test of TB_F2I_CONVERTER is

	component F2I_CONVERTER
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			MANTISSA	: in	std_logic_vector(MANTISSA_SIZE-1 downto 0);
			EXPONENT	: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			SIGN		: in	std_logic;
			CONV		: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
		);
	end component;

	constant MANTISSA_SIZE	: natural := 23;
	constant EXPONENT_SIZE	: natural := 8;

	signal FP				: std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);
	signal MANTISSA_s		: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal EXPONENT_s		: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal SIGN_s			: std_logic;
	signal CONV_s			: std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);

begin

	-- UUT
	UUT: F2I_CONVERTER generic map(MANTISSA_SIZE, EXPONENT_SIZE) port map(MANTISSA_s, EXPONENT_s, SIGN_s, CONV_s);
	FP <= SIGN_s & EXPONENT_s & MANTISSA_s;

	-- STIMULUS
	stimulus: process is begin
		MANTISSA_s	<= "01001000010000100001000";
		EXPONENT_s	<= "10000000";
		SIGN_s		<= '0';
		wait for 2 ns;
		
		MANTISSA_s	<= "01001000010000100001000";
		EXPONENT_s	<= "10000001";
		SIGN_s		<= '0';
		wait for 2 ns;
		
		MANTISSA_s	<= "01001000010000100001000";
		EXPONENT_s	<= "10000001";
		SIGN_s		<= '1';
		wait for 2 ns;
		
		MANTISSA_s	<= "01001000010000100001000";
		EXPONENT_s	<= "11111111";
		SIGN_s		<= '0';
		wait for 2 ns;
		
		MANTISSA_s	<= "00000000000000000000000";
		EXPONENT_s	<= "11111111";
		SIGN_s		<= '1';
		wait for 2 ns;
		
		wait;
	end process;

end architecture;
