library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity FETCH is
	port (
		CLK			: in	std_logic;
		RST			: in	std_logic;
		INSTR		: in	DLX_instr_t;
		INSTR_TYPE	: in	DLX_instr_type_t;
		FOUT		: out	DLX_instr_t;
		PC			: out	DLX_addr_t;
		PREDICTION	: out	std_logic;
		-- CU signals
		FLUSH		: in	std_logic
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
	signal NOP_INSTRUCTION	: DLX_instr_t;	
	signal pc_offset		: pc_offset_t;
	signal selected_offset	: pc_offset_t;
	signal prediction_s		: std_logic;
	signal curr_pc			: DLX_addr_t;
	signal next_pc			: DLX_addr_t;

begin

	-- Construct NOP instruction
	NOP_INSTRUCTION(OPCODE_RANGE)		<= NOP;
	NOP_INSTRUCTION(REG_SOURCE1_RANGE)	<= (others => '0');
	NOP_INSTRUCTION(REG_SOURCE2_RANGE)	<= (others => '0');
	NOP_INSTRUCTION(REG_DEST_RANGE)		<= (others => '0');

	-- Unpack INSTR
	get_pc_offset: process (INSTR_TYPE) is
	begin
		pc_offset <= (others => '0');
		if (INSTR_TYPE = J_TYPE) then
			pc_offset(PC_OFFSET_RANGE) <= INSTR(PC_OFFSET_RANGE);
		end if;
	end process;

	-- Instantiate address predictor
	prediction_s	<= BRANCH_TAKEN when (INSTR_TYPE = J_TYPE) else BRANCH_NOT_TAKEN;	-- For now always taken
	PREDICTION		<= prediction_s;
	
	-- PC register process
	ic_register: process (CLK, RST) is
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
	PC_ADD: CLA generic map (DLX_ADDR_SIZE) port map (curr_pc, selected_offset, '0', next_pc, open);
	
	-- Select offset according to prediction
	selected_offset <= pc_offset when (prediction_s = '1') else std_logic_vector(to_unsigned(4, selected_offset'length));
	
	-- PC output for memory/cache
	PC <= curr_pc;
	
	-- No instruction when flushing
	FOUT <= INSTR when (FLUSH = '0') else NOP_INSTRUCTION;

end architecture;