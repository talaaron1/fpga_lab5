---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--test
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_comilation_package.all;


package aux_package is
---------------------------------------------------------
	component Ifetch is
		generic(
			WORD_GRANULARITY : boolean 	:= False;
			DATA_BUS_WIDTH : integer 	:= 32;
			PC_WIDTH : integer 			:= 10;
			NEXT_PC_WIDTH : integer 	:= 8; -- NEXT_PC_WIDTH = PC_WIDTH-2
			ITCM_ADDR_WIDTH : integer 	:= 8;
			WORDS_NUM : integer 		:= 256;
			INST_CNT_WIDTH : integer 	:= 16
		);
		PORT(	
			IF_ID_flush_ctrl_i    : in STD_LOGIC;
        IF_ID_write_ctrl_i    : in STD_LOGIC;

        clk_i, rst_i    : in STD_LOGIC;

        PCwrite_ctrl_i  : in STD_LOGIC;
        PCSrc_ctrl_i    : in STD_LOGIC_VECTOR(1 downto 0);
        Branch_ctrl_i   : in STD_LOGIC;
        Zero_i          : in STD_LOGIC;

        BTA_i           : in STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
        jump_register_i  : in STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);


        -- IF/ID register outputs
        PC_plus4_o       : out STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
        instruction_o    : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

        -- debug outputs
        PC_o             : out STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
        inst_cnt_o       : out STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 downto 0)
		);
	end component;
---------------------------------------------------------
	component Idecode is
		generic(
			DATA_BUS_WIDTH : integer := 32;
			PC_WIDTH : integer 			:= 10
		);
		PORT(	
			ID_EX_flush_ctrl_i : in  STD_LOGIC;
		ID_EX_write_ctrl_i : in  STD_LOGIC;

        clk_i, rst_i        : in  STD_LOGIC;
        instruction_i       : in  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
        PC_plus_4_i         : in  STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);

        write_register_i    : in  STD_LOGIC_VECTOR(4 downto 0);
        write_data_i        : in  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

        LinkPC_ctrl_i       : in  STD_LOGIC;
        RegWrite_ctrl_i     : in  STD_LOGIC;

        zero_o              : out STD_LOGIC;
        BTA_o               : out STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);


        -- ID/EX register outputs
		rs_data_o        : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
		rt_data_o        : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

		rs_register_o    : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
		rt_register_o    : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
		rd_register_o    : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

		funct_o        	: out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
		sign_extend_o    : out STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

		-- EX Controls
		ALUSrcB_ctrl_o 		: OUT 	STD_LOGIC;
		ALUSrcB_ctrl_i 		: IN 	STD_LOGIC;
		ALUSrcA_ctrl_o 		: OUT 	STD_LOGIC;
		ALUSrcA_ctrl_i 		: IN 	STD_LOGIC;
		ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(3 DOWNTO 0);
		ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(3 DOWNTO 0);

		-- MEM Controls
		MemRead_ctrl_o 		: OUT 	STD_LOGIC;
		MemRead_ctrl_i 		: IN 	STD_LOGIC;
		MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;
		MemWrite_ctrl_i	 	: IN 	STD_LOGIC;

		-- WB Controls
		RegDst_ctrl_o 		: OUT 	STD_LOGIC;
		RegDst_ctrl_i 		: IN 	STD_LOGIC;
		MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
		MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
		RegWrite_ctrl_o     : out  STD_LOGIC 
		);
	end component;
---------------------------------------------------------  
	component control is
		PORT( 	
		opcode_i 			: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);
		func_i 				: IN 	STD_LOGIC_VECTOR(5 DOWNTO 0);

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
	end component;
