library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity shift_rows is 
    port (
    i_row_state_in  : in std_ulogic_vector(127 downto 0);
    o_row_state_out : out std_ulogic_vector(127 downto 0)
    );
end entity shift_rows;

architecture RTL of shift_rows is 
signal row_0 : std_ulogic_vector(31 downto 0) := (others => '0');
signal row_1 : std_ulogic_vector(31 downto 0) := (others => '0');
signal row_2 : std_ulogic_vector(31 downto 0) := (others => '0');
signal row_3 : std_ulogic_vector(31 downto 0) := (others => '0');
signal shift_row_1 : std_ulogic_vector(31 downto 0) := (others => '0');
signal shift_row_2 : std_ulogic_vector(31 downto 0) := (others => '0');
signal shift_row_3 : std_ulogic_vector(31 downto 0) := (others => '0');
begin 
    process(i_row_state_in) 
    begin
        row_0 <= i_row_state_in(127 downto 96);
        row_1 <= i_row_state_in(95 downto 64);
        row_2 <= i_row_state_in(63 downto 32);
        row_3 <= i_row_state_in(31 downto 0);
    end process;
    shift_row_1 <= row_1(23 downto 0) & row_1(31 downto 24);
    shift_row_2 <= row_2(15 downto 0) & row_2(31 downto 16);
    shift_row_3 <= row_3(7 downto 0) & row_3(31 downto 8); 
    o_row_state_out <=  row_0 & shift_row_1 & shift_row_2 & shift_row_3;
end architecture RTL;
