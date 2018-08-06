library ieee;
use ieee.std_logic_1164.all;

entity FA is
	port (
		A, B	: in	std_logic;
		CIN	: in	std_logic;
   		S, C	: out	std_logic	
	);
end entity;

architecture structural of HA is

	signal inter_s, inter_c1, inter_c2 : std_logic;

begin

	ha0: HA port map(A, B, inter_s, inter_c1);
	ha1: HA port map(inter_s, CIN, S, inter_c2);
	
	C <= inter_c1 or inter_c2;

end architecture;
