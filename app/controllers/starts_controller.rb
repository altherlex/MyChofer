class StartsController < ApplicationController
  def index
  end
  
	def consulta_tarifas
		
		
		respond_to do |format|
			format.js { render :layout => false }
		end
	end
end
