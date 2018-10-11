library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_I2F_CONVERTER is
end entity;

architecture test of TB_I2F_CONVERTER is

	component I2F_CONVERTER
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			DIN		: in	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);
			CONV	: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
		);
	end component;

	constant MANTISSA_SIZE	: natural := 23;
	constant EXPONENT_SIZE	: natural := 8;

	signal DIN_s			: std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);
	signal CONV_s			: std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);

begin

	-- UUT
	UUT: I2F_CONVERTER generic map(MANTISSA_SIZE, EXPONENT_SIZE) port map(DIN_s, CONV_s);

	-- STIMULUS
	stimulus: process is begin
		DIN_s	<= std_logic_vector(to_signed(0, DIN_s'length));
		wait for 2 ns;
		
		DIN_s	<= std_logic_vector(to_signed(1, DIN_s'length));
		wait for 2 ns;
		
		DIN_s	<= std_logic_vector(to_signed(-1, DIN_s'length));
		wait for 2 ns;
		
		DIN_s	<= std_logic_vector(to_signed(15, DIN_s'length));
		wait for 2 ns;
		
		DIN_s	<= std_logic_vector(to_signed(16000, DIN_s'length));
		wait for 2 ns;
		
		DIN_s	<= std_logic_vector(to_signed(-16000, DIN_s'length));
		wait for 2 ns;
		
		wait;
	end process;

end architecture;
