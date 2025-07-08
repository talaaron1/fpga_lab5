---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Dmemory module (implements the data memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
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


			target_write_reg_i : IN STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			target_write_reg_o : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			-- to update the MEM/WB register
			-- WB Controls
			RegDst_ctrl_i		: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			LinkPC_ctrl_i		: IN 	STD_LOGIC;
			RegDst_ctrl_o 		: OUT 	STD_LOGIC;
			MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
			RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
			LinkPC_ctrl_o 		: OUT 	STD_LOGIC;


		    --fowording 
			--from EX/MEM to EXECUTE
			EX_MEM_RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
			--from MEM/WB to EXECUTE
			MEM_WB_RegWrite_ctrl_o 	: OUT 	STD_LOGIC


			--dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)

	);
END dmemory;


ARCHITECTURE behavior OF dmemory IS
SIGNAL wrclk_w : STD_LOGIC;

	-- MEM/WB register
	signal dtcm_addr_q 		: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	signal dtcm_data_rd_q   : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1  DOWNTO 0);

BEGIN
	data_memory : altsyncram
	GENERIC MAP  (
		operation_mode => "SINGLE_PORT",
		width_a => DATA_BUS_WIDTH,
		widthad_a => DTCM_ADDR_WIDTH,
		numwords_a => WORDS_NUM,
		lpm_hint => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = DTCM",
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "F:\labs\GPU_labs\lab5\code2\DTCM.hex",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		wren_a => MemWrite_ctrl_i,      -- write enable
		clock0 => wrclk_w,				-- clk
		address_a => dtcm_addr_i,		-- address
		data_a => dtcm_data_wr_i,		-- data to write
		q_a => dtcm_data_rd_o			-- data out
	);

	wrclk_w <= NOT clk_i;	-- Load memory address register with write clock

	-- forwarding
	EX_MEM_RegWrite_ctrl_o <= RegWrite_ctrl_i;
	MEM_WB_RegWrite_ctrl_o <= RegWrite_ctrl_o;

	-- MEM/WB register update
    process (clk_i, rst_i)
     begin
        if MEM_WB_flush_ctrl_i = '1' then
                dtcm_addr_q <= (others => '0'); 
                dtcm_data_rd_q <= (others => '0');

				-- WB Controls
				RegDst_ctrl_o 		<= '0';
				MemtoReg_ctrl_o 	<= '0';
				RegWrite_ctrl_o 	<= '0';
				LinkPC_ctrl_o 		<= '0';

        elsif (RISING_EDGE(clk_i)) then
            if MEM_WB_write_ctrl_i = '1' then
                dtcm_addr_q <= dtcm_addr_i;
                dtcm_data_rd_q <= dtcm_data_rd_o;

				-- WB Controls
				RegDst_ctrl_o 		<= RegDst_ctrl_i;
				MemtoReg_ctrl_o 	<= MemtoReg_ctrl_i;
				RegWrite_ctrl_o 	<= RegWrite_ctrl_i;
				LinkPC_ctrl_o 		<= LinkPC_ctrl_i;

				target_write_reg_o <= target_write_reg_i;
            
            end if;
        end if;
    end process;


END behavior;

