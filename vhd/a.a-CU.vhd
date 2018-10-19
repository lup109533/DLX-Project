library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity CU is
	port (
		CLK					: in	std_logic;
		RST					: in	std_logic;
		ENB					: in	std_logic;
		INSTR				: in	DLX_instr_t;
		
		-- Special signals for TRAP instruction
		ISR_EN				: out	std_logic;
		
		-- DECODE
		RF_RD1_ADDR			: out	reg_addr_t;
		RF_RD2_ADDR			: out	reg_addr_t;
		RF_WR_ADDR			: out	reg_addr_t;
		RF_RD1				: out	std_logic;
		RF_RD2				: out	std_logic;
		RF_CALL				: out	std_logic;
		RF_RETN				: out	std_logic;
		IMM_ARG				: out	immediate_t;
		IMM_SEL				: out	std_logic;
		PC_OFFSET			: out	pc_offset_t;
		PC_OFFSET_SEL		: out	std_logic;
		OPCODE				: out	opcode_t;
		SIGNED_EXT			: out	std_logic;
		
		-- EXECUTE
		ALU_OPCODE			: out	ALU_opcode_t;
		FPU_OPCODE			: out	FPU_opcode_t;
		FPU_FUNC_SEL		: out	std_logic;
		
		-- MEMORY
		MEM_RD_SEL			: out	std_logic;
		MEM_WR_SEL			: out	std_logic;
		MEM_EN				: out	std_logic;
		MEMORY_OP_SEL		: out	std_logic;
		MEM_SIGNED_EXT		: out	std_logic;
		MEM_HALFWORD		: out	std_logic;
		MEM_BYTE			: out	std_logic;
		
		-- WRITE BACK
		LINK_PC				: out	std_logic;
		RF_WR				: out	std_logic;
		
		-- OTHER
		X2D_FORWARD_S1_EN	: out	std_logic;
		M2D_FORWARD_S1_EN	: out	std_logic;
		W2D_FORWARD_S1_EN	: out	std_logic;
		X2D_FORWARD_S2_EN	: out	std_logic;
		M2D_FORWARD_S2_EN	: out	std_logic;
		W2D_FORWARD_S2_EN	: out	std_logic;
		STALL				: out	std_logic
	);
end entity;

architecture behavioural of CU is
	
	constant DEC 				: integer := 0;	-- DECODE
	constant EXE 				: integer := 1;	-- EXCUTE
	constant MEM 				: integer := 2;	-- MEMORY
	constant WRB 				: integer := 3;	-- WRITE BACK
	
	constant JUMP_AND_LINK_ADDR	: reg_addr_t := std_logic_vector(to_unsigned(31, REGISTER_ADDR_SIZE));
				
	signal opcode_s				: opcode_t;
	signal source1_addr_s		: reg_addr_t;
	signal source2_addr_s		: reg_addr_t;
	signal dest_addr_s			: reg_addr_t;
	signal func_s				: func_t;
	signal fpu_func_s			: fp_func_t;
	signal immediate_s			: immediate_t;
	signal pc_offset_s			: pc_offset_t;
	signal op_type				: DLX_instr_type_t;
	
	signal signed_immediate		: std_logic;
	signal signed_alu_op		: std_logic;
	signal signed_fpu_op		: std_logic;
	
	signal alu_opcode_s			: ALU_opcode_t;
	signal fpu_opcode_s			: FPU_opcode_t;
	
	type hazard_pipe_op_type_t  is array (DEC to WRB) of DLX_instr_type_t;
	type hazard_pipe_reg_addr_t is array (DEC to WRB) of reg_addr_t;
	
	signal hazard_pipe_t		: hazard_pipe_op_type_t;
	signal hazard_pipe_s1		: hazard_pipe_reg_addr_t;
	signal hazard_pipe_s2		: hazard_pipe_reg_addr_t;
	signal hazard_pipe_d		: hazard_pipe_reg_addr_t;
	
	signal target_has_s1		: std_logic;
	signal target_has_s2		: std_logic;
	signal exe_source_has_d		: std_logic;
	signal mem_source_has_d		: std_logic;
	signal wrb_source_has_d		: std_logic;
	signal exe_can_forward_s1	: std_logic;
	signal mem_can_forward_s1	: std_logic;
	signal wrb_can_forward_s1	: std_logic;
	signal exe_can_forward_s2	: std_logic;
	signal wrb_can_forward_s2	: std_logic;
	signal mem_can_forward_s2	: std_logic;
	signal exe_source_is_load	: std_logic;
	signal stall_s				: std_logic;

