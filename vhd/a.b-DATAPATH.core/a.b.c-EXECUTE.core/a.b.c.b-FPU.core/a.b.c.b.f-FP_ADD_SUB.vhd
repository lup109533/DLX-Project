library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.and_reduce;
use ieee.std_logic_misc.or_reduce;
use ieee.numeric_std.all;

entity FP_ADD_SUB is
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
end entity;

architecture structural of FP_ADD_SUB is

	-- COMPONENTS
	component RCA
		generic (OPERAND_SIZE : natural);
		port (
			A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic;
			S		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			C		: out	std_logic
		);
	end component;

	-- SIGNALS
	constant FP_SIZE				: natural := 1 + EXPONENT_SIZE + MANTISSA_SIZE;
	constant INF_EXP				: std_logic_vector(EXPONENT_SIZE-1 downto 0) := (others => '1');
	constant ZERO_EXP				: std_logic_vector(EXPONENT_SIZE-1 downto 0) := (others => '0');
	constant ZERO_MANT				: std_logic_vector(MANTISSA_SIZE-1 downto 0) := (others => '0');
	constant NONZERO_MANT			: std_logic_vector(MANTISSA_SIZE-1 downto 0) := (others => '1');
	
	signal sign1_s					: std_logic;
	signal sign2_s					: std_logic;
	signal sign_out					: std_logic;
	signal is_inf1					: std_logic;
	signal is_inf2					: std_logic;
	signal is_nan1					: std_logic;
	signal is_nan2					: std_logic;
	
	signal not_exp2					: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal biggest_exp				: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal exp_diff					: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal exp_out					: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal diff_sel					: std_logic;
	signal correct_exp				: std_logic;
	
	signal smallest_mant			: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal mant1_s					: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal mant2_s					: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal mant_out					: std_logic_vector(MANTISSA_SIZE-1 downto 0);
	signal not_mant1_s				: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal not_mant2_s				: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant1_compl_s			: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant2_compl_s			: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant1_signed_s			: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant2_signed_s			: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant_addsub_out			: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal not_mant_addsub_out		: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant_addsub_compl		: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal mant_addsub_carry		: std_logic;
	signal mant_addsub_out_sign		: std_logic;
	signal shift_amount				: integer range 0 to 2**EXPONENT_SIZE-1;
	
	signal res_out					: std_logic_vector(FP_SIZE-1 downto 0);
	signal out_is_zero				: std_logic;
	signal out_is_inf				: std_logic;
	signal out_is_nan				: std_logic;
	
begin

	-- Get correct signs
	sign1_s		<= SIGN1             when (diff_sel = '0') else SIGN2 xor ADD_SUB;
	sign2_s		<= SIGN2 xor ADD_SUB when (diff_sel = '0') else SIGN1;
	
	-- Check particular values
	is_inf1		<= and_reduce(EXPONENT1) and not(or_reduce(MANTISSA1));
	is_inf2		<= and_reduce(EXPONENT2) and not(or_reduce(MANTISSA2));
	
	is_nan1		<= and_reduce(EXPONENT1) and or_reduce(MANTISSA1);
	is_nan2		<= and_reduce(EXPONENT2) and or_reduce(MANTISSA2);
	
	-- EXPONENT
	-- Compute exponent difference
	not_exp2	<= not(EXPONENT2);
	EXP_DIFF_ADD: RCA generic map (EXPONENT_SIZE) port map (EXPONENT1, not_exp2, '1', exp_diff, diff_sel);
	
	-- Select biggest exponent
	biggest_exp	<= EXPONENT1 when (diff_sel = '1') else EXPONENT2;
	
	-- Add 1 to exponent if necessary (overflow on the mantissa)
	EXP_CORR_ADD: RCA generic map (EXPONENT_SIZE) port map (biggest_exp, (others => '0'), correct_exp, exp_out, open);
	
	-- MANTISSA
	-- Select smallest mantissa
	smallest_mant	<= MANTISSA1 when (diff_sel = '0') else MANTISSA2;
	mant2_s			<= MANTISSA2 when (diff_sel = '0') else MANTISSA1;
	
	-- Shift smallest mantissa to the right according to exp_diff
	shift_amount	<= to_integer(unsigned(exp_diff)) when (diff_sel = '1') else to_integer(unsigned(not exp_diff) + 1);
	mant1_s			<= std_logic_vector(shift_right(unsigned(smallest_mant), shift_amount));
	
	-- Complement according to signal
	mant1_signed_s	<= '0' & mant1_s when (sign1_s = '0') else mant1_compl_s;
	mant2_signed_s	<= '0' & mant2_s when (sign2_s = '0') else mant2_compl_s;
	
	not_mant1_s	<= '1' & not mant1_s;
	not_mant2_s	<= '1' & not mant2_s;
	
	MANT_COMPL_ADD1: RCA generic map (MANTISSA_SIZE+1) port map (not_mant1_s, (others => '0'), '1', mant1_compl_s, open);
	MANT_COMPL_ADD2: RCA generic map (MANTISSA_SIZE+1) port map (not_mant2_s, (others => '0'), '1', mant2_compl_s, open);
	
	-- Add or subtract
	MANTISSA_ADDSUB: RCA generic map (MANTISSA_SIZE+1) port map (mant1_signed_s, mant2_signed_s, '0', mant_addsub_out, mant_addsub_carry);
	
	-- Calculate sign of output and complement/shift if necessary
	mant_addsub_out_sign	<= sign2_s; -- Sign of biggest operand
	correct_exp				<= mant_addsub_out_sign xor mant_addsub_out(MANTISSA_SIZE);
	
	not_mant_addsub_out	<= not mant_addsub_out;
	MANT_ADDSUB_COMPL_ADD: RCA generic map (MANTISSA_SIZE+1) port map (not_mant_addsub_out, (others => '0'), '1', mant_addsub_compl, open);
	
	mant_out 				<= mant_addsub_out(MANTISSA_SIZE-1 downto 0)	when (mant_addsub_out_sign = '0' and correct_exp = '0')	else
							   mant_addsub_out(MANTISSA_SIZE   downto 1)	when (mant_addsub_out_sign = '0' and correct_exp = '1')	else
							   mant_addsub_compl(MANTISSA_SIZE-1 downto 0)	when (mant_addsub_out_sign = '1' and correct_exp = '0')	else
							   mant_addsub_compl(MANTISSA_SIZE   downto 1);
							   
	-- OUTPUT
	-- Pack normal output
	sign_out	<= mant_addsub_out_sign;
	res_out		<= sign_out & exp_out & mant_out;
	
	-- Check exceptions
	out_is_zero	<= not(or_reduce(mant_out));
	out_is_inf	<= and_reduce(exp_out) or (is_inf1 xor is_inf2) or (is_inf1 and is_inf2 and (sign1_s xnor sign2_s));
	out_is_nan	<= (is_inf1 and is_inf2 and (sign1_s xor sign2_s)) or (is_nan1 or is_nan2);
	
	-- Select output
	RESULT	<= sign_out & INF_EXP  & NONZERO_MANT	when (out_is_nan  = '1') else
			   sign_out & INF_EXP  & ZERO_MANT		when (out_is_inf  = '1') else
			   sign_out & ZERO_EXP & ZERO_MANT		when (out_is_zero = '1') else
			   res_out;
	
end architecture;