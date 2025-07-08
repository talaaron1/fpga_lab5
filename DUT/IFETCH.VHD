---------------------------------------------------------------------------------------------
-- Ifetch module (provides the PC and instruction memory for the MIPS computer)
---------------------------------------------------------------------------------------------
library ieee;
library altera_mf;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.const_package.all;
use altera_mf.altera_mf_components.all;

entity IFETCH is
    generic (
        WORD_GRANULARITY : BOOLEAN := false;
        DATA_BUS_WIDTH   : INTEGER := 32;
        PC_WIDTH         : INTEGER := 10;
        ITCM_ADDR_WIDTH  : INTEGER := 8;
        WORDS_NUM        : INTEGER := 256;
        INST_CNT_WIDTH   : INTEGER := 16
    );
    port (
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
end IFETCH;

architecture behavior of IFETCH is

    signal PC_q           : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
    signal PC_plus_4_r    : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
    signal JTA_r          : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
    signal itcm_addr_w    : STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 downto 0);
    signal next_PC_w      : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
    signal branch_w       : STD_LOGIC;
    signal rst_flag_q     : STD_LOGIC;
    signal inst_cnt_q     : STD_LOGIC_VECTOR(INST_CNT_WIDTH-1 downto 0);
    signal PC_prev_q      : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
    signal instruction_r  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    alias addr is instruction_r(25 downto 0);

    -- IF/ID register
    signal instruction_q  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal PC_plus_4_q    : STD_LOGIC_VECTOR(PC_WIDTH-1 downto 0);
begin

    -- ROM for Instruction Memory
    inst_memory: altsyncram
        generic map (
            operation_mode         => "ROM",
            width_a                => DATA_BUS_WIDTH,
            widthad_a              => ITCM_ADDR_WIDTH,
            numwords_a             => WORDS_NUM,
            lpm_hint               => "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
            lpm_type               => "altsyncram",
            outdata_reg_a          => "UNREGISTERED",
            init_file              => "F:\labs\GPU_labs\lab5\code2\ITCM.hex",
            intended_device_family => "Cyclone"
        )
        port map (
            clock0    => clk_i,
            address_a => itcm_addr_w,
            q_a       => instruction_r
    );

    -- Send address to instruction memory
    g1:
    if (WORD_GRANULARITY = true) generate
        itcm_addr_w <= next_PC_w;
    elsif (WORD_GRANULARITY = false) generate
        itcm_addr_w <= next_PC_w & "00";
    end generate;

    ----------------------------------------------------------------
    -- PC Control
    ----------------------------------------------------------------

    -- Compute PC + 4
    PC_plus_4_r <= PC_q(PC_WIDTH-3 downto 0) & "00";
    
    -- Compute JTA (Jump Target Address)
    JTA_r <= addr(PC_WIDTH-3 downto 0) & "00";

    -- Compute branch condition
    -- Branch_ctrl_i = 0: Beq
    -- Branch_ctrl_i = 1: Bne
    branch_w <= Branch_ctrl_i XOR Zero_i;

    -- Compute next PC
    -- PCSrc_ctrl_i = 00: PC + 4
    -- PCSrc_ctrl_i = 01: JTA (Jump Target Address)
    -- PCSrc_ctrl_i = 10: BTA (Branch Target Address)
    -- PCSrc_ctrl_i = 11: Jump Register
    next_PC_w <=    PC_plus_4_r when PCSrc_ctrl_i = "00" else
                    JTA_r when PCSrc_ctrl_i = "00" and branch_w = '1' else
                    BTA_i when PCSrc_ctrl_i = "00" else
                    jump_register_i;
                
    -- IF/ID register update
    process (clk_i, rst_i)
     begin
        if IF_ID_flush_ctrl_i = '1' then
                PC_plus_4_q <= (others => '0'); 
                instruction_q <= (others => '0');

        elsif (RISING_EDGE(clk_i)) then
            if IF_ID_write_ctrl_i = '1' then
                PC_plus_4_q <= PC_plus_4_r;
                instruction_q <= instruction_r;
            
            end if;
        end if;
    end process;

    -- PC register update
    process (clk_i, rst_i)
     begin
        if rst_i = '1' then
            pc_q <= (2 => '1', others => '0');
        elsif (clk_i'event and clk_i = '1') then
            pc_q <= next_pc_w;
        end if;
    end process;

    -- Sample reset flag on rising edge
    process (clk_i)
     begin
        if (clk_i'event and clk_i = '1') then
            rst_flag_q <= rst_i;
        end if;
    end process;

    -- Previous PC tracking (for instruction counter)
    process (clk_i, rst_i)
     begin
        if rst_i = '1' then
            pc_prev_q <= (others => '0');
        elsif falling_edge(clk_i) then
            pc_prev_q <= pc_q;
        end if;
    end process;

    -- Instruction counter logic
    process (clk_i, rst_i)
     begin
        if rst_i = '1' then
            inst_cnt_q <= (others => '0');
        elsif rising_edge(clk_i) then
            if pc_prev_q = pc_q then
                inst_cnt_q <= inst_cnt_q + '1';
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------------------
    -- Output assignments
    ---------------------------------------------------------------------------------------
    PC_o           <= PC_q;
    PC_plus4_o     <= PC_plus_4_q;
    inst_cnt_o     <= inst_cnt_q;
    instruction_o  <= instruction_q;

end behavior;
