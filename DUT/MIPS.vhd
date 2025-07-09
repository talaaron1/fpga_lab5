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
	SIGNAL RegDst_ctrl_w 	: STD_LOGIC;
	SIGNAL LinkPC_ctrl_w 	: STD_LOGIC;
	SIGNAL RegWrite_ctrl_w 		: STD_LOGIC;
	SIGNAL zero_w 			: STD_LOGIC;
	SIGNAL MemWrite_ctrl_w 		: STD_LOGIC;
	SIGNAL MemtoReg_ctrl_w 		: STD_LOGIC;
	SIGNAL MemRead_ctrl_w 		: STD_LOGIC;
	SIGNAL alu_op_w 		: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL instruction_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MCLK_w 			: STD_LOGIC;
	SIGNAL mclk_cnt_q		: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL inst_cnt_w		: STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL BTA_w            : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
	SIGNAL funct_ID_w          : STD_LOGIC_VECTOR(5 downto 0);

	----ID
	SIGNAL rs_data_ID_w 	    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	SIGNAL rt_data_ID_w 	    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	SIGNAL rs_register_ID_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	SIGNAL rt_register_ID_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	SIGNAL rd_register_ID_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	SIGNAL sign_extend_ID_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	
	signal RegWrite_ctrl_ID_w	: STD_LOGIC;
	signal MemRead_ctrl_ID_w	: STD_LOGIC;
	signal MemWrite_ctrl_ID_w	: STD_LOGIC;
	signal RegDst_ctrl_ID_w		: STD_LOGIC;
	signal MemtoReg_ctrl_ID_w	: STD_LOGIC;


	----exe
	--SIGNAL alu_result_exe_w     : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	signal target_write_reg_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL rt_register_EX_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	SIGNAL rd_register_EX_w 	: STD_LOGIC_VECTOR(4 downto 0);
	signal ALUSrcB_ctrl_ID_EX_w 	: 	STD_LOGIC;
	signal ALUSrcA_ctrl_ID_EX_w 	: 	STD_LOGIC;
	signal ALUOp_ctrl_ID_EX_w	 	: 	STD_LOGIC_VECTOR(3 DOWNTO 0);

	----MEM
	SIGNAL dtcm_data_rd_MEM_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_result_EX_MEM_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_result_MEM_WB_w 	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MEM_WB_rd_w 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL rd_register_MEM_w 	: STD_LOGIC_VECTOR(4 downto 0);

	SIGNAL EX_MEM_RegWrite_ctrl_w 			: STD_LOGIC;
	SIGNAL MEM_WB_RegWrite_ctrl_w 			: STD_LOGIC;

	
	---WB
	SIGNAL data_write_reg		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	--internal ex signals
	SIGNAL MemRead_ctrl_ex_w 			: STD_LOGIC;
	SIGNAL MemWrite_ctrl_ex_w 			: STD_LOGIC;
	SIGNAL MemtoReg_ctrl_ex_w 			: STD_LOGIC;
	SIGNAL RegWrite_ctrl_ex_w 			: STD_LOGIC;

	--internal mem signals
	SIGNAL RegDst_ctrl_mem_w			: STD_LOGIC;
	SIGNAL MemtoReg_ctrl_mem_w 			: STD_LOGIC;
	SIGNAL RegWrite_ctrl_mem_w 			: STD_LOGIC;

	--forwarding signals
	
	SIGNAL forwardA_w 			: STD_LOGIC;
	SIGNAL forwardB_w 			: STD_LOGIC;
	-- hazard
	SIGNAL PCwrite_ctrl_w : STD_LOGIC;

