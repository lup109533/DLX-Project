library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity FETCH is
	port (
		CLK				: in	std_logic;
		RST				: in	std_logic;
		INSTR			: in	DLX_instr_t;
		FOUT			: out	DLX_instr_t;
		PC				: out	DLX_addr_t;
		-- CU signals
		BRANCH_TAKEN	: in	std_logic;
		BRANCH_ADDR		: in	DLX_addr_t
	);
end entity;

architecture behavioral of FETCH is

	-- COMPONENTS
	component CLA
		generic (
			OPERAND_SIZE	: natural;
			RADIX			: natural := 2
		);
		port (
			A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic;
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			C		: out	std_logic
		);
	end component;

	-- SIGNALS
	signal pc_offset		: pc_offset_t;
	signal curr_pc			: DLX_addr_t;
	signal next_pc			: DLX_addr_t;

begin
	
	-- PC register process
	pc_register: process (CLK, RST, next_pc) is
	begin
		if rising_edge(CLK) then
			if (RST = '0') then
				curr_pc <= (others => '0');
			else
				curr_pc <= next_pc;
			end if;
		end if;
	end process;
	
	-- Address adder instantiation
	PC_ADD: CLA generic map (DLX_ADDR_SIZE) port map (curr_pc, instr_offset, '0', pc_add_out, open);
	instr_offset <= std_logic_vector(to_unsigned(DLX_ADDR_SIZE/8, instr_offset'length));
	
	-- Select next address (branch may have been calculated in EX stage)
	next_pc <= pc_add_out when (BRANCH_TAKEN = '0') else BRANCH_ADDR;
	
	-- PC output for memory/cache
	PC <= curr_pc;
	
	-- Forward instruction, or push bubble (NOP) if branch
	FOUT <= INSTR when (BRANCH_TAKEN = '0') else NOP & INSTR((DLX_INSTRUCTION_SIZE - OPCODE_SIZE)-1 downto 0);

end architecture;