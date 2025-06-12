library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unitAES is 
    generic (
        KEY_SIZE  : integer := 128;
        TEXT_SIZE : integer := 128;
    );
    port (
        i_data_in  : in std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key : in std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out : out std_ulogic_vector(TEXT_SIZE-1 downto 0)

    );
end entity unitAES;

architecture RTL of unitAES is 


end architecture RTL;