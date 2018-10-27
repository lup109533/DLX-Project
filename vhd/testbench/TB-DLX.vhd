library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.DLX_globals.all;
use work.instr_gen.all;

entity TB_DLX is
end entity;

architecture test of TB_DLX is

	component DLX
		port (
			CLK					: in	std_logic;
			RST					: in	std_logic;
			ENB					: in	std_logic;
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
	
	signal opcodes_s			: opcodes;
	signal alu_codes_s			: alu_codes;
	signal fpu_codes_s			: fpu_codes;
	signal opc					: opcode_t;
	signal alu					: func_t;
	signal fpu					: fp_func_t;
	signal reg1, reg2, dest		: reg_addr_t;
	signal imm					: immediate_t;
	signal pcoff				: pc_offset_t;
	
	type instr_file is file of DLX_instr_t;
	
	constant test_all	: boolean := true;
	constant file_name	: string(1 to 11) := "program.bin";
	
	signal loaded		: boolean := false;
	
	constant ICACHE_SIZE	: natural := 1024;
	type icache_t is array (0 to ICACHE_SIZE-1) of DLX_instr_t;
	signal icache_s			: icache_t;
	
	constant MEMORY_SIZE	: natural := 2**16;
	subtype byte is std_logic_vector(7 downto 0);
	type memory_t is array (0 to MEMORY_SIZE-1) of byte;
	signal memory_s			: memory_t;
	
begin

	UUT: DLX	port map(
					CLK_s,
					RST_s,
					ENB_s,
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
		INSTR_s				<= (others => '0');
		ICACHE_HIT_s		<= '1';
		HEAP_ADDR_s			<= (others => '0');
		RF_ACK_s			<= '0';
		EXT_MEM_BUSY_s		<= '0';
		opc					<= (others => '0');
		alu					<= (others => '0');
		fpu					<= (others => '0');
		reg1				<= "00010";
		reg2				<= "01101";
		dest				<= "00100";
		imm					<= "0000000000000010";
		pcoff				<= "10001001001011101010111111";
		wait for 2 ns;
	
		RST_s	<= '1';
		if (test_all) then
			for op in opcodes loop
				opcodes_s <= op;
				opc <= opcode_to_std_logic_v(op);
				if (opc = ALU_I) then
					for a in alu_codes loop
						alu_codes_s	<= a;
						alu		<= alu_to_std_logic_v(a);
						INSTR_s	<= opc & reg1 & reg2 & dest & alu;
						wait for 2 ns;
					end loop;
				elsif (opc = FPU_I) then
					for f in fpu_codes loop
						fpu_codes_s <= f;
						fpu		<= fpu_to_std_logic_v(f);
						INSTR_s	<= opc & reg1 & reg2 & dest & fpu;
						wait for 2 ns;
					end loop;
				elsif (opc /= TRAP and opc /= RFE) then
					INSTR_s	<= opc & reg1 & dest & imm;
					wait for 2 ns;
				end if;
			end loop;
		else
			wait for 2 ns;
		end if;
	end process;
	
	read_program: process (CLK_s, RST_s) is
		file program_file		: instr_file is file_name;
		variable current_instr	: DLX_instr_t;
		variable i				: integer := 0;
		variable cache_addr		: integer;
	begin
		if (RST_s = '0') then
			while not ENDFILE(program_file) loop
				read(program_file, current_instr);
				icache_s(i)	<= current_instr;
				i := i + 1;
			end loop;
			loaded <= true;
		elsif (rising_edge(CLK_s)) then
			cache_addr	:= to_integer(unsigned(PC_s));
			INSTR_s		<= icache_s(cache_addr);
		end if;
	end process;
	
	memory_proc: process (CLK_s, RST_s) is
		variable addr	: integer;
	begin
		if (RST_s = '0') then
			for i in 0 to MEMORY_SIZE-1 loop
				memory_s(i)	<= "00000000";
			end loop;
		elsif (rising_edge(CLK_s) and EXT_MEM_ENABLE_s = '1') then
			addr := to_integer(unsigned(EXT_MEM_ADDR_s));
			if (addr > MEMORY_SIZE-1) then
				addr := addr mod MEMORY_SIZE-1;
			end if;
			if (EXT_MEM_RD_s = '1') then
				EXT_MEM_DOUT_s(31 downto 24)	<= memory_s(addr);
				EXT_MEM_DOUT_s(23 downto 16)	<= memory_s(addr+1);
				EXT_MEM_DOUT_s(15 downto  8)	<= memory_s(addr+2);
				EXT_MEM_DOUT_s( 7 downto  0)	<= memory_s(addr+3);
			elsif (EXT_MEM_WR_s = '1') then
				memory_s(addr)		<= EXT_MEM_DIN_s(31 downto 24);
				memory_s(addr+1)	<= EXT_MEM_DIN_s(23 downto 16);
				memory_s(addr+2)	<= EXT_MEM_DIN_s(15 downto  8);
				memory_s(addr+3)	<= EXT_MEM_DIN_s( 7 downto  0);
			end if;
		end if;
	end process;

end architecture;
