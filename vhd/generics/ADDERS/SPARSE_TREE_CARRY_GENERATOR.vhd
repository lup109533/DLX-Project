library ieee;
use ieee.std_logic_1164.all;
use work.globals.log2;

entity SPARSE_TREE_CARRY_GENERATOR is
	generic (
		OPERAND_SIZE	: natural;
		RADIX		: natural := 2
	);
	port (
		A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		CIN	: in	std_logic;
		CARRY	: out	std_logic_vector((OPERAND_SIZE/4)-1 downto 0)
	);
end entity;

architecture structural of SPARSE_TREE_CARRY_GENERATOR is

	component G_BLOCK
		port (
			G_ik	: in	std_logic;
			P_ik	: in	std_logic;
			G_km1j	: in	std_logic;
			G_ij	: out	std_logic
		);
	end component;

	component PG_BLOCK
		port (
			G_ik	: in	std_logic;
			P_ik	: in	std_logic;
			G_km1j	: in	std_logic;
			P_km1j	: in	std_logic;
			G_ij	: out	std_logic;
			P_ij	: out	std_logic
		);
	end component;

	signal op_g, op_p : std_logic_vector(OPERAND_SIZE downto 0);

begin

	-- GENERATE SIGNALS FROM OPERANDS
	op_g(OPERAND_SIZE downto 1)	<= A and B;
	op_g(0)				<= CIN;

	-- PROPAGATE SIGNALS FROM OPERANDS
	op_p(OPERAND_SIZE downto 1)	<= A or B;
	op_p(0)				<= '0';

	-- FIRST RADIX ROWS
	first_g(0) <= op_g;
	first_p(0) <= op_p;
	first_rows_gen: for row in 1 to RADIX generate
		first_columns_gen_i: for column in 0 to OPERAND_SIZE/(2**row)-1 generate

			first_rows_g_block_gen: if (column = 0) generate
				first_rows_g_block_ij: G_BLOCK port map(
								G_ik	=> first_g(row-1)(2*column+1),
								P_ik	=> first_p(row-1)(2*column+1),
								G_km1j	=> first_g(row-1)(2*column),
								G_ij	=> first_g(row)(column)
							);
			end generate;

			first_rows_pg_block_gen: if (column != 0) generate
				first_rows_pg_block_ij: PG_BLOCK port map(
								G_ik	=> first_g(row-1)(2*column+1),
								P_ik	=> first_p(row-1)(2*column+1),
								G_km1j	=> first_g(row-1)(2*column),
								P_km1j	=> first_g(row-1)(2*column),
								G_ij	=> first_g(row)(column)
							);

			end generate;

		end generate;
	end generate;

	-- REMAINDER OF THE TREE
	tree_g(0) <= first_g(RADIX)((OPERAND_SIZE/(2**RADIX))-1 downto 0);
	tree_p(0) <= first_p(RADIX)((OPERAND_SIZE/(2**RADIX))-1 downto 0);
	tree_gen: for row in 1 to (log2(OPERAND_SIZE) - RADIX) generate
		tree_column_gen: for column in 0 to (OPERAND_SIZE/(2**RADIX))-1 generate
			
			tree_g_block: if (column < 2**row) and ((column % (2**row))+1 > 2**(row-1)) generate
				tree_g_block_ij: G_BLOCK port map(
							G_ik	=> tree_g(row-1)(column),	-- Same column
							P_ik	=> tree_p(row-1)(column),
							G_km1j	=> tree_g(row-1)(2**row-1),	-- G block of last row
							G_ij	=> tree_g(row)(column)
						);
			end generate;

			tree_pg_block: if (column >= 2**row) and ((column % (2**row))+1 > 2**(row-1)) generate
				tree_g_block_ij: G_BLOCK port map(
							G_ik	=> tree_g(row-1)(column),					-- Same column
							P_ik	=> tree_p(row-1)(column),
							G_km1j	=> tree_g(row-1)(column - ((column % 2**row) - 2**row-1)),	-- First PG block on the rightside columns
							P_km1j	=> tree_p(row-1)(column - ((column % 2**row) - 2**row-1));
							G_ij	=> tree_g(row)(column)
						);
			end generate;

			tree_propagate: if ((column % (2**row))+1 <= 2**(row-1)) generate
				tree_g(row)(column) <= tree_g(row-1)(column);
				tree_p(row)(column) <= tree_p(row-1)(column);
			end generate;

		end generate;
	end generate;

	CARRY <= tree_g(log2(OPERAND_SIZE) - RADIX);

end architecture;
