library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity WRITE_BACK is
	port (
		DIN			: in	DLX_oper_t;
		PC			: in	DLX_addr_t;
		DOUT		: out	DLX_oper_t;
		-- CU signals
		LINK_PC		: in	std_logic;
		RF_WR		: in	std_logic;
		RF_WR_OUT	: out	std_logic
	);
end entity;

architecture structural of WRITE_BACK is

begin

	DOUT <= DIN when (LINK_PC = '0') else PC; -- Write back PC if JAL or similar.
	
	RF_WR_OUT <= RF_WR;

end architecture;