library ieee;
use ieee.std_logic_1164.all;

-- Generate signal for bits i through j
entity G_BLOCK is
	port (
		G_ik	: in	std_logic;
		P_ik	: in	std_logic;
		G_km1j	: in	std_logic;
		G_ij	: out	std_logic
	);
end entity;

architecture structural of G_BLOCK is

begin

	G_ij <= G_ik or (P_ik and G_km1j);

end architecture;
