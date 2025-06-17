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
signal word_0 : std_ulogic_vector(31 downto 0) := (others => '0');
signal word_1 : std_ulogic_vector(31 downto 0) := (others => '0');
signal word_2 : std_ulogic_vector(31 downto 0) := (others => '0');
signal word_3 : std_ulogic_vector(31 downto 0) := (others => '0');
signal expanded_key_temp : std_ulogic_vector(((rounds+1)*128)-1 downto 0) := (others => '0');


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
            temp(i) := byte_out;
        end loop;
    end function;

    process(i_key) 
    variable word : tWord := (others => '0');
    variable rot_last_word :tWord := (others => '0');
    variable sub_word_3 : tWord := (others => '0');
    variable final_word_3 : std_ulogic_vector(31 downto 0) := (others => '0');
    variable temp_1 : std_ulogic_vector(31 downto 0) := (others => '0');
    variable temp_2 : std_ulogic_vector(31 downto 0) := (others => '0');
    variable temp_3 : std_ulogic_vector(31 downto 0) := (others => '0');
    variable temp_4 : std_ulogic_vector(31 downto 0) := (others => '0');
        if (key_size = 128) then 
            expanded_key(0) <= i_key;
        elsif(key_size = 196) then 
            expanded_key(0) <= i_key(191 downto 64);
        elsif(key_size = 256) then 
            expanded_key(0) <= i_key(255 downto 128);
        end if;

        key_expansion_loop : for i in 0 to rounds-1 loop
            word(0) := expanded_key(i)(31 downto 24);
            word(1) := expanded_key(i)(23 downto 16);
            word(2) := expanded_key(i)(15 downto 8);
            word(3) := expanded_key(i)(7 downto 0);
            rot_last_word := rotate(word);
            sub_word_3 := substitue(rot_last_word);
            final_word_3 := (sub_word_3(0) xor round_constant(i)) & sub_word_3(1) & sub_word_3(2) & sub_word_3(3);
            word_0 <= expanded_key(i)(127 downto 96);
            word_1 <= expanded_key(i)(95 downto 64);
            word_2 <= expanded_key(i)(63 downto 32);
            word_3 <= final_word_3;
            temp_1 := word_0 xor word_3;
            temp_2 := temp_1 xor word_1;
            temp_3 := temp_2 xor word_2;
            temp_4 := temp_3 xor word;
            expanded_key(i+1) <= temp_1 & temp_2 & temp_3 & temp_4;   
        end loop;

        final_loop : for i in 0 to rounds loop 
            expanded_key_temp(((i+1)*128)-1 downto i*128) <= expanded_key(i);
        end loop;
    end process;
    o_expanded_key <= expanded_key_temp;
end architecture RTL;
