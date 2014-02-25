class Login < SoapConnection

  def login(p_usuario, p_senha)
    client = soap_client_with_action(:login)

    p_method_name_cameled = :login.to_s.camelcase

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
            xml.ValidationSoapHeader(:xmlns=>"http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end
          xml.soap(:Body) do |xml|
            xml.Login(:xmlns=>"http://tempuri.org/") do |xml|
              xml.strparms(encrypt_values([p_usuario, p_senha] ))
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :login )
    hash = Hash.from_xml(decrypted) rescue nil
  end

  def recupera_senha( p_email )
    client = soap_client_with_action( :recupera_senha )
    p_method_name_cameled = :recupera_senha.to_s.camelcase

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
            xml.ValidationSoapHeader(:xmlns=>"http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end
          xml.soap(:Body) do |xml|
            xml.RecuperaSenha(:xmlns=>"http://tempuri.org/") do |xml|
              xml.strparms(encrypt_values([ p_email ] ))
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :recupera_senha )
    hash = Hash.from_xml(decrypted) rescue nil
  end
end
