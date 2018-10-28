library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;
use work.utils.max;

entity DLX is
	port (
		CLK					: in	std_logic;
		RST					: in	std_logic;
		ENB					: in	std_logic;
		-- ICACHE interface
		PC					: out	DLX_addr_t;
		ICACHE_INSTR		: in	DLX_instr_t;
		ICACHE_HIT			: in	std_logic;
		-- External memory interface
		HEAP_ADDR			: in	DLX_addr_t;
		RF_SWP				: out	DLX_addr_t;
		MBUS				: inout	DLX_oper_t;
		RF_ACK				: in	std_logic;
		EXT_MEM_ADDR		: out	DLX_addr_t;
		EXT_MEM_DIN			: out	DLX_oper_t;
		EXT_MEM_RD			: out	std_logic;
		EXT_MEM_WR			: out	std_logic;
		EXT_MEM_ENABLE		: out	std_logic;
		EXT_MEM_DOUT		: in	DLX_oper_t;
		EXT_MEM_BUSY		: in	std_logic
	);
end entity;

architecture structural of DLX is

	-- COMPONENTS
	component CU
		port (
			CLK					: in	std_logic;
			RST					: in	std_logic;
			ENB					: in	std_logic;
			INSTR				: in	DLX_instr_t;
			
			-- DECODE
			PC_OUT_EN			: out	std_logic;
			RF_RD1_ADDR			: out	reg_addr_t;
			RF_RD2_ADDR			: out	reg_addr_t;
			RF_WR_ADDR			: out	reg_addr_t;
			RF_RD1				: out	std_logic;
			RF_RD2				: out	std_logic;
			IMM_ARG				: out	immediate_t;
			IMM_SEL				: out	std_logic;
			PC_OFFSET			: out	pc_offset_t;
			PC_OFFSET_SEL		: out	std_logic;
			OPCODE				: out	opcode_t;
			SIGNED_EXT			: out	std_logic;
			LHI_EXT				: out	std_logic;
			
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
			RF_CALL				: out	std_logic;
			RF_RETN				: out	std_logic;
			
			-- OTHER
			X2D_FORWARD_S1_EN	: out	std_logic;
			M2D_FORWARD_S1_EN	: out	std_logic;
			W2D_FORWARD_S1_EN	: out	std_logic;
			X2D_FORWARD_S2_EN	: out	std_logic;
			M2D_FORWARD_S2_EN	: out	std_logic;
			W2D_FORWARD_S2_EN	: out	std_logic;
			STALL				: out	std_logic
		);
	end component;
	
	component DATAPATH
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
			PC_OUT_EN			: in	std_logic;
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
	
	component ALU_OPCODE_REG
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	ALU_opcode_t;
			DOUT	: out	ALU_opcode_t
		);
	end component;
	
	component FPU_OPCODE_REG
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	FPU_opcode_t;
			DOUT	: out	FPU_opcode_t
		);
	end component;

	-- SIGNALS
	-- FETCH
	signal fetched_instr_s		: DLX_instr_t;
	signal fetched_instr_s_pipe	: DLX_instr_t;
	
	-- DECODE
	signal pc_out_en_s			: std_logic;
	signal rf_rd1_addr_s		: reg_addr_t;
	signal rf_rd2_addr_s		: reg_addr_t;
	signal rf_rd1_s				: std_logic;
	signal rf_rd2_s				: std_logic;
	signal rf_spill_s			: std_logic;
	signal rf_fill_s			: std_logic;
	signal rf_ok_s				: std_logic;
	signal imm_arg_s			: immediate_t;
	signal imm_sel_s			: std_logic;
	signal pc_offset_s			: pc_offset_t;
	signal pc_offset_sel_s		: std_logic;
	signal opcode_s				: opcode_t;
	signal signed_ext_s			: std_logic;
	signal lhi_ext_s			: std_logic;
	
	-- EXECUTE
	signal alu_opcode_s			: ALU_opcode_t;
	signal fpu_opcode_s			: FPU_opcode_t;
	signal fpu_func_sel_s		: std_logic;
	-- Pipeline 1
	signal alu_opcode_s_exe		: ALU_opcode_t;
	signal fpu_opcode_s_exe		: FPU_opcode_t;
	signal fpu_func_sel_s_exe	: std_logic;
	
	-- MEMORY
	signal mem_rd_sel_s			: std_logic;
	signal mem_wr_sel_s			: std_logic;
	signal mem_en_s				: std_logic;
	signal memory_op_sel_s		: std_logic;
	signal mem_signed_ext_s		: std_logic;
	signal mem_halfword_s		: std_logic;
	signal mem_byte_s			: std_logic;
	signal rf_call_s			: std_logic;
	signal rf_retn_s			: std_logic;
	-- Pipeline 1
	signal mem_rd_sel_s_exe		: std_logic;
	signal mem_wr_sel_s_exe		: std_logic;
	signal mem_en_s_exe			: std_logic;
	signal memory_op_sel_s_exe	: std_logic;
	signal mem_signed_ext_s_exe	: std_logic;
	signal mem_halfword_s_exe	: std_logic;
	signal mem_byte_s_exe		: std_logic;
	signal rf_call_s_exe		: std_logic;
	signal rf_retn_s_exe		: std_logic;
	-- Pipeline 2
	signal mem_rd_sel_s_mem		: std_logic;
	signal mem_wr_sel_s_mem		: std_logic;
	signal mem_en_s_mem			: std_logic;
	signal memory_op_sel_s_mem	: std_logic;
	signal mem_signed_ext_s_mem	: std_logic;
	signal mem_halfword_s_mem	: std_logic;
	signal mem_byte_s_mem		: std_logic;
	signal rf_call_s_mem		: std_logic;
	signal rf_retn_s_mem		: std_logic;
	
	-- WRITE BACK
	signal link_pc_s			: std_logic;
	signal rf_wr_s				: std_logic;
	signal rf_wr_addr_s			: reg_addr_t;
	-- Pipeline 1
	signal link_pc_s_exe		: std_logic;
	signal rf_wr_s_exe			: std_logic;
	signal rf_wr_addr_s_exe		: reg_addr_t;
	-- Pipeline 2
	signal link_pc_s_mem		: std_logic;
	signal rf_wr_s_mem			: std_logic;
	signal rf_wr_addr_s_mem		: reg_addr_t;
	-- Pipeline 3
	signal link_pc_s_wrb		: std_logic;
	signal rf_wr_s_wrb			: std_logic;
	signal rf_wr_addr_s_wrb		: reg_addr_t;
	
	signal x2d_forward_s1_en_s	: std_logic;
	signal m2d_forward_s1_en_s	: std_logic;
	signal w2d_forward_s1_en_s	: std_logic;
	signal x2d_forward_s2_en_s	: std_logic;
	signal m2d_forward_s2_en_s	: std_logic;
	signal w2d_forward_s2_en_s	: std_logic;
	signal stall_s				: std_logic;
	
	signal global_enable		: std_logic;
	signal fetch_enable			: std_logic;
	signal decode_enable		: std_logic;
	
