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

entity REG_N_INIT is
	generic (N : natural);
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		INIT	: in	std_logic_vector(N-1 downto 0);
		DIN		: in	std_logic_vector(N-1 downto 0);
		DOUT	: out	std_logic_vector(N-1 downto 0)
	);
end entity;

architecture structural of REG_N_INIT is

begin

	reg_proc: process (CLK, RST) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				DOUT <= INIT;
			elsif (ENB = '1') then
				DOUT <= DIN;
			end if;
		end if;
	end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use work.DLX_globals.all;

entity ALU_OPCODE_REG is
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		DIN		: in	ALU_opcode_t;
		DOUT	: out	ALU_opcode_t
	);
end entity;

architecture behavioural of ALU_OPCODE_REG is

begin
	reg_proc: process (CLK, RST) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				DOUT <= SHIFT_RL;
			elsif (ENB = '1') then
				DOUT <= DIN;
			end if;
		end if;
	end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use work.DLX_globals.all;

entity FPU_OPCODE_REG is
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		DIN		: in	FPU_opcode_t;
		DOUT	: out	FPU_opcode_t
	);
end entity;

architecture behavoural of FPU_OPCODE_REG is

begin
	reg_proc: process (CLK, RST) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				DOUT <= FP_ADD;
			elsif (ENB = '1') then
				DOUT <= DIN;
			end if;
		end if;
	end process;
end architecture;