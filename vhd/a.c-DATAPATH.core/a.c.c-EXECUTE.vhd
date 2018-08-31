library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity EXECUTE is
	port (
		-- Control signals from CU.
		ALU_OPCODE		: in	alu_opcode_t;
		FPU_OPCODE		: in	fpu_opcode_t;
		IMM_SEL			: in	std_logic;
		FPU_FUNC_SEL	: in	std_logic;
		BRANCH_TAKEN	: out	std_logic;
		BRANCH_ADDR		: out	DLX_addr_t;
		-- Signals from/to previous/successive stages.
		R1, R2			: in	DLX_oper_t;	-- Register inputs.
		IMM				: in	DLX_oper_t;	-- Immediate input, extended with/without sign during DECODE stage.
		EX_OUT			: out	DLX_oper_t;	-- EXECUTE stage output.
	);
end entity;

architecture structural of EXECUTE is

	component ALU
		generic (OPERAND_SIZE : natural);
		port (
			FUNC	: in	alu_opcode_t;
			R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CMP_OUT	: out	std_logic
		);
	end component;
	
	component FPU
		generic (OPERAND_SIZE : natural);
		port (
			FUNC	: in	fpu_opcode_t;
			F1, F2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;
	
	signal alu_opcode_s				: alu_opcode_t;
	signal fpu_opcode_s				: fpu_opcode_t;
	signal r1_s, r2_s, f1_s, f2_s	: DLX_oper_t;
	signal alu_out_s, fpu_out_s		: DLX_oper_t;
	
begin

	EX_ALU: ALU generic map(DLX_OPERAND_SIZE) port map(alu_opcode_s, r1_s, r2_s, alu_out_s, BRANCH_TAKEN);
	EX_FPU: FPU generic map(DLX_OPERAND_SIZE) port map(fpu_opcode_s, f1_s, f2_s, fpu_out_s);
	
	-- MUX INPUTS
	r1_s <= R1;
	r2_s <= R2 when (IMM_SEL = '0') else IMM;
	
	f1_s <= R1;
	f2_s <= r2_s;
	
	alu_opcode_s <= ALU_OPCODE;
	fpu_opcode_s <= FPU_OPCODE;
	
	-- MUX OUTPUTS
	EX_OUT <= alu_out_s when (FPU_FUNC_SEL = '0') else fpu_out_s;

end architecture;