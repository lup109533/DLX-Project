-----------------------------------
----- !!!!!! IMPORTANT !!!!!! -----
----- COMPONENT UNUSED, KEPT  -----
----- TO MAINTAIN PROJECT     -----
----- STRUCTURE               -----
-----------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EXPONENT_ADDER is
	generic (EXP_SIZE	: natural);
	port (
		EXP1, EXP2	: in	std_logic_vector(EXP_SIZE-1 downto 0);
		SHIFT		: in	std_logic;
		ROUND		: in	std_logic;
		EXPO		: out	std_logic_vector(EXP_SIZE-1 downto 0);
		OVFL		: out	std_logic;
		UNFL		: out	std_logic
	);
end entity;

architecture structural of EXPONENT_ADDER is

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
	signal bias				: std_logic_vector(EXP_SIZE-1 downto 0) := std_logic_vector(to_signed(-(2**(EXP_SIZE-1)-1), EXP_SIZE));
	signal add0_out			: std_logic_vector(EXP_SIZE-1 downto 0);
	signal de_biased_out	: std_logic_vector(EXP_SIZE-1 downto 0);
	signal ext_shift		: std_logic_vector(EXP_SIZE-1 downto 0);
	signal add0_cout		: std_logic;
	signal de_biased_cout	: std_logic;
	signal add1_cout		: std_logic;
	signal ovfl_possible	: std_logic;
	
begin

	-- First adder
	ADD0: CLA generic map (EXP_SIZE) port map (EXP1, EXP2, '0', add0_out, add0_cout);
	
	--De-bias adder
	DE_BIAS: CLA generic map (EXP_SIZE) port map (add0_out, bias, '0', de_biased_out, de_biased_cout);
	
	-- Second adder
	ADD1: CLA generic map (EXP_SIZE) port map (de_biased_out, ext_shift, ROUND, EXPO, add1_cout);
	---- Extend shift signal
	ext_shift(0)					<= SHIFT;
	ext_shift(EXP_SIZE-1 downto 1)	<= (others => '0');
	
	-- Check  and signal overflow and underflow
	ovfl_possible <= EXP1(EXP_SIZE-1) and EXP2(EXP_SIZE-1); -- Overflow only possible among positive exponents
	
	OVFL <= '1' when ((add0_cout = '1' or add1_cout = '1') and ovfl_possible = '1') else '0';
	UNFL <= '1' when (de_biased_cout = '0' and add0_cout = '0') else '0';

end architecture;