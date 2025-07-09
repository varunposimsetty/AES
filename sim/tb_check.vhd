library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb is 
end entity tb;

architecture bhv of tb is 
    signal data_in : std_ulogic_vector(191 downto 0) := (others => '0');
    signal data_out : std_ulogic_vector(1663 downto 0);

    begin 
    DUT_AES : entity work.key_expansion(RTL)
        generic map(
            key_size => 192, -- 128/192/256
            rounds => 12 -- 10/12/14
        )
        port map(
            i_key => data_in,
            o_expanded_key => data_out
        );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        data_in <= x"000102030405060708090A0B0C0D0E0F1011121314151617";
        wait for 120 ns;
        data_in <= x"000102030405060708090A0B0C0D0E0F1011121314151617";
        wait for 120 ns;
        --data_in <= (others => '0');
        wait for 120 ns;
        wait;
    end process proc_tb;
end architecture bhv;


