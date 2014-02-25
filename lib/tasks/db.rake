require 'rake'
namespace :db do
	desc 'Excluir todos os registros da tabela User'
	task :delete_all_users => :environment do
		User.delete_all
	end
end