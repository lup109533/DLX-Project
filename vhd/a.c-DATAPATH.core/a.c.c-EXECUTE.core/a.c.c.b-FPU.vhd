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

begin

end architecture;