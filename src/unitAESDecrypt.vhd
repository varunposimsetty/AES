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
    i_de_start       : in  std_ulogic;
    i_data_in     : in  std_ulogic_vector(TEXT_SIZE-1 downto 0);
    i_cipher_key  : in  std_ulogic_vector(KEY_SIZE-1  downto 0);
    o_data_out    : out std_ulogic_vector(TEXT_SIZE-1 downto 0)
  );
end entity AES_decrypt;

architecture RTL of AES_decrypt_piplined is
  subtype word128 is std_ulogic_vector(127 downto 0);
  type tRoundBank is array (0 to ROUNDS) of word128;

  -- stage-0 control & valid tokens
  signal en_d1     : std_ulogic := '0';
  signal vld_pipe  : std_ulogic_vector(0 to ROUNDS) := (others => '0');

  -- registered state per stage
  signal state_bank : tRoundBank := (others => (others => '0'));

  -- stage-0 holds (ciphertext block & K0 slice)
  signal initial_state : word128 := (others => '0');  -- ciphertext hold
  signal key0_reg      : word128 := (others => '0');  -- K0 hold

  -- forward key chain (combinational) for snapshot
  signal key0_next  : word128;                        -- comb slice of input key
  signal key_fwd_w  : tRoundBank := (others => (others => '0'));

  -- reversed keys registered per stage for decryption
  signal dec_key_q  : tRoundBank := (others => (others => '0'));

  -- round comb wires
  signal row_out    : tRoundBank := (others => (others => '0'));
  signal sbox_out   : tRoundBank := (others => (others => '0'));
  signal addrk_out  : tRoundBank := (others => (others => '0'));
  signal invcol_out : tRoundBank := (others => (others => '0'));

  -- slice external key to 128b (K0)
  function initial_key (key : std_ulogic_vector(KEY_SIZE-1 downto 0))
    return word128 is
    variable r : word128 := (others => '0');
  begin
    if KEY_SIZE = 128 then
      r := key(127 downto 0);
    elsif KEY_SIZE = 192 then
      r := key(191 downto 64);
    else -- 256
      r := key(255 downto 128);
    end if;
    return r;
  end function;

