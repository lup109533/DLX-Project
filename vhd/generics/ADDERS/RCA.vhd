library ieee;
use ieee.std_logic_1164.all;

entity RCA is
	generic (OPERAND_SIZE : natural);
	port (
		A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		CIN		: in	std_logic;
   		S	: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
		C	: out	std_logic
	);
end entity;

architecture structural of RCA is

	component FA
		port (
			A, B	: in	std_logic;
			CIN	: in	std_logic;
			S, C	: out	std_logic
		);
	end component;

	signal c_in, c_out : std_logic_vector(OPERAND_SIZE-1 downto 0);

begin

	rca_gen: for i in 0 to OPERAND_SIZE-1 generate
		fa_i: FA port map(A(i), B(i), c_in(i), S(i), c_out(i));
	end generate;

	carry_connect: for i in 0 to OPERAND_SIZE-2 generate
		c_in(i+1) <= c_out(i);
	end generate;

	c_in(0)	<= CIN;
	C	<= c_out(OPERAND_SIZE-1);

end architecture;
