library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity Shifter is
	generic (
		NBIT: integer := 32
	);
	port (
		left_right: in std_logic;	-- LEFT/RIGHT
		logic_Arith : in std_logic;	-- LOGIC/ARITHMETIC, will be used in signed/unsigned instructions
		a : in std_logic_vector(NBIT-1 downto 0); --data to be shift
		b : in std_logic_vector(NBIT-1 downto 0); --# of bits to be shifted
		o : out std_logic_vector(NBIT-1 downto 0)
	);
end Shifter;


architecture behavior of Shifter is

	constant B_SIZE : integer := 5; --max shift is 32, need at most 5 digit to describe
	
begin

	P0: process (a, b, left_right, logic_arith) is
	begin
		
			if left_right = '1' then 			--right

				if logic_arith = '1' then 			--arith
					o <= to_StdLogicVector((to_bitvector(a)) sra (to_integer(unsigned(b(B_SIZE-1 downto 0)))));
				else					  			--logic
					o <= to_StdLogicVector((to_bitvector(a)) srl (to_integer(unsigned(b(B_SIZE-1 downto 0)))));
				end if;				
			else								--left

				if logic_arith = '1' then			--arith
					o <= to_StdLogicVector((to_bitvector(a)) sla (to_integer(unsigned(b(B_SIZE-1 downto 0)))));
				else								--logic
					o <= to_StdLogicVector((to_bitvector(a)) sll (to_integer(unsigned(b(B_SIZE-1 downto 0)))));
				end if;
			end if;
	end process;

end behavior;