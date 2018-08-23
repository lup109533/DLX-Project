library IEEE;
use IEEE.std_logic_1164.all;
use WORK.constants.all;

entity BOOTH_ENCODER is
	port (
		I : in  std_logic_vector(2 downto 0);
		O : out std_logic_vector(2 downto 0)
	);
end BOOTH_ENCODER;

architecture BEHAVIORAL of BOOTH_ENCODER is
begin

	process (I) is begin
		case I is

			when "000" => O <= "000"; -- A = 0
			when "001" => O <= "001"; -- B = +A
			when "010" => O <= "001"; -- B = +A
			when "011" => O <= "011"; -- D = +2A
			when "100" => O <= "100"; -- E = -2A
			when "101" => O <= "010"; -- C = -A
			when "110" => O <= "010"; -- C = -A
			when "111" => O <= "000"; -- A = 0

			when others => O <= "000";

		end case;
	end process;

end architecture;
