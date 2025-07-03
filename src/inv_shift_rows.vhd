library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity inv_shift_rows is 
    port (
    i_inv_row_state_in  : in std_ulogic_vector(127 downto 0);
    o_inv_row_state_out : out std_ulogic_vector(127 downto 0)
    );
end entity inv_shift_rows;

architecture RTL of inv_shift_rows is 
begin 
    o_inv_row_state_out <=  i_inv_row_state_in(127 downto 120) & i_inv_row_state_in(23 downto 16) & i_inv_row_state_in(47 downto 40) & i_inv_row_state_in(71 downto 64) & i_inv_row_state_in(95 downto 88) & i_inv_row_state_in(119 downto 112) & i_inv_row_state_in(15 downto 8) & i_inv_row_state_in(39 downto 32) & i_inv_row_state_in(63 downto 56) & i_inv_row_state_in(87 downto 80) & i_inv_row_state_in(111 downto 104) & i_inv_row_state_in(7 downto 0) & i_inv_row_state_in(31 downto 24) & i_inv_row_state_in(55 downto 48) & i_inv_row_state_in(79 downto 72) & i_inv_row_state_in(103 downto 96);
end architecture RTL;