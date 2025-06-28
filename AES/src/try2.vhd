library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES is 
    generic (
        KEY_SIZE  : integer := 128;
        TEXT_SIZE : integer := 128;
        ROUNDS    : integer := 10 -- # of rounds depends on key size for 128 -> 10, 192 -> 12, 256 -> 1
    );
    port (
        i_clk : in std_ulogic;
        i_nrst_async : in std_ulogic;
        i_start : in std_ulogic;
        i_data_in  : in std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key : in std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
    );
end entity AES;

architecture RTL of AES is
    signal byte_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal byte_out : std_ulogic_vector(127 downto 0);
    signal row_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal row_state_out : std_ulogic_vector(127 downto 0);
    signal column_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal column_state_out : std_ulogic_vector(127 downto 0);
    signal expanded_key : std_ulogic_vector(((rounds+1)*128) - 1 downto 0);
    signal round_key_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal round_expanded_key : std_ulogic_vector(127 downto 0) := (others => '0');
    signal round_key_state_out : std_ulogic_vector(127 downto 0);
    --
    type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);
    signal expanded_key_bank : tExpandedKeyBank := (others => (others => '0'));
    -- 
    signal data_sync : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key_sync : std_ulogic_vector(127 downto 0) := (others => '0');
    -- Pipelined Registers
    signal current_state_bank : tExpandedKeyBank := (others => (others => '0'));
    
    function s_box_function(input_byte : std_ulogic_vector(7 downto 0)) return std_ulogic_vector is
        type s_box_array_type is array(0 to 255) of std_ulogic_vector(7 downto 0);
        constant SBoxArray : s_box_array_type := (
                0  => x"63",  1  => x"7C",  2  => x"77",  3  => x"7B",  4  => x"F2",  5  => x"6B",  6  => x"6F",  7  => x"C5",
                8  => x"30",  9  => x"01",  10 => x"67",  11 => x"2B",  12 => x"FE",  13 => x"D7",  14 => x"AB",  15 => x"76",
                16 => x"CA",  17 => x"82",  18 => x"C9",  19 => x"7D",  20 => x"FA",  21 => x"59",  22 => x"47",  23 => x"F0",
                24 => x"AD",  25 => x"D4",  26 => x"A2",  27 => x"AF",  28 => x"9C",  29 => x"A4",  30 => x"72",  31 => x"C0",
                32 => x"B7",  33 => x"FD",  34 => x"93",  35 => x"26",  36 => x"36",  37 => x"3F",  38 => x"F7",  39 => x"CC",
                40 => x"34",  41 => x"A5",  42 => x"E5",  43 => x"F1",  44 => x"71",  45 => x"D8",  46 => x"31",  47 => x"15",
                48 => x"04",  49 => x"C7",  50 => x"23",  51 => x"C3",  52 => x"18",  53 => x"96",  54 => x"05",  55 => x"9A",
                56 => x"07",  57 => x"12",  58 => x"80",  59 => x"E2",  60 => x"EB",  61 => x"27",  62 => x"B2",  63 => x"75",
                64 => x"09",  65 => x"83",  66 => x"2C",  67 => x"1A",  68 => x"1B",  69 => x"6E",  70 => x"5A",  71 => x"A0",
                72 => x"52",  73 => x"3B",  74 => x"D6",  75 => x"B3",  76 => x"29",  77 => x"E3",  78 => x"2F",  79 => x"84",
                80 => x"53",  81 => x"D1",  82 => x"00",  83 => x"ED",  84 => x"20",  85 => x"FC",  86 => x"B1",  87 => x"5B",
                88 => x"6A",  89 => x"CB",  90 => x"BE",  91 => x"39",  92 => x"4A",  93 => x"4C",  94 => x"58",  95 => x"CF",
                96 => x"D0",  97 => x"EF",  98 => x"AA",  99 => x"FB",  100 => x"43",  101 => x"4D",  102 => x"33",  103 => x"85",
                104 => x"45",  105 => x"F9",  106 => x"02",  107 => x"7F",  108 => x"50",  109 => x"3C",  110 => x"9F",  111 => x"A8",
                112 => x"51",  113 => x"A3",  114 => x"40",  115 => x"8F",  116 => x"92",  117 => x"9D",  118 => x"38",  119 => x"F5",
                120 => x"BC",  121 => x"B6",  122 => x"DA",  123 => x"21",  124 => x"10",  125 => x"FF",  126 => x"F3",  127 => x"D2",
                128 => x"CD",  129 => x"0C",  130 => x"13",  131 => x"EC",  132 => x"5F",  133 => x"97",  134 => x"44",  135 => x"17",
                136 => x"C4",  137 => x"A7",  138 => x"7E",  139 => x"3D",  140 => x"64",  141 => x"5D",  142 => x"19",  143 => x"73",
                144 => x"60",  145 => x"81",  146 => x"4F",  147 => x"DC",  148 => x"22",  149 => x"2A",  150 => x"90",  151 => x"88",
                152 => x"46",  153 => x"EE",  154 => x"B8",  155 => x"14",  156 => x"DE",  157 => x"5E",  158 => x"0B",  159 => x"DB",
                160 => x"E0",  161 => x"32",  162 => x"3A",  163 => x"0A",  164 => x"49",  165 => x"06",  166 => x"24",  167 => x"5C",
                168 => x"C2",  169 => x"D3",  170 => x"AC",  171 => x"62",  172 => x"91",  173 => x"95",  174 => x"E4",  175 => x"79",
                176 => x"E7",  177 => x"C8",  178 => x"37",  179 => x"6D",  180 => x"8D",  181 => x"D5",  182 => x"4E",  183 => x"A9",
                184 => x"6C",  185 => x"56",  186 => x"F4",  187 => x"EA",  188 => x"65",  189 => x"7A",  190 => x"AE",  191 => x"08",
                192 => x"BA",  193 => x"78",  194 => x"25",  195 => x"2E",  196 => x"1C",  197 => x"A6",  198 => x"B4",  199 => x"C6",
                200 => x"E8",  201 => x"DD",  202 => x"74",  203 => x"1F",  204 => x"4B",  205 => x"BD",  206 => x"8B",  207 => x"8A",
                208 => x"70",  209 => x"3E",  210 => x"B5",  211 => x"66",  212 => x"48",  213 => x"03",  214 => x"F6",  215 => x"0E",
                216 => x"61",  217 => x"35",  218 => x"57",  219 => x"B9",  220 => x"86",  221 => x"C1",  222 => x"1D",  223 => x"9E",
                224 => x"E1",  225 => x"F8",  226 => x"98",  227 => x"11",  228 => x"69",  229 => x"D9",  230 => x"8E",  231 => x"94",
                232 => x"9B",  233 => x"1E",  234 => x"87",  235 => x"E9",  236 => x"CE",  237 => x"55",  238 => x"28",  239 => x"DF",
                240 => x"8C",  241 => x"A1",  242 => x"89",  243 => x"0D",  244 => x"BF",  245 => x"E6",  246 => x"42",  247 => x"68",
                248 => x"41",  249 => x"99",  250 => x"2D",  251 => x"0F",  252 => x"B0",  253 => x"54",  254 => x"BB",  255 => x"16",
            others => (others => '0')
        );
    begin
        return SBoxArray(to_integer(unsigned(input_byte)));
    end function;


