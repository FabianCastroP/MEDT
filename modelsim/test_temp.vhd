-- Test temporizador (nuevo fichero)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity test_temp is
end entity;

architecture test of test_temp is
 signal clk: std_logic;
 signal nRst: std_logic;
 signal cambio_estado: std_logic;
 signal tic_1_25ms: std_logic;
 signal tic_1s: std_logic;
 signal tic_2s: std_logic;
 signal tic_4s: std_logic;
 signal tic_6s: std_logic;
 signal tic_8s: std_logic;
 signal tic_spi: std_logic;
 signal T_tic_spi: std_logic_vector(1 downto 0);

 constant T_CLK: time := 20 ns;

 begin
 
 dut: entity work.temporizador(rtl)
 generic map(fdc_125ms => 125)  
  port map(clk,
           nRst,
           cambio_estado,
           tic_1_25ms,
           tic_1s,
           tic_2s,
           tic_4s,
           tic_6s,
           tic_8s,
           tic_spi,
           T_tic_spi
           );

 process
 begin
  clk <= '0';
  wait for T_CLK/2;
  clk <= '1';
  wait for T_CLK/2;
 end process;
 
 process
 begin
  nRst <= '0';
  cambio_estado <= '0';                 -- Estado inicial 4 segundos
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  nRst <= '1';
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  wait for 420690*T_CLK;


  -- Cambio de estado a 6 segundos
  wait until clk'event and clk = '1';
  cambio_estado <= '1';
  wait until clk'event and clk = '1';
  cambio_estado <= '0';
  wait until clk'event and clk = '1';
  wait for 654255*T_CLK;



  -- Cambio de estado a 8 segundos 
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  cambio_estado <= '1';
  wait until clk'event and clk = '1';
  cambio_estado <= '0';
  wait until clk'event and clk = '1';
  wait for 842900*T_CLK;


  -- Cambio de estado a 2 segundos 
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  cambio_estado <= '1';
  wait until clk'event and clk = '1';
  cambio_estado <= '0';
  wait until clk'event and clk = '1';
  wait for 367190*T_CLK;

  
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
 
  assert false report "fin" severity failure;
  
 end process;

end test;