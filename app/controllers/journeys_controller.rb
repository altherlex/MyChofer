class JourneysController < ApplicationController
	layout "profile"
	before_filter :authenticate_user!
	skip_before_filter :verify_authenticity_token, :only => [:create, :destroy, :index]

	def index
		current_user.empresa = SoapConnection::Empresa.valida_master((current_user.id rescue 1), current_user)
	end

  def destroy
		result = SoapConnection::Corrida.cancela(params[:id])
		redirect_to '/journeys',
			:flash=>{ :info => "Corrida excluída com sucesso! Retorno:#{result.inspect}" }
	end
	# Carregar lista POI
	def carregar_lista_poi
		resp = SoapConnection::ListaInteresse.lst_poi(params[:cdg_cidade], params[:cdg_tpo_poi])
		render :json => {:options => view_context.options_for_select(
			resp.map{|i| [i.nme_local.titleize, i.cdg_poi, {:lat_lng=>i.lat_lng_localizacao}]}.insert(0, ['Escolha um local', ''])
		)}.to_json
	end

	# Botao de visualização da localização do motorista
	def localizar_motorista
		local_motorista = SoapConnection::Service.new('ConsultaPosicaoMotorista').invoke(*params[:cdg_motorista])
		render :json => {:longitude=>local_motorista['A031_LONGITUDE'],:latitude=>local_motorista['A031_LATITUDE']}.to_json
	end

	def atualizar_status_corrida
		result = []
		params[:corridas].each do |cdg_corrida|
			#SoapConnection::Service.new('ConsultaStatusCorrida').invoke(cdg_corrida)
			# Utilizado este método pois traz informações do motorista
			corrida = SoapConnection::Corrida.carregar(cdg_corrida)
			h={}
			h[:perguntar] = I18n.td_arr('corrida.regra.status_para_pergunta').include?(corrida.status_corrida)
			h[:pergunta] = I18n.t('corrida.regra.pergunta')
			h[:el_status] = view_context.status_corrida_tag(corrida.status_corrida)
			h[:el_motorista] = view_context.motorista_tag(corrida.Motorista)
			h[:cdg_corrida] = cdg_corrida
			h[:status_corrida] = corrida.status_corrida
			result<<h
		end
		render :json => result.to_json
	end
	# Motorista na porta. O Clienta esta saindo ou precisa de 5 min?
	def responder_motorista
		result=SoapConnection::Corrida.insere_resposta_cliente( params[:cdg_corrida], params[:cdg_resposta] )
		result[:el_resposta] = view_context.resposta_cliente_tag(params[:cdg_resposta], params[:status])
		render :json => result.to_json
	end

	def create
