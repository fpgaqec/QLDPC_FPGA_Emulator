library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
--use ieee.std_logic_unsigned.all;

entity fsm_main is
	port (
        id_a_err : in unsigned(15 downto 0);
		id_t_err : in unsigned(15 downto 0);
	    ic_start : in std_logic;
		ic_rst : in std_logic;
        clk : in std_logic;
        oc_done : out std_logic;
		oc_start : out std_logic;
		oc_rst_full : out std_logic;
		oc_rst_ini : out std_logic
		
    );
end fsm_main;

architecture rtl of fsm_main is
	
    type STATE is (IDLE, INIT, RUN, DONE);
    signal st, next_st : STATE;
    signal b0_out : std_logic_vector(3 downto 0);
	
begin
	
	
    -- 
    B0_L: process (st, ic_start, id_a_err, id_t_err)
    begin
        case st is
            when IDLE =>
                if ic_start = '1' then
                    next_st <= INIT;
                else
                    next_st <= IDLE;
                end if;
			when INIT =>
                next_st <= RUN;
			when RUN =>
                if id_a_err < id_t_err then
                    next_st <= RUN;
                else
                    next_st <= DONE;
                end if;
			when DONE =>
                if ic_start = '1' then
                    next_st <= DONE;
                else
                    next_st <= IDLE;
				end if;
            when others =>
                next_st <= IDLE;
        end case;
    end process B0_L;

    -- 
    B0_R: process (clk)
    begin
        if rising_edge(clk) then
            if ic_rst = '1' then
                st <= IDLE;
                b0_out <= "0000";
            else
                st <= next_st;
                case next_st is
                    when IDLE =>	b0_out <= "0000";
					when INIT =>	b0_out <= "0011";
					when RUN =>     b0_out <= "0100";
             		when DONE => 	b0_out <= "1010";
					when others =>	b0_out <= "0000";
                end case;
            end if;
        end if;
    end process B0_R;
	
	-- Outputs
	oc_done  	<= b0_out(3);
	oc_start 	<= b0_out(2);
	oc_rst_full	<= b0_out(1);
	oc_rst_ini	<= b0_out(0);
end rtl;
