class ExchangePlugin::Proposal < Noosfero::Plugin::ActiveRecord

  belongs_to :origin, :class_name => "Profile"
  belongs_to :target, :class_name => "Profile"
  belongs_to :exchange, :class_name => "ExchangePlugin::Exchange"

  has_many :elements, :class_name => "ExchangePlugin::Element", :dependent => :destroy, :order => "id asc"

  has_many :products, :through => :elements, :source => :element_np, :class_name => 'Product',
    :conditions => "exchange_plugin_elements.object_type = 'Product'"
  has_many :knowledges, :through => :elements, :source => :element_np, :class_name => 'CmsLearningPlugin::Learning',
    :conditions => "exchange_plugin_elements.object_type = 'CmsLearningPlugin::Learning'"

  has_many :messages, :class_name => "ExchangePlugin::Message", :dependent => :destroy, :order => "created_at desc"

  validates_inclusion_of :state, :in => ["open", "closed", "accepted"]
  validates_presence_of :origin, :target, :exchange_id

  def target_elements
    self.elements.all :conditions => {:profile_id => self.target_id}, :include => :element
  end

  def origin_elements
    self.elements.all :conditions => {:profile_id => self.origin_id}, :include => :element
  end

  def target? profile
    (profile.id == self.target_id)
  end

  def the_other(profile)
    target?(profile) ? self.origin : self.target
  end

  def my_elements(profile)
    target?(profile) ? self.target_elements : self.origin_elements
  end

  def other_elements(profile)
    target?(profile) ? self.origin_elements : self.target_elements
  end

end
