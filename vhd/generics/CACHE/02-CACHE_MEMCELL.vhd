library ieee;
use ieee.std_logic_1164.all;

entity CACHE_MEMCELL is
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		WRT		: in	std_logic;
		TAG		: in	std_logic;
		DIN		: in	std_logic;
		DOUT	: out	std_logic;
		HIT		: out	std_logic
	);
end entity;

architecture behavioural of CACHE_MEMCELL is

	signal data	: std_logic;

begin

	HIT	<= not(data xor TAG);
	
	memcell_proc: process (CLK, RST, ENB) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				data <= '0';
			elsif (ENB = '1') then
				if (WRT = '1') then
					data <= DIN;
				else
					data <= data;
				end if;
			end if;
		end if;
	end process;
	
	DOUT <= data;

end architecture;