library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity move_columns is 
    port (
        i_column_state_in : in std_ulogic_vector(127 downto 0);
        o_column_state_out : out std_ulogic_vector(127 downto 0)
    );
end entity move_columns;

architecture RTL of move_columns is 
    type tColumns is array(0 to 3) of std_ulogic_vector(7 downto 0);
    
    constant fixed_row_0 : tColumns := (
        0 => x"02",
        1 => x"03",
        2 => x"01",
        3 => x"01"
    );
    
    constant fixed_row_1 : tColumns := (
        0 => x"01" ,
        1 => x"02",
        2 => x"03",
        3 => x"01"
    );
    
    constant fixed_row_2 : tColumns := (
        0 => x"01",
        1 => x"01",
        2 => x"02",
        3 => x"03"
    );
    
    constant fixed_row_3 :tColumns := (
        0 => x"03", 
        1 => x"01",
        2 => x"01",
        3 => x"02"
    );

    -- Function for multiplication 
   function row_operation(a : tColumns; b : tColumns) return std_ulogic_vector is
        variable result : std_ulogic_vector(7 downto 0) := (others => '0');
        variable temp_result : tColumns := (others => (others => '0'));
        variable shifted_result : unsigned(7 downto 0) := (others => '0');
        begin
        for i in 0 to 3 loop
            if a(i) = x"01" then
                temp_result(i) := b(i);
            elsif a(i) = x"02" then
                shifted_result := unsigned(b(i)) sll 1;
                if b(i)(7) = '1' then
                    shifted_result := shifted_result xor x"1B";
                end if;
                temp_result(i) := std_ulogic_vector(shifted_result);
            elsif a(i) = x"03" then
                shifted_result := unsigned(b(i)) sll 1;
                if b(i)(7) = '1' then
                    shifted_result := shifted_result xor x"1B";
                end if;
                temp_result(i) := std_ulogic_vector(shifted_result) xor b(i);
            else
                temp_result(i) := (others => '0');
        end if;
    end loop;
    result := temp_result(0) xor temp_result(1) xor temp_result(2) xor temp_result(3);
    return result;
end function;

begin 
    process(i_column_state_in)
        variable column_0 : tColumns := (others => (others => '0'));
        variable column_1 : tColumns := (others => (others => '0'));
        variable column_2 : tColumns := (others => (others => '0'));
        variable column_3 : tColumns := (others => (others => '0'));
    
        begin 
        column_0(0) := i_column_state_in(127 downto 120);
        column_0(1) := i_column_state_in(95 downto 88);
        column_0(2) := i_column_state_in(63 downto 56);
        column_0(3) := i_column_state_in(31 downto 24);
        
        column_1(0) := i_column_state_in(119 downto 112);
        column_1(1) := i_column_state_in(87 downto 80);
        column_1(2) := i_column_state_in(55 downto 48);
        column_1(3) := i_column_state_in(23 downto 16);

        column_2(0) := i_column_state_in(111 downto 104);
        column_2(1) := i_column_state_in(79 downto 72);
        column_2(2) := i_column_state_in(47 downto 40);
        column_2(3) := i_column_state_in(15 downto 8);

        column_3(0) := i_column_state_in(103 downto 96);
        column_3(1) := i_column_state_in(71 downto 64);
        column_3(2) := i_column_state_in(39 downto 32);
        column_3(3) := i_column_state_in(7 downto 0);

        o_column_state_out(127 downto 120) <= row_operation(fixed_row_0,column_0);
        o_column_state_out(119 downto 112) <= row_operation(fixed_row_1,column_0);
        o_column_state_out(111 downto 104) <= row_operation(fixed_row_2,column_0);
        o_column_state_out(103 downto 96) <= row_operation(fixed_row_3,column_0);
        o_column_state_out(95 downto 88) <= row_operation(fixed_row_0,column_1);
        o_column_state_out(87 downto 80) <= row_operation(fixed_row_1,column_1);
        o_column_state_out(79 downto 72) <= row_operation(fixed_row_2,column_1);
        o_column_state_out(71 downto 64) <= row_operation(fixed_row_3,column_1);
        o_column_state_out(63 downto 56) <= row_operation(fixed_row_0,column_2);
        o_column_state_out(55 downto 48) <= row_operation(fixed_row_1,column_2);
        o_column_state_out(47 downto 40) <= row_operation(fixed_row_2,column_2);
        o_column_state_out(39 downto 32) <= row_operation(fixed_row_3,column_2);
        o_column_state_out(31 downto 24) <= row_operation(fixed_row_0,column_3);
        o_column_state_out(23 downto 16) <= row_operation(fixed_row_1,column_3);
        o_column_state_out(15 downto 8) <= row_operation(fixed_row_2,column_3);
        o_column_state_out(7 downto 0) <= row_operation(fixed_row_3,column_3);
    end process;

end architecture RTL;
