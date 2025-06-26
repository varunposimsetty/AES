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
begin 

    SBOX : entity work.sbox(RTL)
            port map(
                i_byte_in => byte_in,
                o_byte_out => byte_out
        );
        
        SHIFT_ROWS : entity work.shift_rows(RTL)
            port map(
               i_row_state_in => row_state_in,
               o_row_state_out => row_state_out
        );

        MOVE_COLUMNS : entity work.move_columns(RTL)
            port map(
                i_column_state_in => column_state_in,
                o_column_state_out => column_state_out
        );

        KEY_EXPANSION : entity work.key_expansion(RTL)
            generic map(
                key_size => KEY_SIZE,
                word_size => TEXT_SIZE,
                rounds => ROUNDS

            )
            port map(
                i_key => i_cipher_key,
                o_expanded_key => expanded_key
        );

        ADD_ROUND_KEY : entity work.addRoundKey(RTL)
            port map(
                i_state_in => round_key_state_in,
                i_expanded_key => round_expanded_key,
                o_state_out => round_key_state_out
        );

    process(i_clk,i_nrst_async) is 
        variable count : integer := 0;
    begin 
        if(i_nrst_async = '0') then 

        elsif(rising_edge(i_clk)) then
            case count is 
                when 0 => 
                     

            
