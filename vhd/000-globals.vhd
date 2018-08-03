library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all

package globals is
	-- MATH FUNCTIONS
	function log2	(n   : integer)	return integer;
	function max	(a,b : integer)	return integer;
	function min	(a,b : integer)	return integer;
	
	-- CONSTANTS
	constant DLX_INSTRUCTION_SIZE : natural := 32;
	constant OPCODE_SIZE          : natural := 6;
	constant ALU_FUNCTION_SIZE    : natural := 11;

	-- TYPES AND ENUMS
	subtype DLX_instr_t	is std_logic_vector(DLX_INSTRUCTION_SIZE-1 downto 0);
	subtype opcode_t	is std_logic_vector(OPCODE_SIZE-1 downto 0);
	subtype func_t		is std_logic_vector(ALU_FUNCTION_SIZE-1 downto 0);
	type DLX_instr_type_t is (R_TYPE, I_TYPE, J_TYPE, FI_TYPE, FR_TYPE);

	-- DLX INSTRUCTIONS
	constant ALU		: opcode_t	:= std_logic(to_unsigned(16#00#, OPCODE_SIZE)); -- R-type
	constant FP		: opcode_t	:= std_logic(to_unsigned(16#11#, OPCODE_SIZE)); -- FR-type
	constant LB		: opcode_t	:= std_logic(to_unsigned(16#20#, OPCODE_SIZE));
	constant LH		: opcode_t	:= std_logic(to_unsigned(16#21#, OPCODE_SIZE));
	constant LW		: opcode_t	:= std_logic(to_unsigned(16#23#, OPCODE_SIZE));
	constant LBU		: opcode_t	:= std_logic(to_unsigned(16#24#, OPCODE_SIZE));
	constant LHU		: opcode_t	:= std_logic(to_unsigned(16#25#, OPCODE_SIZE));
	constant SB		: opcode_t	:= std_logic(to_unsigned(16#28#, OPCODE_SIZE));
	constant SH		: opcode_t	:= std_logic(to_unsigned(16#29#, OPCODE_SIZE));
	constant SW		: opcode_t	:= std_logic(to_unsigned(16#2B#, OPCODE_SIZE));
	constant ADDI		: opcode_t	:= std_logic(to_unsigned(16#08#, OPCODE_SIZE));
	constant ADDUI		: opcode_t	:= std_logic(to_unsigned(16#09#, OPCODE_SIZE));
	constant SUBI		: opcode_t	:= std_logic(to_unsigned(16#10#, OPCODE_SIZE));
	constant SUBUI		: opcode_t	:= std_logic(to_unsigned(16#11#, OPCODE_SIZE));
	constant ANDI		: opcode_t	:= std_logic(to_unsigned(16#12#, OPCODE_SIZE));
	constant ORI		: opcode_t	:= std_logic(to_unsigned(16#13#, OPCODE_SIZE));
	constant XORI		: opcode_t	:= std_logic(to_unsigned(16#14#, OPCODE_SIZE));
	constant LHGI		: opcode_t	:= std_logic(to_unsigned(16#15#, OPCODE_SIZE));
	constant CLRI		: opcode_t	:= std_logic(to_unsigned(16#18#, OPCODE_SIZE));
	constant SGRI		: opcode_t	:= std_logic(to_unsigned(16#19#, OPCODE_SIZE));
	constant SEQI		: opcode_t	:= std_logic(to_unsigned(16#1A#, OPCODE_SIZE));
	constant SGEI		: opcode_t	:= std_logic(to_unsigned(16#1B#, OPCODE_SIZE));
	constant SLSI		: opcode_t	:= std_logic(to_unsigned(16#1C#, OPCODE_SIZE));
	constant SNEI		: opcode_t	:= std_logic(to_unsigned(16#1D#, OPCODE_SIZE));
	constant SLEI		: opcode_t	:= std_logic(to_unsigned(16#1E#, OPCODE_SIZE));
	constant SETI		: opcode_t	:= std_logic(to_unsigned(16#1F#, OPCODE_SIZE));
	constant BEQZ		: opcode_t	:= std_logic(to_unsigned(16#04#, OPCODE_SIZE));
	constant BNEZ		: opcode_t	:= std_logic(to_unsigned(16#05#, OPCODE_SIZE));
	constant JR		: opcode_t	:= std_logic(to_unsigned(16#16#, OPCODE_SIZE));
	constant JALR		: opcode_t	:= std_logic(to_unsigned(16#17#, OPCODE_SIZE));
	constant J		: opcode_t	:= std_logic(to_unsigned(16#02#, OPCODE_SIZE));
	constant JAL		: opcode_t	:= std_logic(to_unsigned(16#03#, OPCODE_SIZE));
	constant TRAP		: opcode_t	:= std_logic(to_unsigned(16#3E#, OPCODE_SIZE));
	constant RFE		: opcode_t	:= std_logic(to_unsigned(16#3F#, OPCODE_SIZE));
	constant LOAD_S		: opcode_t	:= std_logic(to_unsigned(16#31#, OPCODE_SIZE));
	constant LOAD_D		: opcode_t	:= std_logic(to_unsigned(16#35#, OPCODE_SIZE));
	constant STORE_S	: opcode_t	:= std_logic(to_unsigned(16#39#, OPCODE_SIZE));
	constant STORE_D	: opcode_t	:= std_logic(to_unsigned(16#3D#, OPCODE_SIZE));
	constant FBEQZ		: opcode_t	:= std_logic(to_unsigned(16#06#, OPCODE_SIZE));
	constant FBNEZ		: opcode_t	:= std_logic(to_unsigned(16#07#, OPCODE_SIZE));
	constant NOP		: opcode_t	:= std_logic(to_unsigned(16#FE#, OPCODE_SIZE));

	-- DLX ALU FUNCTIONS
	constant SLLI		: func_t	:= std_logic(to_unsigned(16#00#, ALU_FUNCTION_SIZE));

	-- DLX MANAGEMENT FUNCTIONS AND PROCEDURES
	procedure get_op_type (
		signal opcode	: in	opcode_t;
		signal op_type	: out	DLX_instr_type_t);
end globals;

package body globals is
	-- LOG2
	function log2(n : integer) return integer is
		variable ret : integer := 0;
		variable tmp : integer;
	begin
		tmp := n;
		while (tmp > 1) loop
			tmp := tmp / 2;
			ret := ret + 1;
		end loop;
		return tmp;
	end function;
	-- MAX
	function max(a,b : integer) return integer is
	begin
		if (a > b) then
			return a;
		else
			return b;
		end if;
	end function;
	-- MIN
	function min(a,b : integer) return integer is
	begin
		if (a < b) then
			return a;
		else
			return b;
		end if;
	end function;
	-- DLX
	procedure get_op_type (
		signal opcode	: in	opcode_t;
		signal op_type	: out	DLX_instr_type_t)
	is
	begin
		op_type <= R_TYPE  when (opcode = ALU)	else

		           J_TYPE  when (opcode = J)	or
			                (opcode = JAL)	or
					(opcode = TRAP) or
					(opcode = RFE)  else

		           FI_TYPE when (opcode = FP)	else

			   FR_TYPE when (opcode = LOAD_S)  or
			                (opcode = LOAD_D)  or
					(opcode = STORE_S) or
					(opcode = STORE_D) or
					(opcode = FBEQZ)   or
					(opcode = FNEQZ)   else

		           I_TYPE;
	end procedure;

end globals;
