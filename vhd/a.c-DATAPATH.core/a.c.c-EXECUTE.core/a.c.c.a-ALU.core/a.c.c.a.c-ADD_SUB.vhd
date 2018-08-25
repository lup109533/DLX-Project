library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std;

entity ADD_SUB is
	generic (OPERAND_SIZE : natural);
	port (
		R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
   		CIN		: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		S, C	: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
	);
end entity;

architecture structural of ADD_SUB is

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
	signal A, B : std_logic_vector(OPERAND_SIZE-1 downto 0);

begin

	A <= R1;
	minus_b: for i in 0 to R2'length-1 generate
		B(i) <= R2(i) xor CIN;
	end generate;

	adder: CLA generic map(OPERAND_SIZE) port map(A, B, CIN, S, C);

end architecture;
