library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity WRITE_BACK is
	port map (
		DIN		: in	DLX_oper_t;
		DOUT	: out	DLX_oper_t;
		WR		: in	std_logic;
		WR_OUT	: out	std_logic
	);
end entity;

architecture structural of WRITE_BACK is

begin

	DOUT <= DIN;
	
	WR <= WR_OUT;

end architecture;