class ClienteCorrida < Cliente
  attr_accessor :corrida_id, :agenda, :tipo_carro, :tipo_corrida, :pacote_id, :origem, :destino, :valor_estimado, :cliente_solicitante_id, :cliente_atendido_id, :km_rodado_real, :tempo_corrida_real

  def consulta_corrida( p_corrida_id )
    client = soap_client_with_action( :consulta_corrida )
    p_method_name_cameled = :consulta_corrida.to_s.camelcase
    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.ConsultaCorrida(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_corrida_id ] ) )
            end
          end
        end
      end
    end

    decrypted = decrypt_with_response( response, :consulta_corrida )
    puts decrypted.to_yaml
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def checkin_corrida( p_corrida_id )
    client = soap_client_with_action( :checkin_cliente )
    p_method_name_cameled = :checkin_cliente.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end
          xml.soap(:Body) do |xml|
            xml.CheckinCliente(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_corrida_id ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :checkin_cliente )
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def cancela_corrida_cliente( p_corrida_id )
    client = soap_client_with_action( :cancela_corrida_cliente )
    p_method_name_cameled = :cancela_corrida_cliente.to_s.camelcase
    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end
          xml.soap(:Body) do |xml|
            xml.CancelaCorridaCliente(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_corrida_id ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :cancela_corrida_cliente )
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def lista_corridas_aberto_cliente( p_cliente_id )
    client = soap_client_with_action( :lista_corridas_aberto_cliente )
    p_method_name_cameled = :lista_corridas_aberto_cliente.to_s.camelcase
    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end
          xml.soap(:Body) do |xml|
            xml.ListaCorridasAbertoCliente(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_cliente_id ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :lista_corridas_aberto_cliente )
    hash = Hash.from_xml(decrypted) rescue nil
    setar_atributos_com_hash( hash )
  end

  # Caso for uma corrida para terceiros, deve se criar um usuário que represente o terceiro
  # class: Client
  # método: insere_cliente
  def insere_corrida( p_agenda, p_tipo_carro, p_tipo_corrida, p_pacote_id, p_origem, p_destino, p_valor_estimado, p_cliente_solicitante_id, p_cliente_atendido_id, p_km_rodado_real, p_tempo_corrida_real )
    client = soap_client_with_action( :insere_corrida )
    p_method_name_cameled = :insere_corrida.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"
 
			soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.InsereCorrida(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_agenda,
                                              p_tipo_carro,
                                              p_tipo_corrida,
                                              p_pacote_id,
                                              p_origem,
                                              p_destino,
                                              p_valor_estimado,
                                              p_cliente_solicitante_id,
                                              p_cliente_atendido_id,
                                              p_km_rodado_real,
                                              p_tempo_corrida_real ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :insere_corrida )
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def atualiza_corrida_cliente( p_corrida_id, p_agenda, p_tipo_carro, p_tipo_corrida, p_pacote_id, p_origem, p_destino, p_valor_estimado, p_cliente_solicitante_id, p_cliente_atendido_id, p_km_rodado_real, p_tempo_corrida_real )
    client = soap_client_with_action( :atualiza_corrida_cliente )

    p_method_name_cameled = :atualiza_corrida_cliente.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.AtualizaCorridaCliente(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_corrida_id,
                                              p_agenda,
                                              p_tipo_carro,
                                              p_tipo_corrida,
                                              p_pacote_id,
                                              p_origem,
                                              p_destino,
                                              p_valor_estimado,
                                              p_cliente_solicitante_id,
                                              p_cliente_atendido_id,
                                              p_km_rodado_real,
                                              p_tempo_corrida_real ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :atualiza_corrida_cliente )
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def preco_estimado( p_cliente_id, p_tempo_corrida_estimado, p_km_rodado_estimado, p_cidade_atendida_id, p_tipo_carro )
    client = soap_client_with_action( :preco_estimado )

    p_method_name_cameled = :preco_estimado.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.PrecoEstimado(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_cliente_id, p_tempo_corrida_estimado, p_km_rodado_estimado, p_cidade_atendida_id, p_tipo_carro ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :preco_estimado )
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def preco_corrida( p_corrida_id )
    client = soap_client_with_action( :preco_corrida )
    p_method_name_cameled = :preco_corrida.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.PrecoCorrida(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_corrida_id ] ) )
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :preco_corrida )
    hash = Hash.from_xml(decrypted) rescue nil
  end
end
