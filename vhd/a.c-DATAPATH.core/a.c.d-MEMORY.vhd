library ieee;
use ieee.std_logic_1164.all;
use work.DLX_globals.all;

entity MEMORY is
	port (
		-- Control signals from CU.
		RD_SEL			: in	std_logic;
		WR_SEL			: in	std_logic;
		MEM_EN			: in	std_logic;
		MEMORY_OP_SEL	: in	std_logic;
		-- Signals to/from external memory.
		EXT_MEM_ADDR	: out	DLX_addr_t;
		EXT_MEM_DIN		: out	DLX_oper_t;
		EXT_MEM_RD		: out	std_logic;
		EXT_MEM_WR		: out	std_logic;
		EXT_MEM_ENABLE	: out	std_logic;
		EXT_MEM_DOUT	: in	DLX_oper_t;
		-- Signals from/to previous/next stage.
		EX_IN			: in	DLX_oper_t;
		DATA_IN			: in	DLX_oper_t;
		MEM_OUT			: out	DLX_oper_t
	);
end entity;

architecture structural of MEMORY is

begin

	-- External memory inputs.
	EXT_MEM_ADDR	<= EX_IN;
	EXT_MEM_DIN		<= DATA_IN;
	EXT_MEM_RD		<= RD_SEL;
	EXT_MEM_WR		<= WR_SEL;
	EXT_MEM_ENABLE	<= MEM_EN;
	
	-- External memory outputs.
	MEM_OUT <= EX_IN when (MEMORY_OP_SEL = '0') else EXT_MEM_DOUT;

end architecture;