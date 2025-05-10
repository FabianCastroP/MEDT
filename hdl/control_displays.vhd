-- Circuito que modela el control para la representacion de la medida de temperatura en los displays
--
-- display_0: representara la letra     C       = centigrados
--                                  medio ocho  = kelvin
--                                      F       = fahrenheit
-- display_1: en blanco (no lo ponemos)
-- display_2: unidades de temperatura 
-- display_3: decenas de temperatura o signo  
-- display_4: centenas de temperatura o signo 
-- display_5: en blanco (no lo ponemos)
-- display_6: indicacion del periodo de actualizacion de temperatura (2, 4, 6 u 8 segundos)
-- display_7: indicacion de nueva medida de temperatura


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- use ieee.std_logic_signed.all;

entity control_displays is
 generic( segundo:  natural := 50000000;
          cambio_display: natural := 2000000 -- 50MHz = 1/20ns -> 20ns*2000000 = 40ms = 25Hz
         );
 port(clk:         in std_logic;
      nRst:        in std_logic;
      T_tic_spi:   in std_logic_vector(3 downto 0);
      data_rdy:    in std_logic;
      signo:       in std_logic;
      temp_bcd:    in std_logic_vector(11 downto 0);
      unidades:    in std_logic_vector(1 downto 0);
      -- tic_1s: bu
      display_0: buffer std_logic_vector(6 downto 0);  

     -- Es necesario los displays en blanco asignandole valor de 0 para q esten apagados o podemos eliminarlos   
     -- display_1: buffer std_logic_vector(6 downto 0);   -- en blanco
      display_2: buffer std_logic_vector(6 downto 0);
      display_3: buffer std_logic_vector(6 downto 0);
      display_4: buffer std_logic_vector(6 downto 0);
     -- display_5: buffer std_logic_vector(6 downto 0);   -- en blanco
      display_6: buffer std_logic_vector(6 downto 0);
      display_7: buffer std_logic_vector(6 downto 0)
     
      );
end entity;

architecture rtl of control_displays is
  signal cnt_1seg: std_logic_vector(27 downto 0);  -- cuenta hasta 50 000 000 (0010 1111 1010 1111 0000 1000 0000) para 1 seg = 
  signal cnt_mux:      std_logic_vector(23 downto 0);  -- cuenta hasta  2 000 000 (0001 1110 1000 0100 1000 0000) para 40 ms

  signal contando: std_logic;
  signal sel_display: std_logic_vector(2 downto 0); -- Seleccion del display a encender
  
  signal fdc_1s: std_logic;
  signal fdc_mux: std_logic;

--  constant segundo:  natural := 50000000;
--  constant cambio_display: natural := 2000000;
  
  
begin

 -- Proceso contador 1 segundo
 process(clk, nRst)
 begin
  if nRst = '0' then
    cnt_1seg <= (others => '0');
 
  elsif clk'event and clk = '1' then
    if fdc_1s = '1' then
        cnt_1seg <= (others => '0');
 
    elsif contando = '1' then
      cnt_1seg <= cnt_1seg + 1;
   
    elsif data_rdy = '1' then
        cnt_1seg <= (0 => '1', others => '0');
     
   end if;
  end if;
 end process;

 fdc_1s <= '1' when cnt_1seg = segundo else 
           '0';

 contando <= '1' when cnt_1seg /= 0 else
             '0';


 -- Proceso contador 40 ms = 25 Hz
 process(clk, nRst)
 begin
  if nRst = '0' then
    cnt_mux <= (others => '0');
 
  elsif clk'event and clk = '1' then
   if fdc_mux = '1' then
    cnt_mux <= (0 => '1',others => '0');

   else
    cnt_mux <= cnt_mux + 1;

   end if;
  end if;
 end process;

 fdc_mux <= '1' when cnt_mux = cambio_display else
            '0';


 -- Proceso contador 40 ms = 25 Hz
 process(clk, nRst)
 begin
  if nRst = '0' then
   sel_display <= (others => '0');
 
  elsif clk'event and clk = '1' then
    if fdc_mux = '1' then
      if sel_display = 5 then
        sel_display <= (others => '0');
      
      else
        sel_display <= sel_display + 1;
      end if;

  --  if sel_display = 5 then
  --   sel_display <= (others => '0');

  --  elsif fdc_mux = '1' then
  --   sel_display <= sel_display + 1;
    
   end if;
  end if;
 end process;



 -- Decodificador: unidad de medida
