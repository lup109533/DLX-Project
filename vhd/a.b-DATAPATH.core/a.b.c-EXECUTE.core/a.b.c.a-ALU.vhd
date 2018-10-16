library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use work.DLX_globals.all;
use work.lu_ctrl.all;
use work.cmp_ctrl.all;

entity ALU is
	generic (OPERAND_SIZE : natural);
	port (
		R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		OPCODE	: in	ALU_opcode_t;
		O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
	);
end entity;

architecture structural of ALU is

	-- COMPONENTS
	component ADD_SUB
		generic (OPERAND_SIZE : natural);
		port (
			R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic;
			S		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			C		: out	std_logic
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
	
	component SHIFTER
		generic (
			NBIT: integer := 32
		);
		port (
			left_right: in std_logic;	-- LEFT/RIGHT
			logic_Arith : in std_logic;	-- LOGIC/ARITHMETIC, will be used in signed/unsigned instructions
			a : in std_logic_vector(NBIT-1 downto 0); --data to be shift
			b : in std_logic_vector(NBIT-1 downto 0); --# of bits to be shifted
			o : out std_logic_vector(NBIT-1 downto 0)
		);
	end component;
	
	component COMPARATOR
		port(
			Z	: in	std_logic;
			C	: in	std_logic;
			SEL	: in	compare_type;
			O	: out	std_logic
		);
	end component;

	-- SIGNALS
	signal shifter_out	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal addsub_out	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal set_out		: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal lu_out		: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal compare_out	: std_logic;
	
	signal sub_sel		: std_logic;
	signal zero_flag	: std_logic;
	signal carry_flag	: std_logic;
	
	type operation_type is (SHIFT, SUM_OR_SUB, LOGIC, COMPARE);
	
	signal alu_function	: operation_type;
	signal compare_sel	: compare_type;
	signal logic_sel	: lu_ctrl_t;
	signal shift_dir	: std_logic;
	signal shift_mode	: std_logic;

begin
	-- CHECK OPERATION TYPE
	alu_function <=	SHIFT		when (OPCODE = SHIFT_RA or OPCODE = SHIFT_LA or OPCODE = SHIFT_RL or OPCODE = SHIFT_LL)	else
					SUM_OR_SUB	when (OPCODE = IADD or OPCODE = ISUB or OPCODE = BRANCH_IF_EQ or OPCODE = BRANCH_IF_NE)	else
					LOGIC		when (OPCODE = LOGIC_AND or OPCODE = LOGIC_OR or OPCODE = LOGIC_XOR)					else
					COMPARE;

					
	-- SHIFTER
	SHIFTER0: SHIFTER generic map (OPERAND_SIZE) port map (shift_dir, shift_mode, R1, R2, shifter_out);
	shift_dir	<= '1' when (OPCODE = SHIFT_RA or OPCODE = SHIFT_RL) else '0';
	shift_mode	<= '1' when (OPCODE = SHIFT_RA or OPCODE = SHIFT_LA) else '0';
	
	
	-- ADDER/SUBTRACTOR
	ADDSUB: ADD_SUB generic map (OPERAND_SIZE) port map (R1, R2, sub_sel, addsub_out, carry_flag);
	---- Check if subtraction
	sub_sel	<= '1' when (OPCODE = ISUB			or
						 OPCODE = COMPARE_EQ	or
						 OPCODE = COMPARE_NE	or
						 OPCODE = COMPARE_GT	or
						 OPCODE = COMPARE_GE	or
						 OPCODE = COMPARE_LT	or
						 OPCODE = COMPARE_LE)	else '0';
	
	
	-- COMPARATOR
	COMPARE0: COMPARATOR port map (zero_flag, carry_flag, compare_sel, compare_out);
	---- Zero flag generation
	zero_flag		<= not(or_reduce(addsub_out));
	---- For set-type operations
	set_out(OPERAND_SIZE-1 downto 1)	<= (others => '0');
	set_out(0) 							<= compare_out;
	---- Translate opcode into comparison type
	compare_sel		<=	EQUAL		when (OPCODE = COMPARE_EQ)	else
						NOT_EQUAL	when (OPCODE = COMPARE_NE)	else
						GREATER		when (OPCODE = COMPARE_GT)	else
						GREATER_EQ	when (OPCODE = COMPARE_GE)	else
						LESS		when (OPCODE = COMPARE_LT)	else
						LESS_EQ		when (OPCODE = COMPARE_LE)	else
						NO_COMPARE;
	
	
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