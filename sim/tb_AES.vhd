library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb is 
end entity tb;

architecture bhv of tb is 
    signal clk : std_ulogic := '0';
    signal rst : std_ulogic := '0';
    signal mode : std_ulogic := '0';
    signal data_in : std_ulogic_vector(127 downto 0) := x"00112233445566778899aabbccddeeff";
    signal key_in : std_ulogic_vector(255 downto 0) := x"b52c505a37d78eda5dd34f20c22540ea1b58963cf8e5bf8ffa85f9f2492505b4";
    signal data_out : std_ulogic_vector(127 downto 0);
    
    begin 
    DUT_AES : entity work.AES(RTL)
        generic map(
            KEY_SIZE  => 256,
            TEXT_SIZE => 128,
            ROUNDS    => 14
        )
        port map(
            i_clk => clk,
            i_nrst_async => rst,
            i_mode => mode,
            i_data_in => data_in,
            i_cipher_key => key_in,
            o_data_out => data_out
        );

     proc_tb : process is 
    begin 
        wait for 10 ns;
        rst <= '1';
        wait for 900 ns;
        key_in <= x"b52c505a37d78eda5dd34f20c22540ea1b58963cf8e5bf8ffa85f9f2492505b4";
        data_in <= x"6bc1bee22e409f96e93d7e117393172a";
        wait for 900 ns;
        --key_in <= x"2b7e151628aed2a6abf7158809cf4f3c";
        data_in <= (others => '0');
        key_in <= (others => '0');
        wait for 900 ns;
        data_in <= (others => '1');
        key_in <= x"ffffffffffffffffffffffffffffffff0000000000000000";
        wait for 900 ns;
        key_in <= x"fbeed618357133667c85e08f7236a8de3c5d2f5d2a7f99f2";
        wait for 725 ns;
        data_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        wait for 200 ns;
        mode <= '1';
        wait for 1600 ns;
        data_in <= x"74e6f7298a9c2d168935f58c001bad88";
        key_in <= x"fbeed618357133667c85e08f7236a8de3c5d2f5d2a7f99f2";
        wait for 1430 ns;
        data_in <= x"f3e25f62d5c85f6addf85f6cbec6d3de";
        wait for 600 ns;
        key_in <= x"ffffffffffffffffffffffffffffffff0000000000000000";
        wait for 460 ns;
        key_in <= x"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b";
        wait for 600 ns;
        mode <= '0';
        wait for 900 ns;
        data_in <= x"6bc1bee22e409f96e93d7e117393172a";
        wait for 900 ns;
        --key_in <= x"2b7e151628aed2a6abf7158809cf4f3c";
        data_in <= (others => '0');
        key_in <= (others => '0');
        wait for 900 ns;
        data_in <= (others => '1');
        key_in <= x"ffffffffffffffffffffffffffffffff0000000000000000";
        wait for 900 ns;
        key_in <= x"fbeed618357133667c85e08f7236a8de3c5d2f5d2a7f99f2";
        wait for 725 ns;
        data_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        wait for 200 ns;
        mode <= '1';
        wait for 1500 ns;
        wait;
    end process proc_tb;

    proc_clk : process is
        begin 
        wait for 1 ns;
        clk <= not clk;
    end process;

end architecture bhv;
