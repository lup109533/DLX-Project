library ieee;
use ieee.std_logic_1164.all;

package lu_ctrl is
	
	subtype lu_ctrl_t is std_logic_vector(3 downto 0);

	constant LU_AND		: lu_ctrl_t := "0001";
	constant LU_NAND	: lu_ctrl_t := "1110";
	constant LU_OR		: lu_ctrl_t := "0111";
	constant LU_NOR		: lu_ctrl_t := "1000";
	constant LU_XOR		: lu_ctrl_t := "0110";
	constant LU_XNOR	: lu_ctrl_t := "1001";

end package;
