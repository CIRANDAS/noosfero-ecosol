desc "Creates new enterprises from the csv file - SIES Data"
task :sies_new_enterprises do
  require 'script/lib/fbes_enterprise_call'
  require 'script/lib/sies_new_enterprises'

  unless ENV["FILE"]
    puts "sintaxe:  "
    puts "  rake sies_new_enterprises FILE=filename"

  else
    init_log "sies-new-enterprises.log"
    enterprises = load_sheet ENV["FILE"]

    existing = Enterprise.where(['created_at > ? AND visible = true AND enabled = false', Date.today - 10.days]).order('id ASC')
    sies_enterprise_map = {}; existing.each do |e|
      id_sies = e.data[:id_sies]
      next e.destroy if sies_enterprise_map[id_sies].present?
      sies_enterprise_map[id_sies] = e
    end

    puts "Iniciando importação..."
    enterprises.each do |data|
      record = sies_enterprise_map[data[:data][:id_sies]]

      if record
        record.update_attribute :layout_template, 'leftbar'
        #update_enterprise data, record
      else
        record = create_enterprise data
      end
      data[:record] = record
    end

    puts "Exportando CSV com dados importados"
    export_imported enterprises

    puts "Importação concluída!"
  end

end
