library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;

entity I2F_CONVERTER is
	generic (
		MANTISSA_SIZE	: natural;
		EXPONENT_SIZE	: natural
	);
	port (
		DIN		: in	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);
		CONV	: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
	);
end entity;

architecture behavioural of I2F_CONVERTER is

	constant INT_SIZE		: natural := MANTISSA_SIZE + EXPONENT_SIZE + 1;
	constant EXTENDED_SIZE	: natural := INT_SIZE + MANTISSA_SIZE;
	subtype  EXTENDED_RANGE is natural range EXTENDED_SIZE-1 downto MANTISSA_SIZE;
	
	signal is_zero		: std_logic;
	signal extended_s	: std_logic_vector(EXTENDED_SIZE-1 downto 0);
	signal shifted_s	: std_logic_vector(EXTENDED_SIZE-1 downto 0);
	signal din_s		: std_logic_vector(INT_SIZE-1 downto 0);
	signal shift_amount	: integer range 0 to INT_SIZE-1;
	
	signal sign_s		: std_logic;
	signal mantissa_s	: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal exponent_s	: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	
begin

	-- Check if zero
	is_zero		<= not(or_reduce(DIN));

	-- Extract sign
	sign_s		<= DIN(INT_SIZE-1);
	
	extend_input: process (DIN, sign_s) is
	begin
		if (sign_s = '0') then
			extended_s(EXTENDED_RANGE)				<= DIN;
			extended_s(MANTISSA_SIZE-1 downto 0)	<= (others => '0');
		else
			extended_s(EXTENDED_RANGE)				<= std_logic_vector(unsigned(not(DIN)) + 1);
			extended_s(MANTISSA_SIZE-1 downto 0)	<= (others => '0');
		end if;
	end process;
	
	-- Re-extract DIN for use in extract_shift
	din_s <= extended_s(EXTENDED_RANGE);
	
	extract_shift: process (din_s) is
	begin
		for i in INT_SIZE-1 downto 0 loop
			if (din_s(i) = '1') then
				shift_amount <= i;
				exit;
			else
				shift_amount <= 0;
			end if;
		end loop;
	end process;
	
	-- Shift and extract mantissa
	shifted_s	<= std_logic_vector(shift_right(unsigned(extended_s), shift_amount));
	mantissa_s	<= shifted_s(MANTISSA_SIZE-1 downto 0);
	
	-- Bias exponent
	exponent_s	<= std_logic_vector(to_signed(shift_amount + 127, exponent_s'length));
	
	CONV <= sign_s & exponent_s & mantissa_s when (is_zero = '0') else (others => '0');

end architecture;