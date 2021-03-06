library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.DLX_globals.all;

entity TB_FPU is
end entity;

architecture test of TB_FPU is

	function to_std_logic(i : in integer) return std_logic is
	begin
		if i = 0 then
			return '0';
		end if;
		return '1';
	end function;

	component FPU
		generic (OPERAND_SIZE : natural);
		port (
			FUNC	: in	fpu_opcode_t;
			F1, F2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
		);
	end component;
	
	constant OPERAND_SIZE	: natural := 32;
	constant MAX_F1			: natural := 2**(OPERAND_SIZE/7)-1;
	constant MAX_F2			: natural := 2**(OPERAND_SIZE/7)-1;
	
	signal FUNC_s		: FPU_opcode_t := INT_MULTIPLY;
	signal F1_s, F2_s	: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal O_s			: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal OK			: boolean;
	
begin

	-- UUT
	UUT: FPU generic map(OPERAND_SIZE) port map(FUNC_s, F1_s, F2_s, O_s);
	OK <= to_integer(unsigned(F1_s))*to_integer(unsigned(F2_s)) = to_integer(unsigned(O_s));

	-- STIMULUS
	stimulus: process is
		variable F1_v, F2_v		: integer;
		variable seed1, seed2	: positive;
		variable rand			: real;
		variable exp_range		: real := real(2**8-1);
		variable mant_range		: real := real(2**23-1);
	begin
		
		FUNC_s <= FP_ADD;
		
		for i in 0 to 10 loop
			-- F1
			uniform(seed1, seed2, rand);
			F1_s(OPERAND_SIZE-1)	<= to_std_logic(integer(rand));
			uniform(seed1, seed2, rand);
			F1_s(EXPONENT_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*exp_range), 8));
			uniform(seed1, seed2, rand);
			F1_s(MANTISSA_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*mant_range), 23));
			-- F2
			uniform(seed1, seed2, rand);
			F2_s(OPERAND_SIZE-1)	<= to_std_logic(integer(rand));
			uniform(seed1, seed2, rand);
			F2_s(EXPONENT_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*exp_range), 8));
			uniform(seed1, seed2, rand);
			F2_s(MANTISSA_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*mant_range), 23));
			
			wait for 1 ns;
		end loop;
		
		FUNC_s <= FP_SUB;
		
		for i in 0 to 10 loop
			-- F1
			uniform(seed1, seed2, rand);
			F1_s(OPERAND_SIZE-1)	<= to_std_logic(integer(rand));
			uniform(seed1, seed2, rand);
			F1_s(EXPONENT_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*exp_range), 8));
			uniform(seed1, seed2, rand);
			F1_s(MANTISSA_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*mant_range), 23));
			-- F2
			uniform(seed1, seed2, rand);
			F2_s(OPERAND_SIZE-1)	<= to_std_logic(integer(rand));
			uniform(seed1, seed2, rand);
			F2_s(EXPONENT_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*exp_range), 8));
			uniform(seed1, seed2, rand);
			F2_s(MANTISSA_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*mant_range), 23));
			
			wait for 1 ns;
		end loop;
		
		FUNC_s <= FP_MULTIPLY;
		
		for i in 0 to 10 loop
			-- F1
			uniform(seed1, seed2, rand);
			F1_s(OPERAND_SIZE-1)	<= to_std_logic(integer(rand));
			uniform(seed1, seed2, rand);
			F1_s(EXPONENT_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*exp_range), 8));
			uniform(seed1, seed2, rand);
			F1_s(MANTISSA_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*mant_range), 23));
			-- F2
			uniform(seed1, seed2, rand);
			F2_s(OPERAND_SIZE-1)	<= to_std_logic(integer(rand));
			uniform(seed1, seed2, rand);
			F2_s(EXPONENT_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*exp_range), 8));
			uniform(seed1, seed2, rand);
			F2_s(MANTISSA_RANGE)	<= std_logic_vector(to_unsigned(integer(rand*mant_range), 23));
			
			wait for 1 ns;
		end loop;
		
		wait;
	end process;

end architecture;
