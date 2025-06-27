library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb is 
end entity tb;

architecture bhv of tb is 
    signal clk : std_ulogic := '0';
    signal rst : std_ulogic := '0';
    signal start : std_ulogic := '0';
    signal data_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal data_out : std_ulogic_vector(127 downto 0);

    begin 
    DUT_AES : entity work.AES(RTL)
        port map(
            i_clk => clk,
            i_nrst_async => rst,
            i_start => start,
            i_data_in => data_in,
            i_cipher_key => key_in,
            o_data_out => data_out
        );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        rst <= '1';
        start <= '1';
        data_in <= x"1A4567F310245543210A135667900100";
        key_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        wait for 125 ns;
        data_in <= x"FEDCBA9876543210FEDCBA9876543210";
        key_in <= x"1A4567F310245543210A135667900100";
        wait for 130 ns;
        data_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        key_in <= x"FEDCBA9876543210FEDCBA9876543210";
        wait for 120 ns;
        wait;
    end process proc_tb;

    proc_clk : process is
        begin 
        wait for 5 ns;
        clk <= not clk;
    end process;

end architecture bhv;
