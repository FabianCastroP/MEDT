-- Test que genera, en 191 accesos a la interfaz SPI, la secuencia de datos de temperatura:
-- de 0 a +150 seguida de -40 a -1
 
-- Reloj 100 MHz
-- El tic se activa cada 3000 ciclos de reloj
-- Es necesario completar la sentencia de emplazamiento del dut

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity test_integral is
end entity;

architecture test of test_integral is
  signal clk:          std_logic;
  signal nRst:         std_logic;
  signal key0: std_logic;
  signal key1: std_logic;
  signal SDAT:         std_logic;
  signal CS:           std_logic;
  signal CL:           std_logic;
  signal unidad:       std_logic_vector(1 downto 0); 
  signal temp_BCD:     std_logic_vector(11 downto 0);
  constant T_clk:      time := 20 ns;      

  signal temp: std_logic_vector(15 downto 0);   

begin 

dut:
entity work.medt(estructural)  -- Completar nombre
  port map(
    clk,           -- in
    nRst,          -- in
    key0,  -- in
    key1,  -- in
    SDAT,          -- in
    CS,            -- buffer
    CL,            -- buffer
    unidad,        -- buffer
    temp_BCD       -- buffer
  );

process     -- Reloj
begin
  wait for T_clk/2;
    clk <= '0';

  wait for T_clk/2;
    clk <= '1';

end process;

process    -- Reset 
begin
  wait until clk'event and clk = '1';
  nRst <= '1';
  wait until clk'event and clk = '1';
  nRst <= '0';
  wait until clk'event and clk = '1';
  wait until clk'event and clk = '1';
  nRst <= '1';
  wait;

end process;

process  -- Genera la secuencia de temperaturas del test
  variable t_i: std_logic_vector(15 downto 0);

begin
  wait until nRst'event and nRst = '0';
    temp <= X"0003";
    t_i := X"0003";

  wait until nRst'event and nRst = '1';

  for i in 1 to 191 loop
     wait until CS'event and CS = '0';
     wait until CS'event and CS = '1';
     if t_i(15 downto 7) /= 150 then
       t_i(15 downto 7) := t_i(15 downto 7) + 1;

     else
       t_i := X"EC03";


     end if;
     temp <= t_i;

  end loop;

  wait for 100*T_clk;

  assert false
  report "fone"
  severity failure;

end process;

process   -- Maneja SDAT
  variable dato: std_logic_vector(15 downto 0) := X"0003";

begin
  wait until CS'event and CS = '0';
    dato := temp;
    SDAT <= dato(15) after 10*T_clk;   
    dato := dato(14 downto 0)&'Z';

  loop
    if CS =  '0' then
      wait until (CL'event and CL = '0') or (CS'event and CS = '1');
      if CS = '0' then
        SDAT <= dato(15) after 10*T_clk;   
        dato := dato(14 downto 0)&'Z';

      else
        SDAT <= 'Z';
        exit;

      end if;
    end if;
  end loop;

end process;

process  -- Genera pulsaciones

begin

  key0 <= '1';
  key1 <= '1';
  wait until clk'event and clk = '1';

  loop
    key0 <= not key0;
    key1 <= not key1;
    wait for 8000*T_clk;
    wait until clk'event and clk = '1';
  end loop;

end process;

end test;
