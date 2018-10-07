library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity DECODE is
	port (
		CLK				: in	std_logic;
		RST				: in	std_logic;
		ENB				: in	std_logic;
		REG_A			: out	DLX_oper_t;
		REG_B			: out	DLX_oper_t;
		IMM				: out	DLX_oper_t;
		-- CU signals
		PC				: in	DLX_addr_t;
		RF_DIN			: in	DLX_oper_t;
		RF_RD1_ADDR		: in	reg_addr_t;
		RF_RD2_ADDR		: in	reg_addr_t;
		RF_WR_ADDR		: in	reg_addr_t;
		RF_RD1			: in	std_logic;
		RF_RD2			: in	std_logic;
		RF_WR			: in	std_logic;
		IMM				: in	immediate_t;
		SIGNED_EXT		: in	std_logic;
		OPCODE			: in	opcode_t;
		BRANCH_TAKEN	: out	std_logic
	);
end entity;

architecture behavioral of DECODE is

	signal RF_dout1_s : DLX_oper_t;

begin

	-- Instantiate RF
	RF: REGISTER_FILE	generic map (
							WORD_SIZE	=> DLX_OPERAND_SIZE,
							WORD_NUM	=> 2**REGISTER_ADDR_SIZE
						)
						port map (
							CLK			=> CLK,
							RST			=> RST,
							ENB			=> ENB,
							DIN			=> RF_DIN,
							RD1			=> RF_RD1,
							RD2			=> RF_RD2,
							WR			=> RF_WR,
							RD1_ADDR	=> RF_RD1_ADDR,
							RD2_ADDR	=> RF_RD2_ADDR,
							WR_ADDR		=> RF_WR_ADDR,
							DOUT1		=> RF_dout1_s,
							DOUT2		=> REG_B
						);
						
	-- Instantiate zero detector to check if branch taken
	ZD: ZERO_DETECTOR generic map (DLX_OPERAND_SIZE) port map (RF_dout1_s, is_zero_s);
	
	-- Check branch taken
	BRANCH_TAKEN <= '1' when (iz_zero_s = '1' and OPCODE = BEQZ) or (is_zero = '0' and OPCODE = BNEZ) else '0';
						
	-- Extend immediate arg
	ext_imm_s(DLX_OPERAND_SIZE-1 downto IMMEDIATE_ARG_SIZE)	<= (others => IMM(IMMEDIATE_ARG_SIZE-1)) when (SIGNED_EXT = '1') else (others => '0');
	ext_imm_s(IMMEDIATE_ARG_SIZE-1 downto 0)				<= IMM;
	
	-- Assign immediates
	REG_A	<= PC when (OPCODE = BEQZ or OPCODE = BNEZ or OPCODE = JR or OPCODE = JALR) else RF_dout1_s; -- Propagate pc in case of branch address calculation
	IMM		<= imm_s;

end architecture;