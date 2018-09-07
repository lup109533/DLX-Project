library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use ieee.std_logic_misc.and_reduce;
use work.DLX_globals.all;

entity FPU is
	generic (OPERAND_SIZE : natural);
	port (
		F1, F2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		OPCODE	: in	FPU_opcode_t;
		O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
	);
end entity;

architecture structural of FPU is

	-- COMPONENTS
	component BOOTH_MULTIPLIER
		generic (N : natural);
		port (
			A, B : in  std_logic_vector(N-1 downto 0);
			P    : out std_logic_vector(2*N-1 downto 0)
		);
	end component;
	
	component FP_MULTIPLICATION_MANAGER_UNIT
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			MANTISSA	: in	std_logic_vector(2*(MANTISSA_SIZE+1)-1 downto 0);
			EXPONENT1	: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			EXPONENT2	: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			SIGN		: in	std_logic;
			NAN			: in	std_logic;
			ZERO		: in	std_logic;
			INF			: in	std_logic;
			PACKED		: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
		);
	end component;

	signal mul1, mul2			: std_logic_vector((FP_MANTISSA_SIZE+1)-1 downto 0);
	signal mul_out				: std_logic_vector(2*(FP_MANTISSA_SIZE+1)-1 downto 0);
	signal int_mul_o			: std_logic_vector(OPERAND_SIZE-1 downto 0);
	
	signal sign1, sign2			: std_logic;
	signal exponent1, exponent2	: std_logic_vector(FP_EXPONENT_SIZE-1 downto 0);
	signal mantissa1, mantissa2	: std_logic_vector(FP_MANTISSA_SIZE-1 downto 0);
	
	signal extended_mantissa1	: std_logic_vector((FP_MANTISSA_SIZE+1)-1 downto 0);
	signal extended_mantissa2	: std_logic_vector((FP_MANTISSA_SIZE+1)-1 downto 0);
	
	signal sign_o				: std_logic;
	signal fp_mul_o				: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal fp_nan_s				: std_logic;
	signal fp_inf_s				: std_logic;
	signal fp_zero_s			: std_logic;
	
	
begin

	-- UNPACK FP
	sign1		<= F1(OPERAND_SIZE-1);
	sign2		<= F2(OPERAND_SIZE-1);
	exponent1	<= F1(EXPONENT_RANGE);
	exponent2	<= F2(EXPONENT_RANGE);
	mantissa1	<= F1(MANTISSA_RANGE);
	mantissa2	<= F2(MANTISSA_RANGE);
	
	---- Extend mantissa to OPERAND_SIZE
	extended_mantissa1(MANTISSA_RANGE)								<= mantissa1;
	extended_mantissa1(FP_MANTISSA_SIZE)							<= '0';--or_reduce(exponent1); -- If exponent all 0s, implicit digit is 0 (gradual underflow), else 1.
	
	extended_mantissa2(MANTISSA_RANGE)								<= mantissa2;
	extended_mantissa2(FP_MANTISSA_SIZE)							<= '0';--or_reduce(exponent2); -- If exponent all 0s, implicit digit is 0 (gradual underflow), else 1.
						  
	---- Sign calculation
	sign_o <= sign1 xor sign2;
	
	---- Detect special FP values
	fp_nan_s	<= (and_reduce(exponent1) and or_reduce(mantissa1)) or (and_reduce(exponent2) and or_reduce(mantissa2));
	fp_inf_s	<= (and_reduce(exponent1) and not(or_reduce(mantissa1))) or (and_reduce(exponent2) and not(or_reduce(mantissa2)));
	fp_zero_s	<= (not(or_reduce(exponent1)) and not(or_reduce(mantissa1))) or (not(or_reduce(exponent2)) and not(or_reduce(mantissa2)));
	

	-- MULTIPLIER
	MUL: BOOTH_MULTIPLIER generic map (FP_MANTISSA_SIZE+1) port map (mul1, mul2, mul_out);
	int_mul_o <= mul_out(OPERAND_SIZE-1 downto 0);
	
	---- Choose multiplier operands (integer or fp)
	mul1 <= F1(FP_MANTISSA_SIZE downto 0) when (OPCODE = INT_MULTIPLY) else extended_mantissa1;
	mul2 <= F2(FP_MANTISSA_SIZE downto 0) when (OPCODE = INT_MULTIPLY) else extended_mantissa2;
	
	---- FP exponent calculation and mantissa rounding
	FP_MUL_MANAGER:	FP_MULTIPLICATION_MANAGER_UNIT	generic map (
														MANTISSA_SIZE	=> FP_MANTISSA_SIZE,
														EXPONENT_SIZE	=> FP_EXPONENT_SIZE
													)
													port map (
														MANTISSA 	=> mul_out(2*(FP_MANTISSA_SIZE+1)-1 downto 0),
														EXPONENT1	=> exponent1,
														EXPONENT2	=> exponent2,
														SIGN		=> sign_o,
														NAN			=> fp_nan_s,
														INF			=> fp_inf_s,
														ZERO		=> fp_zero_s,
														PACKED		=> fp_mul_o
													);
	
	-- OUTPUT MUX
	O <= int_mul_o when (OPCODE = INT_MULTIPLY) else fp_mul_o; -- For now only multiplication

end architecture;