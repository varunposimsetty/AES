library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES is 
    generic (
        KEY_SIZE  : integer := 128;
        TEXT_SIZE : integer := 128;
        ROUNDS    : integer := 10 -- # of rounds depends on key size for 128 -> 10, 192 -> 12, 256 -> 1
    );
    port (
        i_clk : in std_ulogic;
        i_nrst_async : in std_ulogic;
        i_start : in std_ulogic;
        i_data_in  : in std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key : in std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
    );
end entity AES;

architecture RTL of AES is
    signal byte_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal byte_out : std_ulogic_vector(127 downto 0);
    signal row_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal row_state_out : std_ulogic_vector(127 downto 0);
    signal column_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal column_state_out : std_ulogic_vector(127 downto 0);
    signal expanded_key : std_ulogic_vector(((rounds+1)*128) - 1 downto 0);
    signal round_key_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal round_expanded_key : std_ulogic_vector(127 downto 0) := (others => '0');
    signal round_key_state_out : std_ulogic_vector(127 downto 0);
    --
    type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);
    signal expanded_key_bank : tExpandedKeyBank := (others => (others => '0'));