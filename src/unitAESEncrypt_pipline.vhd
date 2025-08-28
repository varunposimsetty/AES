library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_encrypt_piplined is
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
end entity AES_encrypt_piplined;

architecture RTL of AES_encrypt_piplined is
    type tRoundBank is array (0 to ROUNDS) of std_ulogic_vector(127 downto 0);

    -- sync, enable signals for different rounds 
    signal inital_data  : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key0_reg     : std_ulogic_vector(127 downto 0) := (others => '0');
    signal en_d1        : std_ulogic := '0';
    signal vld_pipe     : std_ulogic_vector(0 to ROUNDS) := (others => '0');

    signal state_bank   : tRoundBank := (others => (others => '0'));
    signal key_q        : tRoundBank := (others => (others => '0'));
    signal key_w        : tRoundBank := (others => (others => '0'));
    signal sbox_out     : tRoundBank := (others => (others => '0'));
    signal row_out      : tRoundBank := (others => (others => '0'));
    signal col_out      : tRoundBank := (others => (others => '0'));
    signal addrk_out    : tRoundBank := (others => (others => '0'));

    
    function initial_key (key : std_ulogic_vector(KEY_SIZE-1 downto 0)) return std_ulogic_vector is
        variable init_key : std_ulogic_vector(127 downto 0) := (others => '0');
        begin
            if (KEY_SIZE = 128) then
                init_key := key(127 downto 0);
            elsif (KEY_SIZE = 192) then
                init_key := key(191 downto 64);
            elsif (KEY_SIZE = 256) then
                init_key := key(255 downto 128);
            end if;
        return init_key;
    end function;

begin

    -- Round 0 
    ADD_RK_R0 : entity work.addRoundKey(RTL)
        port map (
            i_state_in     => inital_data,
            i_expanded_key => key0_reg,
            o_state_out    => addrk_out(0)
    );

    -- key generate 
    gen_keys : for i in 1 to ROUNDS generate
        NEXT_KEY_G : entity work.next_key(RTL)
        generic map ( key_size => KEY_SIZE, rounds => ROUNDS )
            port map (
                i_prev_key      => key_q(i-1),
                i_current_round => i,
                o_next_key      => key_w(i)
        );
    end generate;

    -- round 1 to ROUNDS-1   
    gen_rounds : for i in 1 to ROUNDS-1 generate
        SBOX_G : entity work.sbox(RTL)
            port map ( 
                i_byte_in => state_bank(i-1), 
                o_byte_out => sbox_out(i) 
        );

        SHIFT_ROWS_G : entity work.shift_rows(RTL)
            port map ( 
                i_row_state_in => sbox_out(i), 
                o_row_state_out => row_out(i) 
        );

        MOVE_COLUMNS_G : entity work.move_columns(RTL)
            port map ( 
                i_column_state_in => row_out(i), 
                o_column_state_out => col_out(i) 
        );

        ADD_RK_G : entity work.addRoundKey(RTL)
            port map ( 
                i_state_in => col_out(i), 
                i_expanded_key => key_w(i), 
                o_state_out => addrk_out(i) 
        );
    end generate;

    -- Final Round 
    SBOX_LAST : entity work.sbox(RTL)
        port map ( 
            i_byte_in => state_bank(ROUNDS-1), 
            o_byte_out => sbox_out(ROUNDS) 
        );

    SHIFT_ROWS_LAST : entity work.shift_rows(RTL)
        port map ( 
            i_row_state_in => sbox_out(ROUNDS), 
            o_row_state_out => row_out(ROUNDS) 
        );

    ADD_RK_LAST : entity work.addRoundKey(RTL)
        port map ( 
            i_state_in => row_out(ROUNDS), 
            i_expanded_key => key_w(ROUNDS), 
            o_state_out => addrk_out(ROUNDS) 
        );


    proc_regs : process(i_clk, i_nrst_async)
        variable cap : std_ulogic_vector(0 to ROUNDS);
        begin
            if (i_nrst_async = '0') then
                state_bank <= (others => (others => '0'));
                key_q      <= (others => (others => '0'));
                vld_pipe   <= (others => '0');
                en_d1      <= '0';
                inital_data <= (others => '0');
                key0_reg   <= (others => '0');
            elsif (rising_edge(i_clk)) then
                cap(0) := en_d1;     
                en_d1 <= i_en_start;
                vld_pipe(0) <= en_d1;             
                for i in 1 to ROUNDS loop
                    cap(i) := vld_pipe(i-1); 
                end loop;
                -- stage 0 : sync
                if cap(0) = '1' then
                    state_bank(0) <= addrk_out(0);
                    key_q(0)      <= key0_reg;  
                end if;

                if i_en_start = '1' then
                    inital_data <= i_data_in;                 
                    key0_reg    <= initial_key(i_cipher_key); 
                end if;
                -- stages 1 to ROUNDS: sync
                for i in 1 to ROUNDS loop
                    if cap(i) = '1' then
                    state_bank(i) <= addrk_out(i);
                    key_q(i)      <= key_w(i);
                    end if;
                end loop;
                for i in 1 to ROUNDS loop
                    vld_pipe(i) <= vld_pipe(i-1);
                end loop;
            end if;
    end process;
    o_data_out <= state_bank(ROUNDS);
end architecture RTL;