#raise params.to_yaml
		#"date"=>{"minute"=>"29", "day"=>"27", "month"=>"8", "year"=>"2012", "hour"=>"21"}
		#2012-07-27 18:00:53
		dta_corrida="#{params[:date][:year]}-#{params[:date][:month]}-#{params[:date][:day]} #{params[:date][:hour]}:#{params[:date][:minute]}:00"

		#dta_corrida, lat_log_origem, lat_log_destino, dsc_endereco_origem, dsc_endereco_destino, km_rodado_estimado, min_estimado_corrida, vlr_estimado, cdg_cliente_solicitante, agenda_corrida=AGENDA_CORRIDA, cdg_tpo_carro=CDG_TPO_CARRO, tpo_corrida=TPO_CORRIDA, cdg_pacote=CDG_PACOTE, cdg_cliente_atendido=cdg_cliente_solicitante, status_corrida=STATUS_CORRIDA, cdg_poi_origem=CDG_POI_ORIGEM, cdg_poi_destino=CDG_POI_DESTINO, observacao=' ')
		#=>dta_corrida, agenda_corrida, cdg_tpo_carro, tpo_corrida, cdg_pacote, lat_log_origem, lat_log_destino, dsc_endereco_origem, dsc_endereco_destino, km_rodado_estimado, min_estimado_corrida, vlr_estimado, cdg_cliente_solicitante, cdg_cliente_atendido, status_corrida, observacao, cdg_poi_origem, cdg_poi_destino
		@route = calculate_price(params[:journey][:lat_lng_origem], params[:journey][:lat_lng_destino])
		tarifa =
			SoapConnection::Tarifa.estimar_preco_da_corrida(user_id,
																											@route[:duration_em_minutos],
																											@route[:distance_em_metros],
																											@route[:polyline],
																											params[:tpo_carro].nil_or_value!,
																											params[:cdg_area_atuacao],
																											params[:tpo_corrida],
																											dta_corrida
																										 ) #params[:tpo_corrida] = pacote

		#raise params.inspect

		# Lista POI
		cdg_poi_origem=nil
		cdg_poi_destino=nil
		if params[:ck_interesse_start_name]=='1'
			cdg_poi_origem=params[:cdg_poi_start_name]
		end
		if params[:ck_interesse_end_name]=='1'
			cdg_poi_destino=params[:cdg_poi_end_name]
		end
		# end Lista POI

		if params[:format]=='json'
			hash_comp={:dsc_tpo_carro=>I18n.td('dominio.corrida.tipo_carro', params[:tpo_carro])}
			render :json => params.merge(@route).merge(tarifa.first.instance_values.values.first).merge(hash_comp).to_json and return
		else params[:format]=='html'
			cdg_cliente_atendido = (params[:user_id] == 'A' ? 1 : user_id)

			result=SoapConnection::Corrida.insere(
				dta_corrida,
				params[:journey][:lat_lng_origem],
				params[:journey][:lat_lng_destino],
				params[:start_name],
				params[:end_name],
				@route[:distance_em_metros],
				@route[:duration_em_minutos],
				user_id,
				tarifa.first.vlr_estimado_alt,
				params[:tpo_carro].nil_or_value!,
				cdg_poi_origem,
				cdg_poi_destino,
				(params[:ck_agenda] ? 'D' : 'A'),#agenda_corrida
				params[:tpo_corrida],#=CDG_PACOTE,
				cdg_cliente_atendido,#cdg_cliente_atendido
				params[:cdg_area_atuacao],
				' '#observacao=' ',
			)

			#Regra de retornos(WS)
			#false (erro qualquer)
			#> 0 (inseriu)
			#-1 (cartão invalido)
			#-2 (não existe forma de pagamento cadatrada)
			#result.params_retorno
			if result.retorno=='-1'
				info='Cartão inválido.'
			elsif result.retorno=='-2'
				info='Não existe forma de pagamento cadatrada.'
			elsif result.retorno=='false'
				info="Nao foi possível inserir sua corrida. Tente novamente...#{result.params_retorno}"
			#elsif result.retorno.nil?
			#	info='Corrida inserida com sucesso! Confira em corridas ativas.'
			elsif result.retorno.to_i > 0
				info='Corrida inserida com sucesso'
			else
				info='Problema ao criar corrida: '+result.params_retorno.inspect
			end
			redirect_to '/journeys', :flash => { :info => info }
		end
	end

	def carregar_pacotes
	puts '           carregar_pacotes'
		cdg_carro = params[:tpo_carro]

		atuacao = SoapConnection::Corrida.ConsultaAreaAtuacao( params[:latitude], params[:longitude] )
		cdg_area_atuacao = '0'

		if atuacao.class.to_s == 'Array'
			cdg_area_atuacao = atuacao[0]['A018_CD_CIDADE_ATENDIDA'].to_s
		end

		pacotes = (cdg_area_atuacao != '0' ? SoapConnection::Corrida.lista_pacotes(cdg_area_atuacao) : [])[0..2]

		list = [['Trajeto único', '0']]
		pacotes.each do |x|
			list << [x.nome, x.cdg_id];
		end

		render :json => {:options => view_context.options_for_select(list), :cdg_area_atuacao => cdg_area_atuacao}.to_json
	end

	require "net/http"
	require "uri"
	private
	def calculate_price(origin, destination)
		uri=URI("http://maps.googleapis.com/maps/api/directions/json?sensor=false&alternatives=true&origin=#{origin}&destination=#{destination}")
		r = Net::HTTP.get_response(uri)
		r=ActiveSupport::JSON.decode(r.body.as_json)
		min_route = r['routes'].min{|a,b| a['legs'].first['distance']['value']<=>b['legs'].first['distance']['value']}

		retorno={}
		retorno[:polyline] = min_route['overview_polyline']['points'].gsub('|', '###')
		retorno[:distance_em_metros] = min_route['legs'].first['distance']['value']
		retorno[:duration_em_minutos] = min_route['legs'].first['duration']['value']
		retorno[:distance_em_metros_formatado] = (retorno[:distance_em_metros]>=1000)? "#{(retorno[:distance_em_metros]/1000)} km" : "#{retorno[:distance_em_metros]} metros"
		retorno[:duration_em_minutos_formatado] = "#{min_route['legs'].first['duration']['value']} minutos"
		return retorno
	end
	def user_id
		#ONLY TEST
		current_user.read_attribute('id') rescue 1
	end
end
