library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use work.LLR_fpQLP127x254_q_em_pkg.all;

entity fsm_noixe is
	generic (Ng : integer := 4; -- # NG modules
			 Mg : integer := 3; -- # Load Clock cycles S/P
			 DEBUG : integer := 1); -- Debug mode --> 1
    port (
        id_thr_pe : in std_logic_vector(17 downto 0); 
		ic_rst : in std_logic;
        ic_start : in std_logic;
		ic_load : in std_logic;
		ic_edec : in std_logic;
		ic_errl : in std_logic;
		clk : in std_logic;
        oc_noixe_block : out  std_logic_vector(0 to Nvnu-1);
        oc_done : out std_logic;
		-- Ethernet interfaz ----
		clk_eth : in std_logic;
		ic_en_eth : in std_logic;
		ic_addr_cnt_eth : in unsigned(A_ram-1 downto 0);
		od_ram_eth : out std_logic_vector(0 to Ng-1)
    );
end fsm_noixe;

architecture rtl of fsm_noixe is
	component prng_normal_t64_wrp is
		generic(p_seed_num : integer;     				   --seed number: [0-31]
				romtype : integer);                        --coefficients ROM type (0: single 512x27, 1: splitted 256x21,256x15,256x12)
		port(ic_clk : in std_logic;                        --clock signal
			 ic_ena : in std_logic;                        --enable signal
			 ic_rst : in std_logic;                        --reset signal
			 od_randn : out std_logic_vector(17 downto 0); --random number : s[18 13]
			 oc_randn_dv : out std_logic);                 --random number data-valid
	end component;
	component simpledual_2clk_BRAM is
		generic(A_ram : integer;   -- address length
				Wd : integer);   	-- wordlength
		port(
			clka : in std_logic;
			clkb : in std_logic;
			ena : in std_logic;
			enb : in std_logic;
			wea : in std_logic;
			addra : in unsigned(A_ram-1 downto 0);
			addrb : in unsigned(A_ram-1 downto 0);
			dia : in std_logic_vector(0 to Wd-1);
			dob : out std_logic_vector(0 to Wd-1));
	end component;	

    type STATE is (IDLE, INIT, RUN, DONE);
    signal st, next_st : STATE;
    signal b0_cmp_s : std_logic_vector(0 to Ng-1);
	signal b1_cmp_s : std_logic_vector(0 to Ng-1);
	signal b1_reg_sp_r : std_logic_vector(0 to Mg*Ng-1);
	signal b1_reg_p_r : std_logic_vector(0 to Mg*Ng-1);
	signal b3_noixe_block_s : std_logic_vector(0 to Nvnu-1);
	signal b2_run_prng_s : std_logic;
	signal b2_run_sp_s : std_logic;
	signal b2_loop_counter_1 : unsigned(4 downto 0);
	signal b2_loop_counter_2 : unsigned(8 downto 0);
	constant b2_cte_loop_counter_1 : unsigned(4 downto 0) := conv_unsigned(15,b2_loop_counter_1'length);
	
	
	
	type buffer_type is array (0 to M_buf) of std_logic_vector(0 to Ng-1);
	signal b3_buf_r : buffer_type;
	signal b3_buf_dir_r : unsigned(A_buf-1 downto 0);
	signal b3_cmp_s : std_logic_vector(0 to Ng-1);	
	type b3_STATE is (b3_IDLE, b3_WAIT1, b3_WAIT2, b3_CMD);
    signal b3_st, b3_next_st : b3_STATE;
	signal b3_out : std_logic;
    
	signal b3_sub_cnd_s : boolean;
	signal b3_sub_cnd2_s : boolean;
	signal b3_sub_cnd_r : std_logic;
	signal b3_addr_cnt_r : unsigned(A_ram-1 downto 0);
	signal b2_out : std_logic_vector(2 downto 0);
	
begin
	-- Comparison with the threshold
	B0: for eNg in 0 to Ng-1 generate
		signal b0_randn_s : std_logic_vector(17 downto 0);
		signal b0_randn_dv_s : std_logic;
	begin 
	    -- RGN GENERATORS: 
		PN: prng_normal_t64_wrp generic map(p_seed_num => eNg, romtype => 0)
		port map (ic_clk => clk,
				 ic_ena => b2_run_prng_s,
				 ic_rst => ic_rst,
				 od_randn => b0_randn_s,
				 oc_randn_dv =>  b0_randn_dv_s);
				 
		b0_cmp_s(eNg) <= '1' when (b0_randn_s < id_thr_pe) else '0'; 	
	end generate; 
	
	-- Debug mode
	DEBUG_ON : if DEBUG = 1 generate
		b1_cmp_s <= db_cmp_s;
		db_run <= b2_run_sp_s;
	end generate DEBUG_ON;
	DEBUG_OFF : if DEBUG /= 1 generate
		b1_cmp_s <= b0_cmp_s;
	end generate DEBUG_OFF;
	
	
	-- Reg. S/P
	
	B1: process (clk)
    begin
        if rising_edge(clk) then
			if b2_run_sp_s = '1' then
				b1_reg_sp_r <= b1_reg_sp_r(Ng to (Mg*Ng-1)) & b1_cmp_s ;
			end if;
			if ic_load = '1' then
				b1_reg_p_r <= b1_reg_sp_r;
			end if;
		end if;
	end process B1;
	
	
    -- 
    B2_L: process (st, ic_start, ic_load, b2_loop_counter_1, b2_loop_counter_2)
    begin
        case st is
            when IDLE =>
                if ic_start = '1' then
                    next_st <= INIT;
                else
                    next_st <= IDLE;
                end if;
			when INIT =>
                if b2_loop_counter_1 < b2_cte_loop_counter_1 then
                    next_st <= INIT;
                else
                    next_st <= RUN;
                end if;
			when RUN =>
                if b2_loop_counter_2 < Mg then
                    next_st <= RUN;
                else
                    next_st <= DONE;
                end if;
			when DONE =>
                if ic_load = '1' then
                    next_st <= RUN;
                else
                    next_st <= DONE;
				end if;
            when others =>
                next_st <= IDLE;
        end case;
    end process B2_L;

    -- 
    B2_R: process (clk)
    begin
        if rising_edge(clk) then
            if ic_rst = '1' then
                st <= IDLE;
                b2_out <= "000";
                b2_loop_counter_1 <= (others => '0');
				b2_loop_counter_2 <= (others => '0');
            else
                st <= next_st;
                case next_st is
                    when IDLE =>
                        b2_out <= "000";
                        b2_loop_counter_1 <= (others => '0');
						b2_loop_counter_2 <= (others => '0');
					when INIT =>
                        b2_out <= "001";
                        if (b2_loop_counter_1 < b2_cte_loop_counter_1) then
							b2_loop_counter_1 <= b2_loop_counter_1 + 1;--conv_std_logic_vector(1, b2_loop_counter'length);
						end if;
					when RUN =>
                        b2_out <= "011";
                        if (b2_loop_counter_2 < Mg) then
							b2_loop_counter_2 <= b2_loop_counter_2 + 1;--conv_std_logic_vector(1, b2_loop_counter'length);
						end if;
					when DONE =>
                        b2_out <= "100";
						b2_loop_counter_1 <= (others => '0');
						b2_loop_counter_2 <= (others => '0');
					when others =>
                        b2_out <= "000";
						b2_loop_counter_1 <= (others => '0');
						b2_loop_counter_2 <= (others => '0');
                end case;
            end if;
        end if;
    end process B2_R;
	
	b2_run_prng_s <= b2_out(0);
	b2_run_sp_s <= b2_out(1);
	
	
	-- DP-RAM address control
    -- FSM for b3_sub_cnd_s delay
    -- 
	b3_sub_cnd_s  <= (ic_edec = '1' and ic_errl = '0');
	
    B3_L: process (b3_st, b2_run_sp_s, b3_sub_cnd_s)
    begin
        case b3_st is
            when b3_IDLE =>
                if b2_run_sp_s = '1' then
                    b3_next_st <= b3_WAIT1;
                else
                    b3_next_st <= b3_IDLE;
                end if;
			when b3_WAIT1 =>
                if b2_run_sp_s = '1' and not(b3_sub_cnd_s) then
                    b3_next_st <= b3_WAIT1;
                elsif b2_run_sp_s = '1' and b3_sub_cnd_s then
                    b3_next_st <= b3_WAIT2;
				else
					b3_next_st <= b3_IDLE;
                end if;
			when b3_WAIT2 =>
                if b2_run_sp_s = '1' then
                    b3_next_st <= b3_WAIT2;
				else
					b3_next_st <= b3_CMD;
                end if;
			when b3_CMD =>
                b3_next_st <= b3_IDLE;
		    when others =>
                b3_next_st <= b3_IDLE;
        end case;
    end process B3_L;

    -- 
    B3_R: process (clk)
    begin
        if rising_edge(clk) then
            if ic_rst = '1' then
                b3_st <= b3_IDLE;
                b3_out <= '0';
			else
                b3_st <= b3_next_st;
                case b3_next_st is
                    when b3_IDLE =>
                        b3_out <= '0';
					when b3_WAIT1 =>
                        b3_out <= '0';
					when b3_WAIT2 =>
                        b3_out <= '0';
					when b3_CMD =>
                        b3_out <= '1';
					when others =>
                        b3_out <= '0';
                end case;
            end if;
        end if;
    end process B3_R;
	
	
	
	b3_sub_cnd2_s  <= (b3_out = '1') or  b3_sub_cnd_s;
	
	
	B3: process (clk)
    begin
        if rising_edge(clk) then
			if ic_rst = '1' then
				b3_buf_dir_r <= (others => '0');
				b3_addr_cnt_r <= conv_unsigned(2**A_ram-Mg,A_ram);
			else
				if b2_run_sp_s = '1' then
					if b3_buf_dir_r < Mg-1 then 
						b3_buf_dir_r <= b3_buf_dir_r + 1;
					else 
						b3_buf_dir_r <= (others => '0');
					end if;
				end if;
				if b2_run_sp_s = '1' then
					b3_addr_cnt_r <= b3_addr_cnt_r + 1;
				elsif b3_sub_cnd2_s  then
					b3_addr_cnt_r <= b3_addr_cnt_r - Mg;
				end if;				
			end if;
			if b2_run_sp_s = '1' then
                b3_buf_r(conv_integer(b3_buf_dir_r)) <= b1_cmp_s;
            end if;
		end if;
	end process B3;
	
	b3_cmp_s <= b3_buf_r(conv_integer(b3_buf_dir_r));

	B4: simpledual_2clk_BRAM 
		generic map(A_ram => A_ram, 
					Wd => Ng)
		port map(
			clka => clk,
			clkb => clk_eth,
			ena => b2_run_sp_s,
			enb => ic_en_eth,
			wea => b2_run_sp_s,
			addra => b3_addr_cnt_r,
			addrb => ic_addr_cnt_eth,
			dia => b3_cmp_s,
			dob => od_ram_eth
		);
	
	-- Outputs
	oc_done <= b2_out(2);
	oc_noixe_block <= b1_reg_p_r(0 to Nvnu-1);
	
end rtl;
