

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
 
entity medt is
  port(
    clk:          in     std_logic;
    nRst:         in     std_logic;
    pulsador_der: in     std_logic;  -- KEY0
    pulsador_izq: in     std_logic;  -- KEY1
    SDAT:         in     std_logic;
    CS:           buffer std_logic;
    CL:           buffer std_logic
  );
end entity;

architecture estructural of medt is
  signal cambio_estado: std_logic;
  signal tic_spi:       std_logic;
  signal T_tic_spi:     std_logic_vector(3 downto 0);

begin
 
U_0: 
entity work.temporizador_lectura(rtl)
  port map(
    clk           => clk,
    nRst          => nRst,
    cambio_estado => cambio_estado,
    tic_spi       => tic_spi,
    T_tic_spi     => T_tic_spi
  );

U_1: 
entity work.interfaz_spi(rtl)
  port map(
    clk  => clk,
    nRst => nRst,
    tic  => tic_spi,
    CS   => CS,
    CL   => CL,
    SDAT => SDAT
  );

end estructural;