BEGIN

	-- mux og (after) WB
	data_write_reg <= alu_result_MEM_WB_w WHEN MemtoReg_ctrl_mem_w = '0' ELSE 
					  dtcm_data_rd_w;

 -- connect the output signals to the top level ports
   instruction_top_o 	<= 	instruction_w;
   alu_result_o 		<= 	alu_result_w;
   read_data1_o 		<= 	read_data1_w;
   read_data2_o 		<= 	read_data2_w;
   --write_data_o  		<= 	dtcm_data_rd_w WHEN MemtoReg_ctrl_w = '1' ELSE 
	--						alu_result_w;
							
   Branch_ctrl_o 		<= 	branch_w;
   Zero_o 				<= 	zero_w;
   --RegWrite_ctrl_o 		<= 	reg_write_w;
   --MemWrite_ctrl_o 		<= 	mem_write_w;	

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
			-- new
			IF_ID_flush_ctrl_i  => ,
			IF_ID_write_ctrl_i  => ,

			clk_i 				=> MCLK_w,  
			rst_i 				=> rst_i,

			PCSrc_ctrl_i 		=>  pc_src_w,
			Branch_ctrl_i 		=> branch_w,
			zero_i 				=> zero_w,

			BTA_i               => BTA_w,
			jump_register_i     => rs_data_ID_w,

			-- IF/ID register outputs
			pc_plus4_o	 		=> pc_plus4_w,
			instruction_o 		=> instruction_w,

			-- hazard
			PCwrite_ctrl_i 		=>PCwrite_ctrl_w,

			-- debug outputs
			pc_o 				=> pc_o,
			inst_cnt_o			=> inst_cnt_w
		);

	ID : Idecode
		generic map(
			DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
		)
		PORT MAP (	

				----------------- in -----------------
				ID_EX_flush_ctrl_i =>,
				ID_EX_write_ctrl_i =>,

				clk_i 				=> MCLK_w,  
				rst_i 				=> rst_i,
				instruction_i 		=> instruction_w,
				PC_plus_4_i         => pc_plus4_w,

				write_register_i    => MEM_WB_rd_w,
				write_data_i        => data_write_reg,
				
				----------------- out -----------------
				zero_o              =>zero_w,
				BTA_o               =>BTA_w,

				-- ID/EX register outputs
				rs_data_o        	=> rs_data_ID_w,
				rt_data_o        	=> rt_data_ID_w,
				rs_register_o    	=> rs_register_ID_w,
				rt_register_o    	=> rt_register_ID_w,
				rd_register_o    	=> rd_register_ID_w,
				
				funct_o        	    => funct_ID_w,
				sign_extend_o       => sign_extend_ID_w,


				-- EX Controls
				ALUSrcB_ctrl_o 		=> ALUSrcB_ctrl_ID_EX_w,
				ALUSrcB_ctrl_i 		=> alu_src_B_w,
				ALUSrcA_ctrl_o 		=> ALUSrcA_ctrl_ID_EX_w,
				ALUSrcA_ctrl_i 		=> alu_src_A_w,
				ALUOp_ctrl_o	 	=> ALUOp_ctrl_ID_EX_w,
				ALUOp_ctrl_i	 	=> alu_op_w,
				RegDst_ctrl_o 		=> RegDst_ctrl_ID_w,
				RegDst_ctrl_i 		=> RegWrite_ctrl_w,

				-- MEM Controls
				MemRead_ctrl_o 		=> MemRead_ctrl_ID_w,
				MemRead_ctrl_i 		=> MemRead_ctrl_w,
				MemWrite_ctrl_o	 	=> MemWrite_ctrl_ID_w,
				MemWrite_ctrl_i	 	=> MemWrite_ctrl_w,

				-- WB Controls
				
				MemtoReg_ctrl_o 	=> MemtoReg_ctrl_ID_w,
				MemtoReg_ctrl_i 	=> MemtoReg_ctrl_w,
				RegWrite_ctrl_i 	=> RegWrite_ctrl_w,
				RegWrite_ctrl_o     => RegWrite_ctrl_ID_w
				
			);

	CTL:   control
		PORT MAP ( 	
				----------------- in -----------------
				opcode_i 			=> instruction_w(DATA_BUS_WIDTH-1 DOWNTO 26),
				func_i 				=> instruction_w(5 DOWNTO 0),
				----------------- out -----------------
				PCSrc_o 			=> pc_src_w,
				Branch_ctrl_o 		=> branch_w,

				-- EX Controls
				ALUSrcA_ctrl_o 		=> alu_src_A_w,
				ALUSrcB_ctrl_o 		=> alu_src_B_w,
				ALUOp_ctrl_o 		=> alu_op_w,
				RegDst_ctrl_o 		=> RegDst_ctrl_w,

				-- MEM Controls
				MemRead_ctrl_o 		=> MemRead_ctrl_w,
				MemWrite_ctrl_o 	=> MemWrite_ctrl_w,
				-- WB Controls
				MemtoReg_ctrl_o 	=> MemtoReg_ctrl_w,
				RegWrite_ctrl_o 	=> RegWrite_ctrl_w,
				LinkPC_ctrl_o 		=> LinkPC_ctrl_w
			);

	EXE:  Execute
		generic map(
			DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
			FUNCT_WIDTH 		=>	FUNCT_WIDTH,
			PC_WIDTH 			=>	PC_WIDTH
		)
		PORT MAP (	
			----------------- in -----------------
			clk_i 				=> MCLK_w,  
			rst_i 				=> rst_i,

		    rs_data_i 	 		=> rs_data_ID_w,
			rt_data_i 	 		=> rt_data_ID_w,
			 
			funct_i				=> funct_ID_w,
			pc_plus4_i			=> pc_plus4_w,
			----------------- out -----------------
			alu_res_o 			=> alu_result_EX_MEM_w,

			-- ----------------- hazard -----------------
			-- forword signals
			forwardA_o       	=> forwardA_w,
        	forwardB_o     	  	=> forwardB_w,
			EX_MEM_to_alu_i  	<= alu_result_EX_MEM_w, -- EX_MEM.alu_result
			MEM_WB_to_alu_i	 	<= alu_result_EX_MEM_w, -- EX_MEM.alu_result

			-- to update the EX/MEM register
			rs_register_i       => rs_register_ID_w,
			rt_register_i  		=> rt_register_ID_w,
			rt_register_o	    => rt_register_EX_w, -- to update the rt register in the ID/EX register
			rd_register_i  		=> rd_register_ID_w,
			rd_register_o	    => rd_register_EX_w, -- to update the rd register in the ID/EX register
			sign_extend_i 	=> sign_extend_ID_w,
			      -- mux output for the destination register to write to
			target_write_reg_o  <= target_write_reg_w,
			
			-- EX Controls
			ALUSrcB_ctrl_i 		<= ALUSrcB_ctrl_ID_EX_w,
			ALUSrcA_ctrl_i 		<= ALUSrcA_ctrl_ID_EX_w,
			ALUOp_ctrl_i	 	<= ALUOp_ctrl_ID_EX_w,
			RegDst_ctrl_i   	<= RegDst_ctrl_ID_w,
			
		-- to update the EX/MEM register
			-- MEM Controls
			MemRead_ctrl_i 		<= MemRead_ctrl_ID_w,
			MemWrite_ctrl_i	 	<= MemWrite_ctrl_ID_w,
			MemRead_ctrl_o 		<= MemRead_ctrl_ex_w,
			MemWrite_ctrl_o	 	<= MemWrite_ctrl_ex_w,

			-- WB Controls
			
			MemtoReg_ctrl_i     <= MemtoReg_ctrl_ID_w,
			RegWrite_ctrl_i 	<= RegWrite_ctrl_ID_w,
			MemtoReg_ctrl_o 	<= MemtoReg_ctrl_ex_w,
			RegWrite_ctrl_o	 	<= RegWrite_ctrl_ex_w
			
		);

	forward:  ForwardingUnit
		port map (
			forwardA_o          <= forwardA_w,
			forwardB_o          <= forwardB_w,

			EX_MEM_RegisterRd_i <= rd_register_EX_w, -- EX_MEM.rd
			MEM_WB_RegisterRd_i <= rd_register_MEM_w, -- MEM_WB.rd
			
			ID_EX_RegisterRs_i  <= rs_data_ID_w, -- ID_EX.Rs
			ID_EX_RegisterRt_i  <= rt_data_ID_w, -- ID_EX.Rt

			EX_MEM_RegWrite_i   <= EX_MEM_RegWrite_ctrl_w,                  -- EX_MEM.WR (write reg)
			MEM_WB_RegWrite_i   <= MEM_WB_RegWrite_ctrl_w                  -- MEM_WB.WR (write reg)
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
					-- new
					----
					MEM_WB_flush_ctrl_i =>,
					MEM_WB_write_ctrl_i =>,

					clk_i 				<= MCLK_w,  
					rst_i 				<= rst_i,

					dtcm_addr_i 		<= alu_result_EX_MEM_w((DTCM_ADDR_WIDTH+2)-1 DOWNTO 2), -- increment memory address by 4
					dtcm_data_wr_i 		<= rt_register_EX_w,
					MemRead_ctrl_i  	<= MemRead_ctrl_ex_w,
					MemWrite_ctrl_i 	<= MemWrite_ctrl_ex_w,
					dtcm_data_rd_o 		<= dtcm_data_rd_w,
					alu_result_o 		<= alu_result_MEM_WB_w,
					alu_result_i 		<= alu_result_EX_MEM_w,

					-- to update the MEM/WB register
					-- WB Controls
					RegDst_ctrl_i		<= RegDst_ctrl_mem_w,
					MemtoReg_ctrl_i 	<= MemtoReg_ctrl_mem_w,
					RegWrite_ctrl_i 	<= RegWrite_ctrl_mem_w,

					--fowording 
					rd_register_i    <= rd_register_EX_w,
					rd_register_o    <= rd_register_MEM_w,
					--from EX/MEM to EXECUTE
					EX_MEM_RegWrite_ctrl_o 	<= EX_MEM_RegWrite_ctrl_w,
					--from MEM/WB to EXECUTE
					MEM_WB_RegWrite_ctrl_o 	<= MEM_WB_RegWrite_ctrl_w,

					target_write_reg_i <= target_write_reg_w,
					EX_MEM_rd_o        <= EX_MEM_rd_w,	
					MEM_WB_rd_o	       <= MEM_WB_rd_w
				);	
		elsif (WORD_GRANULARITY = False) generate -- i.e. each BYTE has a unike address	
			MEM:  dmemory
				generic map(
					DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
					DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
					WORDS_NUM			=>	DATA_WORDS_NUM
				)
				PORT MAP (	
					dtcm_addr_i 		=> alu_result_w(DTCM_ADDR_WIDTH-1 DOWNTO 2)&"00",

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

