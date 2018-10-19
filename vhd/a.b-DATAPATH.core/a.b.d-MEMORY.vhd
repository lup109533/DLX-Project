library ieee;
use ieee.std_logic_1164.all;
use work.DLX_globals.all;

entity MEMORY is
	port (
		-- Control signals from CU.
		MEM_RD_SEL		: in	std_logic;
		MEM_WR_SEL		: in	std_logic;
		MEM_EN			: in	std_logic;
		MEMORY_OP_SEL	: in	std_logic;
		MEM_SIGNED_EXT	: in	std_logic;
		MEM_HALFWORD	: in	std_logic;
		MEM_BYTE		: in	std_logic;
		-- Signals to/from external memory.
		EXT_MEM_ADDR	: out	DLX_addr_t;
		EXT_MEM_DIN		: out	DLX_oper_t;
		EXT_MEM_RD		: out	std_logic;
		EXT_MEM_WR		: out	std_logic;
		EXT_MEM_ENABLE	: out	std_logic;
		EXT_MEM_DOUT	: in	DLX_oper_t;
		-- Signals from/to previous/next stage.
		EX_IN			: in	DLX_oper_t;
		MEM_OUT			: out	DLX_oper_t
	);
end entity;

architecture structural of MEMORY is

	signal in_halfword				: std_logic_vector(DLX_OPERAND_SIZE/2-1   downto 0);
	signal in_byte					: std_logic_vector(DLX_OPERAND_SIZE/4-1   downto 0);
	signal in_halfword_extension	: std_logic_vector(DLX_OPERAND_SIZE/2-1   downto 0);
	signal in_byte_extension		: std_logic_vector(3*DLX_OPERAND_SIZE/4-1 downto 0);
	
	signal out_halfword				: std_logic_vector(DLX_OPERAND_SIZE/2-1   downto 0);
	signal out_byte					: std_logic_vector(DLX_OPERAND_SIZE/4-1   downto 0);
	signal out_halfword_extension	: std_logic_vector(DLX_OPERAND_SIZE/2-1   downto 0);
	signal out_byte_extension		: std_logic_vector(3*DLX_OPERAND_SIZE/4-1 downto 0);
	
	signal ext_mem_din_s			: DLX_oper_t;
	signal ext_mem_dout_s			: DLX_oper_t;

begin

	-- External memory inputs.
	EXT_MEM_ADDR	<= EX_IN;
	EXT_MEM_DIN		<= ext_mem_din_s;
	EXT_MEM_RD		<= MEM_RD_SEL;
	EXT_MEM_WR		<= MEM_WR_SEL;
	EXT_MEM_ENABLE	<= MEM_EN;
	
	-- Extend input from memory
	in_halfword				<= EX_IN(DLX_OPERAND_SIZE/2-1 downto 0);
	in_byte					<= EX_IN(DLX_OPERAND_SIZE/4-1 downto 0);
	in_halfword_extension	<= (others => EX_IN(DLX_OPERAND_SIZE/2-1)) when (MEM_SIGNED_EXT = '1') else (others => '0');
	in_byte_extension		<= (others => EX_IN(DLX_OPERAND_SIZE/4-1)) when (MEM_SIGNED_EXT = '1') else (others => '0');
	
	out_halfword			<= EXT_MEM_DOUT(DLX_OPERAND_SIZE/2-1 downto 0);
	out_byte				<= EXT_MEM_DOUT(DLX_OPERAND_SIZE/4-1 downto 0);
	out_halfword_extension	<= (others => EXT_MEM_DOUT(DLX_OPERAND_SIZE/2-1)) when (MEM_SIGNED_EXT = '1') else (others => '0');
	out_byte_extension		<= (others => EXT_MEM_DOUT(DLX_OPERAND_SIZE/4-1)) when (MEM_SIGNED_EXT = '1') else (others => '0');
	
	EXT_MEM_DIN				<= ext_mem_din_s;
	ext_mem_din_s			<= in_halfword_extension & in_halfword when (MEM_HALFWORD = '1') else
							   in_byte_extension     & in_byte     when (MEM_BYTE = '1')     else
							   EX_IN;
	
	ext_mem_dout_s			<= out_halfword_extension & out_halfword when (MEM_HALFWORD = '1') else
							   out_byte_extension     & out_byte     when (MEM_BYTE = '1')     else
							   EXT_MEM_DOUT;
	
	-- External memory outputs.
	MEM_OUT <= EX_IN when (MEMORY_OP_SEL = '0') else ext_mem_dout_s;

end architecture;