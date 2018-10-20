library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.DLX_globals.all;
use work.instr_gen.all;

entity TB_CU is
end entity;

architecture test of TB_CU is

	component CU
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
			
			-- MEMORY
			MEM_RD_SEL			: out	std_logic;
			MEM_WR_SEL			: out	std_logic;
			MEM_EN				: out	std_logic;
			MEMORY_OP_SEL		: out	std_logic;
			MEM_SIGNED_EXT		: out	std_logic;
			MEM_HALFWORD		: out	std_logic;
			MEM_BYTE			: out	std_logic;
			MEM_LOAD_HI			: out	std_logic;
			
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
	end component;
	
	signal CLK_s				: std_logic;
	signal RST_s				: std_logic;
	signal ENB_s				: std_logic;
	signal INSTR_s				: DLX_instr_t;
	
	-- Special signals for TRAP instruction
	signal ISR_EN_s				: std_logic;
	
	-- DECODE
	signal RF_RD1_ADDR_s		: reg_addr_t;
	signal RF_RD2_ADDR_s		: reg_addr_t;
	signal RF_WR_ADDR_s			: reg_addr_t;
	signal RF_RD1_s				: std_logic;
	signal RF_RD2_s				: std_logic;
	signal RF_CALL_s			: std_logic;
	signal RF_RETN_s			: std_logic;
	signal IMM_ARG_s			: immediate_t;
	signal IMM_SEL_s			: std_logic;
	signal PC_OFFSET_s			: pc_offset_t;
	signal PC_OFFSET_SEL_s		: std_logic;
	signal OPCODE_s				: opcode_t;
	signal SIGNED_EXT_s			: std_logic;
	
	-- EXECUTE
	signal ALU_OPCODE_s			: ALU_opcode_t;
	signal FPU_OPCODE_s			: FPU_opcode_t;
	
	-- MEMORY
	signal MEM_RD_SEL_s			: std_logic;
	signal MEM_WR_SEL_s			: std_logic;
	signal MEM_EN_s				: std_logic;
	signal MEMORY_OP_SEL_s		: std_logic;
	signal MEM_SIGNED_EXT_s		: std_logic;
	signal MEM_HALFWORD_s		: std_logic;
	signal MEM_BYTE_s			: std_logic;
	signal MEM_LOAD_HI_s		: std_logic;
	
	-- WRITE BACK
	signal LINK_PC_s			: std_logic;
	signal RF_WR_s				: std_logic;
	
	-- OTHER
	signal X2D_FORWARD_S1_EN_s	: std_logic;
	signal M2D_FORWARD_S1_EN_s	: std_logic;
	signal W2D_FORWARD_S1_EN_s	: std_logic;
	signal X2D_FORWARD_S2_EN_s	: std_logic;
	signal M2D_FORWARD_S2_EN_s	: std_logic;
	signal W2D_FORWARD_S2_EN_s	: std_logic;
	signal STALL_s				: std_logic;
	
	signal opcodes_s			: opcodes;
	signal alu_codes_s			: alu_codes;
	signal fpu_codes_s			: fpu_codes;
	signal opc					: opcode_t;
	signal alu					: func_t;
	signal fpu					: fp_func_t;
	signal reg1, reg2, dest		: reg_addr_t;
	signal imm					: immediate_t;
	signal pcoff				: pc_offset_t;
	
begin

	UUT: CU	port map(
					CLK_s,
					RST_s,
					ENB_s,
					INSTR_s,
					
					-- Special signals for TRAP instruction
					ISR_EN_s,
					
					-- DECODE
					RF_RD1_ADDR_s,
					RF_RD2_ADDR_s,
					RF_WR_ADDR_s,
					RF_RD1_s,
					RF_RD2_s,
					RF_CALL_s,
					RF_RETN_s,
					IMM_ARG_s,
					IMM_SEL_s,
					PC_OFFSET_s,
					PC_OFFSET_SEL_s,
					OPCODE_s,
					SIGNED_EXT_s,
					
					-- EXECUTE
					ALU_OPCODE_s,
					FPU_OPCODE_s,
					
					-- MEMORY
					MEM_RD_SEL_s,
					MEM_WR_SEL_s,
					MEM_EN_s,
					MEMORY_OP_SEL_s,
					MEM_SIGNED_EXT_s,
					MEM_HALFWORD_s,
					MEM_BYTE_s,
					MEM_LOAD_HI_s,
					
					-- WRITE BACK
					LINK_PC_s,
					RF_WR_s,
					
					-- OTHER
					X2D_FORWARD_S1_EN_s,
					M2D_FORWARD_S1_EN_s,
					W2D_FORWARD_S1_EN_s,
					X2D_FORWARD_S2_EN_s,
					M2D_FORWARD_S2_EN_s,
					W2D_FORWARD_S2_EN_s,
					STALL_s
			);

	clk_gen: process is
	begin
		if (CLK_s /= '0' and CLK_s /= '1') then
			CLK_s <= '0';
		else
			CLK_s <= not CLK_s;
		end if;
		wait for 1 ns;
	end process;
	
	stimulus: process is
	begin
		RST_s	<= '0';
		ENB_s	<= '0';
		INSTR_s	<= (others => '0');
		opc		<= (others => '0');
		alu		<= (others => '0');
		fpu		<= (others => '0');
		reg1	<= "00010";
		reg2	<= "01101";
		dest	<= "00100";
		imm		<= "0000000000000010";
		pcoff	<= "10001001001011101010111111";
		wait for 1.5 ns;
	
		RST_s	<= '1';
		ENB_s	<= '1';
		for op in opcodes loop
			opcodes_s <= op;
			opc <= opcode_to_std_logic_v(op);
			if (opc = ALU_I) then
				for a in alu_codes loop
					alu_codes_s	<= a;
					alu		<= alu_to_std_logic_v(a);
					INSTR_s	<= opc & reg1 & reg2 & dest & alu;
					wait for 2 ns;
				end loop;
			elsif (opc = FPU_I) then
				for f in fpu_codes loop
					fpu_codes_s <= f;
					fpu		<= fpu_to_std_logic_v(f);
					INSTR_s	<= opc & reg1 & reg2 & dest & fpu;
					wait for 2 ns;
				end loop;
			else
				INSTR_s	<= opc & reg1 & dest & imm;
				wait for 2 ns;
			end if;
		end loop;
		
		wait;
	end process;

end architecture;
