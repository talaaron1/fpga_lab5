library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.const_package.all;

entity ForwardingUnit is
    port (
        forwardA_o          : out STD_LOGIC_VECTOR(1 downto 0);
        forwardB_o          : out STD_LOGIC_VECTOR(1 downto 0);

        EX_MEM_RegisterRd_i : in STD_LOGIC_VECTOR(4 downto 0); -- EX_MEM.rd
        MEM_WB_RegisterRd_i : in STD_LOGIC_VECTOR(4 downto 0); -- MEM_WB.rd
        
        ID_EX_RegisterRs_i  : in STD_LOGIC_VECTOR(4 downto 0); -- ID_EX.Rs
        ID_EX_RegisterRt_i  : in STD_LOGIC_VECTOR(4 downto 0); -- ID_EX.Rt

        EX_MEM_RegWrite_i     : in STD_LOGIC;                  -- EX_MEM.WR (write reg)
        MEM_WB_RegWrite_i     : in STD_LOGIC                   -- MEM_WB.WR (write reg)
    );
end ForwardingUnit;

architecture behavior of ForwardingUnit is
    constant ZERO : STD_LOGIC_VECTOR(4 downto 0) := "00000";
begin
    process (all)
    begin
        -- Default values
        forwardA_o <= "00";
        forwardB_o <= "00";

        ----------------------------------------------------------------------
        -- FORWARDING FROM EX/MEM
        ----------------------------------------------------------------------

        if (EX_MEM_RegWrite_i = '1' and
            EX_MEM_RegisterRd_i /= ZERO and 
            EX_MEM_RegisterRd_i = ID_EX_RegisterRs_i) then  -- Check if A input match destination
            forwardA_o <= "10";
        end if;

        if (EX_MEM_RegWrite_i = '1' and 
            EX_MEM_RegisterRd_i /= ZERO and 
            EX_MEM_RegisterRd_i = ID_EX_RegisterRt_i) then  -- Check if B input match destination
            forwardB_o <= "10";
        end if;

        ----------------------------------------------------------------------
        -- FORWARDING FROM MEM/WB
        ----------------------------------------------------------------------

        if (MEM_WB_RegWrite_i = '1' and 
            MEM_WB_RegisterRd_i /= ZERO and 
            MEM_WB_RegisterRd_i = ID_EX_RegisterRs_i and
            not (EX_MEM_RegWrite_i = '1' and
                EX_MEM_RegisterRd_i /= ZERO and 
                EX_MEM_RegisterRd_i = ID_EX_RegisterRs_i)
            ) then  -- Check if A input match destination
            forwardA_o <= "01";
        end if;

        if (MEM_WB_RegWrite_i = '1' and 
            MEM_WB_RegisterRd_i /= ZERO and 
            MEM_WB_RegisterRd_i = ID_EX_RegisterRt_i and
            not (EX_MEM_RegWrite_i = '1' and
                EX_MEM_RegisterRd_i /= ZERO and 
                EX_MEM_RegisterRd_i = ID_EX_RegisterRt_i) 
            ) then  -- Check if B input match destination
            forwardB_o <= "01";
        end if;

    end process;
end behavior;