---------------------------------------------------------		
	component Execute is
		generic(
			DATA_BUS_WIDTH : integer := 32;
			FUNCT_WIDTH : integer := 6;
			PC_WIDTH : integer := 10
		);
		PORT(	
			clk_i, rst_i     : in  STD_LOGIC;

		    rs_data_i 	 : IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			rt_data_i 	 : IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			 
			funct_i 		 : IN 	STD_LOGIC_VECTOR(FUNCT_WIDTH-1 DOWNTO 0);
			pc_plus4_i 		 : IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
 
			alu_res_o 		 : OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);


			-- forword signals
			forwardA_o       : IN  STD_LOGIC_VECTOR(1 downto 0);
        	forwardB_o       : IN  STD_LOGIC_VECTOR(1 downto 0);
			EX_MEM_to_alu_i  : IN  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
			MEM_WB_to_alu_i	 : IN  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

			-- to update the EX/MEM register
			rs_register_i    : IN STD_LOGIC_VECTOR   (4 downto 0);
			rt_register_i    : IN STD_LOGIC_VECTOR   (4 downto 0);
			rt_register_o    : out STD_LOGIC_VECTOR  (4 downto 0);
			rd_register_i    : IN STD_LOGIC_VECTOR   (4 downto 0);
			rd_register_o    : OUT STD_LOGIC_VECTOR  (4 downto 0);
			sign_extend_i 	 : IN STD_LOGIC_VECTOR   (4 downto 0);
			      -- mux output for the destination register to write to
			target_write_reg_o : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			-- EX Controls
			ALUOp_ctrl_i 	 : IN 	STD_LOGIC_VECTOR(2 DOWNTO 0);
			ALUSrcB_ctrl_i 	 : IN 	STD_LOGIC;
			ALUSrcA_ctrl_i 	 : IN 	STD_LOGIC;
			RegDst_ctrl_i	 : IN 	STD_LOGIC;

		-- to update the EX/MEM register
			-- MEM Controls
			MemRead_ctrl_i 		: IN 	STD_LOGIC;
			MemWrite_ctrl_i	 	: IN 	STD_LOGIC;
			MemRead_ctrl_o 		: OUT 	STD_LOGIC;
			MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;

			-- WB Controls
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
			RegWrite_ctrl_o 	: OUT 	STD_LOGIC
		);
	end component;
---------------------------------------------------------	
	component dmemory is
		generic(
		DATA_BUS_WIDTH : integer := 32;
		DTCM_ADDR_WIDTH : integer := 8;
		WORDS_NUM : integer := 256
		);
		PORT(	
			MEM_WB_flush_ctrl_i    : in STD_LOGIC;
        	MEM_WB_write_ctrl_i    : in STD_LOGIC;	

			clk_i,rst_i			: IN 	STD_LOGIC;

			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			alu_result_o 		: OUT    STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			alu_result_i 		: IN    STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			rd_register_i    : IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
			rd_register_o    : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
			-- to update the MEM/WB register
			-- WB Controls
			RegDst_ctrl_i		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;

			RegDst_ctrl_o 		: OUT 	STD_LOGIC;
			MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
			RegWrite_ctrl_o 	: OUT 	STD_LOGIC;

		    --fowording 
			--from EX/MEM to EXECUTE
			EX_MEM_RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
			--from MEM/WB to EXECUTE
			MEM_WB_RegWrite_ctrl_o 	: OUT 	STD_LOGIC;

			target_write_reg_i : IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			EX_MEM_rd_o        : OUT  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
			MEM_WB_rd_o	       : OUT  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0)

			--dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)


		);
	end component;
---------------------------------------------------------
	COMPONENT ForwardingUnit is
		port (
			forwardA_o          : out STD_LOGIC_VECTOR(1 downto 0);
			forwardB_o          : out STD_LOGIC_VECTOR(1 downto 0);

			EX_MEM_RegisterRd_i : in STD_LOGIC_VECTOR(4 downto 0);
			MEM_WB_RegisterRd_i : in STD_LOGIC_VECTOR(4 downto 0);
			
			ID_EX_RegisterRs_i  : in STD_LOGIC_VECTOR(4 downto 0);
			ID_EX_RegisterRt_i  : in STD_LOGIC_VECTOR(4 downto 0);

			EX_MEM_RegWrite_i     : in STD_LOGIC;
			MEM_WB_RegWrite_i     : in STD_LOGIC
		);
	end COMPONENT;
---------------------------------------------------------
	component MIPS is
		generic( 
			WORD_GRANULARITY : boolean 	:= G_WORD_GRANULARITY;
	        MODELSIM : integer 			:= G_MODELSIM;
			DATA_BUS_WIDTH : integer 	:= 32;
			ITCM_ADDR_WIDTH : integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH : integer 	:= G_ADDRWIDTH;
			PC_WIDTH : integer 			:= 10;
			FUNCT_WIDTH : integer 		:= 6;
			DATA_WORDS_NUM : integer 	:= G_DATA_WORDS_NUM;
			CLK_CNT_WIDTH : integer 	:= 16;
			INST_CNT_WIDTH : integer 	:= 16
		);
		PORT(	
			rst_i		 		:IN	STD_LOGIC;
			clk_i				:IN	STD_LOGIC; 
			-- Output important signals to pins for easy display in Simulator
			pc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			alu_result_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data1_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			write_data_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			instruction_top_o	:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			Branch_ctrl_o		:OUT 	STD_LOGIC;
			Zero_o				:OUT 	STD_LOGIC; 
			MemWrite_ctrl_o		:OUT 	STD_LOGIC;
			RegWrite_ctrl_o		:OUT 	STD_LOGIC;
			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
			inst_cnt_o 			:OUT	STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0)
		);		
	end component;
---------------------------------------------------------	
	COMPONENT PLL port(
	    areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0     		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC );
    END COMPONENT;
---------------------------------------------------------
end aux_package;