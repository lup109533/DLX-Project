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
		-- CU signals
		PC				: in	DLX_addr_t;
		RF_DIN			: in	DLX_oper_t;
		RF_RD1_ADDR		: in	reg_addr_t;
		RF_RD2_ADDR		: in	reg_addr_t;
		RF_WR_ADDR		: in	reg_addr_t;
		RF_RD1			: in	std_logic;
		RF_RD2			: in	std_logic;
		RF_WR			: in	std_logic;
		RF_CALL			: in	std_logic;
		RF_RETN			: in	std_logic;
		RF_SPILL		: out	std_logic;
		RF_FILL			: out	std_logic;
		RF_ACK			: in	std_logic;
		RF_OK			: out	std_logic;
		MBUS			: inout	DLX_oper_t;
		IMM				: in	immediate_t;
		SIGNED_EXT		: in	std_logic;
		OPCODE			: in	opcode_t;
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

	signal RF_dout1_s	: DLX_oper_t;
	signal RF_dout2_s	: DLX_oper_t;
	signal is_zero_s	: std_logic;
	signal ext_imm_s	: DLX_oper_t;
	
begin

	-- Instantiate RF
	RF: REGISTER_FILE	generic map (
							WORD_SIZE			=> DLX_OPERAND_SIZE,
							REGISTER_NUM		=> 2**REGISTER_ADDR_SIZE,
							WINDOWS_NUM			=> 4,
							SYSTEM_ADDR_SIZE	=> DLX_ADDR_SIZE
						)
						port map (
							CLK			=> CLK,
							RST			=> RST,
							ENB			=> ENB,
							HEAP_ADDR	=> HEAP_ADDR,
							RD1			=> RF_RD1
							RD2			=> RF_RD2,
							WR			=> RF_WR,
							DIN			=> RF_DIN
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
	BRANCH_TAKEN <= '1' when (iz_zero_s = '1' and BRANCH_COMPARE = EQZ) or (is_zero_s = '0' and BRANCH_COMPARE = NEZ) or (OP_TYPE = J) else '0';
						
	-- Extend immediate arg
	ext_imm_s(DLX_OPERAND_SIZE-1   downto IMMEDIATE_ARG_SIZE)	<= (others => IMM(IMMEDIATE_ARG_SIZE-1)) when (SIGNED_EXT = '1') else (others => '0');
	ext_imm_s(IMMEDIATE_ARG_SIZE-1 downto                  0)	<= IMM;
	
	-- Assign immediates
	REG_A	<= PC when (OP_TYPE = J) else RF_dout1_s; -- Propagate pc in case of branch address calculation
	REG_B	<= RF_dout2_s;
	IMM_ARG	<= ext_imm_s;

end architecture;