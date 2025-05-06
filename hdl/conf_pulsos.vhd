-- Conformador de pulsos para los pulsadores Key0 y Key1 de la tarjeta XDECA
-- Key0: activo a nivel bajo. Cambia el periodo de medida de temperatura. Pone la salida sal_k0 a 1
-- Key1: activo a nivel bajo. Modifica el modo de representacion de la temperatura. Pone la salida sal_k1 a 1

library ieee;
use ieee.std_logic_1164.all;

entity conf_pulsos is
  port(
    clk:          in     std_logic;
    nRst:         in     std_logic;
    key0:         in     std_logic;
    key1:         in     std_logic;
    pulsador_der: buffer std_logic;
    pulsador_izq: buffer std_logic
  );
end entity;

architecture rtl of conf_pulsos is
  signal aux: std_logic;

begin
 
  process(clk, nRst)
  begin
    if nRst = '0' then
      aux <= '0';

    elsif clk'event and clk = '1' then
      if key0 = '0' then 
        aux <= '1';
   
      elsif key1 = '0' then
        aux <= '1';
    
      else 
        aux <= '0'; 
      end if;

    end if;
  end process;

  pulsador_der <= '1' when key0 = '0' and aux = '0' else
                  '0';

  pulsador_izq <= '1' when key1 = '0' and aux = '0' else
                  '0';

end rtl;