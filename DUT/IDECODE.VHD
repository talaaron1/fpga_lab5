---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
-- Idecode module (implements the register file for the MIPS computer)
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.const_package.all;

entity IDECODE is
    generic (
        DATA_BUS_WIDTH : INTEGER := 32;
        PC_WIDTH       : INTEGER := 10
    );
    port (
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
		ALUSrcA_ctrl_o 		: OUT 	STD_LOGIC;
		ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(3 DOWNTO 0);

		-- MEM Controls
		MemRead_ctrl_o 		: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;

		-- WB Controls
		RegDst_ctrl_o 		: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
		RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
		LinkPC_ctrl_o 		: OUT 	STD_LOGIC
    );
end IDECODE;

architecture behavior of IDECODE is

    type register_file is array (0 to 31) of STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
    signal RF_q             : register_file;

    signal write_register_w : STD_LOGIC_VECTOR(4 downto 0);
    signal write_data_w     : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	signal rs_data_w        : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
    signal rt_data_w        : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
    signal sign_extend_w    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

	alias opcode       		is instruction_i(31 downto 26);
	alias rs_register       is instruction_i(25 downto 21);
    alias rt_register       is instruction_i(20 downto 16);
	alias rd_register       is instruction_i(15 downto 11);
	alias shmat       		is instruction_i(10 downto 6);
	alias funct       		is instruction_i(5 downto 0);
    alias imm               is instruction_i(15 downto 0);

    signal branch_condition_r : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

    -- ID/EX register
    signal rs_data_q        : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
    signal rt_data_q        : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

	signal rs_register_q    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
    signal rt_register_q    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
	signal rd_register_q    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

	signal funct_q        	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);
    signal sign_extend_q    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 downto 0);

    -- WB Controls
    signal RegDst_ctrl_q 		: STD_LOGIC;
    signal MemtoReg_ctrl_q 	    : STD_LOGIC;
    signal RegWrite_ctrl_q 	    : STD_LOGIC;
    signal LinkPC_ctrl_q 		: STD_LOGIC;
    signal RegDst_ctrl_w 		: STD_LOGIC;
    signal MemtoReg_ctrl_w 	    : STD_LOGIC;
    signal RegWrite_ctrl_w 	    : STD_LOGIC;
    signal LinkPC_ctrl_w 		: STD_LOGIC;

    -- MEM Controls
    signal MemRead_ctrl_q 		: STD_LOGIC;
    signal MemWrite_ctrl_q	 	: STD_LOGIC;
    signal MemRead_ctrl_w 		: STD_LOGIC;
    signal MemWrite_ctrl_w	 	: STD_LOGIC;

    -- EX Controls
    signal ALUSrcB_ctrl_q 		: STD_LOGIC;
    signal ALUSrcA_ctrl_q 		: STD_LOGIC;
    signal ALUOp_ctrl_q	 	    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal ALUSrcB_ctrl_w 		: STD_LOGIC;
    signal ALUSrcA_ctrl_w 		: STD_LOGIC;
    signal ALUOp_ctrl_w	 	    : STD_LOGIC_VECTOR(3 DOWNTO 0);

begin

---------------------- Register File Logic ----------------------

    -- Read Register 1 Operation
    rs_data_w <= RF_q(conv_integer(rs_register));

    -- Read Register 2 Operation
    rt_data_w <= RF_q(conv_integer(rt_register));

    -- Mux for Register Write Address
    write_register_w <= write_register_i when LinkPC_ctrl_i = '0' else RA_REGISTER;

    -- Mux to bypass data memory for R-format instructions
    write_data_w <= write_data_i when LinkPC_ctrl_i = '0' else PC_plus_4_i;

	process (clk_i, rst_i)
     begin
        if rst_i = '1' then
            for i in 0 to 31 loop
                RF_q(i) <= conv_std_logic_vector(0, 32);
            end loop;
        elsif rising_edge(clk_i) then
            if RegWrite_ctrl_i = '1' and write_register_w /= "00000" then
                RF_q(conv_integer(write_register_w)) <= write_data_w;
            end if;
        end if;
    end process;

