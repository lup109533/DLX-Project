library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity DATAPATH is
	port (
		CLK					: in	std_logic;
		RST					: in	std_logic;
		FETCH_ENB			: in	std_logic;
		DECODE_ENB			: in	std_logic;
		EXECUTE_ENB			: in	std_logic;
		MEMORY_ENB			: in	std_logic;
		
		-- FETCH
		PC					: out	DLX_addr_t;
		ICACHE_INSTR		: in	DLX_instr_t;
		FETCHED_INSTR		: out	DLX_instr_t;
		
		-- DECODE
		PC_OUT_EN				: in	std_logic;
		HEAP_ADDR			: in	DLX_addr_t;
		RF_SWP				: out	DLX_addr_t;
		MBUS				: inout	DLX_addr_t;
		RF_RD1_ADDR			: in	reg_addr_t;
		RF_RD2_ADDR			: in	reg_addr_t;
		RF_WR_ADDR			: in	reg_addr_t;
		RF_RD1				: in	std_logic;
		RF_RD2				: in	std_logic;
		RF_CALL				: in	std_logic;
		RF_RETN				: in	std_logic;
		IMM_ARG				: in	immediate_t;
		IMM_SEL				: in	std_logic;
		PC_OFFSET			: in	pc_offset_t;
		PC_OFFSET_SEL		: in	std_logic;
		SIGNED_EXT			: in	std_logic;
		LHI_EXT				: in	std_logic;
		OPCODE				: in	opcode_t;
		X2D_FORWARD_S1_EN	: in	std_logic;
		M2D_FORWARD_S1_EN	: in	std_logic;
		W2D_FORWARD_S1_EN	: in	std_logic;
		X2D_FORWARD_S2_EN	: in	std_logic;
		M2D_FORWARD_S2_EN	: in	std_logic;
		W2D_FORWARD_S2_EN	: in	std_logic;
		RF_SPILL			: out	std_logic;
		RF_FILL				: out	std_logic;
		RF_ACK				: in	std_logic;
		RF_OK				: out	std_logic;
		
		-- EXECUTE
		ALU_OPCODE			: in	alu_opcode_t;
		FPU_OPCODE			: in	fpu_opcode_t;
		FPU_FUNC_SEL		: in	std_logic;
		
		-- MEMORY
		MEM_RD_SEL			: in	std_logic;
		MEM_WR_SEL			: in	std_logic;
		MEM_EN				: in	std_logic;
		MEMORY_OP_SEL		: in	std_logic;
		MEM_SIGNED_EXT		: in	std_logic;
		MEM_HALFWORD		: in	std_logic;
		MEM_BYTE			: in	std_logic;
		EXT_MEM_ADDR		: out	DLX_addr_t;
		EXT_MEM_DIN			: out	DLX_oper_t;
		EXT_MEM_RD			: out	std_logic;
		EXT_MEM_WR			: out	std_logic;
		EXT_MEM_ENABLE		: out	std_logic;
		EXT_MEM_DOUT		: in	DLX_oper_t;
		
		-- WRITE BACK
		LINK_PC				: in	std_logic;
		RF_WR				: in	std_logic
	);
end entity;

