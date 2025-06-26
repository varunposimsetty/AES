library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addRoundKey is 
    generic (
        KEY_SIZE : integer := 128;
        WORD_SIZE : integer := 32;
        ROUNDS : integer := 10-- # of rounds depends on key size for 128 -> 10, 192 -> 12, 256 -> 14
    );
    port (
        i_state_in : in std_ulogic_vector(127 downto 0);
        i_expanded_key : in std_ulogic_vector(127 downto 0);
        o_state_out : out std_ulogic_vector(127 downto 0)
    );
end entity addRoundKey;

architecture RTL of addRoundKey is 
    signal state_out : std_ulogic_vector(127 downto 0) := (others => '0');
    begin
        process(i_state_in,i_expanded_key)
            begin 
            state_out <= std_ulogic_vector(unsigned(i_state_in) xor unsigned(i_expanded_key));
        end process;
            o_state_out <= state_out;
end architecture RTL;