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
		STORE_R2_EN		: in	std_logic;
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
end entity;

architecture behavioral of DECODE is

	-- COMPONENTS
	component REGISTER_FILE
		generic (
			FIXED_R0			: boolean := false;
			WORD_SIZE			: natural;
			REGISTER_NUM		: natural;
			WINDOWS_NUM			: natural;
			SYSTEM_ADDR_SIZE	: natural
		);
		port (
			CLK			: in	std_logic;
			RST			: in	std_logic;
			ENB			: in	std_logic;
			HEAP_ADDR	: in	std_logic_vector(SYSTEM_ADDR_SIZE-1 downto 0);
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
			SWP			: out	std_logic_vector(SYSTEM_ADDR_SIZE-1 downto 0);
			MBUS		: inout	std_logic_vector(max(SYSTEM_ADDR_SIZE, WORD_SIZE)-1 downto 0);
			ACK			: in	std_logic;
			RF_OK		: out	std_logic
		);
	end component;
	
	component ZERO_DETECTOR
		generic (NBIT: integer);
		port (
			A: in std_logic_vector(NBIT-1 downto 0);
			Z : out std_logic
		);
	end component;

	-- SIGNALS
	signal reg_a_s			: DLX_oper_t;
	signal reg_b_s			: DLX_oper_t;
	signal RF_dout1_s		: DLX_oper_t;
	signal RF_dout2_s		: DLX_oper_t;
	signal is_zero_s		: std_logic;
	signal ext_imm_s		: DLX_oper_t;
	signal branch_taken_s	: std_logic;
	signal pc_offset_s		: DLX_oper_t;
	
begin

	-- Instantiate RF
	RF: REGISTER_FILE	generic map (
							FIXED_R0			=> true,
							WORD_SIZE			=> DLX_OPERAND_SIZE,
							REGISTER_NUM		=> 2**REGISTER_ADDR_SIZE,
							WINDOWS_NUM			=> DLX_RF_WINDOWS_NUM,
							SYSTEM_ADDR_SIZE	=> DLX_ADDR_SIZE
						)
						port map (
							CLK			=> CLK,
							RST			=> RST,
							ENB			=> '1',
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
	ZD: ZERO_DETECTOR generic map (DLX_OPERAND_SIZE) port map (reg_a_s, is_zero_s);
	
	-- Check branch taken
	BRANCH_TAKEN	<= branch_taken_s;
	branch_taken_s	<= '1' when (is_zero_s = '1' and (OPCODE = BEQZ or OPCODE = BFPF))       else -- when conditional branch matches
					   '1' when (is_zero_s = '0' and (OPCODE = BNEZ or OPCODE = BFPT))       else -- **
					   '1' when (OPCODE = J or OPCODE = JAL or OPCODE = JR or OPCODE = JALR) else -- when operation is unconditional branch
					   '1' when (OPCODE = TRAP or OPCODE = RFE or OPCODE = RET)              else -- when exception call/return
					   '0';
						
	-- Extend immediate arg
	ext_imm_s(DLX_OPERAND_SIZE-1   downto IMMEDIATE_ARG_SIZE)	<= IMM_ARG                                   when (LHI_EXT = '1')    else
																   (others => IMM_ARG(IMMEDIATE_ARG_SIZE-1)) when (SIGNED_EXT = '1') else
																   (others => '0');
	ext_imm_s(IMMEDIATE_ARG_SIZE-1 downto                  0)	<= (others => '0') when (LHI_EXT = '1') else IMM_ARG;
	
	-- Extend pc offset
	pc_offset_s(DLX_OPERAND_SIZE-1    downto JUMP_PC_OFFSET_SIZE)	<= (others => PC_OFFSET(JUMP_PC_OFFSET_SIZE-1));
	pc_offset_s(JUMP_PC_OFFSET_SIZE-1 downto                   0)	<= PC_OFFSET;
	
	-- Assign outputs
	REG_A	<= reg_a_s	when (OPCODE = RET)			else -- Use r31 if RET
			   reg_a_s	when (OPCODE = TRAP)		else -- Use isr if TRAP
			   reg_a_s	when (OPCODE = RFE)			else -- Use iar if RFE
			   PC		when (branch_taken_s = '1')	else -- Propagate pc in case of branch address calculation
			   reg_a_s;
			   
	reg_a_s	<= FORWARD_VALUE1 when (FORWARD_R1_EN = '1')  else -- Receive value from further down the pipeline
			   RF_dout1_s;
			   
	REG_B	<= ext_imm_s      when (IMM_SEL = '1')        else -- Select immediate value if I-type
			   pc_offset_s    when (PC_OFFSET_SEL = '1')  else -- Select PC offset if J-type
			   reg_b_s;	
			   
	reg_b_s	<= FORWARD_VALUE2 when (FORWARD_R2_EN = '1')  else -- Receive value from further down the pipeline
			   RF_dout2_s;
			   
	REG_C	<= PC		when (PC_OUT_EN = '1')   else
			   reg_b_s	when (STORE_R2_EN = '1') else
			   reg_a_s;

end architecture;