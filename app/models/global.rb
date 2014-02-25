class Global < SoapConnection
  # attr_accessible :title, :body

  def consulta_tarifas( p_cidade_atendida_id, p_tipo_carro )
    client = soap_client_with_action( :consulta_tarifas )

    p_method_name_cameled = :consulta_tarifas.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      namespaces = {
        "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema"
      }

      soap.xml do |xml|
        xml.soap(:Envelope, namespaces) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.ConsultaTarifas(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_cidade_atendida_id, p_tipo_carro ] ) )
            end
          end
        end
      end
    end

    decrypted = decrypt_with_response( response, :consulta_tarifas )

    hash = Hash.from_xml(decrypted) rescue nil
  end
  
  def lista_bandeiras_cartao
		client = soap_client_with_action( :lista_bandeiras_cartao )

    p_method_name_cameled = :lista_bandeiras_cartao.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      namespaces = {
        "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema"
      }

      soap.xml do |xml|
        xml.soap(:Envelope, namespaces) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.ListaBandeirasCartao(xmlns: "http://tempuri.org/")
          end
        end
      end
    end

    decrypted = decrypt_with_response( response, :lista_bandeiras_cartao )

    hash = Hash.from_xml(decrypted) rescue nil
  end

  def lista_pacotes( p_cidade_atendida_id )
    client = soap_client_with_action( :lista_pacotes )

    p_method_name_cameled = :lista_pacotes.to_s.camelcase

    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      namespaces = {
        "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema"
      }

      soap.xml do |xml|
        xml.soap(:Envelope, namespaces) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(xmlns: "http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.ListaPacotes(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [ p_cidade_atendida_id ] ) )
            end
          end
        end
      end
    end

    decrypted = decrypt_with_response( response, :lista_pacotes )

    hash = Hash.from_xml(decrypted) rescue nil    
  end

end
