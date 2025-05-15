-- Circuito que modela la genereacion de temporizacion del sistema MEDT
-- Frecuencia de trabajo: 50 MHz ; Periodo: 20 ns
--    1. Tic multiplexacion displays: 20 ns*62500 = 1.25 ms
--    2. Tic 1 segundo: 1.25 ms*800 = 1 segundo
--    Para los tics de 2, 4, 6 y 8 segundos los obtendremos a partir del tic de 1 segundo


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity temporizador is
 generic( fdc_125ms: natural := 62500);
 port(clk: in std_logic;
      nRst: in std_logic;
      cambio_estado: in std_logic;
      tic_1_25ms: buffer std_logic;      -- Mux diplay: 800 Hz
      tic_1s: buffer std_logic;          -- Encendido 0 en display 8 1s
      tic_2s: buffer std_logic;          -- Periodos de medidia SPI
      tic_4s: buffer std_logic;
      tic_6s: buffer std_logic;
      tic_8s: buffer std_logic;
      tic_spi: buffer std_logic;     -- Habilitacion de comunicacion SPI
      T_tic_spi: buffer std_logic_vector(1 downto 0)  -- 2 = 00, 4 = 01, 6 = 10 , 8 = 11
      );
end entity;

architecture rtl of temporizador is

 signal cnt_125ms: std_logic_vector(17 downto 0);   -- cuenta hasta 62500 (timer principal)
 signal cnt_1s: std_logic_vector(9 downto 0);       -- cuenta hasta 800
 signal cnt_2s: std_logic_vector(1 downto 0);
 signal cnt_4s: std_logic_vector(3 downto 0);
 signal cnt_6s: std_logic_vector(3 downto 0);
 signal cnt_8s: std_logic_vector(4 downto 0);

 -- Signals para los estados de temporizacion de lectura del SPI
 type t_estado is(T_2s, T_4s, T_6s, T_8s);
 signal estado: t_estado;
 -- signal T_tic_spi: std_logic_vector(3 downto 0);
 
 -- Constantes para cada fin de cuenta
 constant fdc_1s: natural := 800;
 constant fdc_2s: natural := 2;
 constant fdc_4s: natural := 4;
 constant fdc_6s: natural := 6;
 constant fdc_8s: natural := 8;

begin 
  

 -- Proceso que controla los estados de seleccion temporizacion

 process(clk, nRst)
 begin
 
   if nRst = '0' then
     estado <= T_4s;       -- Hito 1
 
   elsif clk'event and clk = '1' then
     case estado is

        when T_2s =>
         if cambio_estado = '1' then
           estado <= T_4s;
         end if;

        when T_4s =>
         if cambio_estado = '1' then
           estado <= T_6s;
         end if;

        when T_6s =>
         if cambio_estado = '1' then
           estado <= T_8s;
         end if;

        when T_8s =>
         if cambio_estado = '1' then
           estado <= T_2s;
         end if;

      end case;
   end if;
 end process;

-- Proceso contador de 1.25 ms para la multiplexacion de displays
 process(clk, nRst)
  begin
   if nRst = '0' then 
     cnt_125ms <= (others => '0');
  
   elsif clk'event and clk = '1' then
    if tic_1_25ms = '1' then
     cnt_125ms <= (0 => '1', others => '0');
   
    else 
     cnt_125ms <= cnt_125ms + 1;
    
    end if;
   end if;
 end process;

 tic_1_25ms <= '1' when cnt_125ms = fdc_125ms else
               '0';

-- Proceso contador de 1 segundo
 process(clk, nRst)
 begin
  if nRst = '0' then
   cnt_1s <= (others => '0');
 
  elsif clk'event and clk = '1' then 
   if tic_1s = '1' then
    cnt_1s <= (0 => '1', others => '0');
   
   elsif cnt_125ms = fdc_125ms - 1 then 
    cnt_1s <= cnt_1s + 1;
  
   end if;
  end if;
 end process;

 tic_1s <= '1' when cnt_1s = fdc_1s and tic_1_25ms = '1' else
           '0';


-- Proceso contador 2 segundos
 process(clk, nRst)
 begin 
  if nRst = '0' then
   cnt_2s <= (others => '0');

  elsif clk'event and clk = '1' then
   if tic_2s = '1' then
     cnt_2s <= (others => '0');

   elsif cambio_estado = '1' then
      cnt_2s <= (others => '0');
 
   elsif cnt_1s = fdc_1s  then
     cnt_2s <= cnt_2s + 1;

   end if;
  end if;
 end process;

 tic_2s <= '1' when cnt_2s = fdc_2s else --and tic_1s = '1' else
           '0';

-- Proceso contador 4 segundos
 process(clk, nRst)
 begin 
  if nRst = '0' then
   cnt_4s <= (others => '0');

  elsif clk'event and clk = '1' then
   if tic_4s = '1' then
     cnt_4s <= (others => '0');

   elsif cambio_estado = '1' then
      cnt_4s <= (others => '0');
 
   elsif cnt_1s = fdc_1s then 
     cnt_4s <= cnt_4s + 1;

   end if;
  end if;
 end process;

 tic_4s <= '1' when cnt_4s = fdc_4s else--and tic_1s = '1' else
           '0';

 
-- Proceso contador 6 segundos
 process(clk, nRst)
 begin 
  if nRst = '0' then
   cnt_6s <= (others => '0');

  elsif clk'event and clk = '1' then
   if tic_6s = '1' then
     cnt_6s <= (others => '0');

   elsif cambio_estado = '1' then
      cnt_6s <= (others => '0');
 
   elsif cnt_1s = fdc_1s then 
     cnt_6s <= cnt_6s + 1;

   end if;
  end if;
 end process;

 tic_6s <= '1' when cnt_6s = fdc_6s else--and tic_1s = '1' else
           '0';

 
-- Proceso contador 8 segundos
 process(clk, nRst)
 begin 
  if nRst = '0' then
   cnt_8s <= (others => '0');

  elsif clk'event and clk = '1' then
   if tic_8s = '1' then
     cnt_8s <= (others => '0');
 
   elsif cambio_estado = '1' then
      cnt_8s <= (others => '0');

   elsif cnt_1s = fdc_1s then 
     cnt_8s <= cnt_8s + 1;

   end if;
  end if;
 end process;

 tic_8s <= '1' when cnt_8s = fdc_8s else--and tic_1s = '1' else
           '0';


 T_tic_spi <= "00" when estado = T_2s else
              "01" when estado = T_4s else
              "10" when estado = T_6s else
              "11" when estado = T_8s else 
              "00";
 
 tic_spi <= '1' when tic_2s = '1' and estado = T_2s else
            '1' when tic_4s = '1' and estado = T_4s else
            '1' when tic_6s = '1' and estado = T_6s else
            '1' when tic_8s = '1' and estado = T_8s else
            '0';
 
end rtl;