---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_comilation_package.all;
USE work.aux_package.all;


ENTITY MIPS IS
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
	PORT(	rst_i		 		:IN	STD_LOGIC;
			clk_i				:IN	STD_LOGIC; 

			-- Output important signals to pins for easy display in SignalTap
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
END MIPS;
-------------------------------------------------------------------------------------
ARCHITECTURE structure OF MIPS IS
	-- declare signals used to connect VHDL components
-- signals for the MIPS processor
	SIGNAL pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL read_data1_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL sign_extend_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL addr_res_w 		: STD_LOGIC_VECTOR(7 DOWNTO 0 );
	SIGNAL alu_result_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_src_A_w 		: STD_LOGIC;
	SIGNAL alu_src_B_w 		: STD_LOGIC;
	SIGNAL branch_w 		: STD_LOGIC;
	SIGNAL pc_src_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);	
	SIGNAL reg_dst_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL link_pc_w 		: STD_LOGIC;
	SIGNAL reg_write_w 		: STD_LOGIC;
	SIGNAL zero_w 			: STD_LOGIC;
	SIGNAL mem_write_w 		: STD_LOGIC;
	SIGNAL MemtoReg_w 		: STD_LOGIC;
	SIGNAL mem_read_w 		: STD_LOGIC;
	SIGNAL alu_op_w 		: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL instruction_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MCLK_w 			: STD_LOGIC;
	SIGNAL mclk_cnt_q		: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL inst_cnt_w		: STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);

BEGIN
					-- copy important signals to output pins for easy 
					-- display in Simulator

 -- connect the output signals to the top level ports
   instruction_top_o 	<= 	instruction_w;
   alu_result_o 		<= 	alu_result_w;
   read_data1_o 		<= 	read_data1_w;
   read_data2_o 		<= 	read_data2_w;
   write_data_o  		<= 	dtcm_data_rd_w WHEN MemtoReg_w = '1' ELSE 
							alu_result_w;
							
   Branch_ctrl_o 		<= 	branch_w;
   Zero_o 				<= 	zero_w;
   RegWrite_ctrl_o 		<= 	reg_write_w;
   MemWrite_ctrl_o 		<= 	mem_write_w;	

-- connect the PLL component
	G0:
		if (MODELSIM = 0) generate
		MCLK: PLL
			PORT MAP (
				inclk0 	=> clk_i,
				c0 		=> MCLK_w
			);
		else generate
			MCLK_w <= clk_i;
		end generate;
