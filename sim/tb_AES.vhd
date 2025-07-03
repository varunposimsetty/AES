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
    signal key_in : std_ulogic_vector(127 downto 0) := x"000102030405060708090a0b0c0d0e0f";
    signal data_out : std_ulogic_vector(127 downto 0);

    begin 
    DUT_AES : entity work.AES(RTL)
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
        wait for 500 ns;
        data_in <= x"6bc1bee22e409f96e93d7e117393172a";
        wait for 600 ns;
        key_in <= x"2b7e151628aed2a6abf7158809cf4f3c";
        wait for 725 ns;
        data_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        wait for 200 ns;
        mode <= '1';
        wait for 600 ns;
        data_in <= x"69C4E0D86A7B0430D8CDB78070B4C55A";
        key_in <= x"000102030405060708090a0b0c0d0e0f";
        wait for 430 ns;
        data_in <= x"00112233445566778899aabbccddeeff";
        wait for 460 ns;
        key_in <= x"000102030405060708090a0b0c0d0e0f";
        wait for 600 ns;
        mode <= '0';
        wait for 520 ns;
        data_in <= x"00112233445566778899aabbccddeeff";
        key_in <= x"000102030405060708090a0b0c0d0e0f";
        wait for 800 ns;
        data_in <= (others => '0');
        wait for 1500 ns;
        mode <= '1';
        wait for 1500 ns;
        wait;
    end process proc_tb;

    proc_clk : process is
        begin 
        wait for 5 ns;
        clk <= not clk;
    end process;

end architecture bhv;
