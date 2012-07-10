class Kalibro::ProjectResult < Kalibro::Model

  attr_accessor :project, :date, :load_time, :analysis_time, :source_tree, :collect_time

  def self.last_result(project_name)
    last_result = request(:get_last_result_of, {:project_name => project_name})[:project_result]
    new last_result
  end
  
  def self.first_result(project_name)
    first_result = request(:get_first_result_of, {:project_name => project_name})[:project_result]
    new first_result
  end

  def self.first_result_after(project_name, date)
    first_result_after = request(:get_first_result_after, {:project_name => project_name, :date => date})[:project_result]
    new first_result_after
  end

  def self.last_result_before(project_name, date)
    last_result_before = request(:get_last_result_before, {:project_name => project_name, :date => date})[:project_result]
    new last_result_before
  end

  def self.has_results?(project_name)
    request(:has_results_for, {:project_name => project_name})[:has_results]
  end
  
  def self.has_results_before?(project_name, date)
    request(:has_results_before, {:project_name => project_name, :date => date})[:has_results]
  end

  def self.has_results_after?(project_name, date)
    request(:has_results_after, {:project_name => project_name, :date => date})[:has_results]
  end
  
  def project=(value)
    @project = (value.kind_of?(Hash)) ? Kalibro::Project.new(value) : value
  end
  
  def date=(value)
    @date = value.is_a?(String) ? DateTime.parse(value) : value
  end

  def load_time=(value)
    @load_time = value.to_i
  end

  def collect_time=(value)
    @collect_time = value.to_i
  end

  def analysis_time=(value)
    @analysis_time = value.to_i
  end
  
  #FIXME mudar a atribuição depois que refatorarmos o module_result client
  def source_tree=(value)
    @source_tree = value.kind_of?(Hash) ? Kalibro::Entities::ModuleNode.from_hash(value) : value
  end
  
  def formatted_load_time
    format_milliseconds(@load_time)
  end

  def formatted_analysis_time
     format_milliseconds(@analysis_time)
  end

  def format_milliseconds(value)
    seconds = value.to_i/1000
    hours = seconds/3600
    seconds -= hours * 3600
    minutes = seconds/60
    seconds -= minutes * 60
    "#{format(hours)}:#{format(minutes)}:#{format(seconds)}"
  end

  def format(amount)
    ('%2d' % amount).sub(/\s/, '0')
  end
  
  def node_of(module_name)
    if module_name.nil? or module_name == project.name
      node = source_tree
    else
      node = get_node(module_name)
    end
  end

#FIXME mudar a atribuição depois que refatorarmos o module_result client
  def get_node(module_name)
    path = Kalibro::Entities::Module.parent_names(module_name)
    parent = @source_tree
    path.each do |node_name|
      parent = get_leaf_from(parent, node_name)
    end
    return parent
  end
  
  private

  def self.project_result
    endpoint = "ProjectResult" 
    service_address = YAML.load_file("#{RAILS_ROOT}/plugins/mezuro/service.yaml")
    Savon::Client.new("#{service_address}#{endpoint}Endpoint/?wsdl")
  end

  def self.request(action, request_body = nil)
    response = project_result.request(:kalibro, action) { soap.body = request_body }
    response.to_hash["#{action}_response".to_sym]
  end

  def get_leaf_from(node, module_name) 
    node.children.each do |child_node|
      return child_node if child_node.module.name == module_name
    end
    nil
  end

end
