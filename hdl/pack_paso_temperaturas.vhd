-- Comprobar tamaño vector de datos en cada función (C2 9 bits)
-- Rangos:
--   - C [-40, 150]  9 bits
--   - K [233, 423]  10 bits
--   - F [-41, 304]  10 bits
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;

package pack_paso_temperaturas is
  -- Funciones paso unidades
  function centigrados_a_kelvin(temp_C: std_logic_vector(8 downto 0)) return std_logic_vector;
  function centigrados_a_fahrenheit(temp_C: std_logic_vector(8 downto 0)) return std_logic_vector;
  function temperatura_a_BCD(temp_C_K_F: std_logic_vector(9 downto 0)) return std_logic_vector;

end package;

package body pack_paso_temperaturas is

  function centigrados_a_fahrenheit(temp_C: std_logic_vector(8 downto 0)) return std_logic_vector is
    variable temp:      std_logic_vector(13 downto 0) := (others => '0');  -- 150*29 = 4350 = 01 0000 1111 1110
    variable decimales: std_logic_vector(3 downto 0)  := (others => '0');  -- 1000 = 0.5 -> redondeo superior
    variable resultado: std_logic_vector(9 downto 0)  := (others => '0');  -- 150*1.8125 + 32 = 303.845F ~ 304F = 01 0011 0000

    begin
      -- TF = TCENT*1.8125 + 32
      -- 1.8125 = 29/16 = (16 + 8 + 4 + 1)/16

      -- Multiplico por 29
      temp := (temp_C(8) & temp_C & "0000") +
              (temp_C & "000")  +
              (temp_C & "00")   +
              (temp_C);

      -- Divido entre 16
      resultado := temp(13 downto 4);
      decimales := temp(3 downto 0);

      resultado := resultado + 32;
      
      -- Compruebo si hay que redondear
      if decimales(3) = '1' then    -- 0.5
        if temp_C(8) = '1' then -- negativo
          resultado := resultado - 1; -- -40.5 -> -41
        else
          resultado := resultado + 1;
        end if;
      end if;

      -- Compruebo rango: [-41, 304]
      if resultado < -41 then
        resultado := "1111010111";  -- -41

      elsif resultado > 304 then
        resultado := "0100110000";  -- 304
      end if;

      return resultado;
  
  end function;

  function centigrados_a_kelvin(temp_C: std_logic_vector(8 downto 0)) return std_logic_vector is
    variable resultado: std_logic_vector(9 downto 0) := (others => '0');

    begin
      resultado := temp_C(8) & temp_C + 273;

      return resultado;
  
  end function;

  function temperatura_a_BCD(temp_C_K_F: std_logic_vector(9 downto 0)) return std_logic_vector is
    variable resultado : std_logic_vector(11 downto 0) := (others => '0');
    variable temp      : std_logic_vector(9 downto 0) := temp_C_K_F;
  begin
    -- Convert from 2's complement to absolute value
    if temp(9) = '1' then
      temp := (not temp) + 1;
    end if;
  
    -- Shift-Add-3 algorithm (Double Dabble)
    for iter in 1 to 10 loop
      -- Step 1: Add 3 to each BCD digit if it's greater than 4
      if resultado(3 downto 0) > 4 then
        resultado(3 downto 0) := resultado(3 downto 0) + 3;
      end if;
  
      if resultado(7 downto 4) > 4 then
        resultado(7 downto 4) := resultado(7 downto 4) + 3;
      end if;
  
      if resultado(11 downto 8) > 4 then
        resultado(11 downto 8) := resultado(11 downto 8) + 3;
      end if;
  
      -- Step 2: Shift left
      resultado := resultado(10 downto 0) & temp(9);
      temp := temp(8 downto 0) & '0';
    end loop;
  
    return resultado;
  end function;

end package body pack_paso_temperaturas;