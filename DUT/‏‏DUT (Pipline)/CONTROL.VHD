---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;


ENTITY control IS
   PORT( 	
		opcode_i 			: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);
		func_i 				: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);

		IF_ID_flush_ctrl_o 	: OUT STD_LOGIC;
		PCSrc_o 			: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		Branch_ctrl_o 		: OUT 	STD_LOGIC;

		-- WB Controls
		RegDst_ctrl_o 		: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
		RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
		LinkPC_ctrl_o 		: OUT 	STD_LOGIC;

		-- MEM Controls
		MemRead_ctrl_o 		: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;

		-- EX Controls
		ALUSrcB_ctrl_o 		: OUT 	STD_LOGIC;
		ALUSrcA_ctrl_o 		: OUT 	STD_LOGIC;
		ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(2 DOWNTO 0)
	);
END control;

ARCHITECTURE behavior OF control IS
	SIGNAL  rtype_w, lw_w, sw_w, beq_w, itype_imm_w : STD_LOGIC;
BEGIN           
	-- Code to generate control signals using opcode bits
	rtype_w 			<=  '1'	WHEN	opcode_i = R_TYPE_OPC 						ELSE '0';
	lw_w          		<=  '1'	WHEN  	opcode_i = LW_OPC  							ELSE '0';
 	sw_w          		<=  '1'	WHEN  	opcode_i = SW_OPC  							ELSE '0';
   	beq_w         		<=  '1'	WHEN  	opcode_i = BEQ_OPC  						ELSE '0';
	itype_imm_w			<=	'1'	WHEN	((opcode_i = ADDI_OPC) or 
										(opcode_i = ORI_OPC)  or 
										(opcode_i = ANDI_OPC) or
										(opcode_i = XORI_OPC))		ELSE '0';  	
			
	-- PC Control
	PCSrc_o <=  "01" WHEN opcode_i = J_OPC OR opcode_i = JAL_OPC ELSE	-- Jump
				"10" WHEN opcode_i = BEQ_OPC OR opcode_i = BNE_OPC ELSE	-- Branch
				"11" WHEN opcode_i = R_TYPE_OPC ELSE 					-- Jump Register
				"00";	-- PC + 4
							
  	RegDst_ctrl_o    	<=  '0' WHEN rtype_w = '1' OR opcode_i = MUL_OPC ELSE '1';
	RegWrite_ctrl_o 	<=  '1' WHEN (rtype_w = '1' AND func_i /= JR_FUNC) OR 
									opcode_i = MUL_OPC OR lw_w = '1' OR 
									itype_imm_w = '1' OR 
									JAL_OPC = opcode_i ELSE '0';


	ALUSrcA_ctrl_o			<= '1' when rtype_w = '1' AND (func_i = SLL_FUNC OR func_i = SRL_FUNC) else '0';
	ALUSrcB_ctrl_o  		<=  lw_w or sw_w or itype_imm_w;

	MemtoReg_ctrl_o 	<=  lw_w;
  	MemRead_ctrl_o 		<=  lw_w;
   	MemWrite_ctrl_o 	<=  sw_w; 

 	Branch_ctrl_o      	<=  beq_w;
	LinkPC_ctrl_o 		<=  '1' WHEN opcode_i = JAL_OPC ELSE '0';

	process (opcode_i)
	 begin
		case opcode_i is
			WHEN R_TYPE_OPC => 						ALUOp_ctrl_o <= R_TYPE_ALU_CTRL;
			WHEN BEQ_OPC | BNE_OPC | SLTI_OPC =>	ALUOp_ctrl_o <= SUB_ALU_CTRL;
			WHEN ADDI_OPC | LW_OPC | SW_OPC =>		ALUOp_ctrl_o <= ADD_ALU_CTRL;
			WHEN ANDI_OPC => 						ALUOp_ctrl_o <= AND_ALU_CTRL;
			WHEN ORI_OPC => 						ALUOp_ctrl_o <= OR_ALU_CTRL;
			WHEN XORI_OPC => 						ALUOp_ctrl_o <= XOR_ALU_CTRL;
			WHEN MUL_OPC => 						ALUOp_ctrl_o <= MUL_ALU_CTRL;
			WHEN LUI_OPC => 						ALUOp_ctrl_o <= LUI_ALU_CTRL;
			WHEN others  => null;
	 	end case;
	end process;


   END behavior;


