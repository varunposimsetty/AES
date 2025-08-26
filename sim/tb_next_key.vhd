library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb is 
end entity tb;

architecture bhv of tb is 
    signal prev_key : std_ulogic_vector(127 downto 0):= (others => '0');
    signal next_key : std_ulogic_vector(127 downto 0);
    signal current_round : integer := 1;

    begin 
    DUT_next_key : entity work.next_key(RTL)
        generic map(
            key_size => 256,
            rounds => 14
        )
        port map(
            i_prev_key => prev_key,
            i_current_round => current_round,
            o_next_key => next_key
        );

    proc_tb : process is 
    begin 
        wait for 10 ns;
        prev_key <= x"b52c505a37d78eda5dd34f20c22540ea";
        current_round <= 1;
        wait for 10 ns;
        prev_key <= x"1b58963cf8e5bf8ffa85f9f2492505b4";
        current_round <= 2;
        wait for 10 ns;
        prev_key <= x"8b47dd61bc9053bbe1431c9b23665c71";
        current_round <= 3;
        wait for 10 ns;
        prev_key <= x"3d6bdc9fc58e63103f0b9ae2762e9f56";
        current_round <= 4;
        wait for 10 ns;
        prev_key <= x"b89c6c59040c3fe2e54f2379c6297f08";
        current_round <= 5;
        wait for 10 ns;
        prev_key <= x"89ce0eaf4c406dbf734bf75d0565680b";
        current_round <= 6;
        wait for 10 ns;
        prev_key <= x"f1d94732f5d578d0109a5ba9d6b324a1";
        current_round <= 7;
        wait for 10 ns;
        prev_key <= x"7fa3389d33e3552240a8a27f45cdca74";
        current_round <= 8;
        wait for 10 ns;
        prev_key <= x"44add55cb178ad8ca1e2f6257751d284";
        current_round <= 9;
        wait for 10 ns;
        prev_key <= x"8a728dc2b991d8e0f9397a9fbcf4b0eb";
        current_round <= 10;
        wait for 10 ns;
        prev_key <= x"eb4a3c395a3291b5fbd067908c81b514";
        current_round <= 11;
        wait for 10 ns;
        prev_key <= x"ee7e583857ef80d8aed6fa4712224aac";
        current_round <= 12;
        wait for 10 ns;
        prev_key <= x"589cadf002ae3c45f97e5bd575ffeec1";
        current_round <= 13;
        wait for 10 ns;
        prev_key <= x"736870402487f0988a510adf98734073";
        current_round <= 14;
        wait for 10 ns;
        wait;
    end process proc_tb;
end architecture bhv;
