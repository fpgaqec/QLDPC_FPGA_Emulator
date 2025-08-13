library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity fsm_em is
    port (
		id_dloop : in std_logic_vector(7 downto 0);           --current iteration : u[8 0]
        clk : in std_logic;
        ic_rst : in std_logic;
        ic_start : in std_logic;
		ic_done : in std_logic;
        ic_par : in std_logic;
		ic_en : in std_logic;
        id_loop_max : in std_logic_vector(7 downto 0);
        oc_rst : out std_logic;
		oc_rdec : out std_logic;
		oc_load : out std_logic;
		oc_edec : out std_logic
        
    );
end fsm_em;

architecture rtl of fsm_em is
    type STATE is (IDLE, SWAIT, LOAD, RDEC1, RDEC2, EDEC);
    signal st, next_st : STATE;
	signal b0_out : std_logic_vector(3 downto 0);
	
	
begin

    
    SL: process (st, ic_start, ic_done, ic_par, id_dloop, id_loop_max)
    begin
        case st is
            when IDLE =>
                if ic_start = '1' then
                    next_st <= SWAIT;
                else
                    next_st <= IDLE;
                end if;
			when SWAIT =>
                if ic_done = '1' then
                    next_st <= LOAD;
                else
                    next_st <= SWAIT;
                end if;
			when LOAD =>
					next_st <= RDEC1;
			when RDEC1 => next_st <= RDEC2;
            when RDEC2 =>
                if id_dloop = id_loop_max or ic_par = '1' then
                    next_st <= EDEC;
                else
                    next_st <= RDEC2;
                end if;
            when EDEC =>
                next_st <= SWAIT;
            when others =>
                next_st <= IDLE;
        end case;
    end process SL;

    St_OL_R: process (clk)
    begin
        if rising_edge(clk) then
            if ic_rst = '1' then
                st <= IDLE;
                b0_out <= "1000";
            else
                st <= next_st;
                case next_st is
                    when IDLE =>
                        b0_out <= "1000";
                    when SWAIT =>
                        b0_out <= "0000";
                    when LOAD =>
                        b0_out <= "0010";
					when RDEC1 =>
                        b0_out <= "0100";
					when RDEC2 =>
                        b0_out <= "0100";
                    when EDEC =>
                        b0_out <= "0001";
                    when others =>
                        b0_out <= "1000";
                end case;
            end if;
        end if;
    end process St_OL_R;
	
	oc_rst <= 	b0_out(3);
	oc_rdec <= 	b0_out(2);
	oc_load <= 	b0_out(1);
	oc_edec <= 	b0_out(0);
	
end rtl;
