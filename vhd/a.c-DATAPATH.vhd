library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity DATAPATH is
	port (
		INSTR	: in	DLX_instr_t;
		MIN		: in	DLX_oper_t;
		MIN		: out	DLX_oper_t;
		MADDR	: out	DLX_addr_t;
		-- Signals from/to CU here
	);
end entity;

architecture structural of DATAPATH is

	-- COMPONENTS

begin

	

end architecture;