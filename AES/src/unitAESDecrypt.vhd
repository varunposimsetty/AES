library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_decrypt is 
  generic (
    KEY_SIZE  : integer := 128;
    TEXT_SIZE : integer := 128;
    ROUNDS    : integer := 10
  );
  port (
    i_clk         : in  std_ulogic;
    i_nrst_async  : in  std_ulogic;
    i_start       : in  std_ulogic;
    i_data_in     : in  std_ulogic_vector(TEXT_SIZE-1 downto 0);
    i_cipher_key  : in  std_ulogic_vector(KEY_SIZE-1  downto 0);
    o_data_out    : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
  );
end entity AES_decrypt;

architecture RTL of AES_decrypt is

  -- synchronization & key/state capture
  signal data_sync      : std_ulogic_vector(127 downto 0);
  signal key_sync       : std_ulogic_vector(127 downto 0);
  signal sync           : std_ulogic := '1';

  -- pipelined internal buses
  signal byte_in        : std_ulogic_vector(7 downto 0);
  signal byte_out       : std_ulogic_vector(7 downto 0);
  signal row_in         : std_ulogic_vector(127 downto 0);
  signal row_out        : std_ulogic_vector(127 downto 0);
  signal col_in         : std_ulogic_vector(127 downto 0);
  signal col_out        : std_ulogic_vector(127 downto 0);
  signal round_in       : std_ulogic_vector(127 downto 0);
  signal round_out      : std_ulogic_vector(127 downto 0);

  -- expanded key bus
  signal expanded_key   : std_ulogic_vector((ROUNDS+1)*128-1 downto 0);

  type tKeyBank is array(0 to ROUNDS) of std_ulogic_vector(127 downto 0);
  signal rk_bank        : tKeyBank;

begin

  ----------------------------------------------------------------
  -- 1) Key expansion (combinational)
  KEY_EXP : entity work.key_expansion(RTL)
    generic map(
      key_size => KEY_SIZE,
      word_size=> TEXT_SIZE,
      rounds   => ROUNDS
    )
    port map(
      i_key          => key_sync,
      o_expanded_key => expanded_key
    );

  unpack_keys: process(expanded_key)
  begin
    for i in 0 to ROUNDS loop
      rk_bank(i) <= expanded_key((i+1)*128-1 downto i*128);
    end loop;
  end process;

  ----------------------------------------------------------------
  -- 2) Inverse SubBytes (byte-wide)
  INV_SBOX : entity work.inv_sbox(RTL)
    port map(
      i_byte_in  => byte_in,
      o_byte_out => byte_out
    );

  -- 3) Inverse ShiftRows (word-wide)
  INV_SHIFT : entity work.inv_shift_rows(RTL)
    port map(
      i_row_state_in  => row_in,
      o_row_state_out => row_out
    );

  -- 4) Inverse MixColumns (word-wide)
  INV_MIX : entity work.inv_move_columns(RTL)
    port map(
      i_column_state_in => col_in,
      o_column_state_out=> col_out
    );

  -- 5) AddRoundKey (same as encryption)
  ADDRK : entity work.addRoundKey(RTL)
    port map(
      i_state_in     => round_in,
      i_expanded_key => round_out,  -- we’ll swap the port names in the FSM
      o_state_out    => round_out
    );

  ----------------------------------------------------------------
  -- 6) Decryption FSM
  decrypt_fsm: process(i_clk, i_nrst_async)
    variable ext_cnt    : integer range 0 to ROUNDS := 0;
    variable int_cnt    : integer range 0 to 3      := 0;
    variable state_var  : std_ulogic_vector(127 downto 0) := (others => '0');
    variable data_out_v : std_ulogic_vector(127 downto 0) := (others => '0');
  begin
    if i_nrst_async = '0' then
      -- async reset
      sync       <= '1';
      ext_cnt    := 0;
      int_cnt    := 0;
      data_out_v := (others => '0');

    elsif rising_edge(i_clk) then
      if i_start = '1' then

        -- 1) capture once
        if sync = '1' then
          data_sync <= i_data_in;
          key_sync  <= i_cipher_key;
          sync      <= '0';
        
        -- 2) drive decryption rounds
        elsif ext_cnt = 0 then
          -- **Initial AddRoundKey with RoundKey₁₀**
          state_var := std_ulogic_vector(
                         unsigned(data_sync) xor 
                         unsigned(rk_bank(ROUNDS))
                       );
          ext_cnt := 1;

        -- **Rounds 1..9**:
        --   InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns
        elsif ext_cnt <= ROUNDS-1 then
          case int_cnt is
            when 0 =>
              -- InvShiftRows
              row_in    <= state_var;
              state_var := row_out;
              int_cnt   := 1;

            when 1 =>
              -- InvSubBytes (byte loop)
              for b in 0 to 15 loop
                byte_in := state_var(8*b+7 downto 8*b);
                state_var(8*b+7 downto 8*b) := byte_out;
              end loop;
              int_cnt := 2;

            when 2 =>
              -- AddRoundKey with RoundKey[ROUNDS - ext_cnt]
              state_var := std_ulogic_vector(
                             unsigned(state_var) xor 
                             unsigned(rk_bank(ROUNDS - ext_cnt))
                           );
              int_cnt := 3;

            when 3 =>
              -- InvMixColumns
              col_in    <= state_var;
              state_var := col_out;
              -- next round
              int_cnt := 0;
              ext_cnt := ext_cnt + 1;
          end case;

        -- **Final round (ext_cnt = 10)**: InvShiftRows → InvSubBytes → AddRoundKey₀
        elsif ext_cnt = ROUNDS then
          case int_cnt is
            when 0 =>
              -- InvShiftRows
              row_in    <= state_var;
              state_var := row_out;
              int_cnt   := 1;

            when 1 =>
              -- InvSubBytes
              for b in 0 to 15 loop
                byte_in := state_var(8*b+7 downto 8*b);
                state_var(8*b+7 downto 8*b) := byte_out;
              end loop;
              int_cnt := 2;

            when 2 =>
              -- Final AddRoundKey with RoundKey₀
              state_var := std_ulogic_vector(
                             unsigned(state_var) xor 
                             unsigned(rk_bank(0))
                           );
              data_out_v := state_var;
              -- done
              sync    <= '1';
              ext_cnt := 0;
              int_cnt := 0;
          end case;

        end if;
      end if;

      o_data_out <= data_out_v;
    end if;
  end process decrypt_fsm;

end architecture RTL;