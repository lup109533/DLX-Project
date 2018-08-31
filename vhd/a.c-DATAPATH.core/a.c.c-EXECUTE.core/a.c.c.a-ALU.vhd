library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use work.DLX_globals.all;
use work.compare_types.all;
use work.lu_ctrl.all;

entity ALU is
	generic (OPERAND_SIZE : natural);
	port (
		R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		OPCODE	: in	ALU_opcode_t;
		O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
		CMP_OUT	: out	std_logic
	);
end entity;

architecture structural of ALU is

	-- COMPONENTS
	component ADD_SUB
		generic (OPERAND_SIZE : natural);
		port (
			R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			S, C	: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;
	
	component LOGIC_UNIT
		generic (OPERAND_SIZE : natural);
		port (
			CTRL	: in	lu_ctrl_t;
			R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O	: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;

	-- SIGNALS
	signal shifter_out	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal addsub_out	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal set_out		: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal lu_out		: std_logic_vector(OPERAND_SIZE-1 downto 0);
	
	signal sub_sel		: std_logic;
	signal zero_flag	: std_logic;
	signal carry_flag	: std_logic;
	
	type operation_type is (SHIFT, SUM_OR_SUB, LOGIC, COMPARE);
	
	signal alu_function	: operation_type;
	signal compare_sel	: compare_type;
	signal logic_sel	: lu_ctrl_t;

begin
	-- CHECK OPERATION TYPE
	alu_function <=	SHIFT		when (OPCODE = SHIFT)																	else
					SUM_OR_SUB	when (OPCODE = IADD or OPCODE = ISUB or OPCODE = BRANCH_IF_EQ or OPCODE = BRANCH_IF_NE)	else
					LOGIC		when (OPCODE = LOGIC_AND or OPCODE = LOGIC_OR or OPCODE = LOGIC_XOR)					else
					COMPARE;

					
	-- SHIFTER
	SHIFT: SHIFTER generic map (OPERAND_SIZE) port map (R1, R2, shifter_out);
	
	
	-- ADDER/SUBTRACTOR
	ADDSUB: ADD_SUB generic map (OPERAND_SIZE) port map (R1, R2, sub_sel, addsub_out, carry_flag);
	---- Check if subtraction
	sub_sel	<= '1' when (OPCODE = SUB) else '0';
	
	
	-- COMPARATOR
	COMPARE: COMPARATOR generic map (OPERAND_SIZE) port map (zero_flag, carry_flag, compare_sel, comparator_out);
	---- Zero flag generation
	zero_flag		<= not(or_reduce(addsub_out));
	---- For set-type operations
	set_out			<= (OPERAND_SIZE-1 downto 1 => '0', others => comparator_out);
	---- Translate opcode into comparison type
	compare_sel		<=	EQUAL		when (OPCODE = COMPARE_EQ or OPCODE = BRANCH_IF_EQ)	else
						NOT_EQUAL	when (OPCODE = COMPARE_NE or OPCODE = BRANCH_IF_NE)	else
						GREATER		when (OPCODE = COMPARE_GT)							else
						GREATER_EQ	when (OPCODE = COMPARE_GE)							else
						LESS		when (OPCODE = COMPARE_LT)							else
						LESS_EQ		when (OPCODE = COMPARE_LE)							else
						NIL;
	---- Comparator output for conditional branching
	CMP_OUT			<= comparator_out;
	
	
	-- LOGIC UNIT
	LU: LOGIC_UNIT generic map (OPERAND_SIZE) port map (R1, R2, logic_sel, lu_out);
	---- Translate opcode into selection bits
	logic_sel		<=	LU_AND		when (OPCODE = LOGIC_AND)	else
						LU_OR		when (OPCODE = LOGIC_OR)	else
						LU_XOR		when (OPCODE = LOGIC_XOR)	else
						LU_FALSE;
	
	
	-- OUTPUT MUX
	O	<=	shifter_out	when (alu_function = SHIFT)			else
			addsub_out	when (alu_function = SUM_OR_SUB)	else
			set_out		when (alu_function = COMPARE)		else
			lu_out;

end architecture;