display_0 <= "0000000" when sel_display /= 0 else
             "1001110" when unidades = 0 else  -- C
             "1100011" when unidades = 1 else  -- o
             "1000111"; 
             

 
 -- Decodificador: representacion tempertatura
 -- Unidades

 display_2 <= "0000000" when sel_display /= 1         else
              "1111110" when temp_bcd(3 downto 0) = 0 else
              "0110000" when temp_bcd(3 downto 0) = 1 else
              "1101101" when temp_bcd(3 downto 0) = 2 else
              "1111001" when temp_bcd(3 downto 0) = 3 else
              "0110011" when temp_bcd(3 downto 0) = 4 else
              "1011011" when temp_bcd(3 downto 0) = 5 else
              "1011111" when temp_bcd(3 downto 0) = 6 else
              "1110000" when temp_bcd(3 downto 0) = 7 else
              "1111111" when temp_bcd(3 downto 0) = 8 else
              "1111011"; --when temp_bcd(3 downto 0) = 9 else
              

 -- Decenas  

 display_3 <= "0000000" when sel_display /= 2 or (temp_bcd(11 downto 4) = 0 and signo = '0')        else
              "0000001" when signo = '1' and temp_bcd(11 downto 4) = 0 else  -- En Kelvin nunca se pone negativo porque los displays siempre muestran algo ( numero de tres cifras 273)
              "1111110" when temp_bcd(7 downto 4) = 0 else
              "0110000" when temp_bcd(7 downto 4) = 1 else
              "1101101" when temp_bcd(7 downto 4) = 2 else
              "1111001" when temp_bcd(7 downto 4) = 3 else
              "0110011" when temp_bcd(7 downto 4) = 4 else
              "1011011" when temp_bcd(7 downto 4) = 5 else
              "1011111" when temp_bcd(7 downto 4) = 6 else
              "1110000" when temp_bcd(7 downto 4) = 7 else
              "1111111" when temp_bcd(7 downto 4) = 8 else
              "1111011"; --when temp_bcd(3 downto 0) = 9 else
              

             

 -- Centenas

 display_4 <= "0000000" when sel_display /= 3 or temp_bcd(11 downto 4) = 0 else
              "0000001" when signo = '1' and temp_bcd(11 downto 8) = 0 and temp_bcd(7 downto 4) /= 0 else   -- En Kelvin nunca se pone negativo porque los displays siempre muestran algo ( numero de tres cifras 273)
              "1111110" when temp_bcd(11 downto 8) = 0 else
              "0110000" when temp_bcd(11 downto 8) = 1 else
              "1101101" when temp_bcd(11 downto 8) = 2 else
              "1111001" when temp_bcd(11 downto 8) = 3 else
              "0110011"; -- when temp_bcd(7 downto 4) = 4 else
              

 -- Display periodo de medida
 display_6 <= "0000000" when sel_display /= 4         else
              "1101101" when T_tic_spi = 2 else  -- 2
              "0110011" when T_tic_spi = 4 else  -- 4
              "1011111" when T_tic_spi = 6 else  -- 6
              "1111111" ;                        -- 8



  -- sel_display /= 5
  -- contando = '0'
  -- NADA

  -- sel_display == 5
  -- contando = '0'
  -- NADA

  -- sel_display /= 5
  -- contando = '1'
  -- NADA

  -- sel_display == 5
  -- contando = '1'
  -- Display refresco medida
 display_7 <= "1111110" when sel_display = 5 and contando = '1'  else
              "0000000";                    

 
end rtl;

  