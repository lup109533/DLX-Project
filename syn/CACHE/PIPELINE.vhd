library ieee;
use ieee.std_logic_1164.all;

entity FF is
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		DIN		: in	std_logic;
		DOUT	: out	std_logic
	);
end entity;

architecture behavioural of FF is

begin

	ff_proc: process (CLK, RST) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				DOUT <= '0';
			elsif (ENB = '1') then
				DOUT <= DIN;
			end if;
		end if;
	end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity REG_N is
	generic (N : natural);
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		DIN		: in	std_logic_vector(N-1 downto 0);
		DOUT	: out	std_logic_vector(N-1 downto 0)
	);
end entity;

architecture structural of REG_N is

	component FF
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic;
			DOUT	: out	std_logic
		);
	end component;

begin

	reg_gen: for i in 0 to N-1 generate
		FF_i: FF port map (CLK, RST, ENB, DIN(i), DOUT(i));
	end generate;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use work.utils.max;

entity PIPELINE is
	generic (
		WORD_SIZE	: natural;
		WORD_NUM	: natural;
		FF_NUM		: natural := 0
	);
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		DIN		: in	std_logic_vector(WORD_NUM*WORD_SIZE-1 downto 0);
		DOUT	: out	std_logic_vector(WORD_NUM*WORD_SIZE-1 downto 0);
		FFIN	: in	std_logic_vector(FF_NUM-1 downto 0);				-- For 1-bit signals, leave open if unused.
		FFOUT	: out	std_logic_vector(FF_NUM-1 downto 0)					-- See above.
	);
end entity;

architecture structural of PIPELINE is

	component FF
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic;
			DOUT	: out	std_logic
		);
	end component;

	component REG_N
		generic (N : natural);
		port (
			CLK		: in	std_logic;
			RST		: in	std_logic;
			ENB		: in	std_logic;
			DIN		: in	std_logic_vector(N-1 downto 0);
			DOUT	: out	std_logic_vector(N-1 downto 0)
		);
	end component;

begin

	regs_gen: for i in 0 to WORD_NUM-1 generate
		REG_i: REG_N generic map(WORD_SIZE) port map(
												CLK,
												RST,
												ENB,
												DIN((i+1)*WORD_SIZE-1 downto i*WORD_SIZE),
												DOUT((i+1)*WORD_SIZE-1 downto i*WORD_SIZE)
											);
	end generate;
	
	ffs_gen: for i in 0 to max(FF_NUM-1, 0) generate
			check_ffs_not_0: if not(FF_NUM = 0) generate
				FF_i: FF port map(CLK, RST, ENB, FFIN(i), FFOUT(i));
			end generate;
	end generate;

end architecture;