

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
 
entity medt is
  port(
    clk:      in     std_logic;
    nRst:     in     std_logic;
    key0:     in     std_logic;  -- pulsador_der
    key1:     in     std_logic;  -- pulsador_izq
    SDAT:     in     std_logic;
    CS:       buffer std_logic;
    CL:       buffer std_logic;
    temp_BCD: buffer std_logic_vector(11 downto 0)
  );
end entity;

architecture estructural of medt is
  signal cambio_estado: std_logic;
  signal pulsador_der:  std_logic;
  signal pulsador_izq:  std_logic;
  signal tic_spi:       std_logic;
  signal T_tic_spi:     std_logic_vector(3 downto 0);
  signal data_rdy:      std_logic;
  signal temperatura:   std_logic_vector (8 downto 0);

begin

  U0:
  entity work.conf_pulsos(rtl)
  port map(
    clk  => clk,
    nRst => nRst,
    key0 => key0,
    key1 => key1,
    pulsador_der => pulsador_der,
    pulsador_izq => pulsador_izq
  );

  U_1: 
  entity work.temporizador_lectura(rtl)
  port map(
    clk           => clk,
    nRst          => nRst,
    cambio_estado => pulsador_der,
    tic_spi       => tic_spi,
    T_tic_spi     => T_tic_spi
  );

  U_2: 
  entity work.interfaz_spi(rtl)
  port map(
    clk         => clk,
    nRst        => nRst,
    tic         => tic_spi,
    SDAT        => SDAT,
    CS          => CS,
    CL          => CL,
    data_rdy    => data_rdy,
    temperatura => temperatura
  );

  U_3:
  entity work.procesador_temperatura(rtl)
  port map(
    clk             => clk,
    nRst            => nRst,
    data_rdy        => data_rdy,
    temperatura_spi => temperatura,
    T_tic_spi       => T_tic_spi,
    cambio_unidades   => pulsador_izq,
    temp_BCD        => temp_BCD
  );

end estructural;
