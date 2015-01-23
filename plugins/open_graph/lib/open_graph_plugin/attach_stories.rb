require_dependency 'open_graph_plugin/stories'

module OpenGraphPlugin::AttachStories

  module ClassMethods

    def open_graph_attach_stories
      klass = self.name
      callbacks = OpenGraphPlugin::Stories::ModelStories[klass.to_sym]
      return if callbacks.blank?

      callbacks.each do |on, stories|
        # subclasses may overide this, but the callback is called only once
        method = "open_graph_after_#{on}"
        self.send "after_commit", method, on: on
        # TESTING: crash on errors
        #self.send "after_#{on}", method

        self.send :define_method, method do
          actor = User.current.person rescue nil
          klass = OpenGraphPlugin::Stories
          # TESTING: crash on errors
          #klass = klass.delay unless FbAppPlugin.test_user? actor
          klass = klass.delay

          klass.publish self, on, actor, stories if actor
        end
      end
    end

  end

  module InstanceMethods

  end

end
