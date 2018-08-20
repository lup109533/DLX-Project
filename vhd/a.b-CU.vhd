library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity CU is
	port (
		CLK	: in	std_logic;
		RST	: in	std_logic;
		INSTR	: in	DLX_instruction_t;
		-- Control signals here.
	     );
end entity;

architecture behavioural of CU is
	
	type stages_t is (
					FET,	-- FETCH
					DEC,	-- DECODE
					EXE,	-- EXCUTE
					MEM,	-- MEMORY
					WRB		-- WRITE BACK
				);

begin
	
	-- INSTRUCTION UNPACKING
	opcode_s		<= INSTR(OPCODE_RANGE);
	source1_addr_s	<= INSTR(REG_SOURCE1_RANGE);
	source2_addr_s	<= INSTR(REG_SOURCE2_RANGE);
	dest_addr_s		<= INSTR(REG_DEST_RANGE);
	func_s			<= INSTR(ALU_FUNC_RANGE);
	fpu_func_s		<= INSTR(FPU_FUNC_RANGE);
	immediate_s		<= INSTR(IMMEDIATE_ARG_RANGE);
	pc_offset_s		<= INSTR(PC_OFFSET_RANGE);
	
	-- CONTROL SIGNAL GENERATOR
	control_signal_gen: process (RST, ENB, opcode_s) is
	begin
		if (RST <= '0' or ENB = '0') then
			ctrl_s(FET) <= (others => '0');
			ctrl_s(DEC) <= (others => '0');
			ctrl_s(EXE) <= (others => '0');
			ctrl_s(MEM) <= (others => '0');
			ctrl_s(WRB) <= (others => '0');
		else
			case (opcode_s) is
				when NOP =>
					ctrl_s(FET) <= (others => '0');
					ctrl_s(DEC) <= (others => '0');
					ctrl_s(EXE) <= (others => '0');
					ctrl_s(MEM) <= (others => '0');
					ctrl_s(WRB) <= (others => '0');
				-- ...
			end case;
		end if;
	end process;
	
	-- ALU OPCODE GENERATOR
	alu_opcode_manager: process (opcode_s, func_s) is
	begin
		if (opcode_s = ALUI_I) then
			case (func_s) is
				when SHLL | SHRL | SHRA =>
					alu_opcode_s <= SHIFT;
				
				when ADD | ADDU | SUB | SUBU =>
					alu_opcode_s <= ADD_SUB;
					
				when LAND | LOR | LXOR =>
					alu_opcode_s <= LOGIC;
					
				when SEQ | SNE | SLT | SGT | SLE | SGE | SLTU | SGTU | SLEU | SGEU =>
					alu_opcode_s <= COMPARISON;
					
				when others =>
					alu_opcode_s <= MOV;
			end case;
		else
			case (opcode_s) is
				when SLLI | SRLI | SRAI =>
					alu_opcode_s <= SHIFT;
			
				when ADDI | ADDUI | SUBI | SUBUI =>
					alu_opcode_s <= ADD_SUB;
					
				when ANDI | ORI | XORI =>
					alu_opcode_s <= LOGIC;
					
				when SEQI | SNEI | SLTI | SGTI | SLEI | SGEI | SLTUI | SGTUI | SLEUI | SGEUI =>
					alu_opcode_s <= COMPARISON;
					
				when others =>
					alu_opcode_s <= MOV;
			end case;
		end if;
	end process;
	ALU_OPCODE <= alu_opcode_s;
	
	-- FPU OPCODE GENERATOR
	alu_opcode_manager: process (fpu_func_s) is
	begin
		case (fpu_func_s) is
			when MUL | MULU =>
				fpu_opcode_s <= INT_MULTIPLY;
			
			when others =>
				fpu_opcode_s <= CONVERSION;
		end case;
	end process;
	FPU_OPCODE <= fpu_opcode_s;
	
	-- INSTRUCTION TYPE DISCRIMINATOR
	discriminate_instr_type: process (opcode_s) is
	begin
		case (opcode_s) is
			when NOP =>
				op_type <= NO_TYPE;
		
			when J | JAL =>
				op_type <= J_TYPE;
				
			when BEQZ | BNEZ | JR | JALR =>
				op_type <= JR_TYPE;
				
			when ALU_I | FPU_I =>
				op_type <= R_TYPE;
				
			when LHI | LB | LH | LW | LBU | LHU | LF | LD =>
				op_type <= L_TYPE;
				
			when SB | SH | SW | SF | SD =>
				op_type <= S_TYPE;
				
			when others =>
				op_type <= I_TYPE;
		end case;
	end process;
	
	-- HAZARD CHECK PIPELINE
	hazard_pipeline: process (CLK, RST, ENB, op_type, source1_addr_s, source2_addr_s, dest_addr_s, flush_s, stall_s) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				for i in stages_t loop
					hazard_pipe_t(i)	<= NO_TYPE;
					hazard_pipe_s1(i)	<= (others => '0');
					hazard_pipe_s2(i)	<= (others => '0');
					hazard_pipe_d(i)	<= (others => '0');
				end loop;
				
			elsif (ENB = '1') then
				if (flush_s = '1') then
					for i in FET to DEC loop
						hazard_pipe_t(i)	<= NO_TYPE;
						hazard_pipe_s1(i)	<= (others => '0');
						hazard_pipe_s2(i)	<= (others => '0');
						hazard_pipe_d(i)	<= (others => '0');
					end loop;
					
					for i in EXE to WRB loop
						hazard_pipe_t(i)	<= hazard_pipe_t(i-1);
						hazard_pipe_s1(i)	<= hazard_pipe_s1(i-1);
						hazard_pipe_s2(i)	<= hazard_pipe_s2(i-1);
						hazard_pipe_d(i)	<= hazard_pipe_d(i-1);
					end loop;
					
				elsif (stall_s = '1') then
					for i in FET to DEC loop
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
					hazard_pipe_t(FET)	<= op_type;
					hazard_pipe_s1(FET)	<= source1_addr_s;
					hazard_pipe_s2(FET)	<= source2_addr_s;
					hazard_pipe_d(FET)	<= dest_addr_s;
					for i in DEC to WRB loop
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
	target_has_s1		<= '1' when (hazard_pipe_t(DEC) = R_TYPE or hazard_pipe_t(DEC) = I_TYPE or hazard_pipe_t(DEC) = JR_TYPE)	else '0';
	target_has_s2		<= '1' when (hazard_pipe_t(DEC) = R_TYPE)																	else '0';
	exe_source_has_d	<= '1' when not(hazard_pipe_t(EXE) = J_TYPE	or hazard_pipe_t(EXE) = JR_TYPE	or hazard_pipe_t(EXE) = S_TYPE)	else '0';
	mem_source_has_d	<= '1' when not(hazard_pipe_t(MEM) = J_TYPE	or hazard_pipe_t(MEM) = JR_TYPE	or hazard_pipe_t(MEM) = S_TYPE)	else '0';
	wrb_source_has_d	<= '1' when not(hazard_pipe_t(WRB) = J_TYPE	or hazard_pipe_t(WRB) = JR_TYPE	or hazard_pipe_t(WRB) = S_TYPE)	else '0';
	exe_can_forward_s1	<= '1' when (hazard_pipe_s1(DEC) = hazard_pipe_d(EXE))														else '0';
	mem_can_forward_s1	<= '1' when (hazard_pipe_s1(DEC) = hazard_pipe_d(MEM))														else '0';
	wrb_can_forward_s1	<= '1' when (hazard_pipe_s1(DEC) = hazard_pipe_d(WRB))														else '0';
	exe_can_forward_s2	<= '1' when (hazard_pipe_s2(DEC) = hazard_pipe_d(EXE))														else '0';
	mem_can_forward_s2	<= '1' when (hazard_pipe_s2(DEC) = hazard_pipe_d(MEM))														else '0';
	wrb_can_forward_s2	<= '1' when (hazard_pipe_s2(DEC) = hazard_pipe_d(WRB))														else '0';
	
	---- S1
	X2D_FORWARD_S1_EN	<= target_has_s1 and exe_source_has_d and exe_can_forward_s1;
	M2D_FORWARD_S1_EN	<= target_has_s1 and exe_source_has_d and mem_can_forward_s1;
	W2D_FORWARD_S1_EN	<= target_has_s1 and exe_source_has_d and wrb_can_forward_s1;
	---- S2
	X2D_FORWARD_S2_EN	<= target_has_s2 and exe_source_has_d and exe_can_forward_s2;
	M2D_FORWARD_S2_EN	<= target_has_s2 and exe_source_has_d and mem_can_forward_s2;
	W2D_FORWARD_S2_EN	<= target_has_s2 and exe_source_has_d and wrb_can_forward_s2;
	
	-- CONTROL HAZARD FLUSH CHECK
	-- If the instruction at the EXECUTION stage is a branch, the prediction obtained at the DECODE stage is checked against the result.
	-- If the prediction is correct, execution continues as normal, otherwise flushing is required (previous pipeline instructions are
	-- replaced with NOP).
	flush_s	<= '1' when (hazard_pipe_t(EXE) = J_TYPE or hazard_pipe_t(EXE) = JR_TYPE) and not(prediction_exe_s = BRANCH_TAKEN) else '0';
	FLUSH	<= flush_s;
	
	-- STALL CHECK
	-- Stall occurs in the particular case in which a source register requires data that has not been fetched from the main memory yet, i.e. if an instruction in the
	-- DECODE stage requires the destination of a load-type operation in the EXECUTION stage.
	-- In this case, the previous stages are disabled (with the exception of the RF in the DECODE stage) for 1 clock cycle, after which forwarding is possible.
	exe_source_is_load	<= '1' when (hazard_pipe_t(EXE) = L_TYPE) else '0';
	stall_s				<= (target_has_s1 or target_has_s2) and exe_source_is_load and (exe_can_forward_s1 or exe_can_forward_s2);
	STALL				<= stall_s;
	
end architecture;
