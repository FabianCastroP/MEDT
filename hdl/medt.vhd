library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
 
entity medt is
  port(
    clk:          in     std_logic;
    nRst:         in     std_logic;
    key0:         in     std_logic;  -- pulsador_der
    key1:         in     std_logic;  -- pulsador_izq
    SDAT:         in     std_logic;
    CS:           buffer std_logic;
    CL:           buffer std_logic;
    display_out:  buffer std_logic_vector(6 downto 0);  
    nSel_display: buffer std_logic_vector(5 downto 0)
  );
end entity;

architecture estructural of medt is
  signal cambio_estado:   std_logic;
  signal cambio_unidades: std_logic;
  signal pulsador_der:    std_logic;
  signal pulsador_izq:    std_logic;
  signal tic_1_25ms:      std_logic;    -- Mux diplay: 800 Hz
  signal tic_1s:          std_logic;    -- Encendido 0 en display 8 1s
  signal tic_2s:          std_logic;    -- Periodos de medidia SPI
  signal tic_4s:          std_logic;
  signal tic_6s:          std_logic;
  signal tic_8s:          std_logic;
  signal tic:             std_logic;
  signal tic_spi:         std_logic;
  signal T_tic_spi:       std_logic_vector(1 downto 0);
  signal data_rdy:        std_logic;
  signal temperatura:     std_logic_vector(8 downto 0);
  signal temp_BCD:        std_logic_vector(11 downto 0);

  signal signo:           std_logic;
  signal unidades:        std_logic_vector(1 downto 0);

begin

  U0:
  entity work.conf_pulsos(rtl)
  port map(
    clk          => clk,
    nRst         => nRst,
    key0         => key0,
    key1         => key1,
    pulsador_der => pulsador_der,
    pulsador_izq => pulsador_izq
  );

  U_1: 
  entity work.temporizador(rtl)
  --generic map (fdc_125ms => 125)
  port map(
    clk           => clk,
    nRst          => nRst,
    cambio_estado => pulsador_der,
    tic_1_25ms    => tic_1_25ms,
    tic_1s        => tic_1s,
    tic_2s        => tic_2s,
    tic_4s        => tic_4s,
    tic_6s        => tic_6s,
    tic_8s        => tic_8s,
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
    temperatura_spi => temperatura,
    cambio_unidades => pulsador_izq,
    unidad          => unidades,
    signo           => signo,
    temp_BCD        => temp_BCD
  );

  U_4:
  entity work.control_display(rtl)              
  port map(
    clk          => clk,
    nRst         => nRst,
    data_rdy     => data_rdy,
    signo        => signo,
    T_tic_spi    => T_tic_spi,
    tic_1_25ms   => tic_1_25ms,
    tic_1s       => tic_1s,
    unidades     => unidades,
    temp_BCD     => temp_BCD,
    display_out  => display_out,
    nSel_display => nSel_display
  );

end estructural;
