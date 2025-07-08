---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;


package const_package is
---------------------------------------------------------
--	Registers constants
---------------------------------------------------------
	constant RA_REGISTER : 		STD_LOGIC_VECTOR(4 DOWNTO 0) := "11111"; -- Return Address Register

---------------------------------------------------------
--	IDECODE constants
---------------------------------------------------------
	constant R_TYPE_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
	constant LW_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "100011";
	constant SW_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "101011";
	constant BEQ_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000100";
	constant ANDI_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "001100";
	constant ORI_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "001101";
	constant ADDI_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "001000";
	constant MUL_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "011100";

	--------------------------------------- LOGICAL
	constant XORI_OPC :  	STD_LOGIC_VECTOR(5 DOWNTO 0) := "001110";

	--------------------------------------- DATA
	-- move $1,$2			( R-type = ADDU $rs, $0, $rd )
	-- load address (la)    ( I-type = ADDI $rs, $0, address
	-- load immediate (li)  ( I-type = ADDIU $rs, $0, immediate)
	constant ADDUI_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "001001";
	-- loal upper immediate (I-type = lui $1,100 )
	constant LUI_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "001111";

	--------------------------------------- BRANCH
	constant BNE_OPC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "000101";
	-- branch on ge         bge $rs, $rt, offset = (slt $rs,$rs,$rt) and (beq $rs,$0,offset+2)
	-- branch on lt         blt $rs, $rt, offset = (slt $rs,$rs,$rt) and (beq $rs,$0,offset+2)

	-------------------------------------- COMPARISON
	constant SLTI_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "001010";

	-------------------------------------- JUMP
	constant J_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "000010";
	-- jump register (jr) 	(R-type = JR $rs)
	constant JAL_OPC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "000011";


--------------------------------------------------------	
 
---------------------------------------------------------
--	ALU control constants
---------------------------------------------------------

	constant R_TYPE_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; -- R-type
	constant SUB_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "001"; -- beq , bne , slti
	constant ADD_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "010"; -- addi, lw, sw
	constant AND_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "011"; -- andi
	constant OR_ALU_CTRL : 		    STD_LOGIC_VECTOR(2 DOWNTO 0) := "100"; -- ori
	constant XOR_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "101"; -- xori
	constant LUI_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "110"; -- lui
	constant MUL_ALU_CTRL : 		STD_LOGIC_VECTOR(2 DOWNTO 0) := "111"; -- mul

---------------------------------------------------------
--	ALU operations constants
---------------------------------------------------------

	constant ADD_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000"; -- ADD
	constant SUB_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001"; -- SUB
	constant AND_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010"; -- AND
	constant OR_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011"; -- OR
	constant XOR_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100"; -- XOR
	constant MUL_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101"; -- MUL
	constant SLL_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110"; -- SHL
	constant SRL_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111"; -- SHR
	constant LU_ALU_OP : 		STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000"; -- LU

---------------------------------------------------------
--	R-Type functions constants
---------------------------------------------------------
	constant SLL_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "000000";
	constant SRL_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "000010";
	constant JR_FUNC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "001000";
	constant ADD_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "100000";
	constant ADDU_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "100001";
	constant SUB_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "100010";
	constant AND_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "100100";
	constant OR_FUNC : 		STD_LOGIC_VECTOR(5 DOWNTO 0) := "100101";
	constant XOR_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "100110";
	constant NOR_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "100111";
	constant SLT_FUNC : 	STD_LOGIC_VECTOR(5 DOWNTO 0) := "101010";

end const_package;

