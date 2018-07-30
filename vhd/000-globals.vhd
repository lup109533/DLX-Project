library ieee;
use ieee.std_logic_1164.all;

package globals is
	function log2	(n   : integer)	return integer;
	function max	(a,b : integer)	return integer;
	function min	(a,b : integer)	return integer;
end globals;

package body globals is
	-- LOG2
	function log2(n : integer) return integer is
		variable ret : integer := 0;
		variable tmp : integer;
	begin
		tmp := n;
		while (tmp > 1) loop
			tmp := tmp / 2;
			ret := ret + 1;
		end loop;
		return tmp;
	end function;
	-- MAX
	function max(a,b : integer) return integer is
	begin
		if (a > b) then
			return a;
		else
			return b;
		end if;
	end function;
	-- MIN
	function min(a,b : integer) return integer is
	begin
		if (a < b) then
			return a;
		else
			return b;
		end if;
	end function;

end globals;
