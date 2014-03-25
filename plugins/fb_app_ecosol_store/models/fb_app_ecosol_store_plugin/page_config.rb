class FbAppEcosolStorePlugin::PageConfig < Noosfero::Plugin::ActiveRecord

  serialize :config, Hash

  validates_presence_of :page_id

  def profiles
    return nil if self.config[:type] != 'profiles'
    Profile.where(:id => self.config[:data])
  end

  def profiles= profiles
    self.config[:type] = 'profiles'
    self.config[:data] = profiles.map(&:id)
  end

  def profile_ids= profile_ids
    self.profiles = Profile.where('id in (?)',profile_ids.to_a).all
  end

  def query
    return nil if self.config[:type] != 'query'
    self.config[:data]
  end

  def query= value
    self.config[:type] = 'query'
    self.config[:data] = value if self.config[:type] = 'query'
  end

end
