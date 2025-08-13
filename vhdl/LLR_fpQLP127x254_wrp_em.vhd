library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use work.LLR_fpQLP127x254_q_pkg.all;
use work.LLR_fpQLP127x254_q_em_pkg.all;

entity LLR_fpQLP127x254_wrp_em is
port (
        ic_start_dec : in std_logic;
		id_loop_max : in std_logic_vector(7 downto 0); -- u[8,0]
		id_thr_pe : in std_logic_vector(17 downto 0); -- s[18 13]
		id_t_err : in unsigned(15 downto 0); --u[16,0]
		ic_rst: in std_logic;
		clk : in std_logic;
		od_loop_max : out std_logic_vector(7 downto 0); -- u[8,0]
		od_thr_pe : out std_logic_vector(17 downto 0); -- s[18 13]
		od_t_err : out unsigned(15 downto 0); -- u[16,0]
		od_errl_cnt_r : out unsigned(15 downto 0); -- u[16,0]
		od_errf_cnt_r : out unsigned(15 downto 0); -- u[16,0]
		od_dec_cnt_r : out unsigned(79 downto 0); -- u[80,0]
		od_dloop_cnt_r : out unsigned(79 downto 0);   -- u[80,0] 
		oc_runnig : out std_logic;
		oc_done : out std_logic;
		-- Ethernet interfaz ----
		clk_eth : in std_logic;
		ic_en_eth : in std_logic;
		ic_addr_cnt_eth : in unsigned(19 downto 0); 
		od_ram_eth : out std_logic_vector(0 to 79) 
    );
end LLR_fpQLP127x254_wrp_em;

architecture str of LLR_fpQLP127x254_wrp_em is
	-- Component declaration of the tested unit
	component LLR_fpQLP127x254_xH is 
		port(id_noixe_block : in std_logic_vector(0 to 253); -- noisex : 1 bit 
			 od_syn_block : out p_type_a127xstd); -- syndrome block : 1 bit
		end component; 
	component LLR_fpQLP127x254_wrp is
		port(id_llr_block : in p_type_a254xQIstd;           --llr block : qi
			 id_syn_block : in p_type_a127xstd;              --syndrome block : 1 bit
		     ic_decode : in std_logic;                              --decode enable signal
		     od_dec_block : out std_logic_vector(0 to 253);         --decoded block : s[1 0]
		     od_dloop : out std_logic_vector(7 downto 0);           --actual iteration : u[8 0]
		     od_parity : out std_logic;                             --parity check
		     oc_dec_rdy : out std_logic;                            --decode ready signal
		     clk : in std_logic;                                    --clock signal
		     rst : in std_logic);                                   --reset signal
	end component;
	component LLR_fpQLP127x254_xHlogic is 
		port(id_xor_block : in std_logic_vector(0 to 253); -- check xor : 1 bit 
			 od_logic_block : out std_logic_vector(0 to M_Hlogic-1)); -- logic : 1 bit 
		end component; 	
	component fsm_em is
		port (id_dloop : in std_logic_vector(7 downto 0);  
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
	end component; 	
	component fsm_noixe is
		generic (Ng : integer := 4; 
				 Mg : integer := 3; 
				 DEBUG : integer := 1); 
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
			-- Ethernet interface ----
			clk_eth : in std_logic;
			ic_en_eth : in std_logic;
			ic_addr_cnt_eth : in unsigned(A_ram-1 downto 0);
			od_ram_eth : out std_logic_vector(0 to Ng-1)
	);
	end component;
	component fsm_main is
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
	end component;
	
	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	
	signal b0_start_s : std_logic;
	signal b0_rst_full_s : std_logic;
	signal b0_rst_ini_s : std_logic;
	signal b0_done_s : std_logic;
	
	signal b1_rdec_s : std_logic;
	signal b1_edec_s : std_logic;
	signal b1_load_s : std_logic;
	signal b1_rst_s : std_logic;
	signal b2_done_s : std_logic;
	signal b2_ram_eth : std_logic_vector(0 to 79) := (others => '0');
	signal b2_noixe_block_s : std_logic_vector(0 to 253);
	signal b3_syn_block: p_type_a127xstd := (others => '0');
	
	signal b4_dec_block_s: std_logic_vector(0 to 253);
	signal b4_dloop_s: std_logic_vector(7 downto 0);
	signal b4_parity_s: std_logic;
	signal b4_parity_check_r: std_logic;
	signal b4_dec_rdy_s: std_logic;
	
	signal b5_xor_block_s: std_logic_vector(0 to 253);
	signal b5_logic_block_s : std_logic_vector(0 to M_Hlogic-1);
	constant b5_zero_xor_block : std_logic_vector(0 to 253) := (others => '0');
	constant b5_zero_logic_block : std_logic_vector(0 to M_Hlogic-1) := (others => '0');
	
	signal b6_incr_errl_cnt_s : std_logic;
	signal b6_incr_errl_cnt_r : std_logic;
	signal b6_incr_errf_cnt_s : std_logic;
	signal b6_incr_errf_cnt_r : std_logic;
	
	signal b7_edec_r : std_logic;
	signal b7_dec_cnt_r : unsigned(79 downto 0);
	
	signal b8_errl_cnt_r : unsigned(15 downto 0);
	signal b8_errf_cnt_r : unsigned(15 downto 0);
	signal b8_edec_r : std_logic;
	
	signal b9_dloop_r: unsigned(7 downto 0);
	signal b9_dloop_cnt_r : unsigned(85 downto 0);
	signal b9_dloop_cnt_esc_s : unsigned(79 downto 0);
	signal b9_edec_r : std_logic;
	
	signal b10_loop_max : std_logic_vector(7 downto 0);
	signal b10_thr_pe : std_logic_vector(17 downto 0);
	signal b10_t_err : unsigned(15 downto 0);
