# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
MyChofer::Application.initialize!

class String
	def nil_or_value!
		(self.present?)? self : nil
	end
end

module I18n
 class << self
		def dominio(descricao, valor)
			r = self.arr_dominio(descricao.to_s)
			r.detect{|v,c| v==valor}[1] rescue "invalid value #{valor}"
    end
    alias :td :dominio
		
		def arr_dominio(descricao)
			eval I18n.t(descricao.to_s)
		end
		alias :td_arr :arr_dominio
  end
end

=begin
@_binding = binding
def log_var(p, b = @_binding)
  eval("
    local_variables.each do |v| 
      if eval(v + \".object_id\") == " + p.object_id.to_s + "
        puts v + ': ' + \"" + p.to_s + "\"
      end
    end
  " , b)
end
=end