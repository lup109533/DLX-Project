library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.DLX_globals.all;
use work.utils.log2;
use work.utils.max;

entity TB_REGISTER_FILE is
end entity;

architecture test of TB_REGISTER_FILE is

	function to_std_logic(i : in integer) return std_logic is
	begin
		if i = 0 then
			return '0';
		end if;
		return '1';
	end function;

	component REGISTER_FILE
		generic (
			WORD_SIZE			: natural;
			REGISTER_NUM		: natural;
			WINDOWS_NUM			: natural;
			SYSTEM_ADDR_SIZE	: natural
		);
		port (
			CLK			: in	std_logic;
			RST			: in	std_logic;
			ENB			: in	std_logic;
			HEAP_ADDR	: in	std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
			RD1			: in	std_logic;
			RD2			: in	std_logic;
			WR			: in	std_logic;
			DIN			: in	std_logic_vector(WORD_SIZE-1 downto 0);
			DOUT1		: out	std_logic_vector(WORD_SIZE-1 downto 0);
			DOUT2		: out	std_logic_vector(WORD_SIZE-1 downto 0);
			ADDR_IN		: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
			ADDR_OUT1	: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
			ADDR_OUT2	: in	std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
			CALL		: in 	std_logic;
			RETN		: in 	std_logic;
			SPILL		: out 	std_logic;
			FILL		: out	std_logic;
			SWP			: out	std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0);
			MBUS		: inout	std_logic_vector(max(log2(SYSTEM_ADDR_SIZE), WORD_SIZE)-1 downto 0);
			ACK			: in	std_logic;
			RF_OK		: out	std_logic
		);
	end component;
	
	constant WORD_SIZE			: natural := 8;
	constant REGISTER_NUM		: natural := 8;
	constant WINDOWS_NUM		: natural := 4;
	constant SYSTEM_ADDR_SIZE	: natural := 32;
	
	signal CLK			: std_logic;	
	signal RST			: std_logic;
	signal ENB			: std_logic;
	signal RD1			: std_logic;
	signal RD2			: std_logic;
	signal WR			: std_logic;
	signal CALL			: std_logic;
	signal RETN			: std_logic;
	signal SPILL		: std_logic;
	signal FILL			: std_logic;
	signal ACK			: std_logic;
	signal RF_OK		: std_logic;
	signal HEAP_ADDR	: std_logic_vector(log2(SYSTEM_ADDR_SIZE)-1 downto 0) := (others => '0');
	signal DIN			: std_logic_vector(WORD_SIZE-1 downto 0);
	signal DOUT1		: std_logic_vector(WORD_SIZE-1 downto 0);
	signal DOUT2		: std_logic_vector(WORD_SIZE-1 downto 0);
	signal ADDR_IN		: std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
	signal ADDR_OUT1	: std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
	signal ADDR_OUT2	: std_logic_vector(log2(REGISTER_NUM)-1 downto 0);
	signal MBUS			: std_logic_vector(max(log2(SYSTEM_ADDR_SIZE), WORD_SIZE)-1 downto 0);
	
begin

	-- UUT
	UUT: REGISTER_FILE	generic map(WORD_SIZE, REGISTER_NUM, WINDOWS_NUM, SYSTEM_ADDR_SIZE)
						port map(
							CLK			=> CLK,
							RST			=> RST,
							ENB			=> ENB,
							RD1			=> RD1,
							RD2			=> RD2,
							WR			=> WR,
							CALL		=> CALL,
							RETN		=> RETN,
							SPILL		=> SPILL,
							FILL		=> FILL,
							ACK			=> ACK,
							RF_OK		=> RF_OK,
							HEAP_ADDR	=> HEAP_ADDR,
							DIN			=> DIN,
							DOUT1		=> DOUT1,
							DOUT2		=> DOUT2,
							ADDR_IN		=> ADDR_IN,
							ADDR_OUT1	=> ADDR_OUT1,
							ADDR_OUT2	=> ADDR_OUT2,
							MBUS		=> MBUS
						);

	-- STIMULUS
	clk_gen: process is
	begin
		if not (CLK = '1' or CLK = '0') then
			CLK <= '0';
		else
			CLK <= not CLK;
		end if;
		wait for 1 ns;
	end process;
	
	stimulus: process is
	begin
		DIN			<= "00000000";
		RST			<= '0';
		ENB			<= '0';
		RD1			<= '0';
		RD2			<= '0';
		WR			<= '0';
		CALL		<= '0';
		RETN		<= '0';
		ADDR_IN		<= (others => '0');
		ADDR_OUT1	<= (others => '0');
		ADDR_OUT2	<= (others => '0');
		ACK			<= '0';
		MBUS		<= "ZZZZZZZZ";
		wait for 2 ns;
		
		RST <= '1';
		ENB <= '1';
		wait for 2 ns;
		
		WR  <= '1';
		DIN <= "00000001";
		wait for 2 ns;
		
		WR   <= '0';
		CALL <= '1';
		wait for 10 ns;
		
		CALL <= '0';
		ACK  <= '1';
		wait for 64 ns;
		
		ACK  <= '0';
		MBUS <= "00010000";
		wait for 6 ns;
		
		CALL <= '1';
		MBUS <= "ZZZZZZZZ";
		wait for 2 ns;
		
		CALL <= '0';
		WR   <= '1';
		DIN  <= "00000001";
		wait for 2 ns;
		
		ADDR_IN	<= (0 => '1', others => '0');
		CALL	<= '1';
		wait for 2 ns;
		
		CALL		<= '0';
		RD1			<= '1';
		RD2			<= '1';
		ADDR_OUT2	<= (0 => '1', others => '0');
		wait;
	end process;

end architecture;
