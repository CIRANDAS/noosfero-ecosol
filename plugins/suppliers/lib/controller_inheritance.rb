module ControllerInheritance

  module ClassMethods

    def hmvc context
      cattr_accessor :hmvc_context
      cattr_accessor :inherit_templates
      cattr_accessor :hmvc_paths

      self.before_filter :set_hmvc_context

      self.inherit_templates = true
      self.hmvc_context = context
      self.hmvc_paths ||= {}
      self.hmvc_paths[self.hmvc_context] ||= {} if self.hmvc_context

      # initialize other context's controllers paths
      controllers = [self] + context.controllers.map{ |controller| controller.constantize }

      controllers.each do |klass|
        self.hmvc_paths[self.hmvc_context][klass.superclass.controller_path] = klass.controller_path
      end

      include InstanceMethods
    end

    def hmvc_controller_path hmvc_context = self.hmvc_context
      self.hmvc_paths[hmvc_context][self.controller_path] || self.controller_path
    end

    protected

  end

  class ActionView < ActionView::Base

    private

    def _pick_partial_template_with_hmvc partial_path
      if partial_path.include? '/'
        _pick_partial_template_without_hmvc partial_path
      elsif controller
        controller.send :each_template_with_hmvc do |klass|
          begin
            self.view_paths.find_template "#{klass.controller_path}/_#{partial_path}", self.template_format
          rescue ::ActionView::MissingTemplate
            raise "Can't find '#{partial_path}' in any #{controller.class}'s parent" unless (klass.inherit_templates rescue nil)
          end
        end
      else
        _pick_partial_template_without_hmvc partial_path
      end
    end
    alias_method_chain :_pick_partial_template, :hmvc

  end

  module InstanceMethods

    protected

    def set_hmvc_context
      @hmvc_context = self.class.hmvc_context
    end

    # replace method just to change instance class
    def initialize_template_class response
      response.template = ControllerInheritance::ActionView.new self.class.view_paths, {}, self
      response.template.helpers.send :include, self.class.master_helper_module
      response.redirected_to = nil
      @performed_render = @performed_redirect = false
    end

    def default_template action_name = self.action_name
      self.each_template_with_hmvc do |klass|
        begin
          self.view_paths.find_template "#{klass.controller_path}/#{action_name}", default_template_format
        rescue ::ActionView::MissingTemplate => e
          # raise the same exception as rails will rescue it
          raise e unless (klass.inherit_templates rescue nil)
        end
      end
    end

    def url_for options = {}
      controller = options[:controller]
      controller ||= controller_path
      controller = controller.to_s
      dest_controller = self.class.hmvc_paths[@hmvc_context][controller] || self.controller_path rescue self.controller_path

      options[:controller] = dest_controller if dest_controller
      super options
    end

    def each_template_with_hmvc &block
      klass = self.class
      ret = nil
      loop do
        ret = yield klass
        break if ret
        klass = klass.superclass
      end
      ret
    end

  end

end
