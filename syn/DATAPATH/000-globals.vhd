-- GLOBALS PACKAGE
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is
	-- MATH FUNCTIONS
	function log2	(n   : integer)	return integer;
	function max	(a,b : integer)	return integer;
	function min	(a,b : integer)	return integer;
end utils;

package body utils is
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
		return ret;
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
end package body;
	

-- DLX_GLOBALS PACKAGE	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DLX_globals is
	-- CONSTANTS
	constant DLX_OPERAND_SIZE		: natural := 32;
	constant DLX_ADDR_SIZE			: natural := 32;
	constant DLX_INSTRUCTION_SIZE	: natural := 32;
	constant OPCODE_SIZE			: natural := 6;
	constant REGISTER_ADDR_SIZE		: natural := 5;
	constant IMMEDIATE_ARG_SIZE		: natural := 16;
	constant ALU_FUNCTION_SIZE		: natural := 11;
	constant FPU_FUNCTION_SIZE		: natural := 11;
	constant JUMP_PC_OFFSET_SIZE	: natural := 26;
	constant FP_MANTISSA_SIZE		: natural := 23;
	constant FP_EXPONENT_SIZE		: natural := 8;
	
	constant BRANCH_TAKEN			: std_logic := '1';
	constant BRANCH_NOT_TAKEN		: std_logic := '1';

	-- RANGES
	subtype OPCODE_RANGE		is natural range (DLX_INSTRUCTION_SIZE)-1 downto (DLX_INSTRUCTION_SIZE - OPCODE_SIZE);
	subtype REG_SOURCE1_RANGE	is natural range (DLX_INSTRUCTION_SIZE - OPCODE_SIZE)-1 downto (DLX_INSTRUCTION_SIZE - OPCODE_SIZE - REGISTER_ADDR_SIZE);
	subtype REG_SOURCE2_RANGE	is natural range (DLX_INSTRUCTION_SIZE - OPCODE_SIZE - REGISTER_ADDR_SIZE)-1 downto (DLX_INSTRUCTION_SIZE - OPCODE_SIZE - REGISTER_ADDR_SIZE*2);
	subtype REG_DEST_RANGE		is natural range (DLX_INSTRUCTION_SIZE - OPCODE_SIZE - REGISTER_ADDR_SIZE*2)-1 downto (DLX_INSTRUCTION_SIZE - OPCODE_SIZE - REGISTER_ADDR_SIZE*3);
	subtype ALU_FUNC_RANGE		is natural range (ALU_FUNCTION_SIZE)-1 downto 0;
	subtype IMMEDIATE_ARG_RANGE	is natural range (IMMEDIATE_ARG_SIZE)-1 downto 0;
	subtype PC_OFFSET_RANGE		is natural range (JUMP_PC_OFFSET_SIZE)-1 downto 0;
	subtype FPU_FUNC_RANGE		is natural range (FPU_FUNCTION_SIZE)-1 downto 0;
	subtype SIGN_RANGE			is natural range (DLX_OPERAND_SIZE-1) downto (DLX_OPERAND_SIZE-1);
	subtype EXPONENT_RANGE		is natural range (DLX_OPERAND_SIZE-1)-1 downto FP_MANTISSA_SIZE;
	subtype MANTISSA_RANGE		is natural range (FP_MANTISSA_SIZE)-1 downto 0;

	-- TYPES AND ENUMS
	subtype DLX_oper_t	is std_logic_vector(DLX_OPERAND_SIZE-1 downto 0);
	subtype DLX_addr_t	is std_logic_vector(DLX_ADDR_SIZE-1 downto 0);
	subtype DLX_instr_t	is std_logic_vector(DLX_INSTRUCTION_SIZE-1 downto 0);
	subtype opcode_t	is std_logic_vector(OPCODE_SIZE-1 downto 0);
	subtype reg_addr_t	is std_logic_vector(REGISTER_ADDR_SIZE-1 downto 0);
	subtype immediate_t	is std_logic_vector(IMMEDIATE_ARG_SIZE-1 downto 0);
	subtype func_t		is std_logic_vector(ALU_FUNCTION_SIZE-1 downto 0);
	subtype fp_func_t	is std_logic_vector(FPU_FUNCTION_SIZE-1 downto 0);
	subtype pc_offset_t	is std_logic_vector(JUMP_PC_OFFSET_SIZE-1 downto 0);
	
	type DLX_instr_type_t	is (NO_TYPE, R_TYPE, I_TYPE, J_TYPE, JR_TYPE, F_TYPE, S_TYPE, L_TYPE);
	type ALU_opcode_t		is (SHIFT, IADD, ISUB, LOGIC_AND, LOGIC_OR, LOGIC_XOR,
							    COMPARE_EQ, COMPARE_NE, COMPARE_LT, COMPARE_GT, COMPARE_LE, COMPARE_GE,
								MOV);
	type FPU_opcode_t		is (FP_ADD_SUB,  FP_MULTIPLY,  FP_DIVIDE,
							    DEC_ADD_SUB, DEC_MULTIPLY, DEC_DIVIDE,
							    INT_MULTIPLY, INT_DIVIDE,
							    FP_COMPARE_EQ,  FP_COMPARE_NE,  FP_COMPARE_LT,  FP_COMPARE_GT,  FP_COMPARE_LE,  FP_COMPARE_GE,
								DEC_COMPARE_EQ, DEC_COMPARE_NE, DEC_COMPARE_LT, DEC_COMPARE_GT, DEC_COMPARE_LE, DEC_COMPARE_GE,
								CONVERSION);

	-- DLX INSTRUCTIONS
	constant ALU_I		: opcode_t	:= std_logic_vector(to_unsigned(16#00#, OPCODE_SIZE)); -- R-type
	constant FPU_I		: opcode_t	:= std_logic_vector(to_unsigned(16#01#, OPCODE_SIZE)); -- F-type
	constant J			: opcode_t	:= std_logic_vector(to_unsigned(16#02#, OPCODE_SIZE));
	constant JAL		: opcode_t	:= std_logic_vector(to_unsigned(16#03#, OPCODE_SIZE));
	constant BEQZ		: opcode_t	:= std_logic_vector(to_unsigned(16#04#, OPCODE_SIZE));
	constant BNEZ		: opcode_t	:= std_logic_vector(to_unsigned(16#05#, OPCODE_SIZE));
	constant BFPT		: opcode_t	:= std_logic_vector(to_unsigned(16#06#, OPCODE_SIZE));
	constant BFPF		: opcode_t	:= std_logic_vector(to_unsigned(16#07#, OPCODE_SIZE));
	constant ADDI		: opcode_t	:= std_logic_vector(to_unsigned(16#08#, OPCODE_SIZE));
	constant ADDUI		: opcode_t	:= std_logic_vector(to_unsigned(16#09#, OPCODE_SIZE));
	constant SUBI		: opcode_t	:= std_logic_vector(to_unsigned(16#0A#, OPCODE_SIZE));
	constant SUBUI		: opcode_t	:= std_logic_vector(to_unsigned(16#0B#, OPCODE_SIZE));
	constant ANDI		: opcode_t	:= std_logic_vector(to_unsigned(16#0C#, OPCODE_SIZE));
	constant ORI		: opcode_t	:= std_logic_vector(to_unsigned(16#0D#, OPCODE_SIZE));
	constant XORI		: opcode_t	:= std_logic_vector(to_unsigned(16#0E#, OPCODE_SIZE));
	constant LHI		: opcode_t	:= std_logic_vector(to_unsigned(16#0F#, OPCODE_SIZE));
	constant RFE		: opcode_t	:= std_logic_vector(to_unsigned(16#10#, OPCODE_SIZE));
	constant TRAP		: opcode_t	:= std_logic_vector(to_unsigned(16#11#, OPCODE_SIZE));
	constant JR			: opcode_t	:= std_logic_vector(to_unsigned(16#12#, OPCODE_SIZE));
	constant JALR		: opcode_t	:= std_logic_vector(to_unsigned(16#13#, OPCODE_SIZE));
	constant SLLI		: opcode_t	:= std_logic_vector(to_unsigned(16#14#, OPCODE_SIZE));
	constant NOP		: opcode_t	:= std_logic_vector(to_unsigned(16#15#, OPCODE_SIZE));
	constant SRLI		: opcode_t	:= std_logic_vector(to_unsigned(16#16#, OPCODE_SIZE));
	constant SRAI		: opcode_t	:= std_logic_vector(to_unsigned(16#17#, OPCODE_SIZE));
	constant SEQI		: opcode_t	:= std_logic_vector(to_unsigned(16#18#, OPCODE_SIZE));
	constant SNEI		: opcode_t	:= std_logic_vector(to_unsigned(16#19#, OPCODE_SIZE));
	constant SLTI		: opcode_t	:= std_logic_vector(to_unsigned(16#1A#, OPCODE_SIZE));
	constant SGTI		: opcode_t	:= std_logic_vector(to_unsigned(16#1B#, OPCODE_SIZE));
	constant SLEI		: opcode_t	:= std_logic_vector(to_unsigned(16#1C#, OPCODE_SIZE));
	constant SGEI		: opcode_t	:= std_logic_vector(to_unsigned(16#1D#, OPCODE_SIZE));
	constant LB			: opcode_t	:= std_logic_vector(to_unsigned(16#20#, OPCODE_SIZE));
	constant LH			: opcode_t	:= std_logic_vector(to_unsigned(16#21#, OPCODE_SIZE));
	constant LW			: opcode_t	:= std_logic_vector(to_unsigned(16#23#, OPCODE_SIZE));
	constant LBU		: opcode_t	:= std_logic_vector(to_unsigned(16#24#, OPCODE_SIZE));
	constant LHU		: opcode_t	:= std_logic_vector(to_unsigned(16#25#, OPCODE_SIZE));
	constant LF			: opcode_t	:= std_logic_vector(to_unsigned(16#26#, OPCODE_SIZE));
	constant LD			: opcode_t	:= std_logic_vector(to_unsigned(16#27#, OPCODE_SIZE));
	constant SB			: opcode_t	:= std_logic_vector(to_unsigned(16#28#, OPCODE_SIZE));
	constant SH			: opcode_t	:= std_logic_vector(to_unsigned(16#29#, OPCODE_SIZE));
	constant SW			: opcode_t	:= std_logic_vector(to_unsigned(16#2B#, OPCODE_SIZE));
	constant SF			: opcode_t	:= std_logic_vector(to_unsigned(16#2E#, OPCODE_SIZE));
	constant SD			: opcode_t	:= std_logic_vector(to_unsigned(16#2F#, OPCODE_SIZE));
	constant ITLB		: opcode_t	:= std_logic_vector(to_unsigned(16#38#, OPCODE_SIZE));
	constant SLTUI		: opcode_t	:= std_logic_vector(to_unsigned(16#3A#, OPCODE_SIZE));
	constant SGTUI		: opcode_t	:= std_logic_vector(to_unsigned(16#3B#, OPCODE_SIZE));
	constant SLEUI		: opcode_t	:= std_logic_vector(to_unsigned(16#3C#, OPCODE_SIZE));
	constant SGEUI		: opcode_t	:= std_logic_vector(to_unsigned(16#3D#, OPCODE_SIZE));

	-- DLX ALU FUNCTIONS
	constant SHLL		: func_t	:= std_logic_vector(to_unsigned(16#04#, ALU_FUNCTION_SIZE));	-- Disambiguation from VHDL keyword SLL
	constant SHRL		: func_t	:= std_logic_vector(to_unsigned(16#06#, ALU_FUNCTION_SIZE));	-- Disambiguation from VHDL keyword SRL
	constant SHRA		: func_t	:= std_logic_vector(to_unsigned(16#07#, ALU_FUNCTION_SIZE));	-- Disambiguation from VHDL keyword SRA
	constant ADD		: func_t	:= std_logic_vector(to_unsigned(16#20#, ALU_FUNCTION_SIZE));
	constant ADDU		: func_t	:= std_logic_vector(to_unsigned(16#21#, ALU_FUNCTION_SIZE));
	constant SUB		: func_t	:= std_logic_vector(to_unsigned(16#22#, ALU_FUNCTION_SIZE));
	constant SUBU		: func_t	:= std_logic_vector(to_unsigned(16#23#, ALU_FUNCTION_SIZE));
	constant LAND		: func_t	:= std_logic_vector(to_unsigned(16#24#, ALU_FUNCTION_SIZE));	-- Disambiguation from VHDL keyword AND
	constant LOR		: func_t	:= std_logic_vector(to_unsigned(16#25#, ALU_FUNCTION_SIZE));	-- Disambiguation from VHDL keyword OR
	constant LXOR		: func_t	:= std_logic_vector(to_unsigned(16#26#, ALU_FUNCTION_SIZE));	-- Disambiguation from VHDL keyword XOR
	constant SEQ		: func_t	:= std_logic_vector(to_unsigned(16#28#, ALU_FUNCTION_SIZE));
	constant SNE		: func_t	:= std_logic_vector(to_unsigned(16#29#, ALU_FUNCTION_SIZE));
	constant SLT		: func_t	:= std_logic_vector(to_unsigned(16#2A#, ALU_FUNCTION_SIZE));
	constant SGT		: func_t	:= std_logic_vector(to_unsigned(16#2B#, ALU_FUNCTION_SIZE));
	constant SLE		: func_t	:= std_logic_vector(to_unsigned(16#2C#, ALU_FUNCTION_SIZE));
	constant SGE		: func_t	:= std_logic_vector(to_unsigned(16#2D#, ALU_FUNCTION_SIZE));
	constant MOVI2S		: func_t	:= std_logic_vector(to_unsigned(16#30#, ALU_FUNCTION_SIZE));
	constant MOVS2I		: func_t	:= std_logic_vector(to_unsigned(16#31#, ALU_FUNCTION_SIZE));
	constant MOVF		: func_t	:= std_logic_vector(to_unsigned(16#32#, ALU_FUNCTION_SIZE));
	constant MOVD		: func_t	:= std_logic_vector(to_unsigned(16#33#, ALU_FUNCTION_SIZE));
	constant MOVFP2I	: func_t	:= std_logic_vector(to_unsigned(16#34#, ALU_FUNCTION_SIZE));
	constant MOVI2FP	: func_t	:= std_logic_vector(to_unsigned(16#35#, ALU_FUNCTION_SIZE));
	constant MOVI2T		: func_t	:= std_logic_vector(to_unsigned(16#36#, ALU_FUNCTION_SIZE));
	constant MOVT2I		: func_t	:= std_logic_vector(to_unsigned(16#37#, ALU_FUNCTION_SIZE));
	constant SLTU		: func_t	:= std_logic_vector(to_unsigned(16#3A#, ALU_FUNCTION_SIZE));
	constant SGTU		: func_t	:= std_logic_vector(to_unsigned(16#3B#, ALU_FUNCTION_SIZE));
	constant SLEU		: func_t	:= std_logic_vector(to_unsigned(16#3C#, ALU_FUNCTION_SIZE));
	constant SGEU		: func_t	:= std_logic_vector(to_unsigned(16#3D#, ALU_FUNCTION_SIZE));

	-- DLX FP FUNCTIONS
	constant ADDF		: fp_func_t	:= std_logic_vector(to_unsigned(16#00#, FPU_FUNCTION_SIZE));
	constant SUBF		: fp_func_t	:= std_logic_vector(to_unsigned(16#01#, FPU_FUNCTION_SIZE));
	constant MULF		: fp_func_t	:= std_logic_vector(to_unsigned(16#02#, FPU_FUNCTION_SIZE));
	constant DIVF		: fp_func_t	:= std_logic_vector(to_unsigned(16#03#, FPU_FUNCTION_SIZE));
	constant ADDD		: fp_func_t	:= std_logic_vector(to_unsigned(16#04#, FPU_FUNCTION_SIZE));
	constant SUBD		: fp_func_t	:= std_logic_vector(to_unsigned(16#05#, FPU_FUNCTION_SIZE));
	constant MULD		: fp_func_t	:= std_logic_vector(to_unsigned(16#06#, FPU_FUNCTION_SIZE));
	constant DIVD		: fp_func_t	:= std_logic_vector(to_unsigned(16#07#, FPU_FUNCTION_SIZE));
	constant CVTF2D		: fp_func_t	:= std_logic_vector(to_unsigned(16#08#, FPU_FUNCTION_SIZE));
	constant CVTF2I		: fp_func_t	:= std_logic_vector(to_unsigned(16#09#, FPU_FUNCTION_SIZE));
	constant CVTD2F		: fp_func_t	:= std_logic_vector(to_unsigned(16#0A#, FPU_FUNCTION_SIZE));
	constant CVTD2I		: fp_func_t	:= std_logic_vector(to_unsigned(16#0B#, FPU_FUNCTION_SIZE));
	constant CVTI2F		: fp_func_t	:= std_logic_vector(to_unsigned(16#0C#, FPU_FUNCTION_SIZE));
	constant CVTI2D		: fp_func_t	:= std_logic_vector(to_unsigned(16#0D#, FPU_FUNCTION_SIZE));
	constant MUL		: fp_func_t	:= std_logic_vector(to_unsigned(16#0E#, FPU_FUNCTION_SIZE));
	constant DIV		: fp_func_t	:= std_logic_vector(to_unsigned(16#0F#, FPU_FUNCTION_SIZE));
	constant EQF		: fp_func_t	:= std_logic_vector(to_unsigned(16#10#, FPU_FUNCTION_SIZE));
	constant NEF		: fp_func_t	:= std_logic_vector(to_unsigned(16#11#, FPU_FUNCTION_SIZE));
	constant LTF		: fp_func_t	:= std_logic_vector(to_unsigned(16#12#, FPU_FUNCTION_SIZE));
	constant GTF		: fp_func_t	:= std_logic_vector(to_unsigned(16#13#, FPU_FUNCTION_SIZE));
	constant LEF		: fp_func_t	:= std_logic_vector(to_unsigned(16#14#, FPU_FUNCTION_SIZE));
	constant GEF		: fp_func_t	:= std_logic_vector(to_unsigned(16#15#, FPU_FUNCTION_SIZE));
	constant MULU		: fp_func_t	:= std_logic_vector(to_unsigned(16#16#, FPU_FUNCTION_SIZE));
	constant DIVU		: fp_func_t	:= std_logic_vector(to_unsigned(16#17#, FPU_FUNCTION_SIZE));
	constant EQD		: fp_func_t	:= std_logic_vector(to_unsigned(16#18#, FPU_FUNCTION_SIZE));
	constant NED		: fp_func_t	:= std_logic_vector(to_unsigned(16#19#, FPU_FUNCTION_SIZE));
	constant LTD		: fp_func_t	:= std_logic_vector(to_unsigned(16#1A#, FPU_FUNCTION_SIZE));
	constant GTD		: fp_func_t	:= std_logic_vector(to_unsigned(16#1B#, FPU_FUNCTION_SIZE));
	constant LED		: fp_func_t	:= std_logic_vector(to_unsigned(16#1C#, FPU_FUNCTION_SIZE));
	constant GED		: fp_func_t	:= std_logic_vector(to_unsigned(16#1D#, FPU_FUNCTION_SIZE));
	
end package;
