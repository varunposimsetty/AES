library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity key_expansion is
    generic (
        key_size : integer := 128;
        word_size : integer := 32;
        rounds    : integer := 10 -- For AES-128
    );
    port (
        i_key          : in  std_ulogic_vector(key_size-1 downto 0);
        o_expanded_key : out std_ulogic_vector(((rounds+1)*128)-1 downto 0)
    );
end entity key_expansion;

architecture RTL of key_expansion is
    type tWord is array(0 to 3) of std_ulogic_vector(7 downto 0);
    type tExpandedKeyBank is array(0 to rounds) of std_ulogic_vector(127 downto 0);

    -- Expanded key storage
    signal expanded_key : tExpandedKeyBank := (others => (others => '0'));

    -- Round Constants
    type tRoundConstants is array(0 to 13) of std_ulogic_vector(31 downto 0);
    constant round_constant : tRoundConstants := (
        x"01000000", x"02000000", x"04000000", x"08000000",
        x"10000000", x"20000000", x"40000000", x"80000000",
        x"1B000000", x"36000000", x"6C000000", x"D8000000",
        x"AB000000", x"4D000000"
    );

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

    -- Rotate Word 
    function rotate_word(word_in : tWord) return tWord is
        variable rotated_word : tWord := (others => (others => '0'));
    begin
        rotated_word(0) := word_in(1);
        rotated_word(1) := word_in(2);
        rotated_word(2) := word_in(3);
        rotated_word(3) := word_in(0);
        return rotated_word;
    end function;

    -- Substitute Word 
    function substitute_word(word_in : tWord) return tWord is
        variable substituted_word : tWord := (others => (others => '0'));
    begin
        for i in 0 to 3 loop
            substituted_word(i) := s_box_function(word_in(i));
        end loop;
        return substituted_word;
    end function;

begin
    process(i_key)
        variable temp_word : tWord := (others => (others => '0'));
        variable current_word : tWord;
        variable round_key_word : std_ulogic_vector(31 downto 0);
        variable temp_1, temp_2, temp_3, temp_4 : std_ulogic_vector(31 downto 0);
        variable word_array : tWord := (others => (others => '0'));
    begin
       -- first round key 
        if (key_size = 128) then 
            expanded_key(0) <= i_key;
        elsif(key_size = 196) then 
            expanded_key(0) <= i_key(191 downto 64);
        elsif(key_size = 256) then 
            expanded_key(0) <= i_key(255 downto 128);
        end if;

        -- Generating the remaining round keys
        for i in 0 to rounds - 1 loop
            word_array(0) := expanded_key(i)(31 downto 24); 
            word_array(1) := expanded_key(i)(23 downto 16);
            word_array(2) := expanded_key(i)(15 downto 8);
            word_array(3) := expanded_key(i)(7 downto 0);  

            temp_word := rotate_word(word_array);
            temp_word := substitute_word(temp_word);
            temp_word(0) := std_ulogic_vector(unsigned(temp_word(0)) xor unsigned(round_constant(i)(31 downto 24)));
            round_key_word := temp_word(0) & temp_word(1) & temp_word(2) & temp_word(3);
            temp_1 := std_ulogic_vector(unsigned(expanded_key(i)(127 downto 96)) xor unsigned(round_key_word));
            temp_2 := std_ulogic_vector(unsigned(temp_1) xor unsigned(expanded_key(i)(95 downto 64)));
            temp_3 := std_ulogic_vector(unsigned(temp_2) xor unsigned(expanded_key(i)(63 downto 32)));
            temp_4 := std_ulogic_vector(unsigned(temp_3) xor unsigned(expanded_key(i)(31 downto 0)));
            expanded_key(i+1) <= temp_1 & temp_2 & temp_3 & temp_4;
        end loop;

        -- Combining all round keys into a single expanded key
        for i in 0 to rounds loop
            o_expanded_key((i+1)*128-1 downto i*128) <= expanded_key(i);
        end loop;
    end process;

end architecture RTL;