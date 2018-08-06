library ieee;
use ieee.std_logic_1164.all;
use work.lu_ctrl.all;

entity LOGIC_UNIT is
	generic (OPERAND_SIZE : natural);
	port (
		CTRL	: in	lu_ctrl_t;
		R1, R2	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		O	: out	std_logic_vector(OPERAND_SIZE-1 downto 0)
	);
end entity;

architecture structural of LOGIC_UNIT is

	signal S0, S1, S2, S3 : std_logic_vector(OPERAND_SIZE-1 downto 0);
	signal L0, L1, L2, L3 : std_logic_vector(OPERAND_SIZE-1 downto 0);

begin

	-- EXTEND CTRL SIGNALS
	S0 <= (others => CTRL(3));
	S1 <= (others => CTRL(2));
	S2 <= (others => CTRL(1));
	S3 <= (others => CTRL(0));

	-- MAKE L* SIGNALS
	L0 <= not(S0 and not(R1) and not(R2));
	L1 <= not(S1 and not(R1) and    (R2));
	L2 <= not(S2 and    (R1) and not(R2));
	L3 <= not(S3 and    (R1) and    (R2));

	-- OUTPUT SIGNAL
	O <= not(L0 and L1 and L2 and L3);

end architecture;
