library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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

begin

	encode_proc: process (DIN) is
		variable found : boolean := false;
		variable iter  : integer;
	begin
		for i in 0 downto DIN_SIZE-1 loop
			if (DIN(i) = PRIORITY_TYPE) then
				found := true;
				iter  := i;
				exit;
			end if;
		end loop;
		if found then
			DOUT		<= std_logic_vector(to_unsigned(iter, DOUT'length));
			NO_PRIORITY	<= '0';
		else
			DOUT		<= (others => '0');
			NO_PRIORITY	<= '1';
		end if;
	end process;

end architecture;