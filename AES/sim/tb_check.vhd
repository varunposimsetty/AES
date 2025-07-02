library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb is 
end entity tb;

architecture bhv of tb is 
    signal data_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal data_out : std_ulogic_vector(127 downto 0);

    begin 
    DUT_AES : entity work.move_columns(RTL)
        port map(
            i_column_state_in => data_in,
            o_column_state_out => data_out
        );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        data_in <= x"247240236966B3FA6ED2753288425B6C";
        wait for 120 ns;
        data_in <= x"36339D50F9B539269F2C092DC4406D23";
        wait for 120 ns;
        data_in <= (others => '0');
        wait for 120 ns;
        wait;
    end process proc_tb;
end architecture bhv;
