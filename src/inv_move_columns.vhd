library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inv_move_columns is 
    port (
        i_inv_column_state_in : in std_ulogic_vector(127 downto 0);
        o_inv_column_state_out : out std_ulogic_vector(127 downto 0)
    );
end entity inv_move_columns;

architecture RTL of inv_move_columns is 
    type tColumns is array(0 to 3) of std_ulogic_vector(7 downto 0);
    signal c_0 : tColumns := (others => (others => '0'));
    signal c_1 : tColumns := (others => (others => '0'));
    signal c_2 : tColumns := (others => (others => '0'));
    signal c_3 : tColumns := (others => (others => '0'));
    signal r : std_ulogic_vector(7 downto 0) := (others => '0');
    signal r_1 : std_ulogic_vector(7 downto 0) := (others => '0');
    signal r_2 : std_ulogic_vector(7 downto 0) := (others => '0');
    signal r_3 : std_ulogic_vector(7 downto 0) := (others => '0');
    
    constant fixed_row_0 : tColumns := (
        0 => x"0E",
        1 => x"0B",
        2 => x"0D",
        3 => x"09"
    );
    
    constant fixed_row_1 : tColumns := (
        0 => x"09" ,
        1 => x"0E",
        2 => x"0B",
        3 => x"0D"
    );
    
    constant fixed_row_2 : tColumns := (
        0 => x"0D",
        1 => x"09",
        2 => x"0E",
        3 => x"0B"
    );
    
    constant fixed_row_3 :tColumns := (
        0 => x"0B", 
        1 => x"0D",
        2 => x"09",
        3 => x"0E"
    );



    -- multiplication functions doing all multiplications based on the multiplication of 2
    function xtime(x : unsigned(7 downto 0)) return unsigned is
        begin
        if x(7) = '1' then
            return (x sll 1) xor to_unsigned(16#1B#, 8);
        else
            return x sll 1;
        end if;
    end function;

    function mul2(x : unsigned(7 downto 0)) return unsigned is
        begin
            return xtime(x);
    end function;

    function mul4(x : unsigned(7 downto 0)) return unsigned is
        begin
            return xtime(xtime(x));
    end function;

    function mul8(x : unsigned(7 downto 0)) return unsigned is
        begin
            return xtime(xtime(xtime(x)));
    end function;

    function mul9(x : unsigned(7 downto 0)) return unsigned is
        begin
            return mul8(x) xor x;                         
    end function; 

    function mul11(x : unsigned(7 downto 0)) return unsigned is
        begin
            return mul8(x) xor mul2(x) xor x;           
    end function;

    function mul13(x : unsigned(7 downto 0)) return unsigned is
        begin
            return mul8(x) xor mul4(x) xor x;            
    end function;

    function mul14(x : unsigned(7 downto 0)) return unsigned is
        begin
            return mul8(x) xor mul4(x) xor mul2(x);      
    end function;


    -- Function for row multiplication 
   function row_operation(a : tColumns; b : tColumns) return std_ulogic_vector is
        variable result : std_ulogic_vector(7 downto 0) := (others => '0');
        variable temp_result : tColumns := (others => (others => '0'));
        variable shifted_result : unsigned(7 downto 0) := (others => '0');
        
        begin
        for i in 0 to 3 loop
            if a(i) = x"09" then
                temp_result(i) := std_ulogic_vector(mul9(unsigned(b(i))));
            elsif a(i) = x"0B" then
                temp_result(i) := std_ulogic_vector(mul11(unsigned(b(i))));
            elsif a(i) = x"0D" then
                temp_result(i) := std_ulogic_vector(mul13(unsigned(b(i))));
            elsif a(i) = x"0E" then 
                temp_result(i) := std_ulogic_vector(mul14(unsigned(b(i))));
        end if;
    end loop;
    result := std_ulogic_vector(unsigned(temp_result(0)) xor unsigned(temp_result(1)) xor unsigned(temp_result(2)) xor unsigned(temp_result(3)));
    return result;
end function;

begin 
    process(i_inv_column_state_in)
        variable column_0 : tColumns := (others => (others => '0'));
        variable column_1 : tColumns := (others => (others => '0'));
        variable column_2 : tColumns := (others => (others => '0'));
        variable column_3 : tColumns := (others => (others => '0'));
    
        begin 
        column_0(0) := i_inv_column_state_in(127 downto 120);
        column_0(1) := i_inv_column_state_in(119 downto 112);
        column_0(2) := i_inv_column_state_in(111 downto 104);
        column_0(3) := i_inv_column_state_in(103 downto 96);
        c_0(0) <= i_inv_column_state_in(127 downto 120);
        c_0(1) <= i_inv_column_state_in(119 downto 112);
        c_0(2) <= i_inv_column_state_in(111 downto 104);
        c_0(3) <= i_inv_column_state_in(103 downto 96);
        
        column_1(0) := i_inv_column_state_in(95 downto 88);
        column_1(1) := i_inv_column_state_in(87 downto 80);
        column_1(2) := i_inv_column_state_in(79 downto 72);
        column_1(3) := i_inv_column_state_in(71 downto 64);
        c_1(0) <= i_inv_column_state_in(95 downto 88);
        c_1(1) <= i_inv_column_state_in(87 downto 80);
        c_1(2) <= i_inv_column_state_in(79 downto 72);
        c_1(3) <= i_inv_column_state_in(71 downto 64);

        column_2(0) := i_inv_column_state_in(63 downto 56);
        column_2(1) := i_inv_column_state_in(55 downto 48);
        column_2(2) := i_inv_column_state_in(47 downto 40);
        column_2(3) := i_inv_column_state_in(39 downto 32);
        c_2(0) <= i_inv_column_state_in(63 downto 56);
        c_2(1) <= i_inv_column_state_in(55 downto 48);
        c_2(2) <= i_inv_column_state_in(47 downto 40);
        c_2(3) <= i_inv_column_state_in(39 downto 32);

        column_3(0) := i_inv_column_state_in(31 downto 24);
        column_3(1) := i_inv_column_state_in(23 downto 16);
        column_3(2) := i_inv_column_state_in(15 downto 8);
        column_3(3) := i_inv_column_state_in(7 downto 0);
        c_3(0) <= i_inv_column_state_in(31 downto 24);
        c_3(1) <= i_inv_column_state_in(23 downto 16);
        c_3(2) <= i_inv_column_state_in(15 downto 8);
        c_3(3) <= i_inv_column_state_in(7 downto 0);

        o_inv_column_state_out(127 downto 120) <= row_operation(fixed_row_0,column_0);
        r <= row_operation(fixed_row_0,column_0);
        o_inv_column_state_out(119 downto 112) <= row_operation(fixed_row_1,column_0);
        r_1 <= row_operation(fixed_row_1,column_0);
        o_inv_column_state_out(111 downto 104) <= row_operation(fixed_row_2,column_0);
        r_2 <= row_operation(fixed_row_2,column_0);
        o_inv_column_state_out(103 downto 96) <= row_operation(fixed_row_3,column_0);
        r_3 <= row_operation(fixed_row_3,column_0);
        o_inv_column_state_out(95 downto 88) <= row_operation(fixed_row_0,column_1);
        o_inv_column_state_out(87 downto 80) <= row_operation(fixed_row_1,column_1);
        o_inv_column_state_out(79 downto 72) <= row_operation(fixed_row_2,column_1);
        o_inv_column_state_out(71 downto 64) <= row_operation(fixed_row_3,column_1);
        o_inv_column_state_out(63 downto 56) <= row_operation(fixed_row_0,column_2);
        o_inv_column_state_out(55 downto 48) <= row_operation(fixed_row_1,column_2);
        o_inv_column_state_out(47 downto 40) <= row_operation(fixed_row_2,column_2);
        o_inv_column_state_out(39 downto 32) <= row_operation(fixed_row_3,column_2);
        o_inv_column_state_out(31 downto 24) <= row_operation(fixed_row_0,column_3);
        o_inv_column_state_out(23 downto 16) <= row_operation(fixed_row_1,column_3);
        o_inv_column_state_out(15 downto 8) <= row_operation(fixed_row_2,column_3);
        o_inv_column_state_out(7 downto 0) <= row_operation(fixed_row_3,column_3);
    end process;

end architecture RTL;
