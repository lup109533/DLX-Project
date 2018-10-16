library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.DLX_globals.all;

package instr_gen is

	type opcodes is	(I_ALU_I,
					 I_FPU_I,
					 I_J,
					 I_JAL,
					 I_BEQZ,
					 I_BNEZ,
					 I_BFPT,
					 I_BFPF,
					 I_ADDI,
					 I_ADDUI,
					 I_SUBI,
					 I_SUBUI,
					 I_ANDI,
					 I_ORI,
					 I_XORI,
					 I_LHI,
					 I_RFE,
					 I_TRAP,
					 I_JR,
					 I_JALR,
					 I_SLLI,
					 I_NOP,
					 I_SRLI,
					 I_SRAI,
					 I_SEQI,
					 I_SNEI,
					 I_SLTI,
					 I_SGTI,
					 I_SLEI,
					 I_SGEI,
					 I_LB,
					 I_LH,
					 I_LW,
					 I_LBU,
					 I_LHU,
					 I_LF0,
					 I_LD,
					 I_SB,
					 I_SH,
					 I_SW,
					 I_SF,
					 I_SD,
					 I_ITLB,
					 I_SLTUI,
					 I_SGTUI,
					 I_SLEUI,
					 I_SGEUI
					);
					
	type alu_codes is	(A_SHLL,
						 A_SHRL,
						 A_SHRA,
						 A_ADD,
						 A_ADDU,
						 A_SUB0,
						 A_SUBU,
						 A_LAND,
						 A_LOR,
						 A_LXOR,
						 A_SEQ,
						 A_SNE,
						 A_SLT,
						 A_SGT,
						 A_SLE,
						 A_SGE,
						 A_MOVI2S,
						 A_MOVS2I,
						 A_MOVF,
						 A_MOVD,
						 A_MOVFP2I,
						 A_MOVI2FP,
						 A_MOVI2T,
						 A_MOVT2I,
						 A_SLTU,
						 A_SGTU,
						 A_SLEU,
						 A_SGEU
						);
	
	type fpu_codes	is	(F_ADDF,
						 F_SUBF,
						 F_MULF,
						 F_DIVF,
						 F_ADDD,
						 F_SUBD,
						 F_MULD,
						 F_DIVD,
						 F_CVTF2D,
						 F_CVTF2I,
						 F_CVTD2F,
						 F_CVTI2F,
						 F_CVTI2D,
						 F_MUL,
						 F_DIV,
						 F_EQF,
						 F_NEF,
						 F_LTF,
						 F_GTF,
						 F_LEF,
						 F_GEF,
						 F_MULU,
						 F_DIVU,
						 F_EQD,
						 F_NED,
						 F_LTD,
						 F_GTD,
						 F_LED,
						 F_GED
						);

	function opcode_to_std_logic_v(o: opcodes) return std_logic_vector;
	function alu_to_std_logic_v(o: alu_codes)  return std_logic_vector;
	function fpu_to_std_logic_v(o: fpu_codes)  return std_logic_vector;

end package;

