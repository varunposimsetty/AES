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
    -- SYNC DATA
    signal data_sync : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key_sync : std_ulogic_vector(127 downto 0) := (others => '0');
    signal sync : std_ulogic := '1';
    -- Devices
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
    ---
    type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);
    signal expanded_state_bank : tExpandedKeyBank := (others => (others => '0'));
    
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
                i_key => key_sync,
                o_expanded_key => expanded_key
        );

        ADD_ROUND_KEY : entity work.addRoundKey(RTL)
            port map(
                i_state_in => round_key_state_in,
                i_expanded_key => round_expanded_key,
                o_state_out => round_key_state_out
        ); 
process(i_clk,i_nrst_async) is
    variable ext_count : integer := 0;
    variable int_count : integer := 0;
    variable expanded_key_bank_var : tExpandedKeyBank := (others => (others => '0'));
    variable internal : std_ulogic_vector(127 downto 0) := (others => '0');
    variable expanded_state_bank_var : tExpandedKeyBank := (others => (others => '0'));
    variable data_out : std_ulogic_vector(127 downto 0) := (others => '0'); 
      begin 
        if (i_nrst_async = '0') then 
            byte_in <= (others => '0');
            row_state_in <= (others => '0');
            column_state_in <= (others => '0');
            round_key_state_in <= (others => '0');
            int_count := 0;
            ext_count := 0;
        elsif(rising_edge(i_clk)) then
            if (i_start = '1' ) then 
                if (sync = '1') then
                    sync <= '0'; 
                    data_sync <= i_data_in;
                    key_sync <= i_cipher_key;
                elsif(sync = '0') then 
                    case ext_count is 
                        when 0 => 
                            -- Round key  
                            round_key_state_in <= data_sync;
                            round_expanded_key <= key_sync;
                            expanded_state_bank(ext_count) <= round_key_state_out;
                            ext_count := ext_count + 1;
                        when 1 to 9 =>
                            case int_count is 
                                when 0 => 
                                    byte_in <= internal;
                                    --expanded_state_bank_var(ext_count) := byte_out;
                                    internal := byte_out;
                                    int_count := int_count + 1;
                                when 1 => 
                                    row_state_in <= internal;
                                    internal := row_state_out;
                                    int_count := int_count + 1;
                                when 2 =>
                                    column_state_in <= internal;
                                    internal := column_state_out;
                                    int_count := int_count + 1;
                                when 3 =>
                                    round_key_state_in <= internal;
                                    round_expanded_key <= expanded_key((ext_count+1)*128-1 downto ext_count*128);
                                    internal := round_key_state_out;
                                    expanded_state_bank(ext_count) <= round_key_state_out;
                                    int_count := 0;
                                    ext_count := ext_count + 1;
                                when others => 
                                    null;
                            end case;
                        when 10 =>
                            case int_count is 
                                when 0 => 
                                    byte_in <= expanded_state_bank_var(ext_count-1);
                                    internal := byte_out;
                                    int_count := int_count + 1;
                                when 1 => 
                                    row_state_in <= internal;
                                    internal := row_state_out;
                                    int_count := int_count + 1;
                                when 2 =>
                                    round_key_state_in <= internal;
                                    round_expanded_key <= expanded_key((ext_count+1)*128-1 downto ext_count*128);
                                    internal := round_key_state_out;
                                    expanded_state_bank(ext_count) <= round_key_state_out;
                                    data_out := internal;
                                    int_count := 0;
                                    ext_count := 0;
                                    sync <= '1';
                                when others => 
                                    null;
                            end case;
                        when others => 
                            null;
                    end case;
                end if;
                end if;
            end if;
            o_data_out <= data_out;
    end process;
end architecture RTL;

