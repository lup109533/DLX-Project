library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;
use work.utils.log2;

entity PRIORITY_ENCODER is
	generic (
		DIN_SIZE		: natural;
		PRIORITY_TYPE	: std_logic
	);
	port (
		DIN			: in	std_logic_vector(DIN_SIZE-1 downto 0);
		DOUT		: out	std_logic_vector(log2(DIN_SIZE)-1 downto 0);
		NO_PRIORITY	: out	std_logic
	);
end entity;

architecture behavioural of PRIORITY_ENCODER is

	subtype switches is integer range 0 to DIN_SIZE-1;

begin

	encode_proc: process (DIN) is
		variable highest	: switches	:= DIN_SIZE-1;
	begin
		for i in switches loop
			if (DIN(i) = PRIORITY_TYPE) then
				highest := i;
			end if;
		end loop;
		DOUT		<= std_logic_vector(to_unsigned(highest, DOUT'length));
	end process;
	
	NO_PRIORITY <= not(or_reduce(DIN));

end architecture;