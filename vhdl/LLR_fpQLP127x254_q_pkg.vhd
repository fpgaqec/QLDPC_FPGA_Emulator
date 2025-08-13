library ieee;
use ieee.std_logic_1164.all;

package LLR_fpQLP127x254_q_pkg is
	--generics
	constant qf: integer:= 3; --3 bits frac
	constant qi: integer:= 7; --s[7 3]
	constant qm: integer:= 7; --sm[1+6 3]
	constant ql: integer:= 8; --dsm[1,1+6 3]
	constant sa: integer:= 2; --1..4 : alpha = 1-2^-sa
	constant lvnu: integer:= 1; --1
	constant lcnu: integer:= 1; --1
	--types
	type p_type_a5x2std is array(0 to 4) of std_logic_vector(1 downto 0);
	type p_type_a5xQMstd is array(0 to 4) of std_logic_vector(qm-1 downto 0);
	type p_type_a5xQMm1std is array(0 to 4) of std_logic_vector(qm-2 downto 0);
	type p_type_a5xQLstd is array(0 to 4) of std_logic_vector(ql-1 downto 0);
	type p_type_a8x1int is array(0 to 7) of integer;
	type p_type_a5x1int is array(0 to 4) of integer;
	type p_type_a8xstd is array(0 to 7) of std_logic;
	type p_type_a8x2std is array(0 to 7) of std_logic_vector(1 downto 0);
	type p_type_a8xQMstd is array(0 to 7) of std_logic_vector(qm-1 downto 0);
	type p_type_a8xQLstd is array(0 to 7) of std_logic_vector(ql-1 downto 0);
	type p_type_a254xQIstd is array(0 to 253) of std_logic_vector(qi-1 downto 0);
	type p_type_a127xstd is array(0 to 126) of std_logic;
	type p_type_m127a8x1int is array(0 to 126) of p_type_a8x1int;
	type p_type_m254a5x1int is array(0 to 253) of p_type_a5x1int;
	--constraints
--
end package;
