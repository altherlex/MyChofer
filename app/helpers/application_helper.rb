module ApplicationHelper

	def cabecalho_geral
		result = []
		result << %{
		<div id='header_container'>
		<header class="wrapper">
			<h1 class="backgrounds-logo"><a href="/">MyChofer</a></h1>
			<nav>
				<ul class="slide_me">
					<li><a href="/#introduction">Home</a></li>
					<li><a href="/#in_detail">Como funciona</a></li>
					<li><a href="/#rates">Preços</a></li>
					<li><a href="/#for_companies">Para empresas</a></li>
		}
	  if user_signed_in?
			result << %{
						<li class="noslide login_link">
							<a class="noslide" href="/users/edit"><i class="icon-user" style='color:#179CAB;font-size:20px;'></i>#{current_user.complete_name}</a>
						</li>
			}
		else
			result << %{
						<li class="noslide login_link">
							<a class="noslide" href="/users/sign_in"><i class="icon-user" style='color:#179CAB;font-size:20px;'></i>Entrar</a>
						</li>
			}
		end
		result << %{
					<li class="noslide hide download">
						<a class="download yellow noslide nohover" href="https://d.cabify.com/">Download</a>
					</li>
				</ul>
			</nav>
		</header>
		</div>
		}
		result.join.html_safe
	end
	
	#TODO: Cadastrar um cartao de credito!!!
	#		No has añadido una tarjeta de crédito todavía, <a href="#payment_methods">¿quieres añadir una ahora?</a>
	def notify_center
		content_tag(:div, :class=>"centered_section") do
			content_tag(:div, :class=>"notification_bar", :style=>'width: 1200px;') do
				flash[:info]
			end
		end
	end
	
	def head_to_user_tag
		%{
		<header>
			<div class="logo">
				#{ link_to image_tag('logo-chofer.png', :alt=>'Logo'), root_path}
			</div>
			<div class="user">
				<div class="names">
					#{ link_to current_user.complete_name, '/users/edit', :class=>'profile_name' if user_signed_in?}
				</div>
				#{ link_to 'Sair', '/users/sign_out', :class=>'logout', :method=>:delete if user_signed_in?}
				<div class="avatar">
					<a href="/users/edit">
						#{ image_tag current_user.avatar.url(:icon) rescue '' }
					</a>
				</div>
			</div>
			#{notify_center}
		</header>
		}.html_safe
	end
	
	def section_menu_tag(active=1)
		content_tag :div, :class=>:sections do
			content_tag :div, :class=>:row do
				tags=[]
				tags<<( link_to 'Minhas corridas', '/journeys', :class=>"journeys #{'active' if active==1}" )
				tags<<( link_to 'Conta', 'users/edit', :class=>"account #{'active' if active==2}" )
				tags.join.html_safe
			end
		end
	end

	def datepicker_tag(name, value = nil, options = {})
		result =[]
		result << text_field_tag(name, value, options)
		result << %{
			<script>
			$(function(){
				$( "##{name}" ).datepicker({ minDate: #{options[:minDate].to_json}, maxDate: #{options[:maxDate].to_json}, dateFormat: #{(options[:dateFormat]||"dd-mm-yy").to_json}});
			});
			</script>			
		}.html_safe
		result.join.html_safe
	end	
	def profile_menu_tag(nmr_op_ativa)
		%{
		<ul>
			<li class='account #{'active' if nmr_op_ativa==1}'><a href='/users/edit'>Profile</a></li>
			<li class='#{'active' if nmr_op_ativa==2}'><a href='/payments'>Paymente details</a></li>
			<li class='#{'active' if nmr_op_ativa==3}'><a href='/profiles/invitations'>Invitations</a></li>
			<li class='#{'active' if nmr_op_ativa==4}'><a href='balance'>Balance</a></li>
			<li class='#{'active' if nmr_op_ativa==5}'><a href='discount'>Discount codes</a></li>
			<li class='#{'active' if nmr_op_ativa==6}'><a href='company'>Company details</a></li>
			<li class='account #{'active' if nmr_op_ativa==7}'><a href='/chofer_users'>Users</a></li>
			<li class='account #{'active' if nmr_op_ativa==8}'><a href='/vouchers'>Cupons</a></li>
		</ul>
		}.html_safe
	end
	
	def field_set_tag(legend = nil, options = {}, &block)
		id = "modal_field_#{rand(1000)}"
		content = capture(&block)
		output = tag(:fieldset, options, true)
		handle = content_tag(:i, nil, :onclick=>"show_and_hide_to_field_set('##{id}');", :class=>'icon-sort-down modal_field')
		output.safe_concat(content_tag(:legend, (legend+handle).html_safe)) unless legend.blank?
		output.concat("<div id='#{id}' style='height:100%;'>#{content}</div>".html_safe)
		if options[:open]==false
			output.safe_concat( content_tag(:script, "show_and_hide_to_field_set('##{id}');") )
		end
		output.safe_concat("</fieldset>")
	end	
end