begin 

    SBOX : entity work.sbox(RTL)
            port map(
                i_byte_in => byte_in,
                o_byte_out => byte_out
        );
        
        SHIFT_ROWS : entity work.shift_rows(RTL)
            port map(
               i_row_state_in => row_state_in,
               o_row_state_out => row_state_out
        );

        MOVE_COLUMNS : entity work.move_columns(RTL)
            port map(
                i_column_state_in => column_state_in,
                o_column_state_out => column_state_out
        );

        KEY_EXPANSION : entity work.key_expansion(RTL)
            generic map(
                key_size => KEY_SIZE,
                word_size => TEXT_SIZE,
                rounds => ROUNDS

            )
            port map(
                i_key => key_sync,
                o_expanded_key => expanded_key
        );

        ADD_ROUND_KEY : entity work.addRoundKey(RTL)
            port map(
                i_state_in => round_key_state_in,
                i_expanded_key => round_expanded_key,
                o_state_out => round_key_state_out
        );

    process(i_clk,i_nrst_async) is 
        variable count : integer := 0;
        variable expanded_key_bank_var : tExpandedKeyBank := (others => (others => '0'));
        variable current_state_var_bank : tExpandedKeyBank := (others => (others => '0'));
        variable temp : std_ulogic_vector(127 downto 0) := (others => '0');
 
    begin 
        
        if(i_nrst_async = '0') then 
            byte_in <= (others => '0');
            row_state_in  <= (others => '0');
            column_state_in <= (others => '0');
            round_key_state_in <= (others => '0');
            round_expanded_key <= (others => '0');
            current_state_bank <= (others => (others => '0'));
            count := 0;
            expanded_key_bank_var := (others => (others => '0'));
            current_state_var_bank := (others => (others => '0'));
            
        elsif(rising_edge(i_clk)) then
            for i in 0 to rounds loop 
                expanded_key_bank_var(i) := expanded_key((i+1)*128-1 downto i*128);
            end loop;
            expanded_key_bank <= expanded_key_bank_var;
            case count is 
                when 0 =>
                    data_sync <= i_data_in;
                    key_sync <= i_cipher_key;
                    --current_state_var_bank := (others => (others => '0'));
                    current_state_var_bank(0) := std_ulogic_vector(unsigned(expanded_key_bank_var(0)) xor unsigned(data_sync));
                    count := count + 1; 
                when 1 to 9 => 
                    for i in 0 to 15 loop 
                        current_state_var_bank(count)((8*i)+7 downto 8*i) := s_box_function(current_state_var_bank(count-1)((8*i)+7 downto 8*i));
                    end loop;
                    count := count + 1;
                when 10 =>
                    for i in 0 to 15 loop 
                        current_state_var_bank(count)((8*i)+7 downto 8*i) := s_box_function(current_state_var_bank(count-1)((8*i)+7 downto 8*i));
                    end loop;
                    count := 0;
                when others => 
                    null;
            end case;
        end if;
        current_state_bank <= current_state_var_bank;
    end process;
