library ieee;
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_1164.all;

package FP_cmp_ctrl is
	type FP_compare_type	 is (FP_CMP_EQ, FP_CMP_NE, FP_CMP_GE, FP_CMP_GT, FP_CMP_LE, FP_CMP_LT, FP_NO_COMPARE);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.and_reduce;
use ieee.std_logic_misc.or_reduce;
use ieee.numeric_std.all;
use work.FP_cmp_ctrl.all;

entity FP_COMPARATOR is
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
end entity;

architecture structural of FP_COMPARATOR is

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
	signal not_exp2				: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal exp_diff				: std_logic_vector(EXPONENT_SIZE-1 downto 0);
	signal mant1				: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal not_mant2			: std_logic_vector(MANTISSA_SIZE   downto 0);
	signal exp_carry			: std_logic;
	signal mant_carry			: std_logic;
	signal sign_is_greater		: std_logic;
	signal sign_is_equal		: std_logic;
	signal exponent_is_greater	: std_logic;
	signal exponent_is_equal	: std_logic;
	signal mantissa_is_greater	: std_logic;
	signal equal				: std_logic;
	signal greater				: std_logic;
	
begin

	-- Compute differences
	not_exp2	<= not EXPONENT2;
	mant1		<= '0' & MANTISSA1;
	not_mant2	<= '1' & not MANTISSA2;
	
	EXP_DIFF_ADD: RCA	generic map (EXPONENT_SIZE)   port map (EXPONENT1, not_exp2,  '1', exp_diff, exp_carry);
	MAN_DIFF_ADD: RCA	generic map (MANTISSA_SIZE+1) port map (mant1,     not_mant2, '1', open,     mant_carry);

	-- Generate control signals from comparison
	sign_is_greater		<= not(SIGN1) and SIGN2;
	sign_is_equal		<= SIGN1 xnor SIGN2;
	exponent_is_greater	<= exp_carry;
	exponent_is_equal	<= not(or_reduce(exp_diff));
	mantissa_is_greater	<= mant_carry;

	equal	<= and_reduce((SIGN1 xnor SIGN2) & (EXPONENT1 xnor EXPONENT2) & (MANTISSA1 xnor MANTISSA2));
	
	greater_eval: process (sign_is_greater, exponent_is_greater, exponent_is_equal, mantissa_is_greater) is
	begin
		if (sign_is_greater = '1') then
			greater <= '1';
		else
			if (sign_is_equal = '0') then
				greater <= '0';
			else
				if (exponent_is_greater = '1') then
					greater <= '1';
				else
					if (exponent_is_equal = '1' and mantissa_is_greater = '1') then
						greater <= '1';
					else
						greater <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	RESULT	<= equal					when (COMPARISON = FP_CMP_EQ) else
			   not equal				when (COMPARISON = FP_CMP_NE) else
			   greater or equal			when (COMPARISON = FP_CMP_GE) else
			   greater					when (COMPARISON = FP_CMP_GT) else
			   not greater				when (COMPARISON = FP_CMP_LE) else
			   not (greater or equal)	when (COMPARISON = FP_CMP_LT) else
			   '0';
	
end architecture;