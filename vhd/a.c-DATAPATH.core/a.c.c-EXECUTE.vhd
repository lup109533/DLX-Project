library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity EXECUTE is
	port (
		-- Control signals from CU.
		FUNC			: in	func_t;
		IMM_SEL			: in	std_logic;
		FPU_FUNC_SEL	: in	std_logic;
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
			FUNC	: in	func_t;
			R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;
	
	component FPU
		generic (OPERAND_SIZE : natural);
		port (
			FUNC	: in	fp_func_t;
			F1, F2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;
	
	signal alu_func_s				: func_t;
	signal fpu_func_s				: fp_func_t;
	signal r1_s, r2_s, f1_s, f2_s	: DLX_oper_t;
	signal alu_out_s, fpu_out_s		: DLX_oper_t;
	
begin

	EX_ALU: ALU generic map(DLX_OPERAND_SIZE) port map(alu_func_s, r1_s, r2_s, alu_out_s);
	EX_FPU: FPU generic map(DLX_OPERAND_SIZE) port map(fpu_func_s, f1_s, f2_s, fpu_out_s);
	
	-- MUX INPUTS
	r1_s <= R1;
	r2_s <= R2 when (IMM_SEL = '0') else IMM;
	
	f1_s <= R1;
	f2_s <= r2_s;
	
	alu_func_s <= FUNC(ALU_FUNCTION_SIZE-1 downto 0);	-- Allows for generic compatibility in case of architecture change.
	fpu_func_s <= FUNC(FPU_FUNCTION_SIZE-1 downto 0);	-- FUNC is always at least as wide as the widest function signal.
	
	-- MUX OUTPUTS
	EX_OUT <= alu_out_s when (FPU_FUNC_SEL = '0') else fpu_out_s;

end architecture;