architecture structural of DATAPATH is

	-- COMPONENTS
	component FETCH
		port (
			CLK				: in	std_logic;
			RST				: in	std_logic;
			ENB				: in	std_logic;
			INSTR			: in	DLX_instr_t;
			FOUT			: out	DLX_instr_t;
			PC				: out	DLX_addr_t;
			PC_INC			: out	DLX_addr_t;
			-- Datapath signals
			BRANCH_TAKEN	: in	std_logic;
			BRANCH_ADDR_SEL	: in	std_logic;
			BRANCH_ADDR		: in	DLX_addr_t
		);
	end component;
	
	component DECODE
		port (
			CLK				: in	std_logic;
			RST				: in	std_logic;
			ENB				: in	std_logic;
			REG_A			: out	DLX_oper_t;
			REG_B			: out	DLX_oper_t;
			REG_C			: out	DLX_oper_t;
			-- RF signals
			HEAP_ADDR		: in	DLX_addr_t;
			RF_SWP			: out	DLX_addr_t;
			MBUS			: inout	DLX_oper_t;
			-- CU signals
			PC_OUT_EN		: in	std_logic;
			RF_RD1_ADDR		: in	reg_addr_t;
			RF_RD2_ADDR		: in	reg_addr_t;
			RF_WR_ADDR		: in	reg_addr_t;
			RF_RD1			: in	std_logic;
			RF_RD2			: in	std_logic;
			RF_CALL			: in	std_logic;
			RF_RETN			: in	std_logic;
			IMM_ARG			: in	immediate_t;
			IMM_SEL			: in	std_logic;
			PC_OFFSET		: in	pc_offset_t;
			PC_OFFSET_SEL	: in	std_logic;
			SIGNED_EXT		: in	std_logic;
			LHI_EXT			: in	std_logic;
			OPCODE			: in	opcode_t;
			-- Datapath signals
			FORWARD_R1_EN	: in	std_logic;
			FORWARD_R2_EN	: in	std_logic;
			FORWARD_VALUE1	: in	DLX_oper_t;
			FORWARD_VALUE2	: in	DLX_oper_t;
			PC				: in	DLX_addr_t;
			RF_WR			: in	std_logic;
			RF_DIN			: in	DLX_oper_t;
			RF_SPILL		: out	std_logic;
			RF_FILL			: out	std_logic;
			RF_ACK			: in	std_logic;
			RF_OK			: out	std_logic;
			BRANCH_TAKEN	: out	std_logic
		);
	end component;
	
	component EXECUTE
		port (
			-- Control signals from CU.
			ALU_OPCODE		: in	alu_opcode_t;
			FPU_OPCODE		: in	fpu_opcode_t;
			FPU_FUNC_SEL	: in	std_logic;
			-- Signals from/to previous/successive stages.
			R1, R2			: in	DLX_oper_t;	-- Register inputs.
			EX_OUT			: out	DLX_oper_t	-- EXECUTE stage output.
		);
	end component;
	
	component MEMORY
		port (
			-- Control signals from CU.
			MEM_RD_SEL		: in	std_logic;
			MEM_WR_SEL		: in	std_logic;
			MEM_EN			: in	std_logic;
			MEMORY_OP_SEL	: in	std_logic;
			MEM_SIGNED_EXT	: in	std_logic;
			MEM_HALFWORD	: in	std_logic;
			MEM_BYTE		: in	std_logic;
			-- Signals to/from external memory.
			EXT_MEM_ADDR	: out	DLX_addr_t;
			EXT_MEM_DIN		: out	DLX_oper_t;
			EXT_MEM_RD		: out	std_logic;
			EXT_MEM_WR		: out	std_logic;
			EXT_MEM_ENABLE	: out	std_logic;
			EXT_MEM_DOUT	: in	DLX_oper_t;
			-- Signals from/to previous/next stage.
			ADDR_IN			: in	DLX_oper_t;
			DATA_IN			: in	DLX_oper_t;
			MEM_OUT			: out	DLX_oper_t
		);
	end component;
	
	component WRITE_BACK
		port (
			DIN			: in	DLX_oper_t;
			PC			: in	DLX_addr_t;
			DOUT		: out	DLX_oper_t;
			-- CU signals
			LINK_PC		: in	std_logic;
			RF_WR		: in	std_logic;
			RF_WR_OUT	: out	std_logic
		);
	end component;
	
	component FF
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic;
			DOUT	: out	std_logic
		);
	end component;
	
	component REG_N
		generic (N : natural);
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic_vector(N-1 downto 0);
			DOUT	: out	std_logic_vector(N-1 downto 0)
		);
	end component;
	
	-- SIGNALS
	signal fet_fout					: DLX_instr_t;
	signal fet_pc					: DLX_addr_t;
	signal fet_pc_inc				: DLX_addr_t;
	signal fet_branch_taken			: std_logic;
	signal fet_branch_addr			: DLX_addr_t;
	signal fet_branch_addr_sel		: std_logic;
	signal fet_fout_pipe			: DLX_instr_t;
	signal fet_pc_pipe				: DLX_addr_t;
	
	signal dec_reg_a				: DLX_oper_t;
	signal dec_reg_b				: DLX_oper_t;
	signal dec_reg_c				: DLX_oper_t;
	signal dec_forward_r1_en		: std_logic;
	signal dec_forward_r2_en		: std_logic;
	signal dec_forward_value1		: DLX_oper_t;
	signal dec_forward_value2		: DLX_oper_t;
	signal dec_pc					: DLX_addr_t;
	signal dec_rf_din				: DLX_oper_t;
	signal dec_rf_wr				: std_logic;
	signal dec_branch_taken			: std_logic;
	signal dec_branch_taken_pipe	: std_logic;
	signal dec_reg_a_pipe			: DLX_oper_t;
	signal dec_reg_b_pipe			: DLX_oper_t;
	signal dec_reg_c_pipe			: DLX_oper_t;
	
	signal exe_r1					: DLX_oper_t;
	signal exe_r2					: DLX_oper_t;
	signal exe_rc					: DLX_oper_t;
	signal exe_ex_out				: DLX_oper_t;
	signal exe_ex_out_pipe			: DLX_oper_t;
	signal exe_rc_pipe				: DLX_oper_t;
	
	signal mem_addr_in				: DLX_oper_t;
	signal mem_data_in				: DLX_oper_t;
	signal mem_mem_out				: DLX_oper_t;
	signal mem_mem_out_pipe			: DLX_oper_t;
	signal mem_pc_out_pipe			: DLX_oper_t;
	
	signal wrb_din					: DLX_oper_t;
	signal wrb_pc					: DLX_oper_t;
	signal wrb_dout					: DLX_oper_t;
	signal wrb_rf_wr_out			: std_logic;

