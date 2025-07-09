library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES is 
    generic (
        KEY_SIZE  : integer := 128; -- can be 128/192/256
        TEXT_SIZE : integer := 128; -- Always 128
        ROUNDS    : integer := 10 -- # of rounds depends on key size for 128 -> 10, 192 -> 12, 256 -> 14
    );
    port (
        i_clk        : in std_ulogic;
        i_nrst_async : in std_ulogic;
        i_mode       : in std_ulogic; -- '0' for encryption and '1' decryption 
        i_data_in    : in std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key : in std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out   : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
    );
end entity AES;

architecture RTL of AES is 
    signal en_start : std_ulogic := '0';
    signal en_data_out : std_ulogic_vector(TEXT_SIZE-1 downto 0);
    signal de_start : std_ulogic := '0';
    signal de_data_out : std_ulogic_vector(TEXT_SIZE-1 downto 0);

begin 

    unit_Encryption : entity work.AES_encrypt(RTL) 
        generic map(
            KEY_SIZE  => KEY_SIZE,
            TEXT_SIZE => TEXT_SIZE,
            ROUNDS    => ROUNDS
        )
        port map(
        i_clk        => i_clk,
        i_nrst_async => i_nrst_async,
        i_en_start   => en_start,
        i_data_in    => i_data_in,
        i_cipher_key => i_cipher_key,
        o_data_out   => en_data_out
        );
    
    unit_Decryption : entity work.AES_decrypt(RTL)
        generic map(
            KEY_SIZE  => KEY_SIZE,
            TEXT_SIZE => TEXT_SIZE,
            ROUNDS    => ROUNDS
        )
        port map(
        i_clk        => i_clk,
        i_nrst_async => i_nrst_async,
        i_de_start   => de_start,
        i_data_in    => i_data_in,
        i_cipher_key => i_cipher_key,
        o_data_out   => de_data_out
        );

    process(i_clk,i_nrst_async) is 
    variable final_data_out : std_ulogic_vector(TEXT_SIZE-1 downto 0) := (others => '0');
    begin 
        if (i_nrst_async = '0')  then 
            en_start <= '0';
            de_start <= '0';
        elsif(rising_edge(i_clk)) then 
            if(i_mode = '0') then 
                en_start <= '1';
                de_start <= '0';
                final_data_out := en_data_out;
            elsif(i_mode = '1') then
                en_start <= '0';
                de_start <= '1';
                final_data_out := de_data_out;
            end if;
        end if;
        o_data_out <= final_data_out;
    end process;
end architecture RTL;