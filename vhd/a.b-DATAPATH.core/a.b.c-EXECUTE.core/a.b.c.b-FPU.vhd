library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.or_reduce;
use ieee.std_logic_misc.and_reduce;
use work.DLX_globals.all;
use work.FP_cmp_ctrl.all;

entity FPU is
	generic (OPERAND_SIZE : natural);
	port (
		FUNC		: in	FPU_opcode_t;
		F1, F2		: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		O			: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
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
	
	component FP_ADD_SUB
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			ADD_SUB			: in	std_logic; -- 0 = add / 1 = sub
			SIGN1			: in	std_logic;
			SIGN2			: in	std_logic;
			EXPONENT1		: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			EXPONENT2		: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			MANTISSA1		: in	std_logic_vector(MANTISSA_SIZE-1 downto 0);
			MANTISSA2		: in	std_logic_vector(MANTISSA_SIZE-1 downto 0);
			RESULT			: out	std_logic_vector((1 + EXPONENT_SIZE + MANTISSA_SIZE)-1 downto 0)
		);
	end component;
	
	component F2I_CONVERTER
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			MANTISSA	: in	std_logic_vector(MANTISSA_SIZE-1 downto 0);
			EXPONENT	: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			SIGN		: in	std_logic;
			CONV		: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
		);
	end component;
	
	component I2F_CONVERTER
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			DIN		: in	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0);
			CONV	: out	std_logic_vector((MANTISSA_SIZE + EXPONENT_SIZE + 1)-1 downto 0)
		);
	end component;
	
	component FP_COMPARATOR
		generic (
			MANTISSA_SIZE	: natural;
			EXPONENT_SIZE	: natural
		);
		port (
			COMPARISON		: in	FP_compare_type;
			SIGN1			: in	std_logic;
			SIGN2			: in	std_logic;
			EXPONENT1		: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			EXPONENT2		: in	std_logic_vector(EXPONENT_SIZE-1 downto 0);
			MANTISSA1		: in	std_logic_vector(MANTISSA_SIZE-1 downto 0);
			MANTISSA2		: in	std_logic_vector(MANTISSA_SIZE-1 downto 0);
			RESULT			: out	std_logic
		);
	end component;

	signal mul1, mul2			: std_logic_vector((FP_MANTISSA_SIZE+1)-1 downto 0);
	signal mul_out				: std_logic_vector(2*(FP_MANTISSA_SIZE+1)-1 downto 0);
	signal int_mul_o			: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal addsub_o				: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal f2i_o				: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal i2f_o				: std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal conv_o				: std_logic;
	signal conv_ext_o			: std_logic_vector(OPERAND_SIZE-1 downto 0);
	
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
	signal add_sub				: std_logic;
	signal cmp_type				: FP_compare_type;
	