end architecture RTL;


----------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity AES is 
    generic (
        KEY_SIZE  : integer := 128;
        TEXT_SIZE : integer := 128;
        ROUNDS    : integer := 10 -- # of rounds depends on key size for 128 -> 10, 192 -> 12, 256 -> 1
    );
    port (
        i_clk : in std_ulogic;
        i_nrst_async : in std_ulogic;
        i_start : in std_ulogic;
        i_data_in  : in std_ulogic_vector(TEXT_SIZE-1 downto 0);
        i_cipher_key : in std_ulogic_vector(KEY_SIZE-1 downto 0);
        o_data_out : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
    );
end entity AES;

architecture RTL of AES is
    signal byte_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal byte_out : std_ulogic_vector(127 downto 0);
    signal row_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal row_state_out : std_ulogic_vector(127 downto 0);
    signal column_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal column_state_out : std_ulogic_vector(127 downto 0);
    signal expanded_key : std_ulogic_vector(((rounds+1)*128) - 1 downto 0);
    signal round_key_state_in : std_ulogic_vector(127 downto 0) := (others => '0');
    signal round_expanded_key : std_ulogic_vector(127 downto 0) := (others => '0');
    signal round_key_state_out : std_ulogic_vector(127 downto 0);
    
    -- 
    signal data_sync : std_ulogic_vector(127 downto 0) := (others => '0');
    signal key_sync : std_ulogic_vector(127 downto 0) := (others => '0');
    signal sync : std_ulogic := '1';

    type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);
    signal expanded_key_bank : tExpandedKeyBank := (others => (others => '0'));
    signal expanded_state_bank : tExpandedKeyBank := (others => (others => '0'));
    --
    --signal ext_count : integer := 0;
    --signal int_count : integer := 0;

    signal state_reg : std_ulogic_vector(127 downto 0);


