library ieee;
use ieee.std_logic_1164.all;

package cmp_ctrl is
	type compare_type		is (EQUAL, NOT_EQUAL, GREATER, GREATER_EQ, LESS, LESS_EQ, NO_COMPARE);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_signed.ALL;
use work.cmp_ctrl.all;

entity COMPARATOR is
	port(
		Z	: in	std_logic;
		C	: in	std_logic;
		SEL	: in	compare_type;
		O	: out	std_logic
	);
end COMPARATOR;

architecture Behavioral of COMPARATOR is
begin 
	
	process (SEL, C, Z) is
	begin
		case (SEL) is
			when EQUAL =>
				O <= Z;
				
			when NOT_EQUAL =>
				O <= not Z;
				
			when GREATER =>
				O <= C and not Z;
				
			when GREATER_EQ =>
				O <= C;
				
			when LESS =>
				O <= not C;
				
			when LESS_EQ =>
				O <= not C or Z;
				
			when NO_COMPARE =>
				O <= '0';
		end case;
	end process;
	
end Behavioral;
