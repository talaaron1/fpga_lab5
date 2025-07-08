---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;

ENTITY Execute IS
	generic(
		DATA_BUS_WIDTH : integer := 32;
		FUNCT_WIDTH : integer := 6;
		PC_WIDTH : integer := 10
	);
	PORT(	
			EX_MEM_flush_ctrl_i    : in STD_LOGIC;
        	EX_MEM_write_ctrl_i    : in STD_LOGIC;

			clk_i, rst_i        : in  STD_LOGIC;

		    read_data1_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			sign_extend_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			funct_i 		: IN 	STD_LOGIC_VECTOR(FUNCT_WIDTH-1 DOWNTO 0);

			ALUOp_ctrl_i 	: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0);
			ALUSrcB_ctrl_i 	: IN 	STD_LOGIC;
			ALUSrcA_ctrl_i 	: IN 	STD_LOGIC;

			pc_plus4_i 		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);

			zero_o 			: OUT	STD_LOGIC;
			alu_res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_res_o 		: OUT	STD_LOGIC_VECTOR( 7 DOWNTO 0 )
	);
END Execute;


ARCHITECTURE behavior OF Execute IS
	SIGNAL a_input_w, b_input_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_out_mux_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL branch_addr_r 			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL alu_ctl_w				: STD_LOGIC_VECTOR(3 DOWNTO 0);

	alias shamt is sign_extend_i(10 downto 6);


	-- EX/MEM register
	signal zero_q 			: STD_LOGIC;
	signal alu_res_q 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	signal addr_res_q 		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );

BEGIN
	--------------------------------------------------------------------------------------------------------
	-- ALU Operation Decoder
	--------------------------------------------------------------------------------------------------------
	process (ALUOp_ctrl_i, funct_i)
	 begin
		case ALUOp_ctrl_i is
			WHEN R_TYPE_ALU_CTRL =>
				case funct_i is
					WHEN SLL_FUNC => 				alu_ctl_w <= SLL_ALU_OP;
					WHEN SRL_FUNC => 				alu_ctl_w <= SRL_ALU_OP;
					WHEN ADD_FUNC | ADDU_FUNC | JR_FUNC => 	alu_ctl_w <= ADD_ALU_OP;
					WHEN SUB_FUNC | SLT_FUNC => 	alu_ctl_w <= SUB_ALU_OP;
					WHEN AND_FUNC => 				alu_ctl_w <= AND_ALU_OP;
					WHEN OR_FUNC  => 				alu_ctl_w <= OR_ALU_OP;
					WHEN XOR_FUNC => 				alu_ctl_w <= XOR_ALU_OP;
					WHEN others  => null;
				end case;
			WHEN ADD_ALU_CTRL => 		alu_ctl_w <= ADD_ALU_OP;
			WHEN MUL_ALU_CTRL => 		alu_ctl_w <= MUL_ALU_OP;
			WHEN SUB_ALU_CTRL => 		alu_ctl_w <= SUB_ALU_OP;
			WHEN AND_ALU_CTRL => 		alu_ctl_w <= AND_ALU_OP;
			WHEN OR_ALU_CTRL => 		alu_ctl_w <= OR_ALU_OP;
			WHEN XOR_ALU_CTRL => 		alu_ctl_w <= XOR_ALU_OP;
			WHEN LUI_ALU_CTRL => 		alu_ctl_w <= LU_ALU_OP;
			WHEN others  => null;
	 	end case;
	end process;

	-- ALU A input mux
	a_input_w <= read_data1_i WHEN (ALUSrcA_ctrl_i = '0') ELSE (26 downto 0 => '0') & shamt;

	-- ALU B input mux
	b_input_w <= 	read_data2_i WHEN (ALUSrcB_ctrl_i = '0') ELSE sign_extend_i(DATA_BUS_WIDTH-1 DOWNTO 0);
	
	-- Generate Zero Flag
	zero_o <=	'1' WHEN (alu_out_mux_w(DATA_BUS_WIDTH-1 DOWNTO 0) = X"00000000") ELSE '0';    
					
	-- Adder to compute Branch Address
	branch_addr_r	<= pc_plus4_i(PC_WIDTH-1 DOWNTO 2) + sign_extend_i(7 DOWNTO 0);
	addr_res_o 		<= branch_addr_r(7 DOWNTO 0);

	process (alu_ctl_w, a_input_w, b_input_w)
	 begin
		case alu_ctl_w is
			WHEN SLL_ALU_OP =>	alu_out_mux_w <= b_input_w SLL CONV_INTEGER(unsigned(a_input_w(4 downto 0)));
			WHEN SRL_ALU_OP =>	alu_out_mux_w <= b_input_w SRL CONV_INTEGER(unsigned(a_input_w(4 downto 0)));
			WHEN ADD_ALU_OP => 	alu_out_mux_w <= a_input_w + b_input_w;
			WHEN SUB_ALU_OP =>	alu_out_mux_w <= a_input_w - b_input_w;
			WHEN MUL_ALU_OP =>	alu_out_mux_w <= a_input_w(15 downto 0) * b_input_w(15 downto 0);
			WHEN AND_ALU_OP =>	alu_out_mux_w <= a_input_w AND b_input_w;
			WHEN OR_ALU_OP =>	alu_out_mux_w <= a_input_w OR b_input_w;
			WHEN XOR_ALU_OP =>	alu_out_mux_w <= a_input_w XOR b_input_w;
			WHEN LU_ALU_OP =>	alu_out_mux_w <= sign_extend_i(15 downto 0) & X"0000";
			WHEN others => null;
		end case;
  	end process;

	alu_res_o <= 	X"0000000" & B"000"  & alu_out_mux_w(31) WHEN
					(ALUOp_ctrl_i = R_TYPE_ALU_CTRL AND funct_i = SLT_FUNC) ELSE
					alu_out_mux_w;
  
  
    -- EX/MEM register update
    process (clk_i, rst_i)
     begin
        if EX_MEM_flush_ctrl_i = '1' then
				zero_q 		   <= '0';
				alu_res_q 	   <= (others => '0');
				addr_res_q 	   <= (others => '0');

        elsif (RISING_EDGE(clk_i)) then
            if EX_MEM_write_ctrl_i = '1' then
				zero_q 		   <= zero_o;	
				alu_res_q 	   <= alu_res_o;
				addr_res_q 	   <= addr_res_o; 

            end if;
        end if;
    end process;

-- I-type = [op,rs,rt,imm]

-- xori $rt, $rs, imm     <===>     $rt = $rs XOR imm ==> aluop = ?
-- addi $rt, $rs, imm     <===>     $rt = $rs + imm  ==>  aluop = 010
-- andi $rt, $rs, imm     <===>     $rt = $rs & imm  ==>  aluop = 000

--  func  (and)                      == 100100

--	ALUOp_ctrl_o(0) 	<=  beq_w;   == 0
--	ALUOp_ctrl_o(1) 	<=  rtype_w; == 0

 --- alu operation:
 --- 000 = AND
 --- 001 = OR
 --- 010 = ADD
 --- 110 = SUB
 --- 111 = SLT (Set on Less Than)
--------------------------------------------------------------------------------------------------------

END behavior;

