-- Replace with your QLDPC decoder. You must keep the interface.

library ieee;
use ieee.std_logic_1164.all;
use work.LLR_fpQLP127x254_q_pkg.all;

entity LLR_fpQLP127x254_wrp is
	port(id_llr_block : in p_type_a254xQIstd;           --llr block : qi
		 id_syn_block : in p_type_a127xstd;              --syndrom block : 1 bit
	     ic_decode : in std_logic;                               --decode enable signal
	     od_dec_block : out std_logic_vector(0 to 253);         --decoded block : s[1 0]
	     od_dloop : out std_logic_vector(7 downto 0);            --actual iteration : u[8 0]
	     od_parity : out std_logic;                              --parity check
	     oc_dec_rdy : out std_logic;                             --decode ready signal
	     clk : in std_logic;                                     --clock signal
	     rst : in std_logic);                                    --reset signal
end LLR_fpQLP127x254_wrp;

architecture wrp of LLR_fpQLP127x254_wrp is
	--Wrapped component
	component LLR_fpQLP127x254 is
		port(id_llr_block : in p_type_a254xQIstd;           --llr block : qi
			 id_syn_block : in p_type_a127xstd;              --syndrom block : 1 bit
		     ic_decode : in std_logic;                       --decode enable signal
		     od_dec_block : out std_logic_vector(0 to 253); --decoded block : s[1 0]
		     od_dloop : out std_logic_vector(7 downto 0);    --actual iteration : u[8 0]
		     od_parity : out std_logic;                      --parity check
		     oc_dec_rdy : out std_logic;                     --decode ready signal
		     clk : in std_logic;                             --clock signal
		     rst : in std_logic);                            --reset signal
	end component;
	--Mapped signals

begin

	WC: LLR_fpQLP127x254 port map(id_llr_block => id_llr_block,
							 id_syn_block => id_syn_block,
	                         ic_decode => ic_decode,
	                         od_dec_block => od_dec_block,
	                         od_dloop => od_dloop,
	                         od_parity => od_parity,
	                         oc_dec_rdy => oc_dec_rdy,
	                         clk => clk,
	                         rst => rst);
end wrp;