package body instr_gen is

	function opcode_to_std_logic_v(o: opcodes) return std_logic_vector is
	begin
		case(o) is
			when I_ALU_I =>
				return ALU_I;
			when I_FPU_I =>
				return FPU_I;
			when I_J =>
				return J;
			when I_JAL =>
				return JAL;
			when I_BEQZ =>
				return BEQZ;
			when I_BNEZ =>
				return BNEZ;
			when I_BFPT =>
				return BFPT;
			when I_BFPF =>
				return BFPF;
			when I_ADDI =>
				return ADDI;
			when I_ADDUI =>
				return ADDUI;
			when I_SUBI =>
				return SUBI;
			when I_SUBUI =>
				return SUBUI;
			when I_ANDI =>
				return ANDI;
			when I_ORI =>
				return ORI;
			when I_XORI =>
				return XORI;
			when I_LHI =>
				return LHI;
			when I_RFE =>
				return RFE;
			when I_TRAP =>
				return TRAP;
			when I_JR =>
				return JR;
			when I_JALR =>
				return JALR;
			when I_SLLI =>
				return SLLI;
			when I_NOP =>
				return NOP;
			when I_SRLI =>
				return SRLI;
			when I_SRAI =>
				return SRAI;
			when I_SEQI =>
				return SEQI;
			when I_SNEI =>
				return SNEI;
			when I_SLTI =>
				return SLTI;
			when I_SGTI =>
				return SGTI;
			when I_SLEI =>
				return SLEI;
			when I_SGEI =>
				return SGEI;
			when I_LB =>
				return LB;
			when I_LH =>
				return LH;
			when I_LW =>
				return LW;
			when I_LBU =>
				return LBU;
			when I_LHU =>
				return LHU;
			when I_LF0 =>
				return LF0;
			when I_LD =>
				return LD;
			when I_SB =>
				return SB;
			when I_SH =>
				return SH;
			when I_SW =>
				return SW;
			when I_SF =>
				return SF;
			when I_SD =>
				return SD;
			when I_ITLB =>
				return ITLB;
			when I_SLTUI =>
				return SLTUI;
			when I_SGTUI =>
				return SGTUI;
			when I_SLEUI =>
				return SLEUI;
			when I_SGEUI =>
				return SGEUI;
		end case;
	end function;
	
	function alu_to_std_logic_v(o: alu_codes)  return std_logic_vector is
	begin
		case(o) is
			when A_SHLL =>
				return SHLL;
			when A_SHRL =>
				return SHRL;
			when A_SHRA =>
				return SHRA;
			when A_ADD =>
				return ADD;
			when A_ADDU =>
				return ADDU;
			when A_SUB0 =>
				return SUB0;
			when A_SUBU =>
				return SUBU;
			when A_LAND =>
				return LAND;
			when A_LOR =>
				return LOR;
			when A_LXOR =>
				return LXOR;
			when A_SEQ =>
				return SEQ;
			when A_SNE =>
				return SNE;
			when A_SLT =>
				return SLT;
			when A_SGT =>
				return SGT;
			when A_SLE =>
				return SLE;
			when A_SGE =>
				return SGE;
			when A_MOVI2S =>
				return MOVI2S;
			when A_MOVS2I =>
				return MOVS2I;
			when A_MOVF =>
				return MOVF;
			when A_MOVD =>
				return MOVD;
			when A_MOVFP2I =>
				return MOVFP2I;
			when A_MOVI2FP =>
				return MOVI2FP;
			when A_MOVI2T =>
				return MOVI2T;
			when A_MOVT2I =>
				return MOVT2I;
			when A_SLTU =>
				return SLTU;
			when A_SGTU =>
				return SGTU;
			when A_SLEU =>
				return SLEU;
			when A_SGEU =>
				return SGEU;
		end case;
	end function;
	
	function fpu_to_std_logic_v(o: fpu_codes)  return std_logic_vector is
	begin
		case(o) is
			when F_ADDF =>
				return ADDF;
			when F_SUBF =>
				return SUBF;
			when F_MULF =>
				return MULF;
			when F_DIVF =>
				return DIVF;
			when F_ADDD =>
				return ADDD;
			when F_SUBD =>
				return SUBD;
			when F_MULD =>
				return MULD;
			when F_DIVD =>
				return DIVD;
			when F_CVTF2D =>
				return CVTF2D;
			when F_CVTF2I =>
				return CVTF2I;
			when F_CVTD2F =>
				return CVTD2F;
			when F_CVTI2F =>
				return CVTI2F;
			when F_CVTI2D =>
				return CVTI2D;
			when F_MUL =>
				return MUL;
			when F_DIV =>
				return DIV;
			when F_EQF =>
				return EQF;
			when F_NEF =>
				return NEF;
			when F_LTF =>
				return LTF;
			when F_GTF =>
				return GTF;
			when F_LEF =>
				return LEF;
			when F_GEF =>
				return GEF;
			when F_MULU =>
				return MULU;
			when F_DIVU =>
				return DIVU;
			when F_EQD =>
				return EQD;
			when F_NED =>
				return NED;
			when F_LTD =>
				return LTD;
			when F_GTD =>
				return GTD;
			when F_LED =>
				return LED;
			when F_GED =>
				return GED;
		end case;
	end function;

end package body;
