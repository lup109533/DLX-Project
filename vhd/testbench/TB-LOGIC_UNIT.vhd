library ieee;
use ieee.std_logic_1164.all;
use work.lu_ctrl.all;

entity TB_LOGIC_UNIT is
end entity;

architecture test of TB_LOGIC_UNIT is

	component LOGIC_UNIT
		generic (OPERAND_SIZE : natural);
		port (
			CTRL	: in	lu_ctrl_t;
			R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O	: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;

	constant OPERAND_SIZE	: natural := 4;

	signal CTRL_s		: lu_ctrl_t;
	signal R1_s, R2_s	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal O_s		: std_logic_vector(OPERAND_SIZE-1 downto 0);

begin

	-- STIMULUS
	stimulus: process is begin
		R1_s	<= "0101";
		R2_s	<= "1010";

		CTRL_s	<= LU_AND;
		wait for 1 ns;

		CTRL_s	<= LU_NAND;
		wait for 1 ns;

		CTRL_s	<= LU_OR;
		wait for 1 ns;

		CTRL_s	<= LU_NOR;
		wait for 1 ns;

		CTRL_s	<= LU_XOR;
		wait for 1 ns;

		CTRL_s	<= LU_XNOR;
		wait for 1 ns;
		
		wait;
	end process;

end architecture;
