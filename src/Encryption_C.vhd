library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_encrypt_C is
    generic (
        KEY_SIZE  : integer := 128; -- 128/192/256
        TEXT_SIZE : integer := 128; -- 128
        ROUNDS    : integer := 10   -- 10/12/14
    );
    port (
        i_clk         : in  std_ulogic;
        i_nrst_async  : in  std_ulogic;
        i_en_start    : in  std_ulogic;
        i_data_in     : in  std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key  : in  std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out    : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
    );
end entity AES_encrypt_C;

architecture RTL of AES_encrypt_C is
    type tRoundBank is array (natural range <>) of std_ulogic_vector(127 downto 0);
    signal intial_state : std_ulogic_vector(127 downto 0) := (others => '0');
    signal state_bank : tRoundBank(0 to ROUNDS) := (others => (others => '0'));
    signal key_bank : tRoundBank(0 to ROUNDS) := (others => (others => '0'));

    signal s_box_out : tRoundBank(0 to ROUNDS) := (others => (others => '0'));
    signal row_state_out : tRoundBank(0 to ROUNDS) := (others => (others => '0'));
    signal column_state_out : tRoundBank(0 to ROUNDS) := (others => (others => '0'));

begin

    -- Round 0: AddRoundKey only
    ADD_RK_R0 : entity work.addRoundKey(RTL)
        port map (
            i_state_in     => intial_state,
            i_expanded_key => key_bank(0),
            o_state_out    => state_bank(0)
        );

    -- Rounds 1 to ROUNDS-1
    gen_block : for i in 1 to ROUNDS-1 generate
        NEXT_KEY_G : entity work.next_key(RTL)
            generic map (
                key_size => KEY_SIZE,
                rounds   => ROUNDS
            )
            port map (
                i_prev_key       => key_bank(i-1),
                i_current_round  => i,
                o_next_key       => key_bank(i)
        );

        SBOX_G : entity work.sbox(RTL)
            port map (
                i_byte_in  => state_bank(i-1),
                o_byte_out => s_box_out(i)
        );

        SHIFT_ROWS_G : entity work.shift_rows(RTL)
            port map (
                i_row_state_in  => s_box_out(i),
                o_row_state_out => row_state_out(i)
        );

        MOVE_COLUMNS_G : entity work.move_columns(RTL)
            port map (
                i_column_state_in  => row_state_out(i),
                o_column_state_out => column_state_out(i)
        );

        ADD_RK_G : entity work.addRoundKey(RTL)
            port map (
                i_state_in     => column_state_out(i),
                i_expanded_key => key_bank(i),
                o_state_out    => state_bank(i)
        );

    end generate gen_block;

    -- Final round 
    FINAL_KEY : entity work.next_key(RTL)
        generic map (
            key_size => KEY_SIZE,
            rounds   => ROUNDS
        )
        port map (
            i_prev_key       => key_bank(ROUNDS-1),
            i_current_round  => ROUNDS,
            o_next_key       => key_bank(ROUNDS)
    );

    SBOX_LAST : entity work.sbox(RTL)
        port map (
            i_byte_in  => state_bank(ROUNDS-1),
            o_byte_out => s_box_out(ROUNDS)
    );

    SHIFT_ROWS_LAST : entity work.shift_rows(RTL)
        port map (
            i_row_state_in  => s_box_out(ROUNDS),
            o_row_state_out => row_state_out(ROUNDS)
    );

    ADD_RK_LAST : entity work.addRoundKey(RTL)
        port map (
            i_state_in     => row_state_out(ROUNDS),
            i_expanded_key => key_bank(ROUNDS),
            o_state_out    => state_bank(ROUNDS)
    );

   
    proc_initial : process(i_clk, i_nrst_async)
    begin
        if i_nrst_async = '0' then
            intial_state <= (others => '0');
            key_bank(0)  <= (others => '0');

        elsif rising_edge(i_clk) then
            if i_en_start = '1' then
                intial_state <= i_data_in;
                if KEY_SIZE = 128 then
                    key_bank(0) <= i_cipher_key(127 downto 0);
                elsif KEY_SIZE = 192 then
                    key_bank(0) <= i_cipher_key(191 downto 64);
                elsif KEY_SIZE = 256 then
                    key_bank(0) <= i_cipher_key(255 downto 128);
                else
                    key_bank(0) <= (others => '0');
                end if;
            end if;
        end if;
    end process proc_initial;
    o_data_out <= state_bank(ROUNDS);
end architecture RTL;