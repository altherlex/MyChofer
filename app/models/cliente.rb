# Deprecate!
#		Use a classe cliente do module SoapConnection
class Cliente < SoapConnection
	attr_accessor :id, :nome, :sobrenome, :telefone, :login, :email, :senha, :corridas

	class<<self
		def consulta_cliente2( p_id )
			client = soap_client_with_action( :consulta_cliente )
			p_method_name_cameled = :consulta_cliente.to_s.camelcase
			response = client.request "#{p_method_name_cameled}" do
				http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"
				soap.xml do |xml|
					xml.soap(:Envelope, SoapConnection::NAMESPACES) do |xml|
						SoapConnection.define_head(xml)
						xml.soap(:Body) do |xml|
							xml.ConsultaCliente(:xmlns=> "http://tempuri.org/") do |xml|
								xml.strparms( encrypt_values( [p_id] ) )
							end
						end
					end
				end
			end
			SoapConnection.higienize( response, :consulta_cliente )
		end		
		def lista_detalhes_pagamento_cliente( p_cliente_id )
			client = soap_client_with_action( :lista_detalhes_pagamento_cliente )
			p_method_name_cameled = :lista_detalhes_pagamento_cliente.to_s.camelcase
			response = client.request "#{p_method_name_cameled}" do
				http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

				soap.xml do |xml|
					xml.soap(:Envelope, NAMESPACES) do |xml|
						xml.soap(:Header) do |xml|
							xml.ValidationSoapHeader(:xmlns=> "http://tempuri.org/") do |xml|
								xml.DevToken(@@dev_token)
							end
						end

						xml.soap(:Body) do |xml|
							xml.ListaDetalhesPagamentoCliente(:xmlns=> "http://tempuri.org/") do |xml|
								xml.strparms( encrypt_values( [p_cliente_id] ) )
							end
						end
					end
				end
			end
			decrypted = decrypt_with_response( response, :lista_detalhes_pagamento_cliente )
			hash = Hash.from_xml(decrypted) rescue nil
			setar_atributos_com_hash( hash )
		end
	end	

=begin
	# FIXME: Não é usado!
  def exclui_cliente( p_cliente_id )
    client = soap_client_with_action( :exclui_cliente )
    p_method_name_cameled = :exclui_cliente.to_s.camelcase
    response = client.request "#{p_method_name_cameled}" do
      http.headers["SOAPAction"] = "http://tempuri.org/#{p_method_name_cameled}"

      soap.xml do |xml|
        xml.soap(:Envelope, NAMESPACES) do |xml|
          xml.soap(:Header) do |xml|
            xml.ValidationSoapHeader(:xmlns=>"http://tempuri.org/") do |xml|
              xml.DevToken(@@dev_token)
            end
          end

          xml.soap(:Body) do |xml|
            xml.ExcluiCliente(:xmlns=> "http://tempuri.org/") do |xml|
              xml.strparms(encrypt_values([p_cliente_id] ))
            end
          end
        end
      end
    end
    decrypted = decrypt_with_response( response, :exclui_cliente )
    Hash.from_xml(decrypted) rescue nil
  end
=end

=begin
  def lista_poi( p_cliente_id )
    client = Savon::Client.new do
      wsdl.document = "http://www.santacruzsistemas.com.br/WS/Service.asmx?WSDL"
    end

    p_method_name_cameled = 'ListaPOI'

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
            xml.ListaPOI(xmlns: "http://tempuri.org/") do |xml|
              xml.strparms( encrypt_values( [p_cliente_id] ) )
            end
          end
        end
      end
    end

    decrypted = decrypt_with_response( response, :lista_poi )

    hash = Hash.from_xml(decrypted) rescue nil

    #setar_atributos_com_hash( hash )
  end
=end
  ### --- Corrida --- ###
  ### --- Fim Corrida --- ###
  def cliente_existe?
    self.id.to_i != 0
  end
  def insere_lista_convite
    #InsereListaConvite
  end
end
