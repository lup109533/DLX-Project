library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity DECODE is
	port (
		CLK			: in	std_logic;
		RST			: in	std_logic;
		ENB			: in	std_logic;
		REG_A		: out	DLX_oper_t;
		REG_B		: out	DLX_oper_t;
		IMM_ARG1	: out	DLX_oper_t;
		IMM_ARG2	: out	DLX_oper_t;
		-- CU signals
		RF_DIN		: in	DLX_oper_t;
		RF_RD1_ADDR	: in	reg_addr_t;
		RF_RD2_ADDR	: in	reg_addr_t;
		RF_WR_ADDR	: in	reg_addr_t;
		RF_RD1		: in	std_logic;
		RF_RD2		: in	std_logic;
		RF_WR		: in	std_logic;
		IMM			: in	immediate_t
	);
end entity;

architecture behavioral of DECODE is

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
							DOUT1		=> REG_A,
							DOUT2		=> REG_B
						);
						
	IMM_ARG1 <= IMM;
	IMM_ARG2 <= IMM;

end architecture;