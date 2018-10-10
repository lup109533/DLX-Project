library ieee;
use ieee.std_logic_1164.all;

entity CLA is
	generic (
		OPERAND_SIZE	: natural;
		RADIX			: natural := 2
	);
	port (
		A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
		CIN		: in	std_logic;
		O		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
		C		: out	std_logic
	);
end entity;

architecture structural of CLA is

	component SPARSE_TREE_CARRY_GENERATOR
		generic (
			OPERAND_SIZE	: natural;
			RADIX			: natural := 2
		);
		port (
			A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic;
			CARRY	: out	std_logic_vector((OPERAND_SIZE/4)-1 downto 0)
		);
	end component;

	component RCA
		generic (OPERAND_SIZE : natural);
		port (
			A, B	: in	std_logic_vector(OPERAND_SIZE-1 downto 0);
			CIN		: in	std_logic;
	   		S		: out	std_logic_vector(OPERAND_SIZE-1 downto 0);
			C		: out	std_logic
		);
	end component;

	constant ADDER_SIZE		: natural := 2**RADIX;
	constant NUM_OF_ADDERS	: natural := OPERAND_SIZE/ADDER_SIZE;

	signal carry	: std_logic_vector(NUM_OF_ADDERS downto 0);

begin

	sparse_tree: SPARSE_TREE_CARRY_GENERATOR generic map(OPERAND_SIZE, RADIX) port map(A, B, CIN, carry(NUM_OF_ADDERS downto 1));
	
	carry(0) <= CIN;

	add_stage_gen: for i in 0 to (NUM_OF_ADDERS)-1 generate
		rca_i: RCA generic map (ADDER_SIZE) port map (
							A(ADDER_SIZE*(i+1)-1 downto ADDER_SIZE*i),
							B(ADDER_SIZE*(i+1)-1 downto ADDER_SIZE*i),
							carry(i),
							O(ADDER_SIZE*(i+1)-1 downto ADDER_SIZE*i),
							open);
	end generate;

	C <= carry(NUM_OF_ADDERS);

end architecture;
