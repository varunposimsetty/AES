library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb is 
end entity tb;

architecture bhv of tb is 
    signal data_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal data_out : std_ulogic_vector(127 downto 0);

    begin 
    DUT_AES : entity work.AES(RTL)
        port map(
            i_data_in => data_in,
            i_cipher_key => key_in,
            o_data_out => data_out
        );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        data_in <= x"1A4567F310245543210A135667900100";
        key_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        wait for 20 ns;
        data_in <= x"FEDCBA9876543210FEDCBA9876543210";
        key_in <= x"1A4567F310245543210A135667900100";
        wait for 30 ns;
        data_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        key_in <= x"FEDCBA9876543210FEDCBA9876543210";
        wait for 20 ns;
        wait;
    end process proc_tb;

end architecture bhv;