-- connect the 5 MIPS components   
	IFE : Ifetch
		generic map(
			WORD_GRANULARITY	=> 	WORD_GRANULARITY,
			DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
			PC_WIDTH			=>	PC_WIDTH,
			ITCM_ADDR_WIDTH		=>	ITCM_ADDR_WIDTH,
			WORDS_NUM			=>	DATA_WORDS_NUM,
			INST_CNT_WIDTH		=>	INST_CNT_WIDTH
		)
		PORT MAP (	
			clk_i 			=> MCLK_w,  
			rst_i 			=> rst_i, 
			add_result_i 	=> addr_res_w,
			alu_result_i 	=> alu_result_w(PC_WIDTH-1 DOWNTO 0),
			Branch_ctrl_i 	=> branch_w,
			PCSrc_ctrl_i =>  pc_src_w,
			zero_i 			=> zero_w,
			pc_o 			=> pc_o,
			instruction_o 	=> instruction_w,
			pc_plus4_o	 	=> pc_plus4_w,
			inst_cnt_o		=> inst_cnt_w
		);

	ID : Idecode
		generic map(
			DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
		)
		PORT MAP (	
				clk_i 				=> MCLK_w,  
				rst_i 				=> rst_i,
				instruction_i 		=> instruction_w,
				dtcm_data_rd_i 		=> dtcm_data_rd_w,
				alu_result_i 		=> alu_result_w,
				pc_plus4_i 			=> pc_plus4_w,
				RegWrite_ctrl_i 	=> reg_write_w,
				MemtoReg_ctrl_i 	=> MemtoReg_w,
				RegDst_ctrl_i 		=> reg_dst_w,
				LinkPC_ctrl_i 		=> link_pc_w,
				read_data1_o 		=> read_data1_w,
				read_data2_o 		=> read_data2_w,
				sign_extend_o 		=> sign_extend_w	 
			);

	CTL:   control
		PORT MAP ( 	
				opcode_i 			=> instruction_w(DATA_BUS_WIDTH-1 DOWNTO 26),
				func_i 			=> instruction_w(5 DOWNTO 0),
				RegDst_ctrl_o 		=> reg_dst_w,
				LinkPC_ctrl_o 		=> link_pc_w,
				ALUSrcA_ctrl_o 		=> alu_src_A_w,
				ALUSrcB_ctrl_o 		=> alu_src_B_w,
				MemtoReg_ctrl_o 	=> MemtoReg_w,
				RegWrite_ctrl_o 	=> reg_write_w,
				MemRead_ctrl_o 		=> mem_read_w,
				MemWrite_ctrl_o 	=> mem_write_w,
				Branch_ctrl_o 		=> branch_w,
				PCSrc_o =>  pc_src_w,
				ALUOp_ctrl_o 		=> alu_op_w
			);

	EXE:  Execute
		generic map(
			DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
			FUNCT_WIDTH 		=>	FUNCT_WIDTH,
			PC_WIDTH 			=>	PC_WIDTH
		)
		PORT MAP (	
			pc_plus4_i		=> pc_plus4_w,
			read_data1_i 	=> read_data1_w,
			read_data2_i 	=> read_data2_w,
			sign_extend_i 	=> sign_extend_w,
			funct_i			=> instruction_w(5 DOWNTO 0),
			ALUOp_ctrl_i 	=> alu_op_w,
			ALUSrcA_ctrl_i 	=> alu_src_A_w,
			ALUSrcB_ctrl_i 	=> alu_src_B_w,
			zero_o 			=> zero_w,
			alu_res_o		=> alu_result_w,
			addr_res_o 		=> addr_res_w			
		);

	G1: 
		if (WORD_GRANULARITY = True) generate -- i.e. each WORD has a unike address
			MEM:  dmemory
				generic map(
					DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
					DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
					WORDS_NUM			=>	DATA_WORDS_NUM
				)
				PORT MAP (	
					clk_i 				=> MCLK_w,  
					rst_i 				=> rst_i,
					dtcm_addr_i 		=> alu_result_w((DTCM_ADDR_WIDTH+2)-1 DOWNTO 2), -- increment memory address by 4
					dtcm_data_wr_i 		=> read_data2_w,
					MemRead_ctrl_i 		=> mem_read_w, 
					MemWrite_ctrl_i 	=> mem_write_w,
					dtcm_data_rd_o 		=> dtcm_data_rd_w 
				);	
		elsif (WORD_GRANULARITY = False) generate -- i.e. each BYTE has a unike address	
			MEM:  dmemory
				generic map(
					DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
					DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
					WORDS_NUM			=>	DATA_WORDS_NUM
				)
				PORT MAP (	
					clk_i 				=> MCLK_w,  
					rst_i 				=> rst_i,
					dtcm_addr_i 		=> alu_result_w(DTCM_ADDR_WIDTH-1 DOWNTO 2)&"00",
					dtcm_data_wr_i 		=> read_data2_w,
					MemRead_ctrl_i 		=> mem_read_w, 
					MemWrite_ctrl_i 	=> mem_write_w,
					dtcm_data_rd_o 		=> dtcm_data_rd_w
				);
		end generate;
---------------------------------------------------------------------------------------
--									IPC - MCLK counter register
---------------------------------------------------------------------------------------

process (MCLK_w , rst_i)
	begin
		if rst_i = '1' then
			mclk_cnt_q	<=	(others	=> '0');
		elsif rising_edge(MCLK_w) then
			mclk_cnt_q	<=	mclk_cnt_q + '1';
		end if;
	end process;

	mclk_cnt_o	<=	mclk_cnt_q;
	inst_cnt_o	<=	inst_cnt_w;
---------------------------------------------------------------------------------------
END structure;

