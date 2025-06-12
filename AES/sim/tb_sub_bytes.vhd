library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb is 
end entity tb;

architecture bhv of tb is 
    signal byte_in : std_ulogic_vector(7 downto 0) := (others => '0');
    signal byte_out : std_ulogic_vector(7 downto 0);

    begin 
    DUT_S_BOX : entity work.sbox(RTL) 
    port map(
        i_byte_in => byte_in,
        o_byte_out => byte_out
    );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        byte_in <= x"12";
        wait for 20 ns;
        byte_in <= x"15";
        wait for 30 ns;
        byte_in <= x"FD";
        wait for 20 ns;
        wait;
    end process proc_tb;

end architecture bhv;
