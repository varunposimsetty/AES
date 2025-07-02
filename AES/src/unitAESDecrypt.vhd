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
  begin 

end architecture RTL;