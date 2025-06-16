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
type tRoundConstants is array(0 to 13) of std_ulogic_vector(7 downto 0);
type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);
type tWord is array(0 to 3) of std_ulogic_vector(7 downto 0);
signal expanded_key : tExpandedKeyBank := (others => '0');
signal byte_in : std_ulogic_vector(7 downto 0) := (others => '0');
signal byte_out : std_ulogic_vector(7 downto 0);
signal last_word : tWord := (others => '0');

constant round_constant : tRoundConstants := (
    0 => x"01" ,
    1 => x"02",
    2 => x"04",
    3 => x"08",
    4 => x"10",
    5 => x"20",
    6 => x"40",
    7 => x"80",
    8 => x"1B",
    9 => x"36",
    10 => x"6C",
    11 => x"D8",
    12 => x"AB",
    13 => x"4D"
);

begin
    SBox : entity work.sbox(RTL)
    port map(
        i_byte_in => byte_in,
        o_byte_out => byte_out
    );

    -- Function to rotate the last word in the 4 words
    function rotate(last_word : tWord) return tWord is 
        variable rot_word : tWord := (others => '0');
        rot_word(0) := last_word(1);
        rot_word(1) := last_word(2);
        rot_word(2) := last_word(3);
        rot_word(3) := last_word(0);
        return rot_word;
    end function;

    function substitue(last_word : tWord ) return tWord is 
        variable temp : tWord := (others => '0');
        for i in 0 to 3 loop 
            byte_in <= last_word(i);
            temp(i) <= byte_out;
        end loop;
    end function;

    process(i_key) 
    variable word_0 : tWord := (others => '0');
    variable word_1 : tWord := (others => '0');
    variable word_2 : tWord := (others => '0');
    variable word_3 : tWord := (others => '0');
        if (key_size = 128) then 
            expanded_key(0) <= i_key;
        elsif(key_size = 196) then 
            expanded_key(0) <= i_key(191 downto 64);
        elsif(key_size = 256) then 
            expanded_key(0) <= i_key(255 downto 128);
        end if;

        word_0 <= expanded_key(0)(0) <= 
        
    


    end process;
end architecture RTL;
