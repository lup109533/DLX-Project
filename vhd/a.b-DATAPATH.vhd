library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity DATAPATH is
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		INSTR	: in	DLX_instr_t;
		-- Signals from/to CU here
	);
end entity;

architecture structural of DATAPATH is

	-- COMPONENTS
	component FETCH
		port (
			CLK				: in	std_logic;
			RST				: in	std_logic;
			INSTR			: in	DLX_instr_t;
			FOUT			: out	DLX_instr_t;
			PC				: out	DLX_addr_t;
			-- Datapath signals
			BRANCH_TAKEN	: in	std_logic;
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
			IMM_ARG			: out	DLX_oper_t;
			-- Special signals for TRAP instruction
			ISR_TABLE_ADDR	: in	DLX_addr_t;
			ISR_EN			: in	std_logic;
			-- RF signals
			HEAP_ADDR		: in	DLX_addr_t;
			RF_SWP			: out	DLX_addr_t;
			MBUS			: inout	DLX_oper_t;
			-- CU signals
			RF_RD1_ADDR		: in	reg_addr_t;
			RF_RD2_ADDR		: in	reg_addr_t;
			RF_WR_ADDR		: in	reg_addr_t;
			RF_RD1			: in	std_logic;
			RF_RD2			: in	std_logic;
			RF_WR			: in	std_logic;
			RF_CALL			: in	std_logic;
			RF_RETN			: in	std_logic;
			IMM_ARG			: in	immediate_t;
			IMM_SEL			: in	std_logic;
			PC_OFFSET		: out	pc_offset_t;
			PC_OFFSET_SEL	: out	std_logic;
			SIGNED_EXT		: in	std_logic;
			OPCODE			: in	opcode_t;
			-- Datapath signals
			PC				: in	DLX_addr_t;
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
			EX_OUT			: out	DLX_oper_t;	-- EXECUTE stage output.
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
			EX_IN			: in	DLX_oper_t;
			MEM_OUT			: out	DLX_oper_t
		);
	end component;
	
	component WRITE_BACK
		port map (
			DIN		: in	DLX_oper_t;
			DOUT	: out	DLX_oper_t;
			WR		: in	std_logic;
			WR_OUT	: out	std_logic
		);
	end component;
	
	-- SIGNALS

begin

	FET_STAGE: FETCH	

end architecture;