-- Replace with your Gaussian noise generator. Must respect the interface


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity prng_normal_t64_wrap is
    generic(p_seed_num : integer;     				   --seed number: [0-31]
            romtype : integer);                        --coefficients ROM type (0: single 512x27, 1: splitted 256x21,256x15,256x12)
    port(ic_clk : in std_logic;                        --clock signal
         ic_ena : in std_logic;                        --enable signal
         ic_rst : in std_logic;                        --reset signal
         od_randn : out std_logic_vector(17 downto 0); --random number : s[18 13]
         oc_randn_dv : out std_logic);                 --random number data-valid
end prng_normal_t64_wrap;

architecture rtl of prng_normal_t64 is
component prng_normal_t64 is
		generic(p_seed_num : integer;     				   --seed number: [0-31]
				romtype : integer);                        --coefficients ROM type (0: single 512x27, 1: splitted 256x21,256x15,256x12)
		port(ic_clk : in std_logic;                        --clock signal
			 ic_ena : in std_logic;                        --enable signal
			 ic_rst : in std_logic;                        --reset signal
			 od_randn : out std_logic_vector(17 downto 0); --random number : s[18 13]
			 oc_randn_dv : out std_logic);                 --random number data-valid
	end component;

begin
	
  PN: prng_normal_t64 generic map(p_seed_num => eNg, romtype => 0)
		port map (ic_clk => ic_clk,
				 ic_ena => ic_ena,
				 ic_rst => ic_rst,
				 od_randn => od_randn,
				 oc_randn_dv =>  oc_randn_dv);
end rtl;
