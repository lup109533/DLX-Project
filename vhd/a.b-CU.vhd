library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_pack.all;

entity CU is
	port (
		CLK	: in	std_logic;
		RST	: in	std_logic;
		INSTR	: in	DLX_instruction_t;
		-- Control signals here.
		STALL	: out	std_logic;
	     );
end entity;

architecture behavioural of CU is

begin
	-- FILTER INSTRUCTION
	-- Push NOP into the pipeline in case of hazard.
	instr_s <= (OPCODE_RANGE => NOP, others => '0') when (stall_s = '1') else INSTR;

	-- UNPACK INSTRUCTION
	opcode		<= instr_s(OPCODE_RANGE);
	source1		<= instr_s(REG_SOURCE1_RANGE);
	source2		<= instr_s(REG_SOURCE2_RANGE);
	dest		<= instr_s(REG_DEST_RANGE);
	func		<= instr_s(ALU_FUNC_RANGE);
	immediate	<= instr_s(IMMEDIATE_ARG_RANGE);
	pc_offset	<= instr_s(PC_OFFSET_RANGE);
	fp_func		<= instr_s(FP_FUNC_RANGE);

	-- PREVIOUS INSTRUCTION REGISTER
	-- Used to check for hazards.
	prev_instr_reg: process (CLK, RST, instr_s) is begin
		if rising_edge(CLK) then
			if (RST = '0') then
				prev_instr_s <= (OPCODE_RANGE => NOP, others => '0');
			else
				prev_instr_s <= instr_s;
			end if;
		end if;
	end process;

	-- Unpack necessary portions of previous instruction.
	prev_opcode 	<= prev_instr_s(OPCODE_RANGE);
	prev_source1	<= prev_instr_s(REG_SOURCE1_RANGE);
	prev_source2	<= prev_instr_s(REG_SOURCE2_RANGE);
	prev_dest	<= prev_instr_s(REG_DEST_RANGE);

	-- OPCODE RELOCATOR
	relocated_opcode <= opcode; -- !!!TODO!!! TO BE CHANGED AFTER FINALIZATION !!!TODO!!!

	-- ADDRESSES MANAGER
	address_manager: process (CLK, RST, INSTR) is begin
		if rising_edge(CLK) then
			if (RST = '0') then
				addr1 <= 0;
				addr2 <= 0;
				addr3 <= 0;
				addr4 <= 0;
				addr5 <= 0;
			else
				addr1 <= to_integer(unsigned(relocated_opcode));
				addr2 <= addr1;
				addr3 <= addr2;
				addr4 <= addr3;
				addr5 <= addr4;
			end if;
		end if;
	end process;

	-- MICROCODE MANAGER
	fetch_ctrl	<= microcode(addr1)(FETCH_STAGE);
	decode_ctrl	<= microcode(addr2)(DECODE_STAGE);
	execute_ctrl	<= microcode(addr3)(EXECUTE_STAGE);
	memory_ctrl	<= microcode(addr4)(MEMORY_STAGE);
	write_back_ctrl	<= microcode(addr5)(WRITE_BACK_STAGE);

	-- CONTROL SIGNALS OUTPUT
	-- !!TODO!!!

	-- ARGUMENTS FOR DATAPATH
	IMM_ARG	<= immediate;
	RS1	<= source1;
	RS2	<= source2;
	RD	<= dest;
	F_ALU	<= func;
	F_FP	<= fp_func;

	-- PIPELINE HAZARD MANAGEMENT LOGIC
	raw_detect	<= ((op_class(HAS_SOURCE) = '1') and (prev_op_class(HAS_DEST) = '1')) and ((source1 = prev_dest) or (source2 = prev_dest));
	STALL		<= stall_s;

end architecture;