begin 
    SBOX : entity work.sbox(RTL)
            port map(
                i_byte_in => byte_in,
                o_byte_out => byte_out
        );
        
        SHIFT_ROWS : entity work.shift_rows(RTL)
            port map(
               i_row_state_in => row_state_in,
               o_row_state_out => row_state_out
        );

        MOVE_COLUMNS : entity work.move_columns(RTL)
            port map(
                i_column_state_in => column_state_in,
                o_column_state_out => column_state_out
        );

        KEY_EXPANSION : entity work.key_expansion(RTL)
            generic map(
                key_size => KEY_SIZE,
                word_size => TEXT_SIZE,
                rounds => ROUNDS

            )
            port map(
                i_key => key_sync,
                o_expanded_key => expanded_key
        );

        ADD_ROUND_KEY : entity work.addRoundKey(RTL)
            port map(
                i_state_in => round_key_state_in,
                i_expanded_key => round_expanded_key,
                o_state_out => round_key_state_out
        );

    process(i_clk,i_nrst_async) is 
    variable ext_count : integer := 0;
    variable int_count : integer := 0;
    variable expanded_key_bank_var : tExpandedKeyBank := (others => (others => '0'));
    variable expanded_state_bank_var : tExpandedKeyBank := (others => (others => '0'));
    variable data_out : std_ulogic_vector(127 downto 0) := (others => '0');
    
    begin 
        if (i_nrst_async = '0') then 
            byte_in <= (others => '0');
            row_state_in <= (others => '0');
            column_state_in <= (others => '0');
            round_key_state_in <= (others => '0');
            int_count := 0;
            ext_count := 0;
        elsif(rising_edge(i_clk)) then 
            state_reg <= expanded_state_bank_var(ext_count);
            if (i_start = '1' ) then 
                -- DATA CAPTURE 
                if (sync = '1') then
                    sync <= '0'; 
                    int_count := 0;
                    ext_count := 0;
                    data_sync <= i_data_in;
                    key_sync <= i_cipher_key;
                    for i in 0 to rounds loop 
                        expanded_key_bank_var(i) := expanded_key((i+1)*128-1 downto i*128);
                    end loop; 
                    expanded_key_bank <= expanded_key_bank_var; 
                end if;

                case ext_count is 
                    when 0 => 
                        -- Round key  
                        round_key_state_in <= i_data_in;
                        round_expanded_key <= i_cipher_key;
                        expanded_state_bank_var(ext_count) := round_key_state_out;
                        expanded_state_bank(ext_count) <= round_key_state_out;
                        byte_in <= expanded_state_bank_var(ext_count);
                        ext_count := ext_count + 1;
                    when 1 to 9 =>
                        case int_count is 
                            when 0 => 
                                expanded_state_bank_var(ext_count) := byte_out;
                                int_count := int_count + 1;
                            when 1 => 
                                row_state_in <= expanded_state_bank_var(ext_count);
                                expanded_state_bank_var(ext_count) := row_state_out;
                                int_count := int_count + 1;
                            when 2 =>
                                column_state_in <= expanded_state_bank_var(ext_count);
                                expanded_state_bank_var(ext_count) := column_state_out;
                                int_count := int_count + 1;
                            when 3 =>
                                round_key_state_in <= expanded_state_bank_var(ext_count);
                                round_expanded_key <= expanded_key_bank(ext_count);
                                expanded_state_bank_var(ext_count) := round_key_state_out;
                                expanded_state_bank(ext_count) <= round_key_state_out;
                                int_count := 0;
                                ext_count := ext_count + 1;
                            when others => 
                                null;
                        end case;
                    when 10 =>
                        case int_count is 
                            when 0 => 
                                byte_in <= expanded_state_bank_var(ext_count-1);
                                expanded_state_bank_var(ext_count) := byte_out;
                                int_count := int_count + 1;
                            when 1 => 
                                row_state_in <= expanded_state_bank_var(ext_count);
                                expanded_state_bank_var(ext_count) := row_state_out;
                                int_count := int_count + 1;
                            when 2 =>
                                round_key_state_in <= expanded_state_bank_var(ext_count);
                                round_expanded_key <= expanded_key_bank(ext_count);
                                expanded_state_bank_var(ext_count) := round_key_state_out;
                                expanded_state_bank(ext_count) <= round_key_state_out;
                                data_out := expanded_state_bank(ext_count);
                                int_count := 0;
                                ext_count := 0;
                                sync <= '1';
                                --expanded_state_bank_var := (others => (others => '0'));
                                --expanded_key_bank_var := (others => (others => '0'));
                            when others => 
                                null;
                        end case;
                    when others => 
                        null;
                end case;
            end if;
        end if;
        o_data_out <= data_out;
    end process; 
end architecture RTL;