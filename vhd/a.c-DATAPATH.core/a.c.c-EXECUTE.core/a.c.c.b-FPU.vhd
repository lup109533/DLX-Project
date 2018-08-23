library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_misc.or_reduce;
use work.DLX_globals.all;

entity FPU is
	generic (OPERAND_SIZE : natural);
	port (
		F1, F2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		OPCODE	: in	FPU_opcode_t;
		O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
	);
end entity;

architecture structural of FPU is

	-- COMPONENTS
	component BOOTH_MULTIPLIER
		generic (N : natural);
		port (
			A, B : in  std_logic_vector(N-1 downto 0);
			P    : out std_logic_vector(2*N-1 downto 0)
		);
	end component;

	signal mul1, mul2	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal mul_out		: std_logic_vector(OPERAND_SIZE-1 downto 0);
	
begin

	-- MULTIPLIER
	MUL: BOOTH_MULTIPLIER generic map (OPERAND_SIZE) port map (mul1, mul2, mul_out);
	-- Choose multiplier operands (integer or fp)
	mul1 <= F1; -- For now only integer
	mul2 <= F2;
	
	-- OUTPUT MUX
	O <= mul_out; -- For now only int multiplication

end architecture;