begin

	-- Global enable is active iff no stall and no RF spill/fill
	global_enable	<= ENB and not EXT_MEM_BUSY and rf_ok_s and ICACHE_HIT;
	fetch_enable	<= global_enable and not stall_s;
	decode_enable	<= global_enable and not stall_s;

	CU0: CU	port map (
				CLK					=> CLK,
				RST					=> RST,
				ENB					=> global_enable,
				INSTR				=> fetched_instr_s_pipe,
				
				-- DECODE
				PC_OUT_EN			=> pc_out_en_s,
				RF_RD1_ADDR			=> rf_rd1_addr_s,
				RF_RD2_ADDR			=> rf_rd2_addr_s,
				RF_WR_ADDR			=> rf_wr_addr_s,
				RF_RD1				=> rf_rd1_s,
				RF_RD2				=> rf_rd2_s,
				IMM_ARG				=> imm_arg_s,
				IMM_SEL				=> imm_sel_s,
				PC_OFFSET			=> pc_offset_s,
				PC_OFFSET_SEL		=> pc_offset_sel_s,
				OPCODE				=> opcode_s,
				SIGNED_EXT			=> signed_ext_s,
				LHI_EXT				=> lhi_ext_s,
				
				-- EXECUTE
				ALU_OPCODE			=> alu_opcode_s,
				FPU_OPCODE			=> fpu_opcode_s,
				FPU_FUNC_SEL		=> fpu_func_sel_s,
				
				-- MEMORY
				MEM_RD_SEL			=> mem_rd_sel_s,
				MEM_WR_SEL			=> mem_wr_sel_s,
				MEM_EN				=> mem_en_s,
				MEMORY_OP_SEL		=> memory_op_sel_s,
				MEM_SIGNED_EXT		=> mem_signed_ext_s,
				MEM_HALFWORD		=> mem_halfword_s,
				MEM_BYTE			=> mem_byte_s,
				
				-- WRITE BACK
				LINK_PC				=> link_pc_s,
				RF_WR				=> rf_wr_s,
				RF_CALL				=> rf_call_s,
				RF_RETN				=> rf_retn_s,
				
				-- OTHER
				X2D_FORWARD_S1_EN	=> x2d_forward_s1_en_s,
				M2D_FORWARD_S1_EN	=> m2d_forward_s1_en_s,
				W2D_FORWARD_S1_EN	=> w2d_forward_s1_en_s,
				X2D_FORWARD_S2_EN	=> x2d_forward_s2_en_s,
				M2D_FORWARD_S2_EN	=> m2d_forward_s2_en_s,
				W2D_FORWARD_S2_EN	=> w2d_forward_s2_en_s,
				STALL				=> stall_s
			);
	
	-- Pipeline for CU signals
	-- To CU/DECODE stage
	INSTR_PIPE:	REG_N	generic map (DLX_INSTRUCTION_SIZE)	port map (CLK, RST, fetch_enable, fetched_instr_s, fetched_instr_s_pipe);
	
	-- To EXECUTE stage
	ALU_OPCODE_PIPE1: 	ALU_OPCODE_REG	port map (CLK, RST, decode_enable, alu_opcode_s, alu_opcode_s_exe);
	FPU_OPCODE_PIPE1: 	FPU_OPCODE_REG	port map (CLK, RST, decode_enable, fpu_opcode_s, fpu_opcode_s_exe);
	FPU_FUNC_SEL_PIPE1:	FF				port map (CLK, RST, decode_enable, fpu_func_sel_s, fpu_func_sel_s_exe);
	
	-- To MEMORY stage
	RD_SEL_PIPE1:			FF	port map (CLK, RST, decode_enable, mem_rd_sel_s, mem_rd_sel_s_exe);
	RD_SEL_PIPE2:			FF	port map (CLK, RST, global_enable, mem_rd_sel_s_exe, mem_rd_sel_s_mem);
	WR_SEL_PIPE1:			FF	port map (CLK, RST, decode_enable, mem_wr_sel_s, mem_wr_sel_s_exe);
	WR_SEL_PIPE2:			FF	port map (CLK, RST, global_enable, mem_wr_sel_s_exe, mem_wr_sel_s_mem);
	MEM_EN_PIPE1:			FF	port map (CLK, RST, decode_enable, mem_en_s, mem_en_s_exe);
	MEM_EN_PIPE2:			FF	port map (CLK, RST, global_enable, mem_en_s_exe, mem_en_s_mem);
	MEMORY_OP_SEL_PIPE1:	FF	port map (CLK, RST, decode_enable, memory_op_sel_s, memory_op_sel_s_exe);
	MEMORY_OP_SEL_PIPE2:	FF	port map (CLK, RST, global_enable, memory_op_sel_s_exe, memory_op_sel_s_mem);
	SIGNED_EXT_PIPE1:		FF	port map (CLK, RST, decode_enable, mem_signed_ext_s, mem_signed_ext_s_exe);
	SIGNED_EXT_PIPE2:		FF	port map (CLK, RST, global_enable, mem_signed_ext_s_exe, mem_signed_ext_s_mem);
	HALFWORD_PIPE1:			FF	port map (CLK, RST, decode_enable, mem_halfword_s, mem_halfword_s_exe);
	HALFWORD_PIPE2:			FF	port map (CLK, RST, global_enable, mem_halfword_s_exe, mem_halfword_s_mem);
	BYTE_PIPE1:				FF	port map (CLK, RST, decode_enable, mem_byte_s, mem_byte_s_exe);
	BYTE_PIPE2:				FF	port map (CLK, RST, global_enable, mem_byte_s_exe, mem_byte_s_mem);
	RF_CALL_PIPE1:			FF	port map (CLK, RST, decode_enable, rf_call_s, rf_call_s_exe);
	RF_CALL_PIPE2:			FF	port map (CLK, RST, global_enable, rf_call_s_exe, rf_call_s_mem);
	RF_RETN_PIPE1:			FF	port map (CLK, RST, decode_enable, rf_retn_s, rf_retn_s_exe);
	RF_RETN_PIPE2:			FF	port map (CLK, RST, global_enable, rf_retn_s_exe, rf_retn_s_mem);
	
	-- To WRITE BACK stage
	LINK_PC_PIPE1:		FF		port map (CLK, RST, decode_enable, link_pc_s, link_pc_s_exe);
	LINK_PC_PIPE2:		FF		port map (CLK, RST, global_enable, link_pc_s_exe, link_pc_s_mem);
	LINK_PC_PIPE3:		FF		port map (CLK, RST, global_enable, link_pc_s_mem, link_pc_s_wrb);
	RF_WR_PIPE1:		FF		port map (CLK, RST, decode_enable, rf_wr_s, rf_wr_s_exe);
	RF_WR_PIPE2:		FF		port map (CLK, RST, global_enable, rf_wr_s_exe, rf_wr_s_mem);
	RF_WR_PIPE3:		FF		port map (CLK, RST, global_enable, rf_wr_s_mem, rf_wr_s_wrb);
	RF_WR_ADDR_PIPE1:	REG_N	generic map (REGISTER_ADDR_SIZE) port map (CLK, RST, decode_enable, rf_wr_addr_s, rf_wr_addr_s_exe);
	RF_WR_ADDR_PIPE2:	REG_N	generic map (REGISTER_ADDR_SIZE) port map (CLK, RST, global_enable, rf_wr_addr_s_exe, rf_wr_addr_s_mem);
	RF_WR_ADDR_PIPE3:	REG_N	generic map (REGISTER_ADDR_SIZE) port map (CLK, RST, global_enable, rf_wr_addr_s_mem, rf_wr_addr_s_wrb);
	
	
	DP0: DATAPATH	port map (
						CLK					=> CLK,
						RST					=> RST,
						FETCH_ENB			=> fetch_enable,
						DECODE_ENB			=> decode_enable,
						EXECUTE_ENB			=> global_enable,
						MEMORY_ENB			=> global_enable,
						
						-- FETCH
						PC					=> PC,
						ICACHE_INSTR		=> ICACHE_INSTR,
						FETCHED_INSTR		=> fetched_instr_s,
						
						-- DECODE
						PC_OUT_EN			=> pc_out_en_s,
						HEAP_ADDR			=> HEAP_ADDR,
						RF_SWP				=> RF_SWP,
						MBUS				=> MBUS,
						RF_RD1_ADDR			=> rf_rd1_addr_s,
						RF_RD2_ADDR			=> rf_rd2_addr_s,
						RF_RD1				=> rf_rd1_s,
						RF_RD2				=> rf_rd2_s,
						IMM_ARG				=> imm_arg_s,
						IMM_SEL				=> imm_sel_s,
						PC_OFFSET			=> pc_offset_s,
						PC_OFFSET_SEL		=> pc_offset_sel_s,
						SIGNED_EXT			=> signed_ext_s,
						LHI_EXT				=> lhi_ext_s,
						OPCODE				=> opcode_s,
						X2D_FORWARD_S1_EN	=> x2d_forward_s1_en_s,
						M2D_FORWARD_S1_EN	=> m2d_forward_s1_en_s,
						W2D_FORWARD_S1_EN	=> w2d_forward_s1_en_s,
						X2D_FORWARD_S2_EN	=> x2d_forward_s2_en_s,
						M2D_FORWARD_S2_EN	=> m2d_forward_s2_en_s,
						W2D_FORWARD_S2_EN	=> w2d_forward_s2_en_s,
						RF_SPILL			=> rf_spill_s,
						RF_FILL				=> rf_fill_s,
						RF_ACK				=> RF_ACK,
						RF_OK				=> rf_ok_s,
						
						-- EXECUTE
						ALU_OPCODE			=> alu_opcode_s_exe,
						FPU_OPCODE			=> fpu_opcode_s_exe,
						FPU_FUNC_SEL		=> fpu_func_sel_s_exe,
						
						-- MEMORY
						MEM_RD_SEL			=> mem_rd_sel_s_mem,
						MEM_WR_SEL			=> mem_wr_sel_s_mem,
						MEM_EN				=> mem_en_s_mem,
						MEMORY_OP_SEL		=> memory_op_sel_s_mem,
						MEM_SIGNED_EXT		=> mem_signed_ext_s_mem,
						MEM_HALFWORD		=> mem_halfword_s_mem,
						MEM_BYTE			=> mem_byte_s_mem,
						EXT_MEM_ADDR		=> EXT_MEM_ADDR,
						EXT_MEM_DIN			=> EXT_MEM_DIN,
						EXT_MEM_RD			=> EXT_MEM_RD,
						EXT_MEM_WR			=> EXT_MEM_WR,
						EXT_MEM_ENABLE		=> EXT_MEM_ENABLE,
						EXT_MEM_DOUT		=> EXT_MEM_DOUT,
						RF_CALL				=> rf_call_s_mem,
						RF_RETN				=> rf_retn_s_mem,
						
						-- WRITE BACK
						LINK_PC				=> link_pc_s_wrb,
						RF_WR				=> rf_wr_s_wrb,
						RF_WR_ADDR			=> rf_wr_addr_s_wrb
					);

end architecture;