library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity FETCH is
	port (
		CLK				: in	std_logic;
		RST				: in	std_logic;
		ENB				: in	std_logic;
		BRANCH_DELAY_EN	: in	std_logic;
		INSTR			: in	DLX_instr_t;
		FOUT			: out	DLX_instr_t;
		PC				: out	DLX_addr_t;
		PC_INC			: out	DLX_addr_t;
		-- Datapath signals
		BRANCH_TAKEN	: in	std_logic;
		BRANCH_ADDR_SEL	: in	std_logic;
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
	signal curr_pc			: DLX_addr_t;
	signal next_pc			: DLX_addr_t;
	signal instr_offset		: DLX_addr_t;
	signal pc_add_out		: DLX_addr_t;
	signal push_nop_s		: DLX_instr_t;

begin
	
	-- PC register process
	pc_register: process (CLK, RST, ENB, next_pc) is
	begin
		if (RST = '0') then
			curr_pc <= (others => '0');
		elsif rising_edge(CLK) and (ENB = '1') then
			curr_pc <= next_pc;
		end if;
	end process;
	
	-- Address adder instantiation
	PC_ADD: CLA generic map (DLX_ADDR_SIZE) port map (curr_pc, instr_offset, '0', pc_add_out, open);
	instr_offset <= std_logic_vector(to_unsigned(DLX_ADDR_SIZE/8, instr_offset'length));
	
	-- Select next address (branch may have been calculated in EX stage)
	next_pc <= pc_add_out when (BRANCH_ADDR_SEL = '0') else BRANCH_ADDR;
	
	-- PC output for memory/cache
	PC		<= curr_pc;
	PC_INC	<= pc_add_out;
	
	-- Forward instruction, or push bubble (NOP) if branch, unless branch delay slot is enabled
	FOUT		<= push_nop_s when (BRANCH_TAKEN = '1' and BRANCH_DELAY_EN = '0') else INSTR;
	push_nop_s	<= NOP & INSTR((DLX_INSTRUCTION_SIZE - OPCODE_SIZE)-1 downto 0);

end architecture;