begin

	-- UNPACK FP
	sign1		<= F1(OPERAND_SIZE-1);
	sign2		<= F2(OPERAND_SIZE-1);
	exponent1	<= F1(EXPONENT_RANGE);
	exponent2	<= F2(EXPONENT_RANGE);
	mantissa1	<= F1(MANTISSA_RANGE);
	mantissa2	<= F2(MANTISSA_RANGE);
	
	---- Extend mantissa to OPERAND_SIZE
	extended_mantissa1(MANTISSA_RANGE)		<= mantissa1;
	extended_mantissa1(FP_MANTISSA_SIZE)	<= '0';--or_reduce(exponent1); -- If exponent all 0s, implicit digit is 0 (gradual underflow), else 1.
	
	extended_mantissa2(MANTISSA_RANGE)		<= mantissa2;
	extended_mantissa2(FP_MANTISSA_SIZE)	<= '0';--or_reduce(exponent2); -- If exponent all 0s, implicit digit is 0 (gradual underflow), else 1.
						  
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
	mul1 <= F1(FP_MANTISSA_SIZE downto 0) when (FUNC = INT_MULTIPLY) else extended_mantissa1;
	mul2 <= F2(FP_MANTISSA_SIZE downto 0) when (FUNC = INT_MULTIPLY) else extended_mantissa2;
	
	---- FP exponent calculation and mantissa rounding
	FP_MUL_MANAGER:	FP_MULTIPLICATION_MANAGER_UNIT	generic map (
														MANTISSA_SIZE	=> FP_MANTISSA_SIZE,
														EXPONENT_SIZE	=> FP_EXPONENT_SIZE
													)
													port map (
														MANTISSA 	=> mul_out,
														EXPONENT1	=> exponent1,
														EXPONENT2	=> exponent2,
														SIGN		=> sign_o,
														NAN			=> fp_nan_s,
														INF			=> fp_inf_s,
														ZERO		=> fp_zero_s,
														PACKED		=> fp_mul_o
													);
	
	-- ADDER/SUBTRACTOR
	add_sub <= '1' when (FUNC = FP_SUB) else '0';
	ADDSUB: FP_ADD_SUB	generic map (
							MANTISSA_SIZE	=> FP_MANTISSA_SIZE,
							EXPONENT_SIZE	=> FP_EXPONENT_SIZE
						)
						port map (
							ADD_SUB		=> add_sub,
							SIGN1		=> sign1,
							SIGN2		=> sign2,
							MANTISSA1	=> mantissa1,
							MANTISSA2	=> mantissa2,
							EXPONENT1	=> exponent1,
							EXPONENT2	=> exponent2,
							RESULT		=> addsub_o
						);
	
	-- CONVERTERS
	-- FP to INT
	F2I: F2I_CONVERTER	generic map (
							MANTISSA_SIZE	=> FP_MANTISSA_SIZE,
							EXPONENT_SIZE	=> FP_EXPONENT_SIZE
						)
						port map (
							MANTISSA	=> mantissa1,
							EXPONENT	=> exponent1,
							SIGN		=> sign1,
							CONV		=> f2i_o
						);
						
	-- INT to FP					
	I2F: I2F_CONVERTER	generic map (
							MANTISSA_SIZE	=> FP_MANTISSA_SIZE,
							EXPONENT_SIZE	=> FP_EXPONENT_SIZE
						)
						port map (
							DIN		=> F1,
							CONV	=> i2f_o
						);
						
	-- COMPARATOR
	CMP: FP_COMPARATOR	generic map (
							MANTISSA_SIZE	=> FP_MANTISSA_SIZE,
							EXPONENT_SIZE	=> FP_EXPONENT_SIZE
						)
						port map (
							COMPARISON	=> cmp_type,
							SIGN1		=> sign1,
							SIGN2		=> sign2,
							MANTISSA1	=> mantissa1,
							MANTISSA2	=> mantissa2,
							EXPONENT1	=> exponent1,
							EXPONENT2	=> exponent2,
							RESULT		=> conv_o
						);
						
	conv_ext_o(0)						<= conv_o;
	conv_ext_o(OPERAND_SIZE-1 downto 1)	<= (others => '0');
	
	cmp_type	<= FP_CMP_EQ when (FUNC = FP_COMPARE_EQ) else
				   FP_CMP_NE when (FUNC = FP_COMPARE_NE) else
				   FP_CMP_GE when (FUNC = FP_COMPARE_GE) else
				   FP_CMP_GT when (FUNC = FP_COMPARE_GT) else
				   FP_CMP_LE when (FUNC = FP_COMPARE_LE) else
				   FP_CMP_LT when (FUNC = FP_COMPARE_LT) else
				   FP_NO_COMPARE;
	
	-- OUTPUT MUX
	O 	<=	int_mul_o when (FUNC = INT_MULTIPLY)              else
			fp_mul_o  when (FUNC = FP_MULTIPLY)               else
			addsub_o  when (FUNC = FP_ADD or FUNC = FP_SUB) else
			f2i_o     when (FUNC = F2I_CONVERT)               else
			i2f_o     when (FUNC = I2F_CONVERT)               else
			conv_ext_o;

end architecture;