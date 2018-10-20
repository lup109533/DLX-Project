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
			ICACHE_INSTR		: in	DLX_instr_t;
			-- External memory interface
			ISR_TABLE_ADDR		: in	DLX_addr_t;
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
	
	signal INSTR_s				: DLX_instr_t;
	
	signal HEAP_ADDR_s			: DLX_addr_t;
	signal ISR_TABLE_ADDR_s		: DLX_addr_t;
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
	
begin

	UUT: DLX	port map(
					CLK_s,
					RST_s,
					ENB_s,
					-- ICACHE interface
					INSTR_s,
					-- External memory interface
					ISR_TABLE_ADDR_s,
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
		ISR_TABLE_ADDR_s	<= (others => '0');
		HEAP_ADDR_s			<= (others => '0');
		RF_ACK_s			<= '0';
		EXT_MEM_DOUT_s		<= std_logic_vector(to_unsigned(8, EXT_MEM_DOUT_s'length));
		EXT_MEM_BUSY_s		<= '0';
		opc					<= (others => '0');
		alu					<= (others => '0');
		fpu					<= (others => '0');
		reg1				<= "00010";
		reg2				<= "01101";
		dest				<= "00100";
		imm					<= "0000000000000010";
		pcoff				<= "10001001001011101010111111";
		wait for 1.5 ns;
	
		RST_s	<= '1';
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
			else
				INSTR_s	<= opc & reg1 & dest & imm;
				wait for 2 ns;
			end if;
		end loop;
		
		wait;
	end process;

end architecture;
