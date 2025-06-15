library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity key_expansion is 
    generic(
        key_size : integer := 128;
        word_size : integer := 32;
        rounds : integer := to_integer(key_size/word_size)
    );
    port (
        i_key : in std_ulogic_vector(key_size-1 downto 0);
        o_expanded_key : out std_ulogic_vector(((rounds+1)*128)-1 downto 0)
    );
end entity key_expansion;

architecture RTL of key_expansion is 
type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);
signal expanded_key : tExpandedKeyBank := ((others => '0'));
signal byte_in : std_ulogic_vector(7 downto 0) := (others => '0');
signal byte_out : std_ulogic_vector(7 downto 0);
begin
    SBox : entity work.sbox(RTL)
    port map(
        i_byte_in => byte_in,
        o_byte_out => byte_out
    );

    process(i_key) 
        if (key_size = 128) then 
            expanded_key(0) <= i_key;
        elsif(key_size = 196) then 
            expanded_key(0) <= i_key(191 downto 64);
        elsif(key_size = 256) then 
            expanded_key(0) <= i_key(255 downto 128);
        end if;
        gen_loop : for i in 0 to 
        

    end process;
         

end architecture RTL;
