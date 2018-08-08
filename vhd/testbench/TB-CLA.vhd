library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_CLA is
end entity;

architecture test of TB_CLA is

	component CLA
		generic (
			OPERAND_SIZE	: natural;
			RADIX		: natural := 2
		);
		port (
			A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN	: in	std_logic;
			O	: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			C	: out	std_logic
		);
	end component;

	constant OPERAND_SIZE	: natural := 8;
	constant RADIX			: natural := 2;
	
	constant MAX_A	: natural := 100;
	constant MAX_B	: natural := 100;
	
	signal A_s, B_s	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal CIN_s	: std_logic;
	signal O_s		: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal C_s		: std_logic;
	
begin

	-- UUT
	UUT: CLA generic map(OPERAND_SIZE, RADIX) port map(A_s, B_s, CIN_s, O_s, C_s);

	-- STIMULUS
	CIN_s <= '0';
	stimulus: process is
		variable A_v, B_v : natural;
	begin
	
		for A_v in 0 to MAX_A loop
			for B_v in 0 to MAX_B loop
				A_s <= std_logic_vector(to_unsigned(A_v, A_s'length));
				B_s <= std_logic_vector(to_unsigned(B_v, B_s'length));
				wait for 1 ns;
			end loop;
		end loop;
		
		wait;
	end process;

end architecture;
