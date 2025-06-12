use ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unitKeyExpansion is 
    generic (
        KEY_SIZE : integer := 128;
        WORD_SIZE : integer := 32;
        ROUNDS : integer := 10; -- # of rounds depends on key size for 128 -> 10, 192 -> 12, 256 -> 14
    );
    port (
        i_clk : in std_ulogic;
        i_nrst_async : in std_ulogic;
        i_key : in std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_round_keys : in std_ulogic_vector()
    );
end entity unitKeyExpansion;

architecture RTL of unitKeyExpansion is 
    signal round_count : integer := ROUNDS + 1;



end architecture RTL;