begin

	-- FETCH
	-- Connect inputs to pipelines of other stages or other signals
	fet_branch_taken	<= dec_branch_taken or dec_branch_taken_pipe;
	fet_branch_addr_sel	<= dec_branch_taken_pipe;
	fet_branch_addr		<= exe_ex_out;
	PC					<= fet_pc;
	FETCHED_INSTR		<= fet_fout;
	
	FET_STAGE: FETCH		port map (
								CLK				=> CLK,
								RST				=> RST,
								ENB				=> FETCH_ENB,
								INSTR			=> ICACHE_INSTR,
								FOUT			=> fet_fout,
								PC				=> fet_pc,
								PC_INC			=> fet_pc_inc,
								-- Datapath signals
								BRANCH_TAKEN	=> fet_branch_taken,
								BRANCH_ADDR_SEL	=> fet_branch_addr_sel,
								BRANCH_ADDR		=> fet_branch_addr
							);
	
	-- Pipeline stage
	FET_FOUT_PIPELINE:	REG_N	generic map (DLX_INSTRUCTION_SIZE) port map (CLK, RST, FETCH_ENB, fet_fout, fet_fout_pipe);
	FET_PC_PIPELINE:	REG_N	generic map (DLX_ADDR_SIZE)        port map (CLK, RST, FETCH_ENB, fet_pc_inc, fet_pc_pipe);
		
		
	-- DECODE
	-- Connect inputs to pipelines of other stages or other signals
	dec_forward_r1_en	<= X2D_FORWARD_S1_EN or M2D_FORWARD_S1_EN or W2D_FORWARD_S1_EN;
	dec_forward_r2_en	<= X2D_FORWARD_S2_EN or M2D_FORWARD_S2_EN or W2D_FORWARD_S2_EN;
	
	dec_forward_value1	<= exe_ex_out  when (X2D_FORWARD_S1_EN = '1') else
						   mem_mem_out when (M2D_FORWARD_S1_EN = '1') else
						   wrb_dout;
	dec_forward_value2	<= exe_ex_out  when (X2D_FORWARD_S2_EN = '1') else
						   mem_mem_out when (M2D_FORWARD_S2_EN = '1') else
						   wrb_dout;
						   
	dec_pc				<= fet_pc_pipe;
	dec_rf_din			<= wrb_dout;
	dec_rf_wr			<= wrb_rf_wr_out;
	
	DEC_STAGE: DECODE		port map (
								CLK				=> CLK,
								RST				=> RST,
								ENB				=> DECODE_ENB,
								REG_A			=> dec_reg_a,
								REG_B			=> dec_reg_b,
								REG_C			=> dec_reg_c,
								-- RF signals
								HEAP_ADDR		=> HEAP_ADDR,
								RF_SWP			=> RF_SWP,
								MBUS			=> MBUS,
								-- CU signals
								PC_OUT_EN		=> PC_OUT_EN,
								RF_RD1_ADDR		=> RF_RD1_ADDR,
								RF_RD2_ADDR		=> RF_RD2_ADDR,
								RF_WR_ADDR		=> RF_WR_ADDR,
								RF_RD1			=> RF_RD1,
								RF_RD2			=> RF_RD2,
								RF_CALL			=> RF_CALL,
								RF_RETN			=> RF_RETN,
								IMM_ARG			=> IMM_ARG,
								IMM_SEL			=> IMM_SEL,
								PC_OFFSET		=> PC_OFFSET,
								PC_OFFSET_SEL	=> PC_OFFSET_SEL,
								SIGNED_EXT		=> SIGNED_EXT,
								LHI_EXT			=> LHI_EXT,
								OPCODE			=> OPCODE,
								-- Datapath signals
								FORWARD_R1_EN	=> dec_forward_r1_en,
								FORWARD_R2_EN	=> dec_forward_r2_en,
								FORWARD_VALUE1	=> dec_forward_value1,
								FORWARD_VALUE2	=> dec_forward_value2,
								PC				=> dec_pc,
								RF_WR			=> dec_rf_wr,
								RF_DIN			=> dec_rf_din,
								RF_SPILL		=> RF_SPILL,
								RF_FILL			=> RF_FILL,
								RF_ACK			=> RF_ACK,
								RF_OK			=> RF_OK,
								BRANCH_TAKEN	=> dec_branch_taken
							);
	
	-- Pipeline stage
	DEC_REG_A_PIPELINE: REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, DECODE_ENB, dec_reg_a, dec_reg_a_pipe);
	DEC_REG_B_PIPELINE: REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, DECODE_ENB, dec_reg_b, dec_reg_b_pipe);
	DEC_REG_C_PIPELINE: REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, DECODE_ENB, dec_reg_c, dec_reg_c_pipe);
	
	DEC_BRANCH_TAKEN_PIPELINE: FF port map (CLK, RST, DECODE_ENB, dec_branch_taken, dec_branch_taken_pipe);
	
		
	-- EXECUTE
	-- Connect inputs to pipelines of other stages or other signals
	exe_r1	<= dec_reg_a_pipe;
	exe_r2	<= dec_reg_b_pipe;
	exe_rc	<= dec_reg_c_pipe;
	
	EXE_STAGE: EXECUTE		port map (
								-- Control signals from CU.
								ALU_OPCODE		=> ALU_OPCODE,
								FPU_OPCODE		=> FPU_OPCODE,
								FPU_FUNC_SEL	=> FPU_FUNC_SEL,
								-- Signals from/to previous/successive stages.
								R1				=> exe_r1,
								R2				=> exe_r2,
								EX_OUT			=> exe_ex_out
							);
							
	-- Pipeline stage
	EXE_EX_OUT_PIPELINE: REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, EXECUTE_ENB, exe_ex_out, exe_ex_out_pipe);
	EXE_RC_PIPELINE:     REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, EXECUTE_ENB, exe_rc, exe_rc_pipe);
	

	-- MEMORY
	-- Connect inputs to pipelines of other stages or other signals
	mem_addr_in	<= exe_ex_out_pipe;
	mem_data_in <= exe_rc_pipe;
	
	MEM_STAGE: MEMORY		port map (
								-- Control signals from CU.
								MEM_RD_SEL		=> MEM_RD_SEL,
								MEM_WR_SEL		=> MEM_WR_SEL,
								MEM_EN			=> MEM_EN,
								MEMORY_OP_SEL	=> MEMORY_OP_SEL,
								MEM_SIGNED_EXT	=> MEM_SIGNED_EXT,
								MEM_HALFWORD	=> MEM_HALFWORD,
								MEM_BYTE		=> MEM_BYTE,
								-- Signals to/from external memory.
								EXT_MEM_ADDR	=> EXT_MEM_ADDR,
								EXT_MEM_DIN		=> EXT_MEM_DIN,
								EXT_MEM_RD		=> EXT_MEM_RD,
								EXT_MEM_WR		=> EXT_MEM_WR,
								EXT_MEM_ENABLE	=> EXT_MEM_ENABLE,
								EXT_MEM_DOUT	=> EXT_MEM_DOUT,
								-- Signals from/to previous/next stage.
								ADDR_IN			=> mem_addr_in,
								DATA_IN			=> mem_data_in,
								MEM_OUT			=> mem_mem_out
							);
							
	-- Pipeline stage
	MEM_MEM_OUT_PIPELINE: REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, MEMORY_ENB, mem_mem_out, mem_mem_out_pipe);
	-- Propagate PC in case of jump-and-link
	MEM_PC_OUT_PIPELINE: REG_N	generic map (DLX_OPERAND_SIZE) port map (CLK, RST, MEMORY_ENB, mem_data_in, mem_pc_out_pipe);
	
	
	-- WRITE BACK
	-- Connect inputs to pipelines of other stages or other signals
	wrb_din	<= mem_mem_out_pipe;
	wrb_pc	<= mem_pc_out_pipe;
	
	WRB_STAGE: WRITE_BACK	port map (
								DIN			=> wrb_din,
								PC			=> wrb_pc,
								DOUT		=> wrb_dout,
								-- CU signals
								LINK_PC		=> LINK_PC,
								RF_WR		=> RF_WR,
								RF_WR_OUT	=> wrb_rf_wr_out
							);

end architecture;