module JourneysHelper
	def lista_interesse_tag(field_name)
		select_id="cdg_poi_#{field_name}"
		div_id = "poi_#{field_name}"
		output = check_box_tag "ck_interesse_#{field_name}", 1, false, {:onclick=>"set_lst_interesse('##{div_id}');"}
		output.safe_concat(content_tag(:span, 'Ponto de interesse?'))
		output.safe_concat(
			content_tag(:div, :id=>div_id, :style=>'display:none;') do
				#FIXME: /*Just Test*/ gsub provisorio ate resolver problema de encode
				out = select_tag :cdg_cidade, options_for_select(SoapConnection::Cidade.atendidas.map{|i| [i.nme_cidade.gsub('SÃ£o', 'Sao').titleize, i.cdg_cidade]}.uniq), :onchange=>"carregar_lista_poi('##{select_id}', '#{div_id}')", :prompt=>'Escolha uma cidade'
				out.safe_concat select_tag :cdg_tpo_poi, options_for_select(SoapConnection::ListaInteresse.lst_tipo_poi.map{|i| [i.nme_tpo_poi.titleize, i.cdg_tpo_poi]}), :onchange=>"carregar_lista_poi('##{select_id}', '#{div_id}')", :prompt=>'Qual seu interesse'
				out.safe_concat select_tag select_id, nil, :class=>'cdg_poi', :field_name=>field_name, :onchange=>"load_field_poi('##{select_id}')", :prompt=>'Escolha um local'
				#out.safe_concat select_tag select_id, grouped_options_for_select( SoapConnection::ListaInteresse.lst_poi_all_group_to_select, nil, '' ), :style=>"padding:0px;display:none;", :field_name=>field_name, :onchange=>"load_field_poi('##{select_id}')"
				out
			end
		)
	end
	def painel_corrida
		output = content_tag(:div, :class=>'button') do
			"<h1 class='head'><a href='#'>Chame o Chofer</a></h1>".html_safe
		end
		output.safe_concat( tag('div', {:class=>"details", :style=>"display:block;height:334px;padding: 6px;"}, false) )

		output.safe_concat(
			content_tag(:form, :id=>'inserindo_corrida', :action=>"/journeys", :method=>"post") do
				out= hidden_field_tag 'journey[lat_lng_origem]', nil, :required=>true
				out.safe_concat hidden_field_tag 'cdg_area_atuacao', nil, :required=>true
				#out.safe_concat(protect_from_forgery :secret => form_authenticity_token)

				out.safe_concat(
					content_tag(:div) do
						field_set_tag('Tipo do carro', :style=>"border:1px solid silver;", :open=>false) do
							ooo=select_tag :tpo_carro, options_for_select([["Carro de luxo", '1'], ['Carro blindado', '2']], '1')
						end
					end
				)

				out.safe_concat hidden_field_tag 'journey[lat_lng_destino]', nil, :required=>true
				out.safe_concat(
					field_set_tag('De', :style=>"border:1px solid silver;padding-bottom:5px;border-width: 1px 0;") do
						from = text_field_tag :start_name, nil, :placeholder=>"From...", :autocomplete=>"off", :required=>true
						from.safe_concat lista_interesse_tag('start_name')
					end
				)

				#pacotes = SoapConnection::Corrida.lista_pacotes
				out.safe_concat(
					content_tag(:div) do
						field_set_tag('Tipo de corrida', :style=>"border:1px solid silver;", :open=>false) do
							ooo=select_tag :tpo_corrida, options_for_select([['Trajeto ònico', '0']], '0')
						end
					end
				)


				out.safe_concat(
					field_set_tag('Para', :style=>"border:1px solid silver;padding-bottom:5px;border-width: 1px 0;") do
						to = text_field_tag :end_name, nil, :placeholder=>"To...", :autocomplete=>"off", :required=>true
						to.safe_concat lista_interesse_tag('end_name')
					end
				)


				out.safe_concat select_tag :user_id, options_for_select([["Para mim", 'P'], ['Para alguem', 'A']], 'P'), :onchange=>"$(function(){ console.log($('#user_id').val()=='A');($('#user_id').val()=='A')? $('.rider_details').show() : $('.rider_details').hide() })"
				out.safe_concat(
					content_tag(:div, :style=>"display: none;", :class=>"rider_details") do
						o=text_field_tag :rider_name, nil, :placeholder=>"Passageiro", :class=>"rider_name"
						o.safe_concat text_field_tag :rider_mobile, nil, :placeholder=>"Número de celular"
					end
				)

				out.safe_concat(
					content_tag(:div) do
						o=safe_concat(content_tag(:span, 'Corrida agendada?'))
						o.safe_concat(check_box_tag "ck_agenda", 1, false, {:checked => "checked", :onclick=>"show_datetime();"})
					end
				)

				out.safe_concat(
					content_tag(:div, :class=>"whenDetails") do
						oo=content_tag(:div, :class=>"dateDetails") do
							datepicker_tag :start_journey, I18n.l(Date.current, :format=>:default), :minDate=>0, :maxDate=>"+1M"
						end

						oo.safe_concat(
							content_tag(:div, :id => "div_time", :class=>"dateDetails") do
								select_time(Time.now, {:time_separator=>':'}, {:style=>'width: 84px;'})
							end
						)

						oo.safe_concat(
							content_tag(:div, :id => "div_real_time") do
								content_tag(:span, 'Sua corrida ser‡ agendada para agora')
							end
						)

					end
				)

				out.safe_concat(submit_tag 'Criar rota', :class=>"grey_button", :id=>'criar_rota')
			end
		)

		output.safe_concat('</div>')
		output.html_safe
	end
	def painel_corridas_pendentes
		arr_corrida = SoapConnection::Corrida.corridas_aberto_cliente((current_user.read_attribute('id') rescue 1))
		%{
		<div class="button"><h1 class="head"><a href="#">Corridas ativas (#{arr_corrida.size} corridas) (cliente#{current_user.id rescue 1})</a></h1></div>
		<div class="details" style="display:block;padding:6px;">
			#{ datepicker_tag :date_journey_active, nil, :placeholder=>"Informe uma data", :autocomplete=>"off"}
			#{ link_to 'Buscar', "javascript:find_by_class($('#date_journey_active').val(), 'pendentes')", :class=>"grey_button"}
			#{ lista_corridas(arr_corrida) }
		</div>
		}.html_safe
	end
	def painel_corridas_anteriores
		arr_corrida = []#SoapConnection::Corrida.corridas_anteriores_cliente((current_user.id rescue 1))
		%{
		<div class="button"><h1 class="head"><a href="#">Corridas anteriores (#{arr_corrida.size} corridas) (cliente#{current_user.id rescue 1})</a></h1></div>
		<div class="details" style="display:block;padding: 6px;">
			#{ datepicker_tag :date_journey, nil, :placeholder=>"Informe uma data", :autocomplete=>"off"}
			#{ link_to 'Buscar', "javascript:find_by_class($('#date_journey').val(), 'anteriores')", :class=>"grey_button"}
			#{ lista_corridas(arr_corrida, 'VIS') }
		</div>
		}.html_safe
	end
	def lista_corridas(arr_corrida, modo='EDT')
		ul_class = (modo=='EDT')? 'pendentes' : 'anteriores'
		html=[]
		html<<%{
			<div class="entries" style='overflow: auto;height: 258px;margin-top: 11px;'>
				<ul class="clear lst_corridas #{ul_class}">
		}
		arr_corrida.each do |corrida|
			html<<%{
				<li style='cursor: pointer;' class="map_entry #{corrida.dta_corrida.to_s(:default)} tip_details corrida" lat_lng_origem="#{corrida.origem}" lat_lng_destino="#{corrida.destino}" cdg_corrida="#{corrida.cdg_corrida}" status="#{corrida.status_corrida}">
				<div class="inner">
					<div class="date">
						<span class="day">#{corrida.dta_corrida.to_s(:day)}</span><span class="month">#{corrida.dta_corrida.to_s(:mon)}</span>
					</div>
					<div class="origin">
						<span class="label">De:</span>
						<span class="value">#{corrida.origem_endereco}</span>
					</div>
					<div class="destination">
						<span class="label">Para:</span>
						<span class="value">#{corrida.destino_endereco}</span>
					</div>
					#{detalhe_corrida_tag(corrida,modo)}
				</div>
				</li>
			}
		end
		html<<%{
				</ul>
			</div>
		}
		html.join.html_safe
	end
	def detalhe_corrida_tag(corrida={}, modo='EDT')
		#corrida.cdg_motorista
		#corrida.cdg_pacote
		%{
		<div class="tooltip_description" style="display:none" title="#{corrida.dta_corrida.to_s(:complete)}">
			<input type="hidden" id="cdg_corrida" value="#{corrida.cdg_corrida}"/>
			<p>
			<div class='detalhe_motorista'>
				#{motorista_tag(corrida.Motorista)}
			</div>
			De: (#{corrida.origem}) #{corrida.origem_endereco}<br/>
			Para: (#{corrida.destino}) #{corrida.destino_endereco}<br/>
			Aproximadamente: #{corrida.km_estimado} km | #{corrida.tmp_corrida_estimado} min<br/>
			Tipo da corrida: #{I18n.td('dominio.corrida.tipo',corrida.tipo_corrida)}<br/>
			<div class='status_corrida'>
				#{status_corrida_tag(corrida.status_corrida)}
			</div>
			<div class='resposta_cliente'>
				#{resposta_cliente_tag(corrida.resposta_cliente, corrida.status_corrida)}
			</div>
			#{atendido_tag(corrida.ClienteAtendido)}
			Corrida agendada para #{I18n.td('dominio.corrida.agenda', corrida.agenda_corrida)}<br/>
			#{I18n.td('dominio.corrida.tipo_carro',corrida.tpo_veiculo)}<br/>
			Valor estimado: #{corrida.vlr_estimado_to_s}<br/>
			#{ link_to "<i class='icon-trash' style='font-size:16px'>Cancelar</i>".html_safe, "/journeys/#{corrida.cdg_corrida}", :class=>'grey_button', :method=>:delete, :data=>{:confirm=>'Tem certeza?'} if modo=='EDT' }
			</p>
		<div>
		}.html_safe
	end
	def motorista_tag(motorista=nil)
		return '' if motorista.nil?
		#TODO
		# ao clicar em ver localização do motorista. Bloquear o botão por alguns minutos.
		# Apresentar um contator de punição pra saber o fim.
		id_tag = 'btn-localizar-motorista'+rand(1000).to_s
		%{
			<img src="#{motorista.foto_url}" style='width:57px;'>
			<p>
				Motorista:#{motorista.nome} #{motorista.sobrenome}
				#{ link_to "<i class='icon-eye-open'>Veja onde está o motorista</i>".html_safe, "javascript:localizar_motorista("+motorista.cdg_motorista+", '."+id_tag+"')", :class=>'grey_button '+id_tag }
			</p>
		}.html_safe
	end
	def atendido_tag(atendido=nil)
		return '' if atendido.nil?
		"Corrida para #{atendido.first_name} #{atendido.last_name}<br/>".html_safe
	end
	def status_corrida_tag(p_status)
		r = []
		r << "Status: #{I18n.td('dominio.corrida.status', p_status)}"
		if I18n.td_arr('corrida.regra.status_a_atualizar').include?(p_status)
			r << image_tag('ajax-loader-bar.gif', :style=>'padding-left: 9px;')
		end
		r << '<br/>'
		return r.join
	end
	def resposta_cliente_tag(p_cdg_resposta, p_status)
		#Mostrar esta informação apenas para corridas que estão na situação de motorista esperando
		if I18n.td_arr('corrida.regra.status_para_pergunta').include?(p_status)
			"#{I18n.t('corrida.regra.pergunta.mensagem')} #{I18n.td('dominio.corrida.pergunta',p_cdg_resposta)}"
		end
	end
	def detalhe_corrida_cabify_test
		%{
			<div class="tooltip_description" style="display:none" title="#{corrida.dta_corrida.to_s(:complete)}">
				<div class="inner">
					<div class="image">
						<img src="https://cabify.s3.amazonaws.com/production/avatars/a317d6ef9c3cbc91d326dcf31416967b/thumb_Jose_Mu_oz.jpg">
					</div>
					<div class="driver">
						<span class="label">Motorista:</span>
						<span class="value">???????????????</span>
					</div>
					<div class="taxi">
						<span class="label">Veículo:</span>
						<span class="value">????????</span>
					</div>
					<div class="rider">
						<span class="label">Passageiro:</span>
						<span class="value">Pedro Viado</span>
					</div>
					<div class="origin">
						<span class="label">19:49h:</span>
						<span class="value">Calle de Caramuel, Madrid, España</span>
					</div>
					<div class="destination">
						<span class="label">19:50h:</span>
						<span class="value">Av. de Portugal, Sintra, Portugal</span>
					</div>
					<div class="endState">Recorrido cancelado por el pasajero</div>
				</div>
				<div class="bottom">
					<div class="actions"></div>
					<div class="receipt noCharge"><span>Sin cargo</span></div>
				</div>
			</div>
		}.html_safe
	end
end