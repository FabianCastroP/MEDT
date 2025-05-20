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

entity control_display is
  port (
    clk:         in     std_logic;
    nRst:        in     std_logic;
    T_tic_spi:   in     std_logic_vector(1 downto 0); -- Periodo lectura temperatura
    data_rdy:    in     std_logic;
    signo:       in     std_logic;  
    temp_bcd:    in     std_logic_vector(11 downto 0);
    unidades:    in     std_logic_vector(1 downto 0);
    tic_1_25ms:  in     std_logic;                    -- Mux diplay: 800 Hz
    tic_1s:      in     std_logic;                    -- Encendido 0 en display 8 1s
    display_out: buffer std_logic_vector(6 downto 0); -- Salida display (segmentos)
    nSel_display: buffer std_logic_vector(5 downto 0) -- Selector display a nivel bajo   
  );
end entity;

architecture rtl of control_display is
  signal contando: std_logic;  -- Indica si se deberia mostrar el 0 de dato recibido

  -- Segnales auxiliares (ceros no significativos y posicion bit de signo)
  signal cero_no_sig_c: std_logic;
  signal cero_no_sig_d: std_logic;

  signal pos_sgn_d:     std_logic;
  signal pos_sgn_c:     std_logic;

  signal BCD: std_logic_vector(3 downto 0);

  constant C: std_logic_vector(1 downto 0) := "00";
  constant K: std_logic_vector(1 downto 0) := "01";
  constant F: std_logic_vector(1 downto 0) := "10";

  -- Constantes decodificacion
  constant symb_0:       std_logic_vector(3 downto 0) := "0000";
  constant symb_2:       std_logic_vector(3 downto 0) := "0010";
  constant symb_4:       std_logic_vector(3 downto 0) := "0100";
  constant symb_6:       std_logic_vector(3 downto 0) := "0110";
  constant symb_8:       std_logic_vector(3 downto 0) := "1000";
  constant symb_C:       std_logic_vector(3 downto 0) := "1010";
  constant symb_grados:  std_logic_vector(3 downto 0) := "1011";
  constant symb_F:       std_logic_vector(3 downto 0) := "1100";
  constant symb_menos:   std_logic_vector(3 downto 0) := "1101";
  constant symb_apagado: std_logic_vector(3 downto 0) := "1110";
  
begin
           
  -- flip-flop para mostrar 0 en display 7 durante 1 segundo
  process(clk, nRst)
  begin
    if nRst = '0' then
      contando <= '0';

    elsif clk'event and clk = '1' then
      if data_rdy = '1' then
        contando <= '1';

      elsif tic_1s = '1' then
        contando <= '0';

      end if;
    end if;
  end process;

  -- Seleccion display a nivel bajo (11 1110 -> 01 1111)
  process(clk, nRst)
  begin
    if nRst = '0' then
      nSel_display <= (5 => '0', others => '1');
 
    elsif clk'event and clk = '1' then
      if tic_1_25ms = '1' then
        if nSel_display = "011111" then
          nSel_display <= (0 => '0', others => '1');
      
        else
          nSel_display <= nSel_display(4 downto 0) & '1';
        
        end if;
      end if;
    end if;
  end process;
  
  cero_no_sig_c <= '1' when temp_bcd(11 downto 8) = 0 and temp_bcd(7 downto 4) /= 0 else
                   '0';

  cero_no_sig_d <= '1' when temp_bcd(11 downto 4) = 0 else
                   '0';

  pos_sgn_c <= '1' when signo = '1' and cero_no_sig_c = '1' else
               '0';
  
  pos_sgn_d <= '1' when signo = '1' and cero_no_sig_d = '1' else
               '0';

  BCD <= symb_C                when nSel_display(0) = '0' and unidades = C        else
         symb_grados           when nSel_display(0) = '0' and unidades = K        else
         symb_F                when nSel_display(0) = '0' and unidades = F        else

         temp_bcd(3 downto 0)  when nSel_display(1) = '0'                         else

         symb_menos            when nSel_display(2) = '0' and pos_sgn_d = '1'     else
         symb_apagado          when nSel_display(2) = '0' and cero_no_sig_d = '1' else 
         temp_bcd(7 downto 4)  when nSel_display(2) = '0'                         else

         symb_menos            when nSel_display(3) = '0' and pos_sgn_c = '1'     else
         symb_apagado          when nSel_display(3) = '0' and cero_no_sig_c = '1' else
         temp_bcd(11 downto 8) when nSel_display(3) = '0'                         else

         symb_2                when nSel_display(4) = '0' and T_tic_spi = 0       else
         symb_4                when nSel_display(4) = '0' and T_tic_spi = 1       else
         symb_6                when nSel_display(4) = '0' and T_tic_spi = 2       else
         symb_8                when nSel_display(4) = '0' and T_tic_spi = 3       else

         symb_0                when nSel_display(5) = '0' and contando = '1'      else
         symb_apagado;

  -- Decodificador BCD (ampliado) a 7 segmentos: salidas activas a nivel alto
  process(BCD)
  begin
    case BCD is                    --abcdefg
      when "0000" => display_out <= "1111110"; -- 0 
      when "0001" => display_out <= "0110000"; -- 1
      when "0010" => display_out <= "1101101"; -- 2 
      when "0011" => display_out <= "1111001"; -- 3
      when "0100" => display_out <= "0110011"; -- 4
      when "0101" => display_out <= "1011011"; -- 5
      when "0110" => display_out <= "1011111"; -- 6
      when "0111" => display_out <= "1110000"; -- 7
      when "1000" => display_out <= "1111111"; -- 8
      when "1001" => display_out <= "1110011"; -- 9
      when "1010" => display_out <= "0001101"; -- c
      when "1011" => display_out <= "1100011"; -- grados (º)
      when "1100" => display_out <= "1000111"; -- F
      when "1101" => display_out <= "0000001"; -- sgn - 
      when "1110" => display_out <= "0000000"; -- Apagado
      when others => display_out <= "XXXXXXX";
  
    end case;
  end process;

end rtl;
