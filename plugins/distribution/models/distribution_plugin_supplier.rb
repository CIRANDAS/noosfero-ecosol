class DistributionPluginSupplier < ActiveRecord::Base

  belongs_to :node,  :class_name => 'DistributionPluginNode'
  belongs_to :consumer,  :class_name => 'DistributionPluginNode'

  has_many :supplied_products, :foreign_key => 'supplier_id', :class_name => 'DistributionPluginProduct', :order => 'name ASC'

  has_one :profile, :through => :node
  def profile
    node.profile
  end

  named_scope :from_node, lambda { |n| { :conditions => {:node_id => n.id} } }
  named_scope :from_node_id, lambda { |id| { :conditions => {:node_id => id} } }
  named_scope :with_name, lambda { |name| { :conditions => ["LOWER(name) LIKE ?",'%'+name.downcase+'%']  } }
  named_scope :active, :conditions => {:active => true}

  validates_presence_of :node
  validates_presence_of :consumer
  validates_associated :node
  validates_uniqueness_of :consumer_id, :scope => :node_id

  def self.new_dummy(attributes)
    new_profile = Enterprise.new :visible => false, :identifier => Digest::MD5.hexdigest(rand.to_s),
      :environment => attributes[:consumer].profile.environment
    new_node = DistributionPluginNode.new :role => 'supplier', :profile => new_profile
    supplier = new :node => new_node
    supplier.attributes = attributes
    supplier
  end
  def self.create_dummy(attributes)
    s = new_dummy attributes
    s.save!
    s
  end

  def self?
    node == consumer
  end

  def dummy?
    node.dummy?
  end

  def active?
   self.active
  end

  def name
    attributes['name'] || self.profile.name
  end

  def abbreviation_or_name
    name_abbreviation.blank? ? name : name_abbreviation
  end

  def name=(value)
    self['name'] = value
    if dummy?
      self.profile.name = value
      self.profile.save!
    end
  end

  alias_method :destroy_orig, :destroy
  def destroy!
    supplied_products.each{ |p| p.destroy! }
    destroy_orig
  end

  # FIXME: inactivate instead of deleting
  def destroy
    if node.dummy?
      node.profile.destroy
      node.destroy
    end
    supplied_products.distributed.update_all({:archived => true})

    super
  end

  protected

  after_create :complete
  def complete
    if dummy?
      consumer.profile.admins.each{ |a| node.profile.add_admin(a) } if node.dummy?
    end
  end

  after_destroy

  #delegate to node
  def method_missing(method, *args, &block)
    if self.respond_to? method
      super
    else
      node.send(method, *args, &block)
    end
  end

end
