require_dependency 'product'

class Product

  named_scope :available, :conditions => {:available => true}
  named_scope :inavailable, :conditions => {:available => false}
  named_scope :archived, :conditions => {:archived => true}
  named_scope :unarchived, :conditions => {:archived => false}

  named_scope :with_available, lambda { |available| { :conditions => {:available => available} } }
  named_scope :with_price, :conditions => 'products.price > 0'
  named_scope :with_product_category_id, lambda { |id| { :conditions => {:product_category_id => id} } }

  # FIXME: transliterate input and on db
  named_scope :name_like, lambda { |name| { :conditions => ["LOWER(products.name) LIKE ?", "%#{name}%"] } }

  named_scope :by_profile, lambda { |profile| { :conditions => {:profile_id => profile.id} } }
  named_scope :by_profile_id, lambda { |profile_id| { :conditions => {:profile_id => profile_id} } }

  def self.product_categories_of products
    ProductCategory.find products.collect(&:product_category_id).compact.select{ |id| not id.zero? }
  end

  # The lines above should be on the core. The following are real extensions

  has_many :sources_from_products, :class_name => 'SuppliersPlugin::SourceProduct', :foreign_key => :to_product_id, :dependent => :destroy
  has_many :sources_to_products, :class_name => 'SuppliersPlugin::SourceProduct', :foreign_key => :from_product_id, :dependent => :destroy
  has_many :to_products, :through => :sources_to_products, :order => 'id ASC'
  has_many :from_products, :through => :sources_from_products, :order => 'id ASC'
  def from_product
    self.from_products.first
  end

  has_many :sources_from_2x_products, :through => :sources_from_products, :source => :sources_from_products, :foreign_key => :id
  has_many :sources_to_2x_products, :through => :sources_to_product, :source => :sources_to_products, :foreign_key => :id
  has_many :from_2x_products, :through => :sources_from_2x_products, :source => :from_product
  has_many :to_2x_products, :through => :sources_to_2x_products, :source => :to_product

  has_many :suppliers, :through => :sources_from_products, :order => 'id ASC'

  # join source_products
  default_scope :include => [:from_2x_products, {:profile => [:domains]}]

  named_scope :distributed, :conditions => ["products.type = 'SuppliersPlugin::DistributedProduct'"]
  named_scope :own, :conditions => ["products.type = 'Product'"]

  named_scope :from_supplier_profile_id, lambda { |profile_id| {
      :conditions => ['suppliers_plugin_suppliers.profile_id = ?', profile_id],
      :joins => 'INNER JOIN suppliers_plugin_suppliers ON suppliers_plugin_suppliers.profile_id = suppliers_plugin_source_products.supplier_id'
    }
  }
  named_scope :from_supplier_id, lambda { |supplier_id| { :conditions => ['suppliers_plugin_source_products.supplier_id = ?', supplier_id] } }

  extend CurrencyHelper::ClassMethods
  has_currency :price

  after_create :distribute_to_consumers

  def own?
    self.class.name == Product
  end

  def supplier_products
    self.from_products
  end
  def supplier_product
    self.supplier_products.first
  end

  def supplier
    @supplier ||= self.supplier_product.supplier if self.supplier_product
    @supplier ||= self.profile.self_supplier
  end
  def supplier= value
    @supplier = value
  end
  def supplier_id
    self.supplier.id if self.supplier
  end
  def supplier_id= id
    @supplier = profile.environment.profiles.find id
  end

  def supplier_dummy?
    self.supplier ? self.supplier.dummy? : false
  end

  protected

  # see also #distribute_supplier_products
  def distribute_to_consumers
    self.profile.consumers.except_people.except_self.each do |consumer|
      SuppliersPlugin::DistributedProduct.create! :profile => consumer.profile, :from_products => [self]
    end
  end

end
