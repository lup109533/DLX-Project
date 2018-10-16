library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ZERO_DETECTOR is
    generic (NBIT: integer);
    port (
        A: in std_logic_vector(NBIT-1 downto 0);
        Z : out std_logic
    );
end ZERO_DETECTOR;

architecture BEHAVIOURAL of ZERO_DETECTOR is
begin
    Z <= '1' when A = (NBIT-1 downto 0 => '0') else '0';
end BEHAVIOURAL;