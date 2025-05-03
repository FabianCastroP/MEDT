-- Comprobar tamaño vector de datos en cada función (C2 9 bits)
-- Rangos:
--   - C [-40, 150]  9 bits
--   - K [233, 423]  10 bits
--   - F [-41, 304]  10 bits
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package pack_test_reloj is
  -- Funciones auxiliares
  function kelvin_a_centigrados(temp_K: std_logic_vector(8 downto 0)) return std_logic_vector;
  function centigrados_a_fahrenheit(temp_C: std_logic_vector(7 downto 0)) return std_logic_vector;
  -- Funciones paso unidades
  function centigrados_a_kelvin(temp_C: std_logic_vector(7 downto 0)) return std_logic_vector;
  function kelvin_a_fahrenheit(temp_K: std_logic_vector(8 downto 0)) return std_logic_vector;
  function fahrenheit_a_centigrados(temp_F: std_logic_vector(8 downto 0)) return std_logic_vector;

end package;

package body pack_test_reloj is

  -- Funciones auxiliares

  function kelvin_a_centigrados(signo: std_logic; temp_K: std_logic_vector(8 downto 0)) return std_logic_vector is
    variable temp:      std_logic_vector(8 downto 0) := (others => '0');
    variable resultado: std_logic_vector(7 downto 0) := (others => '0');

    begin
        temp      := (temp_K - 273);
        resultado := temp(7 downto 0);
      
      if signo = '1' then
        resultado := not (resultado) + 1;
      end if;

      return resultado;
  
  end function;

  function centigrados_a_fahrenheit(signo: std_logic; temp_C: std_logic_vector(7 downto 0)) return std_logic_vector is
    variable temp:      std_logic_vector(12 downto 0) := (others => '0');  -- 150*29 = 4350 = 1 0000 1111 1110
    variable decimales: std_logic_vector(3 downto 0)  := (others => '0');  -- 1000 = 0.5 -> redondeo superior
    variable resultado: std_logic_vector(8 downto 0)  := (others => '0');  -- 150*1.8125 + 32 = 303.845F ~ 304F = 1 0011 0000

    begin
      -- TF = TCENT*1.8125 + 32
      -- 1.8125 = 29/16 = (16 + 8 + 4 + 1)/16

      -- Multiplico por 29
      temp := (temp_C & "0000") +
              (temp_C & "000")  +
              (temp_C & "00")   +
              (temp_C);

      -- Divido entre 16
      resultado := temp(12 downto 4);
      decimales := temp(3 downto 0);

      -- Sumo 32
      if signo = '1' then
        resultado := resultado - 32;
        -- Para temp(12 downto 4) < 31 se produce underflow. Hago valor absoluto
        if resultado < 32 then
          resultado := (not resultado) + 1;
        end if;
      else
        resultado := resultado + 32;
      end if;
      
      -- Compruebo si hay que redondear
      if decimales(3) = '1' then
        if resultado(8) = '1' 
          resultado := resultado - 1; 
        else
          resultado := resultado + 1;
        end if;
      end if;

      -- Compruebo rango: [-41, 304]
      if resultado > 41 and signo = '1' then
        resultado := "000101001";  -- 41

      elsif resultado > 304 and signo = '0' then
        resultado := "100110000";  -- 304
      end if;

      return resultado;
  
  end function;
  
  -- Funciones paso unidades

  function centigrados_a_kelvin(signo: std_logic; temp_C: std_logic_vector(7 downto 0)) return std_logic_vector is
    variable resultado: std_logic_vector(8 downto 0) := (others => '0');

    begin
      if signo = '1' then
        resultado := '0' & (273 - temp_C);
      else
        resultado := '0' & (273 + temp_C);
      end if;

      return resultado;
  
  end function;

  function kelvin_a_fahrenheit(signo: std_logic; temp_K: std_logic_vector(8 downto 0)) return std_logic_vector is
    variable temp_C:    std_logic_vector(7 downto 0) := (others => '0');
    variable resultado: std_logic_vector(8 downto 0) := (others => '0');

    begin
      -- Paso kelvin a centigrados
      temp_C    := kelvin_a_centigrados(signo, temp_K);
      resultado := centigrados_a_fahrenheit(signo, temp_C);
    
    return resultado;
  
  end function;

  function fahrenheit_a_centigrados(signo: std_logic; temp_F: std_logic_vector(8 downto 0)) return std_logic_vector is
    variable temp:      std_logic_vector(12 downto 0) := (others => '0');  -- (304 - 32)*16 = 4352 = "1 0001 0000 0000"
    variable decimales: std_logic_vector(3 downto 0)  := (others => '0');  -- "1000" = 0.5 -> redondeo superior
    variable resultado: std_logic_vector(7 downto 0)  := (others => '0');  -- (304 - 32)/1.8125 = 150.07C ~ 150C = "1001 0110"

    begin
      -- TF = TCENT*1.8125 + 32
      -- TCENT = (TF - 32)/1.8125

      -- 1/1.8125 = 16/29
      -- 1/29 ~ (1/(2^5) + 1/(2^9) + 1/(2^10) + 1/(2^12) + 1/(2^15) + 1/(2^16) + 1/(2^17) + 1/(2^18))
      
      -- Resto 32
      if signo = '1' then
        temp := temp_F + 32;
      else
        temp := temp_F - 32;
      end if;
      temp := "0000" & (temp_F - 32);

      -- Multiplico por 16
      temp := temp(9 downto 0) & "0000";

      -- Division entre 29 no es posible. Aproximacion mas cercana:
      -- 1/2 + 1/(2^5) + 1/(2^6) + 1/(2^8) + 1/(2^11) + 1/(2^12)4096 + 1/(2^13) + 1/(2^14) + 1/(2^15)
      temp := ("0000" & temp(12 downto 4)) +
              ("000"  & temp(12 downto 3)) +
              ("00"   & temp(12 downto 2)) +
              temp(12 downto 0);

      resultado := temp(12 downto 5);
      decimales := temp(3 downto 0);

      -- Compruebo si hay que redondear
      if decimales(3) = '1' then
        resultado := resultado + 1;
      end if;

    --   -- Compruebo rango: [-40, 150]
    --   if resultado > 40 and signo = '1' then
    --     resultado := "00101000";  -- 40

    --   elsif resultado > 150 and signo = '0' then
    --     resultado := "10010110";  -- 304
    --   end if;

      return resultado;
  
  end function;


end package body pack_test_reloj;