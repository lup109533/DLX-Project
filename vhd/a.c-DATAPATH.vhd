library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_globals.all;

entity DATAPATH is
	port (
		CLK		: in	std_logic;
		RST		: in	std_logic;
		ENB		: in	std_logic;
		INSTR	: in	DLX_instr_t;
		MIN		: in	DLX_oper_t;
		MIN		: out	DLX_oper_t;
		MADDR	: out	DLX_addr_t;
		-- Signals from/to CU here
	);
end entity;

architecture structural of DATAPATH is

	-- COMPONENTS
	component FETCH
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
	end component;
	
	-- SIGNALS
	-- Should be named ComponentName_PortName_s

begin

	FET_STAGE: FETCH	port map (
							CLK			=> clk_s,
							RST			=> rst_s,
							INSTR		=> instr_s,
							INSTR_TYPE	=> cu_instr_type_s,
							FOUT		=> fetch_fout_s,
							PC			=> fetch_pc_s,
							PREDICTION	=> fetch_prediction_s,
							FLUSH		=> cu_flush_s
						);

end architecture;