---------------------- Branch Logic ----------------------

    -- Check branch condition
    branch_condition_r <= rs_data_w - rt_data_w;
    zero_o <= branch_condition_r(DATA_BUS_WIDTH-1);

    -- Sign Extend Logic
    sign_extend_w <= X"0000" & imm when imm(15) = '0' else X"FFFF" & imm;

    -- Compute BTA = PC + 4 + (SignImm << 2)
    BTA_o <= PC_plus_4_i + (sign_extend_w(PC_WIDTH-3 downto 0) & "00");


	---------------------- ID/EX Register Logic ----------------------

	rs_data_o <= rs_data_q;
	rt_data_o <= rt_data_q;

	rs_register_o <= rs_register_q;
	rt_register_o <= rt_register_q;
	rd_register_o <= rd_register_q;

	funct_o <= funct_q;
	sign_extend_o <= sign_extend_q;

    -- WB Controls
    RegDst_ctrl_o 	<= RegDst_ctrl_q;
    MemtoReg_ctrl_o <= MemtoReg_ctrl_q;
    RegWrite_ctrl_o <= RegWrite_ctrl_q;
    LinkPC_ctrl_o 	<= LinkPC_ctrl_q;

    -- MEM Controls
    MemRead_ctrl_o 	<= MemRead_ctrl_q;
    MemWrite_ctrl_o	 <= MemWrite_ctrl_q;

    -- EX Controls
    ALUSrcB_ctrl_o 	<= ALUSrcB_ctrl_q;
    ALUSrcA_ctrl_o 	<= ALUSrcA_ctrl_q;
    ALUOp_ctrl_o	 <= ALUOp_ctrl_q;



	-- ID/EX register update
    process (clk_i, rst_i)
    begin
		if ID_EX_flush_ctrl_i = '1' then
			rs_data_q 		<= (others => '0');
			rt_data_q 		<= (others => '0');

			rs_register_q   <= (others => '0');
			rt_register_q   <= (others => '0');
			rt_register_q 	<= (others => '0');
			
			sign_extend_q 	<= (others => '0');
			
			funct_q 		<= (others => '0');

			-- WB Controls
			RegDst_ctrl_q 	<= '0';
			MemtoReg_ctrl_q <= '0';
			RegWrite_ctrl_q <= '0';
			LinkPC_ctrl_q 	<= '0';
			-- MEM Controls
			MemRead_ctrl_q 	<= '0';
			MemWrite_ctrl_q	<= '0';

			-- EX Controls
			ALUSrcB_ctrl_q 	<= '0';
			ALUSrcA_ctrl_q 	<= '0';
			ALUOp_ctrl_q	<= (others => '0');

        elsif rising_edge(clk_i) then
			if ID_EX_write_ctrl_i = '1' then
				rs_data_q <= rs_data_w;
				rt_data_q <= rs_data_w;

				rs_register_q <= rs_register;
				rt_register_q <= rt_register;
				rd_register_q <= rd_register;

				sign_extend_q <= sign_extend_w;

				funct_q <= funct;
				
				-- WB Controls
				RegDst_ctrl_q 	<= RegDst_ctrl_w;
				MemtoReg_ctrl_q <= MemtoReg_ctrl_w;
				RegWrite_ctrl_q <= RegWrite_ctrl_w;
				LinkPC_ctrl_q 	<= LinkPC_ctrl_w;

				-- MEM Controls
				MemRead_ctrl_q 	<= MemRead_ctrl_w;
				MemWrite_ctrl_q	 <= MemWrite_ctrl_w;

				-- EX Controls
				ALUSrcB_ctrl_q 	<= ALUSrcB_ctrl_w;
				ALUSrcA_ctrl_q 	<= ALUSrcA_ctrl_w;
				ALUOp_ctrl_q	 <= ALUOp_ctrl_w;
        	end if;
		end if;
    end process;

end behavior;
