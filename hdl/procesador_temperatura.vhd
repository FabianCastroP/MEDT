

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

entity procesador_temperatura is
  port(
    clk:             in     std_logic;
    nRst:            in     std_logic;
    temperatura_spi: in     std_logic_vector(8 downto 0);  -- C con signo
    cambio_unidades: in     std_logic;
    unidad:          buffer std_logic_vector(1 downto 0);
    signo:           buffer std_logic;
    temp_BCD:        buffer std_logic_vector(11 downto 0)  -- [0, 423]
  );
end entity;

architecture rtl of procesador_temperatura is
  type   t_estado is (centigrados, kelvin, fahrenheit);
  signal estado:      t_estado;
  -- signal signo:       std_logic;  -- negativo = 1
  signal temp_K:      std_logic_vector(9 downto 0);   -- [233, 423]
  signal temp_F_mult: std_logic_vector(13 downto 0);  -- 150*29 = 4350 = 01 0000 1111 1110
  signal temp_F_div:  std_logic_vector(9 downto 0);
  signal redondeo:    std_logic;          -- temp_F_div(3 downto 0) 1000 = 0.5 -> redondeo
  signal temp_F:      std_logic_vector(9 downto 0);   -- [-41, 304]
  signal temp_abs:    std_logic_vector(9 downto 0);   -- 423 = 01 1010 0111
  signal temp_BCD_C:  std_logic_vector(3 downto 0);   -- [0, 4]
  signal aux_temp_BCD_DU: std_logic_vector(8 downto 0);  -- Almacena decenas y unidades [0, 99]
  signal temp_BCD_D:  std_logic_vector(4 downto 0);   -- [0, 9]
  signal temp_BCD_U:  std_logic_vector(8 downto 0);   -- [0, 9]

  begin

  process(clk, nRst)
  begin
    if nRst = '0' then
      estado <= centigrados;
    
    elsif clk'event and clk = '1' then
      if cambio_unidades = '1' then
        case estado is

          when centigrados =>
            estado <= kelvin;
        
          when kelvin =>
            estado <= fahrenheit;

          when fahrenheit =>
            estado <= centigrados;

        end case;
      end if;
    
    end if;
  end process;

  unidad <= "00" when estado = centigrados else
            "01" when estado = kelvin      else
            "10";

  signo <= temperatura_spi(8) when estado /= kelvin else
           '0';

  -- Conversion temperatura --

  temp_K <= (signo & temperatura_spi) + 273;

  -- Fahrenheit
  -- TF = TCENT*1.8125 + 32
  -- 1.8125 = 29/16 = (16 + 8 + 4 + 1)/16
  -- -1160
  -- 
  -- Multiplico por 29
  temp_F_mult <= (temperatura_spi(8) & temperatura_spi & "0000") +
                 (temperatura_spi & "000")  +
                 (temperatura_spi & "00")   +
                 (temperatura_spi);
  
  -- Divido entre 16
  temp_F_div <= temp_F_mult(13 downto 4);
  redondeo   <= temp_F_mult(3);

  -- Sumo 32 y redondeo
  temp_F <= (temp_F_div + 32) - 1 when temperatura_spi(8) = '1' and redondeo = '1' else
            (temp_F_div + 32) + 1 when temperatura_spi(8) = '0' and redondeo = '1' else
            (temp_F_div + 32);

  temp_abs <= not (temperatura_spi(8) & temperatura_spi) + 1 when estado = centigrados and temperatura_spi(8) = '1' else
              temperatura_spi(8) & temperatura_spi           when estado = centigrados and temperatura_spi(8) = '0' else
              -- not (temp_K) + 1                  when estado = kelvin      and signo = '1' else -- Nunca va a ser negativa
              temp_K                            when estado = kelvin                      else
              not (temp_F) + 1                  when estado = fahrenheit  and temperatura_spi(8) = '1' else
              temp_F;
  
  temp_BCD_C <= "0100" when temp_abs >= 400 else
                "0011" when temp_abs >= 300 else
                "0010" when temp_abs >= 200 else
                "0001" when temp_abs >= 100 else
                "0000";
  
  -- 423
  -- temp_BCD_C = 4
  -- aux_temp_BCD_DU = 423 - 400 = 23
  aux_temp_BCD_DU <= (temp_abs(8 downto 0) - 400) when temp_BCD_C = 4 else
                     (temp_abs(8 downto 0) - 300) when temp_BCD_C = 3 else
                     (temp_abs(8 downto 0) - 200) when temp_BCD_C = 2 else
                     (temp_abs(8 downto 0) - 100) when temp_BCD_C = 1 else
                     temp_abs(8 downto 0);

  temp_BCD_D <= "01001" when (aux_temp_BCD_DU >= 90) else
                "01000" when (aux_temp_BCD_DU >= 80) else
                "00111" when (aux_temp_BCD_DU >= 70) else
                "00110" when (aux_temp_BCD_DU >= 60) else
                "00101" when (aux_temp_BCD_DU >= 50) else
                "00100" when (aux_temp_BCD_DU >= 40) else
                "00011" when (aux_temp_BCD_DU >= 30) else
                "00010" when (aux_temp_BCD_DU >= 20) else
                "00001" when (aux_temp_BCD_DU >= 10) else
                "00000";
  
  temp_BCD_U <= (aux_temp_BCD_DU - 90) when temp_BCD_D = 9 else
                (aux_temp_BCD_DU - 80) when temp_BCD_D = 8 else
                (aux_temp_BCD_DU - 70) when temp_BCD_D = 7 else
                (aux_temp_BCD_DU - 60) when temp_BCD_D = 6 else
                (aux_temp_BCD_DU - 50) when temp_BCD_D = 5 else
                (aux_temp_BCD_DU - 40) when temp_BCD_D = 4 else
                (aux_temp_BCD_DU - 30) when temp_BCD_D = 3 else
                (aux_temp_BCD_DU - 20) when temp_BCD_D = 2 else
                (aux_temp_BCD_DU - 10) when temp_BCD_D = 1 else
                aux_temp_BCD_DU;

  temp_BCD <= temp_BCD_C(3 downto 0) & temp_BCD_D(3 downto 0) & temp_BCD_U(3 downto 0);
                

end rtl;
