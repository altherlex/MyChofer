$(document).ready(function(){
	atualizar_status_corrida();
});
/* TODO: 1) Passar os cdg de corrida em aberto para atualizacao do status
*				 2) Atualizar os detalhes da corrida com o retorno da requisicao ajax (Info Motorista e status)
*			   3) Motorista chegou! Fazer pergunta pro cliente, atualizar o status e retirar das corridas a ser atualizadas
*/
function atualizar_status_corrida(){
	$(function startTime(){
		var arr_corridas = $.map($('ul.pendentes>li.corrida[status!="nao-atualizar"]'), function(c){return c.getAttribute('cdg_corrida')});
		//Atualizacao apenas se houver corridas pendentes
		if ($(arr_corridas).size()!=0){
			$.getJSON('/journeys/atualizar_status_corrida/', {corridas:arr_corridas}, function(data){
				$.each($(data), function(index, i){
					li_corrida = $('ul.pendentes').find('li.corrida[cdg_corrida="'+i.cdg_corrida+'"]')
					li_corrida.find('.detalhe_motorista').html(i.el_motorista);
					li_corrida.find('.status_corrida').html(i.el_status);
					if ((i.perguntar==true) && (li_corrida.size()!=0)){
						//Ativando menu de corridas pendentes
						$('#accordion').accordion( "activate" , 1 );
						//Motorista chegou: Parar de atualizar status
						li_corrida.attr('status', 'nao-atualizar');
						//Necessario esperar um tempo ate que o menu se abra por completo pois há um efeito
						setTimeout(function(){li_corrida.click()},300);
						chamar_cliente(i.pergunta, i.cdg_corrida, i.status_corrida);
					}
				});
			});				
		}
		//20s = 20000ms
		t=setTimeout(function(){startTime()},20000);
	});
	//setTimeout(function(){clearTimeout(t)},10000);
}
/*
* Este método é ativado quando o status configurado (em /locale) representa que o motirsta chegou
*   então é feita uma pergunta para o cliente afim de saber onde ele está!
* FIXME: A resposta do cliente é inserida no detalhe da corrida inside-client. 
* 			 Caso a tela seja renderizada esta informação não será apresentada.
*/
function chamar_cliente(pergunta, cdg_corrida, status_corrida){
	var marcar_detalhe_corrida = function(cdg_corrida, str){
		$('ul.pendentes').find('li.corrida[cdg_corrida="'+cdg_corrida+'"]').find('.tooltip_description .resposta_cliente').html(str);
	}

	var buttons = [
		{	text:pergunta.primeira_opcao.texto, click: function(){ 
			$.get('/journeys/responder_motorista', {status:status_corrida, cdg_corrida:cdg_corrida, cdg_resposta:pergunta.primeira_opcao.valor}, 
			function(data){
				//marcando a resposta do cliente no detalhe da corrida
				marcar_detalhe_corrida(cdg_corrida, data.el_resposta);
			});
			$(this).dialog("close");
		}},
		{ text:pergunta.segunda_opcao.texto, click: function(){
			$.get('/journeys/responder_motorista', {status:status_corrida, cdg_corrida:cdg_corrida, cdg_resposta:pergunta.segunda_opcao.valor}, 
			function(data){
				//marcando a resposta do cliente no detalhe da corrida
				marcar_detalhe_corrida(cdg_corrida, data.el_resposta);
			});	
			$(this).dialog("close");
		}},
	]
	confirmacao(pergunta.mensagem, pergunta.titulo, {
		width:'auto', 
		buttons:buttons, 
		zIndex:10001, 
		closeOnEscape:false,
		create: function(event, ui){/*no close button*/$(this).prev().find('a.ui-dialog-titlebar-close[role="button"]').hide();}
	})
}
function find_by_class(p_data, ul){
	$('ul.'+ul+'.lst_corridas').find('li').hide();
	if (p_data=='')
		$('.lst_corridas li').show();
	else
		$('.lst_corridas li.'+p_data).show();
}
function show_and_hide_to_field_set(p_element_content){
	var el=$(p_element_content);
	if ( show_and_hide(p_element_content) ){
		el.siblings().find('i').addClass('icon-sort-down').removeClass('icon-sort-up');
	}else{
		el.siblings().find('i').addClass('icon-sort-up').removeClass('icon-sort-down');
	}
}
function show_and_hide(p_selection){
	var r = $(p_selection+':visible').size()==0;
	if (r)
		$(p_selection).show();
	else
		$(p_selection).hide();
	return r;
}
/* Seta como requerido a lista de interesses, caso o combobox seja assinado */
function set_lst_interesse(p_ele){
	var ele = $(p_ele);
	if (show_and_hide(p_ele))
		ele.find('.cdg_poi').attr('required', 'required');
	else
		ele.find('.cdg_poi').removeAttr('required');
}
function carregar_lista_poi(el, classe){
	/* Requisicao ajax com retorno json para popular o select */
	if (($('#'+classe).find('#cdg_cidade').val()) && ($('#'+classe).find('#cdg_tpo_poi').val()))
		$.getJSON('/journeys/carregar_lista_poi/', {cdg_cidade:$('#'+classe).find('#cdg_cidade').val(), cdg_tpo_poi:$('#'+classe).find('#cdg_tpo_poi').val()}, function(data){
			$(el).html(data.options);
		});
}
function localizar_motorista(p_cdg_motorista, p_el){
	//$.ajax({type: 'POST',	url: '/journeys.json', data: $('form').serialize(),	success: function(data){confirmar_corrida(data)}, dataType: 'json', async: false});
	$.getJSON('/journeys/localizar_motorista/', {cdg_motorista:p_cdg_motorista}, function(data){
		define_place(new google.maps.LatLng(data.latitude, data.longitude), 'taxi');
	});
	/* 5 min aguardando para a prox requisicao */
	p_el = $(p_el);
	p_el.css('pointer-events', 'none');
	label_original = p_el.find('i').html();
	p_el.find('i').html('Aguarde 5 min...');
	setTimeout(function(){ p_el.css('pointer-events', 'auto');p_el.find('i').html(label_original); },150000);
}
/* Custom Dialog Confirm */
function confirmacao(msn, titulo, args){
	titulo= (typeof titulo=="undefined")? 'Notificação' : titulo;
	args1 = {
		resizable: false,
		height:140,
		modal: true,
	};
/*
		buttons: [{
			text:"OK", click: function() { $(this).dialog("close"); return true; } 
		}]
*/	
	if (args) $.extend(args1, args);
	$(".dialog-confirm").dialog("destroy");
	$(".dialog-confirm").remove();
	$('.jquery-gdakram-tooltip').remove();
	$('<div class="dialog-confirm" title="'+titulo+'">'+msn+'</div>').appendTo('body');
	//config
	$(".dialog-confirm").dialog(args1);
};

/*TODO:
*  Ao fazer uma requisicao AJAX, fechar a tela. Ao concluir a requisicao, abrir a tela.
*/
function overlay(fechar_tela){
	//$.ui.dialog.overlay.create();
	if (fechar_tela){
		$('<div></div>').addClass('ui-widget-overlay')
			.appendTo(document.body)
			.css({
				width: $(window).width(),
				height: $(window).height()
			});	
	}else{
		$('.ui-widget-overlay').remove();
	}
}