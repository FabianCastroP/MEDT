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

entity control_displays is
 generic( segundo:  natural := 50000000;
          cambio_display: natural := 50000
         );
 port(clk:         in     std_logic;
      nRst:        in     std_logic;
      T_tic_spi:   in     std_logic_vector(3 downto 0);
      data_rdy:    in     std_logic;
      signo:       in     std_logic;
      temp_bcd:    in     std_logic_vector(11 downto 0);
      unidades:    in     std_logic_vector(1 downto 0);
      display_out: buffer std_logic_vector(6 downto 0); -- Salida display
      sel_display: buffer std_logic_vector(5 downto 0)  -- Selector display a nivel bajo   
      );
end entity;

architecture rtl of control_displays is
  signal cnt_1seg: std_logic_vector(25 downto 0);  -- cuenta hasta 50 000 000 (10 1111 1010 1111 0000 1000 0000) para 1 seg = 
  signal contando: std_logic;  -- Indica si se deberia mostrar el 0 de dato recibido
  signal fdc_1s:   std_logic;
  
  signal cnt_mux:  std_logic_vector(17 downto 0);  -- cuenta hasta 250 000 (11 1101 0000 1001 0000) para 5 ms
  signal fdc_mux:  std_logic;

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

 -- Proceso contador 5 ms = 200 Hz
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


  -- Seleccion display a nivel bajo (11 1110 -> 01 1111)
  process(clk, nRst)
  begin
    if nRst = '0' then
      sel_display <= (0 => '0', others => '1');
 
    elsif clk'event and clk = '1' then
      if fdc_mux = '1' then
        if sel_display = 31 then
          sel_display <= (0 => '0', others => '1');
      
        else
          sel_display <= sel_display(4 downto 0) & '1';
        
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

  BCD <= symb_C                when sel_display(0) = '0' and unidades = C        else
         symb_grados           when sel_display(0) = '0' and unidades = K        else
         symb_F                when sel_display(0) = '0' and unidades = F        else

         temp_bcd(3 downto 0)  when sel_display(1) = '0'                         else

         symb_menos            when sel_display(2) = '0' and pos_sgn_d = '1'     else
         symb_apagado          when sel_display(2) = '0' and cero_no_sig_d = '1' else 
         temp_bcd(7 downto 4)  when sel_display(2) = '0'                         else

         symb_menos            when sel_display(3) = '0' and pos_sgn_c = '1'     else
         symb_apagado          when sel_display(3) = '0' and cero_no_sig_c = '1' else
         temp_bcd(11 downto 8) when sel_display(3) = '0'                         else

         symb_2                when sel_display(4) = '0' and T_tic_spi = 2       else
         symb_4                when sel_display(4) = '0' and T_tic_spi = 4       else
         symb_6                when sel_display(4) = '0' and T_tic_spi = 6       else
         symb_8                when sel_display(4) = '0' and T_tic_spi = 8       else

         symb_0                when sel_display(5) = '0' and contando = '1'      else
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