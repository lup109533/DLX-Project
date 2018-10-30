library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.DLX_globals.all;
use work.instr_gen.all;
use work.utils.min;

library std;
use std.textio.all;

entity TB_DLX is
end entity;

architecture test of TB_DLX is

	component DLX
		port (
			CLK					: in	std_logic;
			RST					: in	std_logic;
			ENB					: in	std_logic;
			-- Branch delay slot toggle
			BRANCH_DELAY_EN		: in	std_logic;
			-- ICACHE interface
			PC					: out	DLX_addr_t;
			ICACHE_INSTR		: in	DLX_instr_t;
			ICACHE_HIT			: in	std_logic;
			-- External memory interface
			HEAP_ADDR			: in	DLX_addr_t;
			RF_SWP				: out	DLX_addr_t;
			MBUS				: inout	DLX_oper_t;
			RF_ACK				: in	std_logic;
			EXT_MEM_ADDR		: out	DLX_addr_t;
			EXT_MEM_DIN			: out	DLX_oper_t;
			EXT_MEM_RD			: out	std_logic;
			EXT_MEM_WR			: out	std_logic;
			EXT_MEM_ENABLE		: out	std_logic;
			EXT_MEM_DOUT		: in	DLX_oper_t;
			EXT_MEM_BUSY		: in	std_logic
		);
	end component;
	
	signal CLK_s				: std_logic;
	signal RST_s				: std_logic;
	signal ENB_s				: std_logic;
	
	signal BRANCH_DELAY_EN_s	: std_logic := '0';
	
	signal PC_s					: DLX_addr_t;
	signal INSTR_s				: DLX_instr_t;
	signal ICACHE_HIT_s			: std_logic;
	
	signal HEAP_ADDR_s			: DLX_addr_t;
	signal RF_SWP_s				: DLX_addr_t;
	signal MBUS_s				: DLX_oper_t;
	signal RF_ACK_s				: std_logic;
	signal EXT_MEM_ADDR_s		: DLX_addr_t;
	signal EXT_MEM_DIN_s		: DLX_oper_t;
	signal EXT_MEM_RD_s			: std_logic;
	signal EXT_MEM_WR_s			: std_logic;
	signal EXT_MEM_ENABLE_s		: std_logic;
	signal EXT_MEM_DOUT_s		: DLX_oper_t;
	signal EXT_MEM_BUSY_s		: std_logic;
	
	constant ICACHE_SIZE	: natural := 256;
	type icache_t is array (0 to ICACHE_SIZE-1) of DLX_instr_t;
	signal icache_s			: icache_t;
	signal cache_addr		: integer := 0;
	
	constant MEMORY_SIZE	: natural := 2**8;
	subtype byte is std_logic_vector(7 downto 0);
	type memory_t is array (0 to MEMORY_SIZE-1) of byte;
	signal memory_s			: memory_t;
	signal addr : integer range 0 to MEMORY_SIZE-1 := 0;
	
	type char_file_t is file of character;
	file program_file	: char_file_t open read_mode is "program.bin";
	signal loaded		: boolean := false;
	
begin

	UUT: DLX	port map(
					CLK_s,
					RST_s,
					ENB_s,
					-- Branch delay slot toggle
					BRANCH_DELAY_EN_s,
					-- ICACHE interface
					PC_s,
					INSTR_s,
					ICACHE_HIT_s,
					-- External memory interface
					HEAP_ADDR_s,
					RF_SWP_s,
					MBUS_s,
					RF_ACK_s,
					EXT_MEM_ADDR_s,
					EXT_MEM_DIN_s,
					EXT_MEM_RD_s,
					EXT_MEM_WR_s,
					EXT_MEM_ENABLE_s,
					EXT_MEM_DOUT_s,
					EXT_MEM_BUSY_s
				);

	clk_gen: process is
	begin
		if (CLK_s /= '0' and CLK_s /= '1') then
			CLK_s <= '0';
		else
			CLK_s <= not CLK_s;
		end if;
		wait for 1 ns;
	end process;
	
	stimulus: process is
	begin
		RST_s				<= '0';
		ENB_s				<= '1';
		ICACHE_HIT_s		<= '1';
		HEAP_ADDR_s			<= (others => '0');
		RF_ACK_s			<= '0';
		EXT_MEM_BUSY_s		<= '0';
		wait for 2 ns;
	
		RST_s	<= '1';
		wait;
	end process;
	
	read_program: process (CLK_s, RST_s) is
		variable curr_char		: character;
		variable i				: natural := 0;
	begin
		if (RST_s = '0') then
			for i in 0 to ICACHE_SIZE-1 loop
				icache_s(i)					<= (others => '0');
				icache_s(i)(OPCODE_RANGE)	<= NOP;
			end loop;
		elsif (rising_edge(RST_s) and not loaded) then
			while not ENDFILE(program_file) loop
				read(program_file, curr_char);
				icache_s(i)(31 downto 24) <= std_logic_vector(to_unsigned(character'pos(curr_char), 8));
				read(program_file, curr_char);
				icache_s(i)(23 downto 16) <= std_logic_vector(to_unsigned(character'pos(curr_char), 8));
				read(program_file, curr_char);
				icache_s(i)(15 downto  8) <= std_logic_vector(to_unsigned(character'pos(curr_char), 8));
				read(program_file, curr_char);
				icache_s(i)( 7 downto  0) <= std_logic_vector(to_unsigned(character'pos(curr_char), 8));
				i := i + 1;
			end loop;
			loaded <= true;
		end if;
	end process;
	cache_addr	<= to_integer(unsigned(PC_s))/4;
	INSTR_s		<= icache_s(cache_addr) when (RST_s = '1') else NOP & "00000000000000000000000000";
	
	memory_proc: process (CLK_s, RST_s) is
	begin
		if (RST_s = '0') then
			for i in 0 to MEMORY_SIZE-1 loop
				memory_s(i)	<= std_logic_vector(to_unsigned(i, 8));
			end loop;
		elsif (rising_edge(CLK_s) and EXT_MEM_ENABLE_s = '1') then
			if (EXT_MEM_WR_s = '1') then
				memory_s(addr)		<= EXT_MEM_DIN_s(31 downto 24);
				memory_s(addr+1)	<= EXT_MEM_DIN_s(23 downto 16);
				memory_s(addr+2)	<= EXT_MEM_DIN_s(15 downto  8);
				memory_s(addr+3)	<= EXT_MEM_DIN_s( 7 downto  0);
			end if;
		end if;
	end process;
	
	get_addr: process (EXT_MEM_ADDR_s) is
	begin
		addr <= abs(to_integer(unsigned(EXT_MEM_ADDR_s)) mod MEMORY_SIZE-1);
		EXT_MEM_DOUT_s(31 downto 24)	<= memory_s(addr);
		EXT_MEM_DOUT_s(23 downto 16)	<= memory_s(work.utils.min(MEMORY_SIZE-1, addr+1));
		EXT_MEM_DOUT_s(15 downto  8)	<= memory_s(work.utils.min(MEMORY_SIZE-1, addr+2));
		EXT_MEM_DOUT_s( 7 downto  0)	<= memory_s(work.utils.min(MEMORY_SIZE-1, addr+3));
	end process;

end architecture;
