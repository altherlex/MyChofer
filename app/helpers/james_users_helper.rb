module ChoferUsersHelper
	def lista_usuarios(arr_usuarios)
		html=[]
		html<<%{
			<div class="entries" style='overflow: auto;height: 258px;margin-top: 11px;'>
				<ul class="clear lst_corridas">
		}
		#id="journey_entry_3a9cbc871412a3231d6030d798fe2330" 
		arr_usuarios.each do |usuario|

=begin
A001_CD_CLIENTE: "1"
A001_SOBRENOME: TANAKA
A001_FOTO_URL: http://www.santacruzsistemas.com.br/Perfil/Cliente/defaultprofile.png
A001_EMAIL: TANAKA@HOTMAIL.COM
A001_TELEFONE: "FSDFSDFDS                     "
A001_NOME: MAURO

	record.cdg_id=p_h
	record.id=p_hash[
	record.first_name
	record.last_name=
	record.number_pho
	record.password=p
	record.email=p_ha
	record.login=reco

=end

			html<<%{
				<li class="map_entry #{usuario.first_name.to_s + usuario.last_name.to_s}">

				</li>
			}
		end
		html<<%{
				</ul>
				<div style="display: none;" class="load_more"><a href="#" class="grey_button">ver m·s</a></div>
			</div>
		}
		html.join.html_safe
	end
end