begin
  ----------------------------------------------------------------------------
  -- Combinational K0 slice and forward key chain (for snapshot on start)
  ----------------------------------------------------------------------------
  key0_next    <= initial_key(i_cipher_key);
  key_fwd_w(0) <= key0_next;

  gen_fwd_keys : for i in 1 to ROUNDS generate
    NEXT_KEY_G : entity work.next_key(RTL)
      generic map ( key_size => KEY_SIZE, rounds => ROUNDS )
      port map (
        i_prev_key      => key_fwd_w(i-1),   -- comb forward chain
        i_current_round => i,
        o_next_key      => key_fwd_w(i)
      );
  end generate;

  ----------------------------------------------------------------------------
  -- Stage 0 (combinational): initial AddRoundKey with K[Nr]
  ----------------------------------------------------------------------------
  ADD_RK_R0 : entity work.addRoundKey(RTL)
    port map (
      i_state_in     => initial_state,     -- ciphertext hold
      i_expanded_key => dec_key_q(0),      -- K[Nr]
      o_state_out    => addrk_out(0)
    );

  ----------------------------------------------------------------------------
  -- Rounds 1..ROUNDS-1 (combinational): InvShiftRows → InvSubBytes → ARK → InvMC
  ----------------------------------------------------------------------------
  gen_rounds : for i in 1 to ROUNDS-1 generate
    INV_SHIFT_ROWS_G : entity work.inv_shift_rows(RTL)
      port map ( i_inv_row_state_in => state_bank(i-1), o_inv_row_state_out => row_out(i) );

    INV_SBOX_G : entity work.inv_sbox(RTL)
      port map ( i_inv_byte_in => row_out(i), o_inv_byte_out => sbox_out(i) );

    ADD_RK_G : entity work.addRoundKey(RTL)
      port map ( i_state_in => sbox_out(i), i_expanded_key => dec_key_q(i), o_state_out => addrk_out(i) );

    INV_MIX_COLUMNS_G : entity work.inv_move_columns(RTL)
      port map ( i_inv_column_state_in => addrk_out(i), o_inv_column_state_out => invcol_out(i) );
  end generate;

  ----------------------------------------------------------------------------
  -- Final round (no InvMixColumns): InvShiftRows → InvSubBytes → ARK(K0)
  ----------------------------------------------------------------------------
  INV_SHIFT_ROWS_LAST : entity work.inv_shift_rows(RTL)
    port map ( i_inv_row_state_in => state_bank(ROUNDS-1), o_inv_row_state_out => row_out(ROUNDS) );

  INV_SBOX_LAST : entity work.inv_sbox(RTL)
    port map ( i_inv_byte_in => row_out(ROUNDS), o_inv_byte_out => sbox_out(ROUNDS) );

  ADD_RK_LAST : entity work.addRoundKey(RTL)
    port map ( i_state_in => sbox_out(ROUNDS), i_expanded_key => dec_key_q(ROUNDS), o_state_out => addrk_out(ROUNDS) );

  ----------------------------------------------------------------------------
  -- Registers: snapshot reversed keys on start, then run the pipe
  ----------------------------------------------------------------------------
  proc_regs : process(i_clk, i_nrst_async)
    variable cap : std_ulogic_vector(0 to ROUNDS); -- capture enables per stage
  begin
    if i_nrst_async = '0' then
      state_bank   <= (others => (others => '0'));
      dec_key_q    <= (others => (others => '0'));
      vld_pipe     <= (others => '0');
      en_d1        <= '0';
      initial_state<= (others => '0');
      key0_reg     <= (others => '0');

    elsif rising_edge(i_clk) then
      ------------------------------------------------------------------------
      -- (A) compute capture enables from previous tokens
      ------------------------------------------------------------------------
      cap(0) := en_d1;                     -- stage-0 captures one cycle after start
      for i in 1 to ROUNDS loop
        cap(i) := vld_pipe(i-1);
      end loop;

      ------------------------------------------------------------------------
      -- (B) register stage outputs using 'cap'
      ------------------------------------------------------------------------
      if cap(0) = '1' then
        state_bank(0) <= addrk_out(0);
      end if;

      for i in 1 to ROUNDS-1 loop
        if cap(i) = '1' then
          state_bank(i) <= invcol_out(i);
        end if;
      end loop;

      if cap(ROUNDS) = '1' then
        state_bank(ROUNDS) <= addrk_out(ROUNDS);
      end if;

      ------------------------------------------------------------------------
      -- (C) on start: load holds and SNAPSHOT reversed keys for this key
      ------------------------------------------------------------------------
      if i_de_start = '1' then
        -- holds for ciphertext and K0
        initial_state <= i_data_in;
        key0_reg      <= key0_next;

        -- snapshot reversed key order into per-stage registers:
        -- dec_key_q(0) = K[Nr], ..., dec_key_q(Nr-1) = K[1], dec_key_q(Nr) = K[0]
        for k in 0 to ROUNDS loop
          dec_key_q(k) <= key_fwd_w(ROUNDS - k);
        end loop;
      end if;

      ------------------------------------------------------------------------
      -- (D) advance the valid tokens for next cycle
      ------------------------------------------------------------------------
      en_d1        <= i_de_start;   -- delayed start for stage-0 capture
      vld_pipe(0)  <= en_d1;
      for i in 1 to ROUNDS loop
        vld_pipe(i) <= vld_pipe(i-1);
      end loop;
    end if;
  end process;

  o_data_out <= state_bank(ROUNDS);
  -- Optional: expose a valid
  -- o_valid <= vld_pipe(ROUNDS);
end architecture RTL;
