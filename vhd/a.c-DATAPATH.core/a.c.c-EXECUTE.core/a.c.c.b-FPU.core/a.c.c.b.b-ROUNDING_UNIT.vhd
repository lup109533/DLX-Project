library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use ieee.numeric_std.all;

entity ROUNDING_UNIT is
	generic (MANTISSA_SIZE : natural);	-- Actual mantissa size + 1
	port (
		DIN		: in	std_logic_vector(2*MANTISSA_SIZE-1 downto 0);
		SHIFT	: out	std_logic;
		ROUND	: out	std_logic;
		DOUT	: out	std_logic_vector(MANTISSA_SIZE-1 downto 0)
	);
end entity;

architecture structural of ROUNDING_UNIT is

	-- COMPONENTS
	component CLA
		generic (
			OPERAND_SIZE	: natural;
			RADIX			: natural := 2
		);
		port (
			A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic;
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			C		: out	std_logic
		);
	end component;

	-- SIGNALS
	constant ONE					: std_logic_vector(MANTISSA_SIZE-1 downto 0) := std_logic_vector(to_unsigned(1, MANTISSA_SIZE));

	signal shifted_s				: std_logic_vector(2*MANTISSA_SIZE-1 downto 0);
	signal truncated_s				: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal rounded_s				: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal rounded_and_shifted_s	: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	
	signal guard_bit				: std_logic;
	signal round_bit				: std_logic;
	signal sticky_bit				: std_logic;
	signal round_s					: std_logic;
	signal rounding_ovfl_s			: std_logic;
	
begin

	-- Shift correction if overflow
	shift_correction: process (DIN) is
	begin
		if (DIN(MANTISSA_SIZE*2-1) = '1') then
			SHIFT									<= '1';
			shifted_s(MANTISSA_SIZE*2-1)			<= '0';
			shifted_s(MANTISSA_SIZE*2-2 downto 0)	<= DIN(MANTISSA_SIZE*2-1 downto 1);
		else
			SHIFT		<= '0';
			shifted_s	<= DIN;
		end if;
	end process;
	
	-- Generate rounding signals
	guard_bit	<= shifted_s(MANTISSA_SIZE-1);
	round_bit	<= shifted_s(MANTISSA_SIZE-2);
	sticky_bit	<= or_reduce(shifted_s(MANTISSA_SIZE-3 downto 0));
	
	check_if_round: process (guard_bit, round_bit, sticky_bit, shifted_s) is
	begin
		if (guard_bit = '0') then
			round_s <= '0';
		else
			if (round_bit = '0' and sticky_bit = '0' and shifted_s(MANTISSA_SIZE) = '1') then
				round_s <= '1';
			elsif (round_bit = '1' or sticky_bit = '1') then
				round_s <= '1';
			else
				round_s <= '0';
			end if;
		end if;
	end process;
	
	-- Select if rounded or not
	truncated_s	<= shifted_s(MANTISSA_SIZE*2-2 downto MANTISSA_SIZE-1);
	
	-- Rounding adder
	ROUND_ADD: CLA generic map (MANTISSA_SIZE) port map (truncated_s, ONE, '0', rounded_s, rounding_ovfl_s);
	
	-- Shift if overflow
	post_rounding_correction: process (rounded_s, rounding_ovfl_s) is
	begin
		if (rounding_ovfl_s = '1') then
			rounded_and_shifted_s(MANTISSA_SIZE-1)			<= '0';
			rounded_and_shifted_s(MANTISSA_SIZE-2 downto 0)	<= rounded_s(MANTISSA_SIZE-1 downto 1);
			ROUND <= '1';
		else
			rounded_and_shifted_s <= rounded_s;
			ROUND <= '0';
		end if;
	end process;
	
	-- Output
	DOUT <= rounded_and_shifted_s when (round_s = '1') else truncated_s;

end architecture;