library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CIRCULAR_BUFFER is
	generic (N : integer);
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		INIT	: in	std_logic_vector(N-1 downto 0);
		SHR		: in	std_logic;
		SHL		: in	std_logic;
		OVFL	: out	std_logic;
		UNFL	: out	std_logic;
		DOUT	: out	std_logic_vector(N-1 downto 0)
	);
end entity;

architecture behavioural of CIRCULAR_BUFFER is

	signal buff		: std_logic_vector(N-1 downto 0);
	signal tmp		: std_logic;
	signal unfl_s	: std_logic;
	signal ovfl_s	: std_logic;

begin

	buffer_manager: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			buff <= INIT;
		elsif (ENB = '1' and rising_edge(CLK)) then
			if (SHR = '1') then
				tmp					<= buff(N-1);
				buff(N-1 downto 1)	<= buff(N-2 downto 0);
				buff(0)				<= tmp;
			elsif (SHL = '1') then
				tmp					<= buff(0);
				buff(N-2 downto 0)	<= buff(N-1 downto 1);
				buff(N-1)			<=tmp;
			end if;
		end if;
	end process;
	
	ovfl_unfl_manager: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			unfl_s <= '0';
			ovfl_s <= '0';
		elsif (ENB = '1' and rising_edge(CLK)) then
			if (unfl_s = '1') then
				unfl_s <= '0';
			elsif (buff(N-1) = '1' and buff(0) = '1' and SHL = '1') then
				unfl_s <= '1';
			end if;
			if (ovfl_s = '1') then
				ovfl_s <= '0';
			elsif (buff(N-1) = '1' and buff(0) = '1' and SHR = '1') then
				ovfl_s <= '1';
			end if;
		end if;
	end process;
	
	OVFL <= ovfl_s;
	UNFL <= unfl_s;
	DOUT <= buff;

end architecture;