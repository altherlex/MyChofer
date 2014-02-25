module StartsHelper
	def slide_show_tag
		%{
			<div id="my-slideshow">
				<ul class="bjqs">
					<li>#{image_tag('carros/carro1.jpg')}</li>
					<li>#{image_tag('carros/carro2.jpg')}</li>
					<li>#{image_tag('carros/carro3.jpg')}</li>
					<li>#{image_tag('carros/carro4.jpg')}</li>
				</ul>
			</div>
			<script>
			$(document).ready(function(){
				$('#my-slideshow').bjqs({
					'width' : 940,
					'height' : 340,
					'animation' : 'slide',
					'animationDuration' : 200,
					/*'showMarkers' : true,*/
					/*'showControls' : true,*/
					'centerControls' :true,
					'centerMarkers' : true,
					'nextText': '<i class="icon-chevron-right icon-white"></i>',
					'prevText': '<i class="icon-chevron-left icon-white"></i>',
					'useCaptions' : false,
					'keyboardNav' : true
				});
			});
			</script>
		}.html_safe
	end
	
	def cidades_atendidas
		cidades = SoapConnection::Cidade.atendidas
	
		%{
			<div>
				#{select_tag :cdg_cidade_atendida, options_from_collection_for_select(cidades, "cdg_cidade", "nme_cidade"), :onchange => 'load_prices()'}
			</div>
			<div>
				#{select_tag :cdg_tipo_carro, options_for_select([['Carro de luxo', '1'], ['Carro blindado', '2']]), :onchange => 'load_prices()'}
			</div>
			<script>
				function load_prices() {
					cdg_cidade = $('#cdg_cidade_atendida option:selected')[0].value
					cdg_carro = $('#cdg_tipo_carro option:selected')[0].value		
					
					if(cdg_cidade == 0 || cdg_carro == 0) {
						alert('Preencha o campo de cidade e tipo de carro);
						return;
					} else {
						
					}
				}
			</script>
		}.html_safe
	end
	
	def precos
		arr = SoapConnectio::Tarifa
	end
end
