library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;
use work.utils.log2;
use work.utils.max;

entity DECODE is
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
end entity;

architecture behavioral of DECODE is

	component REGISTER_FILE
		generic (
			WORD_SIZE			: natural;
			REGISTER_NUM		: natural;
			WINDOWS_NUM			: natural;
			SYSTEM_ADDR_SIZE	: natural
		);
		port (
			CLK			: in	std_logic;
			RST			: in	std_logic;
			ENB			: in	std_logic;
			HEAP_ADDR	: in	std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
			RD1			: in	std_logic;
			RD2			: in	std_logic;
			WR			: in	std_logic;
			DIN			: in	std_logic_vector(WORD_SIZE-1 downto 0);
			DOUT1		: out	std_logic_vector(WORD_SIZE-1 downto 0);
			DOUT2		: out	std_logic_vector(WORD_SIZE-1 downto 0);
			ADDR_IN		: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
			ADDR_OUT1	: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
			ADDR_OUT2	: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
			CALL		: in 	std_logic;
			RETN		: in 	std_logic;
			SPILL		: out 	std_logic;
			FILL		: out	std_logic;
			SWP			: out	std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
			MBUS		: inout	std_logic_vector(max(log2(SYSTEM_ADDR_SIZE), WORD_SIZE)-1 downto 0);
			ACK			: in	std_logic;
			RF_OK		: out	std_logic
		);
	end component;

	signal RF_dout1_s		: DLX_oper_t;
	signal RF_dout2_s		: DLX_oper_t;
	signal is_zero_s		: std_logic;
	signal ext_imm_s		: DLX_oper_t;
	signal branch_taken_s	: std_logic;
	signal pc_offset_s		: pc_offset_t;
	
begin

	-- Instantiate RF
	RF: REGISTER_FILE	generic map (
							WORD_SIZE			=> DLX_OPERAND_SIZE,
							REGISTER_NUM		=> 2**REGISTER_ADDR_SIZE,
							WINDOWS_NUM			=> DLX_RF_WINDOWS_NUM,
							SYSTEM_ADDR_SIZE	=> DLX_ADDR_SIZE
						)
						port map (
							CLK			=> CLK,
							RST			=> RST,
							ENB			=> ENB,
							HEAP_ADDR	=> HEAP_ADDR,
							RD1			=> RF_RD1,
							RD2			=> RF_RD2,
							WR			=> RF_WR,
							DIN			=> RF_DIN,
							DOUT1		=> RF_dout1_s,
							DOUT2		=> RF_dout2_s,
							ADDR_IN		=> RF_WR_ADDR,
							ADDR_OUT1	=> RF_RD1_ADDR,
							ADDR_OUT2	=> RF_RD2_ADDR,
							CALL		=> RF_CALL,
							RETN		=> RF_RETN,
							SPILL		=> RF_SPILL,
							FILL		=> RF_FILL,
							SWP			=> RF_SWP,
							MBUS		=> MBUS,
							ACK			=> RF_ACK,
							RF_OK		=> RF_OK
						);
						
	-- Instantiate zero detector to check if branch taken
	ZD: ZERO_DETECTOR generic map (DLX_OPERAND_SIZE) port map (RF_dout1_s, is_zero_s);
	
	-- Check branch taken
	BRANCH_TAKEN	<= branch_taken_s;
	branch_taken_s	<= '1' when (iz_zero_s = '1' and OPCODE = BEQZ) or (is_zero_s = '0' and OPCODE = BNEZ) else -- when conditional branch matches
					   '1' when (OPCODE = J or OPCODE = JAL or OPCODE = JR or OPCODE = JALR) else               -- when operation is unconditional branch
					   '0';
						
	-- Extend immediate arg
	ext_imm_s(DLX_OPERAND_SIZE-1   downto IMMEDIATE_ARG_SIZE)	<= (others => IMM_ARG(IMMEDIATE_ARG_SIZE-1)) when (SIGNED_EXT = '1') else (others => '0');
	ext_imm_s(IMMEDIATE_ARG_SIZE-1 downto                  0)	<= IMM_ARG;
	
	-- Extend pc offset
	pc_offset_s(DLX_OPERAND_SIZE-1    downto JUMP_PC_OFFSET_SIZE)	<= (others => PC_OFFSET(IMMEDIATE_ARG_SIZE-1));
	pc_offset_s(JUMP_PC_OFFSET_SIZE-1 downto                   0)	<= IMM_ARG;
	
	-- Assign immediates
	REG_A	<= PC             when (branch_taken_s = '1') else -- Propagate pc in case of branch address calculation
			   IRS_TABLE_ADDR when (ISR_EN = '1')         else -- Load ISR table pointer if TRAP instruction called
			   RF_dout2_s;
	REG_B	<= ext_imm_s      when (IMM_SEL = '1')        else -- Select immediate value if I-type
			   pc_offset_s    when (PC_OFFSET_SET = '1')  else -- Select PC offset if J-type
			   RF_dout2_s;

end architecture;