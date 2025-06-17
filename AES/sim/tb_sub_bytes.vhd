library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb is 
end entity tb;

architecture bhv of tb is 
    signal state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal state_out : std_ulogic_vector(127 downto 0);

    begin 
    DUT_S_BOX : entity work.move_columns(RTL) 
    port map(
        i_column_state_in => state_in,
        o_column_state_out => state_out
    );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        state_in <= x"db135345f20a225c01010101c2c2c2c2";
        wait for 20 ns;
        state_in <= x"FEDCBA9876543210FEDCBA9876543210";
        wait for 30 ns;
        state_in <= x"A1B2C3D4E5F60718293A4B5C6D7E8F90";
        wait for 20 ns;
        wait;
    end process proc_tb;

end architecture bhv;
