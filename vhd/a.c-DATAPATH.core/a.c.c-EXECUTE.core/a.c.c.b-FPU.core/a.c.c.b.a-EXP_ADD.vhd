library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity EXP_ADD is
	generic (
		EXP_SIZE	: natural;
	);
	port (
		EXP1, EXP2	: in	std_logic_vector(EXP_SIZE-1 downto 0);
		SHIFT		: in	std_logic_vector;
		ROUND		: in	std_logic_vector;
		EXPO		: out	std_logic_vector(EXP_SIZE-1 downto 0);
		OVFL		: out	std_logic;
		UNFL		: out	std_logic
	);
end entity;

architecture structural of EXP_ADD is

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

	signal bias	: std_logic_vector(EXP_SIZE-1 downto 0) := std_logic_vector(to_signed(-(2**(EXP_SIZE-1)-1), bias'length));
	
begin

	-- First adder
	ADD0: CLA generic map (EXP_SIZE) port map (EXP1, EXP2, '0', add0_out, add0_cout);
	
	--De-bias adder
	DE_BIAS: CLA generic map (EXP_SIZE) port map (add0_out, bias, '0', de_biased_out, de_biased_cout);
	
	-- Second adder
	ADD1: CLA generic map (EXP_SIZE) port map (de_biased_out, ext_shift, ROUND, EXPO, add1_cout);
	
	-- Check  and signal overflow and underflow
	OVFL <= '1' when (add0_cout = '1' or add1_cout = '1') else '0';
	UNFL <= '1' when (de_biased_cout = '0' and add0_cout = '0') else '0';

end architecture;