library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use ieee.std_logic_misc.and_reduce;
use ieee.numeric_std.all;
use work.utils.log2;

entity F2I_CONVERTER is
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
end entity;

architecture behavioural of F2I_CONVERTER is

	constant INT_SIZE			: natural := MANTISSA_SIZE + EXPONENT_SIZE + 1;
	constant EXTENDED_SIZE		: natural := INT_SIZE + MANTISSA_SIZE;
	subtype  CONV_RANGE is natural range EXTENDED_SIZE-1 downto MANTISSA_SIZE;
	
	constant max_positive_int	: std_logic_vector(INT_SIZE-1 downto 0) := std_logic_vector(to_signed( 2**(INT_SIZE-1)-1, INT_SIZE));
	constant max_negative_int	: std_logic_vector(INT_SIZE-1 downto 0) := std_logic_vector(to_signed(-2**(INT_SIZE-1)+1, INT_SIZE));
	
	signal is_inf				: std_logic;
	signal is_nan				: std_logic;
	signal is_unrepresentable	: std_logic;
	signal implicit_digit		: std_logic;
	
	signal mantissa_s			: std_logic_vector(EXTENDED_SIZE-1      downto 0);
	signal exponent_s			: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal exp_sign				: std_logic;
	signal shift_amount			: integer range 0 to INT_SIZE-1;
	signal conv_s				: std_logic_vector(EXTENDED_SIZE-1 downto 0);
	
begin

	-- Check if number cannot be properly represented in integer form (exponent too big, infinity or NaN)
	is_inf			<= and_reduce(EXPONENT) and not(or_reduce(MANTISSA));
	is_nan			<= and_reduce(EXPONENT) and or_reduce(MANTISSA);
	is_unrepresentable	<= or_reduce(exponent_s(EXPONENT_SIZE-2 downto log2(INT_SIZE))) or is_inf or is_nan;
	
	-- De-bias exponent and extend mantissa
	implicit_digit										<= or_reduce(EXPONENT);
	mantissa_s(MANTISSA_SIZE   downto               0)	<= implicit_digit & MANTISSA;
	mantissa_s(EXTENDED_SIZE-1 downto MANTISSA_SIZE+1)	<= (others => '0');
	exponent_s											<= std_logic_vector(unsigned(EXPONENT) - 127);
	
	-- Extract values for shifting
	exp_sign			<= exponent_s(EXPONENT_SIZE-1);
	shift_amount		<= to_integer(unsigned(exponent_s(log2(INT_SIZE)-1 downto 0)));
	
	shift_mantissa: process (mantissa_s, shift_amount, exp_sign) is
	begin
		-- Positive number --> shift left
		if (exp_sign = '0') then
			conv_s <= std_logic_vector(shift_left(unsigned(mantissa_s), shift_amount));
		-- Negative number --> shift right
		else
			conv_s <= std_logic_vector(shift_right(signed(mantissa_s), shift_amount));
		end if;
	end process;
	
	select_output: process (is_unrepresentable, conv_s, SIGN) is
	begin
		if (is_unrepresentable = '1') then
			if (SIGN = '0') then
				CONV <= max_positive_int;
			else
				CONV <= max_negative_int;
			end if;
		else
			if (SIGN = '0') then
				CONV <= conv_s(CONV_RANGE);
			else
				CONV <= std_logic_vector(unsigned(not(conv_s(CONV_RANGE))) + 1);
			end if;
		end if;
	end process;

end architecture;