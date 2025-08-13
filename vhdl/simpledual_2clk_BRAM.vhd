library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity simpledual_2clk_BRAM is
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
		dob : out std_logic_vector(0 to Wd-1)
);
end simpledual_2clk_BRAM;

architecture syn of simpledual_2clk_BRAM is

	type ram_type is array (0 to 2**A_ram-1) of std_logic_vector(0 to Wd-1);
	signal RAM : ram_type;
	attribute ram_style : string; 
	attribute ram_style of RAM : signal is "block"; 

begin

	process(clka)
	begin
		if rising_edge(clka) then
			if ena = '1' then
				if wea = '1' then
					RAM(conv_integer(addra)) <= dia;
				end if;
			end if;
		end if;
	end process;

	process(clkb)
	begin
		if rising_edge(clkb) then
			if enb = '1' then
				dob <= RAM(conv_integer(addrb));
			end if;
		end if;
	end process;
	
end syn;


