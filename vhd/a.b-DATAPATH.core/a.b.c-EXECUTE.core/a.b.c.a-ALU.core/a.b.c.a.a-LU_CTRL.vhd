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
	constant LU_NOT_R1	: lu_ctrl_t := "1100";
	constant LU_R1		: lu_ctrl_t := "0011";
	constant LU_NOT_R2	: lu_ctrl_t := "1010";
	constant LU_R2		: lu_ctrl_t := "0101";
	constant LU_AND_NOT	: lu_ctrl_t := "0010";
	constant LU_NOT_OR	: lu_ctrl_t := "1101";
	constant LU_NOT_AND	: lu_ctrl_t := "0100";
	constant LU_OR_NOT	: lu_ctrl_t := "1011";
	constant LU_FALSE	: lu_ctrl_t := "0000";
	constant LU_TRUE	: lu_ctrl_t := "1111";

end package;