begin
	
	-- INSTRUCTION UNPACKING
	opcode_s		<= INSTR(OPCODE_RANGE);
	source1_addr_s	<= INSTR(REG_SOURCE1_RANGE);
	source2_addr_s	<= INSTR(REG_SOURCE2_RANGE);
	dest_addr_s		<= INSTR(REG_DEST_RANGE) when (op_type = R_TYPE) else INSTR(REG_SOURCE2_RANGE);
	func_s			<= INSTR(ALU_FUNC_RANGE);
	fpu_func_s		<= INSTR(FPU_FUNC_RANGE);
	immediate_s		<= INSTR(IMMEDIATE_ARG_RANGE);
	pc_offset_s		<= INSTR(PC_OFFSET_RANGE);
	
	-- CONTROL SIGNAL GENERATION
	-- DECODE STAGE
	RF_RD1_ADDR		<= source1_addr_s;
	RF_RD2_ADDR		<= source2_addr_s;
	RF_WR_ADDR		<= JUMP_AND_LINK_ADDR when (opcode_s = JAL or opcode_s = JALR) else dest_addr_s;
	RF_RD1			<= '1' when (op_type = R_TYPE) else '0';
	RF_RD2			<= '1' when (op_type = R_TYPE) else '0';
	RF_CALL			<= '1' when (opcode_s = TRAP)  else '0';
	RF_RETN			<= '1' when (opcode_s = RFE)   else '0';
	ISR_EN			<= '1' when (opcode_s = TRAP)  else '0';
	IMM_ARG			<= immediate_s;
	IMM_SEL			<= '1' when (op_type = I_TYPE or opcode_s = LHI) else '0';
	PC_OFFSET		<= (others => '0') when (opcode_s = JAL or opcode_s = JALR) else pc_offset_s;
	PC_OFFSET_SEL	<= '1' when (op_type = J_TYPE or
					             opcode_s = BEQZ  or
								 opcode_s = BNEZ  or
								 opcode_s = JR    or
								 opcode_s = JALR) else '0';
	OPCODE			<= opcode_s;
	SIGNED_EXT		<= '1' when	((op_type = I_TYPE   and signed_immediate = '1') or
							     (opcode_s = ALU_I   and signed_alu_op = '1')    or
							     (opcode_s = FPU_I   and signed_fpu_op = '1'))   else '0';
	
	-- EXCUTE STAGE
	FPU_FUNC_SEL	<= '1' when (opcode_s = FPU_I) else '0';
	
	-- MEMORY STAGE
	MEM_RD_SEL		<= '1' when (op_type = L_TYPE) else '0';
	MEM_WR_SEL		<= '1' when (op_type = S_TYPE) else '0';
	MEM_EN			<= '1' when (op_type = L_TYPE  or
					             op_type = S_TYPE) else '0';
	MEMORY_OP_SEL	<= '1' when (op_type = L_TYPE  or
					             op_type = S_TYPE) else '0';
	MEM_SIGNED_EXT	<= '1' when (opcode_s = LBU  or
					             opcode_s = LHU) else '0';
	MEM_HALFWORD	<= '1' when (opcode_s = LH  or
					             opcode_s = LHU or
								 opcode_s = SH) else '0';
	MEM_BYTE		<= '1' when (opcode_s = LB  or
					             opcode_s = LBU or
								 opcode_s = SB) else '0';
								 
	-- WRITE BACK STAGE
	RF_WR			<= '1' when (op_type = R_TYPE or opcode_s = JAL or opcode_s = JALR) else '0';
	LINK_PC			<= '1' when (opcode_s = JAL or opcode_s = JALR) else '0';
								
	
	signed_immediate	<= '0' when (opcode_s = ADDUI or
						             opcode_s = SUBUI or
									 opcode_s = SLTUI or
									 opcode_s = SGTUI or
									 opcode_s = SLEUI or
									 opcode_s = SGEUI) else '1';
									 
	signed_alu_op		<= '0' when (func_s = ADDU or
						             func_s = SUBU or
									 func_s = SLTU or
									 func_s = SGTU or
									 func_s = SLEU or
									 func_s = SGEU) else '1';
									 
	signed_fpu_op		<= '0' when (fpu_func_s = MULU or fpu_func_s = DIVU) else '1';
	
	-- ALU OPCODE GENERATOR
	alu_opcode_s	<= SHIFT_LL		when (func_s = SHLL) else
					   SHIFT_RL		when (func_s = SHRL) else
					   SHIFT_RA		when (func_s = SHRA) else
					   IADD			when (func_s = ADD  or func_s = ADDU) else
					   ISUB			when (func_s = SUB0 or func_s = SUBU) else
					   LOGIC_AND	when (func_s = LAND) else
					   LOGIC_OR		when (func_s = LOR)  else
					   LOGIC_XOR	when (func_s = LXOR) else
					   COMPARE_EQ	when (func_s = SEQ)  else
					   COMPARE_NE	when (func_s = SNE)  else
					   COMPARE_LT	when (func_s = SLT or func_s = SLTU) else
					   COMPARE_GT	when (func_s = SGT or func_s = SGTU) else
					   COMPARE_LE	when (func_s = SLE or func_s = SLEU) else
					   COMPARE_GE	when (func_s = SGE or func_s = SGEU) else
					   
					   IADD			when (opcode_s = ADDI or opcode_s = ADDUI) else
					   IADD			when (opcode_s = J    or opcode_s = JAL    or opcode_s = JR or opcode_s = JALR) else
					   ISUB			when (opcode_s = SUBI or opcode_s = SUBUI) else
					   LOGIC_AND	when (opcode_s = ANDI)  else
					   LOGIC_OR		when (opcode_s = ORI)   else
					   LOGIC_XOR	when (opcode_s = XORI)  else
					   COMPARE_EQ	when (opcode_s = SEQI)  else
					   COMPARE_NE	when (opcode_s = SNEI)  else
					   COMPARE_LT	when (opcode_s = SLTI or opcode_s = SLTUI) else
					   COMPARE_GT	when (opcode_s = SGTI or opcode_s = SGTUI) else
					   COMPARE_LE	when (opcode_s = SLEI or opcode_s = SLEUI) else
					   COMPARE_GE	when (opcode_s = SGEI or opcode_s = SGEUI) else
					   MOV;
					   
	ALU_OPCODE <= alu_opcode_s;
	
	-- FPU OPCODE GENERATOR
	fpu_opcode_s	<= FP_ADD		 when (fpu_func_s = ADDF) else
					   FP_SUB		 when (fpu_func_s = SUBF) else
					   INT_MULTIPLY	 when (fpu_func_s = MUL or fpu_func_s = MULU) else
					   FP_MULTIPLY	 when (fpu_func_s = MULF) else
					   FP_COMPARE_EQ when (fpu_func_s = EQF) else 
					   FP_COMPARE_NE when (fpu_func_s = NEF) else  
					   FP_COMPARE_LT when (fpu_func_s = LTF) else  
					   FP_COMPARE_GT when (fpu_func_s = GTF) else  
					   FP_COMPARE_LE when (fpu_func_s = LEF) else  
					   FP_COMPARE_GE when (fpu_func_s = GEF) else 
					   F2I_CONVERT	 when (fpu_func_s = CVTF2I) else
					   I2F_CONVERT;
					   
	FPU_OPCODE <= fpu_opcode_s;
	
	-- INSTRUCTION TYPE DISCRIMINATOR
	op_type	<= NO_TYPE	when (opcode_s = NOP) else
			   J_TYPE	when (opcode_s = J     or opcode_s = JAL) else
			   R_TYPE	when (opcode_s = ALU_I or opcode_s = FPU_I) else
			   L_TYPE	when (opcode_s = LHI   or opcode_s = LB  or
			                  opcode_s = LH    or opcode_s = LW  or
							  opcode_s = LBU   or opcode_s = LHU or
							  opcode_s = LF0   or opcode_s = LD) else
			   S_TYPE	when (opcode_s = SB    or opcode_s = SH  or
			                  opcode_s = SW    or opcode_s = SF  or
							  opcode_s = SD)                     else
			   I_TYPE;
	
	-- HAZARD CHECK PIPELINE
	hazard_pipeline: process (CLK, RST, ENB, op_type, source1_addr_s, source2_addr_s, dest_addr_s, stall_s) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				for i in DEC to WRB loop
					hazard_pipe_t(i)	<= NO_TYPE;
					hazard_pipe_s1(i)	<= (others => '0');
					hazard_pipe_s2(i)	<= (others => '0');
					hazard_pipe_d(i)	<= (others => '0');
				end loop;
				
			elsif (ENB = '1') then
				if (stall_s = '1') then
					for i in DEC to DEC loop
						hazard_pipe_t(i)	<= hazard_pipe_t(i);
						hazard_pipe_s1(i)	<= hazard_pipe_s1(i);
						hazard_pipe_s2(i)	<= hazard_pipe_s2(i);
						hazard_pipe_d(i)	<= hazard_pipe_d(i);
					end loop;
					
					hazard_pipe_t(EXE)	<= NO_TYPE;
					hazard_pipe_s1(EXE)	<= (others => '0');
					hazard_pipe_s2(EXE)	<= (others => '0');
					hazard_pipe_d(EXE)	<= (others => '0');
					
					for i in MEM to WRB loop
						hazard_pipe_t(i)	<= hazard_pipe_t(i-1);
						hazard_pipe_s1(i)	<= hazard_pipe_s1(i-1);
						hazard_pipe_s2(i)	<= hazard_pipe_s2(i-1);
						hazard_pipe_d(i)	<= hazard_pipe_d(i-1);
					end loop;
					
				else
					hazard_pipe_t(DEC)	<= op_type;
					hazard_pipe_s1(DEC)	<= source1_addr_s;
					hazard_pipe_s2(DEC)	<= source2_addr_s;
					hazard_pipe_d(DEC)	<= dest_addr_s;
					for i in EXE to WRB loop
						hazard_pipe_t(i)	<= hazard_pipe_t(i-1);
						hazard_pipe_s1(i)	<= hazard_pipe_s1(i-1);
						hazard_pipe_s2(i)	<= hazard_pipe_s2(i-1);
						hazard_pipe_d(i)	<= hazard_pipe_d(i-1);
					end loop;
				end if;
			end if;
		end if;
	end process;
	
	-- FORWRDING CHECK
	-- Forwarding is checked at the earliest possible occasion (DECODE stage, if forwarding is not possible, stalling is employed).
	-- The forwarding target instruction type is checked to see whether one or more source registers are employed, then the source register(s)
	-- is/are checked against the destination register(s) of the following instructions, but only if the following instruction types
	-- require a destination register (in most cases).
	target_has_s1		<= '1' when (hazard_pipe_t(DEC) = R_TYPE or hazard_pipe_t(DEC) = I_TYPE)	else '0';
	target_has_s2		<= '1' when (hazard_pipe_t(DEC) = R_TYPE)									else '0';
	exe_source_has_d	<= '1' when not(hazard_pipe_t(EXE) = J_TYPE	or hazard_pipe_t(EXE) = S_TYPE)	else '0';
	mem_source_has_d	<= '1' when not(hazard_pipe_t(MEM) = J_TYPE	or hazard_pipe_t(MEM) = S_TYPE)	else '0';
	wrb_source_has_d	<= '1' when not(hazard_pipe_t(WRB) = J_TYPE	or hazard_pipe_t(WRB) = S_TYPE)	else '0';
	exe_can_forward_s1	<= '1' when (hazard_pipe_s1(DEC) = hazard_pipe_d(EXE))						else '0';
	mem_can_forward_s1	<= '1' when (hazard_pipe_s1(DEC) = hazard_pipe_d(MEM))						else '0';
	wrb_can_forward_s1	<= '1' when (hazard_pipe_s1(DEC) = hazard_pipe_d(WRB))						else '0';
	exe_can_forward_s2	<= '1' when (hazard_pipe_s2(DEC) = hazard_pipe_d(EXE))						else '0';
	mem_can_forward_s2	<= '1' when (hazard_pipe_s2(DEC) = hazard_pipe_d(MEM))						else '0';
	wrb_can_forward_s2	<= '1' when (hazard_pipe_s2(DEC) = hazard_pipe_d(WRB))						else '0';
	
	---- S1
	X2D_FORWARD_S1_EN	<= target_has_s1 and exe_source_has_d and exe_can_forward_s1;
	M2D_FORWARD_S1_EN	<= target_has_s1 and exe_source_has_d and mem_can_forward_s1;
	W2D_FORWARD_S1_EN	<= target_has_s1 and exe_source_has_d and wrb_can_forward_s1;
	---- S2
	X2D_FORWARD_S2_EN	<= target_has_s2 and exe_source_has_d and exe_can_forward_s2;
	M2D_FORWARD_S2_EN	<= target_has_s2 and exe_source_has_d and mem_can_forward_s2;
	W2D_FORWARD_S2_EN	<= target_has_s2 and exe_source_has_d and wrb_can_forward_s2;
	
	-- STALL CHECK
	-- Stall occurs in the particular case in which a source register requires data that has not been fetched from the main memory yet, i.e. if an instruction in the
	-- DECODE stage requires the destination of a load-type operation in the EXECUTION stage.
	-- In this case, the previous stages are disabled (with the exception of the RF in the DECODE stage) for 1 clock cycle, after which forwarding is possible.
	exe_source_is_load	<= '1' when (hazard_pipe_t(EXE) = L_TYPE) else '0';
	stall_s				<= (target_has_s1 or target_has_s2) and exe_source_is_load and (exe_can_forward_s1 or exe_can_forward_s2);
	STALL				<= stall_s;
	
end architecture;
