
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_decrypt_piplined is
    generic (
        KEY_SIZE  : integer := 128; -- 128/192/256
        TEXT_SIZE : integer := 128; -- 128
        ROUNDS    : integer := 10   -- 10/12/14
    );
    port (
        i_clk         : in  std_ulogic;
        i_nrst_async  : in  std_ulogic;
        i_de_start    : in  std_ulogic;
        i_data_in     : in  std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key  : in  std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out    : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
    );
end entity AES_decrypt_piplined;

architecture RTL of AES_decrypt_piplined is
    type tRoundBank is array (0 to ROUNDS) of std_ulogic_vector(127 downto 0);
    signal en_d1 : std_ulogic := '0';
    signal state_bank : tRoundBank := (others => (others => '0'));
    signal vld_pipe  : std_ulogic_vector(0 to ROUNDS) := (others => '0');
    signal initial_state : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key_bank  : tRoundBank := (others => (others => '0'));
    signal sbox_out       : tRoundBank := (others => (others => '0'));
    signal row_out        : tRoundBank := (others => (others => '0'));
    signal invcol_out     : tRoundBank := (others => (others => '0')); 
    signal addrk_out      : tRoundBank := (others => (others => '0'));

    function initial_key (key : std_ulogic_vector(KEY_SIZE-1 downto 0)) 
        return std_ulogic_vector is
        variable init_key : std_ulogic_vector(127 downto 0);
    begin
        if (KEY_SIZE = 128) then
            init_key := key;
        elsif (KEY_SIZE = 192) then
            init_key := key(191 downto 64);
        else
            init_key := key(255 downto 128);
        end if;
        return init_key;
    end function;

begin
    gen_keys: for i in 1 to ROUNDS generate
        NEXT_KEY_G: entity work.next_key(RTL)
            generic map (
                key_size => KEY_SIZE,
                rounds   => ROUNDS
            )
            port map (
                i_prev_key       => key_bank(i-1),
                i_current_round  => i,
                o_next_key       => key_bank(i)
            );
    end generate;

    -- Initial 
    ADD_RK_R0: entity work.addRoundKey(RTL)
        port map (
            i_state_in     => initial_state,
            i_expanded_key => key_bank(ROUNDS),  
            o_state_out    => addrk_out(0)
        );

    -- Rounds 1 to ROUNDS-1 
    gen_rounds: for i in 1 to ROUNDS-1 generate
        INV_SHIFT_ROWS_G: entity work.inv_shift_rows(RTL)
            port map (
                i_inv_row_state_in  => state_bank(i-1),
                o_inv_row_state_out => row_out(i)
            );

        INV_SBOX_G: entity work.inv_sbox(RTL)
            port map (
                i_inv_byte_in  => row_out(i),
                o_inv_byte_out => sbox_out(i)
            );

        ADD_RK_G: entity work.addRoundKey(RTL)
            port map (
                i_state_in     => sbox_out(i),
                i_expanded_key => key_bank(ROUNDS - i), 
                o_state_out    => addrk_out(i)
            );

        INV_MIX_COLUMNS_G: entity work.inv_move_columns(RTL)
            port map (
                i_inv_column_state_in  => addrk_out(i),
                o_inv_column_state_out => invcol_out(i)
            );
    end generate;

    -- Final round 
    INV_SHIFT_ROWS_LAST: entity work.inv_shift_rows(RTL)
        port map (
            i_inv_row_state_in  => state_bank(ROUNDS-1),
            o_inv_row_state_out => row_out(ROUNDS)
        );

    INV_SBOX_LAST: entity work.inv_sbox(RTL)
        port map (
            i_inv_byte_in  => row_out(ROUNDS),
            o_inv_byte_out => sbox_out(ROUNDS)
        );

    ADD_RK_LAST: entity work.addRoundKey(RTL)
        port map (
            i_state_in     => sbox_out(ROUNDS),
            i_expanded_key => key_bank(0), 
            o_state_out    => addrk_out(ROUNDS)
        );

    proc_in: process(i_clk, i_nrst_async)
    begin
        if i_nrst_async = '0' then
            initial_state <= (others => '0');
            en_d1 <= '0';
            vld_pipe <= (others => '0');
            state_bank <= (others => (others => '0'));
        elsif rising_edge(i_clk) then
            en_d1 <= i_de_start;

            if i_de_start = '1' then
                initial_state <= i_data_in(127 downto 0);
                key_bank(0) <= initial_key(i_cipher_key);
            end if;
            vld_pipe(0) <= en_d1;
            for j in 1 to ROUNDS loop
                vld_pipe(j) <= vld_pipe(j-1);
            end loop;
            if en_d1 = '1' then
                state_bank(0) <= addrk_out(0);
            end if;
            for j in 1 to ROUNDS-1 loop
                if vld_pipe(j-1) = '1' then
                    state_bank(j) <= invcol_out(j);
                end if;
            end loop;
            if vld_pipe(ROUNDS-1) = '1' then
                state_bank(ROUNDS) <= addrk_out(ROUNDS);
            end if;
        end if;
    end process;

    o_data_out <= state_bank(ROUNDS);

end architecture RTL;