begin
	
	-- FSM MAIN
	B0 : fsm_main 
	port map (id_a_err => b8_errl_cnt_r,
			id_t_err => id_t_err,
			ic_start => ic_start_dec,
			ic_rst => ic_rst,
			clk => clk,
			oc_done => b0_done_s,
			oc_start => b0_start_s,
			oc_rst_full => b0_rst_full_s,
			oc_rst_ini => b0_rst_ini_s
    );
	-- FSM EM
	B1 : fsm_em
	port map (id_dloop => b4_dloop_s,
			clk => clk,
			ic_rst => b0_rst_full_s, 
			ic_start => b0_start_s,
			ic_done => b2_done_s,
			ic_par => b4_parity_check_r, 
			ic_en => b4_dec_rdy_s,
			id_loop_max => id_loop_max,
			oc_rst => b1_rst_s,
			oc_rdec => b1_rdec_s,
			oc_load => b1_load_s,
			oc_edec => b1_edec_s
	);
	-- FSM NOIXE
	B2 : fsm_noixe
		generic map(Ng => Ng,Mg => Mg,DEBUG  => DEBUG)
		port map (id_thr_pe => id_thr_pe,
			ic_rst => b1_rst_s,
			ic_start => b0_start_s, --ic_start_dec,
			ic_load => b1_load_s,
			ic_edec => b7_edec_r,
			ic_errl => b6_incr_errl_cnt_r,
			clk => clk,
			oc_noixe_block => b2_noixe_block_s,
			oc_done => b2_done_s,
			-- Ethernet interfaz ----
			clk_eth => clk_eth,
			ic_en_eth => ic_en_eth,
			ic_addr_cnt_eth => ic_addr_cnt_eth(A_ram-1 downto 0),
			od_ram_eth => b2_ram_eth(0 to Ng-1)
		);
	-- xH
	B3: LLR_fpQLP127x254_xH  
	port map(id_noixe_block => b2_noixe_block_s,
			 od_syn_block => b3_syn_block
	);
	
	-- DECODER: Replace with your decoder. You must respect the interface.
	B4 : LLR_fpQLP127x254_wrp
	port map(
		id_llr_block => cnt_llr_in,  
		id_syn_block => b3_syn_block,
		ic_decode => b1_rdec_s,
		od_dec_block => b4_dec_block_s,
		od_dloop => b4_dloop_s,
		od_parity => b4_parity_s,
		oc_dec_rdy => b4_dec_rdy_s,
		clk => clk,
		rst => b0_rst_full_s 
	);
	
	b4_parity_check_r <= b4_parity_s; 
		
	-- Check xor
	b5_xor_block_s <= b2_noixe_block_s xor b4_dec_block_s;
	
	-- xHlogic
	B5 : LLR_fpQLP127x254_xHlogic 
	port map(id_xor_block => b5_xor_block_s, 
		od_logic_block => b5_logic_block_s
	);	
		
	-- Check if b5_logic_block_s==zero
	b6_incr_errl_cnt_s <= '0' when b5_logic_block_s=b5_zero_logic_block else '1';
	b6_incr_errf_cnt_s <= '0' when b5_xor_block_s=b5_zero_xor_block else '1';
    
	B6: process (clk)
    begin
        if rising_edge(clk) then
            if b1_edec_s = '1' then
				b6_incr_errl_cnt_r <= b6_incr_errl_cnt_s;
				b6_incr_errf_cnt_r <= b6_incr_errf_cnt_s;
            end if;
        end if;
    end process B6;
	
	-- Frame counter
	B7: process (clk)
    begin
        if rising_edge(clk) then
            if b0_rst_ini_s = '1' then 
				b7_dec_cnt_r <= (others => '0');
            elsif  b1_edec_s = '1' then
				b7_dec_cnt_r <= b7_dec_cnt_r + conv_unsigned(1,b7_dec_cnt_r'length);
            end if;
			b7_edec_r <= b1_edec_s;
        end if;
    end process B7;
	
	-- Logic and physical error (eL, eF) counter
	B8: process (clk)
    begin
        if rising_edge(clk) then
            if b0_rst_ini_s = '1' then
				b8_errl_cnt_r <= (others => '0');
				b8_errf_cnt_r <= (others => '0');
            elsif  b7_edec_r = '1' then
				b8_errl_cnt_r <= b8_errl_cnt_r + b6_incr_errl_cnt_r;
				b8_errf_cnt_r <= b8_errf_cnt_r + b6_incr_errf_cnt_r;
            end if;
			b8_edec_r <= b7_edec_r;
        end if;
    end process B8;
	
	-- Dloop counter
	B9: process (clk)
    begin
        if rising_edge(clk) then
			if  b1_edec_s = '1' then
				b9_dloop_r <= conv_unsigned(conv_integer(b4_dloop_s),b9_dloop_r'length);
			end if;
            if b0_rst_ini_s = '1' then
				b9_dloop_cnt_r <= (others => '0');
            elsif  b7_edec_r = '1' then
				b9_dloop_cnt_r <= b9_dloop_cnt_r + b9_dloop_r;
            end if;
			b9_edec_r <= b8_edec_r;
        end if;
    end process B9;
	
	b9_dloop_cnt_esc_s <= b9_dloop_cnt_r(79-ESC_DLOOP_CNT downto 0+ESC_DLOOP_CNT);
	
	-- Reg. configuration
	B10: process (clk)
    begin
        if rising_edge(clk) then
			if  b0_rst_ini_s = '1' then
				b10_loop_max <= id_loop_max;
				b10_thr_pe <= id_thr_pe;
				b10_t_err <= id_t_err;
            end if;
        end if;
    end process B10;
	
	
	-- Outputs
	oc_runnig <= b0_start_s;
	oc_done <= b0_done_s;
	od_loop_max<= b10_loop_max;
	od_thr_pe <= b10_thr_pe;
	od_t_err <= b10_t_err;
	od_errf_cnt_r <= b8_errf_cnt_r;
	od_errl_cnt_r <= b8_errl_cnt_r;
	od_dec_cnt_r <= b7_dec_cnt_r;
	od_dloop_cnt_r <= b9_dloop_cnt_esc_s;
	od_ram_eth <= b2_ram_eth;
	
	-- DEBUG
	DEBUG_ON : if DEBUG = 1 generate
		db_load <= b1_load_s;
		db_b1_edec_s <= b1_edec_s;
		db_b7_edec_r <= b7_edec_r;
		db_b8_edec_r <= b8_edec_r;
		db_b9_edec_r <= b9_edec_r;
		db_b4_dec_block_s <= b4_dec_block_s;
		db_b4_parity_check_r <= b4_parity_check_r;
		db_b7_dec_cnt_r <= b7_dec_cnt_r;
		db_b8_errf_cnt_r <= b8_errf_cnt_r;
		db_b8_errl_cnt_r <= b8_errl_cnt_r;
		db_b9_dloop_cnt_r <= b9_dloop_cnt_r;
	end generate DEBUG_ON;
end str;
