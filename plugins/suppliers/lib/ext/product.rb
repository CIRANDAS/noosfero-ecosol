require_dependency 'product'

class Product

  named_scope :distributed, :conditions => ["products.type = 'SuppliersPlugin::DistributedProduct'"]

  named_scope :available, :conditions => {:available => true}
  named_scope :inavailable, :conditions => {:available => false}
  named_scope :archived, :conditions => {:archived => true}
  named_scope :unarchived, :conditions => {:archived => false}

  named_scope :by_profile, lambda { |profile| { :conditions => {:profile_id => profile.id} } }
  named_scope :by_profile_id, lambda { |profile_id| { :conditions => {:profile_id => profile_id} } }

  named_scope :from_supplier_profile_id, lambda { |profile_id|
    return {} if profile_id.nil?
    {
      :conditions => ['suppliers_plugin_suppliers.profile_id = ?', profile_id],
      :joins => 'INNER JOIN suppliers_plugin_source_products ON suppliers_plugin_source_products.to_product_id = products.id ' +
        'INNER JOIN suppliers_plugin_suppliers ON suppliers_plugin_suppliers.profile_id = suppliers_plugin_source_products.supplier_id '
    }
  }
  named_scope :from_supplier_id, lambda { |supplier_id|
    return {} if supplier_id.nil?
    {
      :conditions => ['suppliers_plugin_source_products.supplier_id = ?', supplier_id],
      :joins => 'INNER JOIN suppliers_plugin_source_products ON suppliers_plugin_source_products.to_product_id = products.id '
    }
  }

  named_scope :own,
    :conditions => ['products.profile_id = suppliers_plugin_source_products.to_product_id AND suppliers_plugin_source_products.from_product_id IS NULL'],
    :joins => 'INNER JOIN suppliers_plugin_source_products ON suppliers_plugin_source_products.to_product_id = products.id '

  has_many :sources_from_products, :class_name => 'SuppliersPlugin::SourceProduct', :foreign_key => :to_product_id, :dependent => :destroy
  has_many :sources_to_products, :class_name => 'SuppliersPlugin::SourceProduct', :foreign_key => :from_product_id, :dependent => :destroy

  has_many :suppliers, :through => :sources_from_products, :order => 'id ASC'

  has_many :to_products, :through => :sources_to_products, :order => 'id ASC'
  has_many :from_products, :through => :sources_from_products, :order => 'id ASC'
  has_many :to_profiles, :through => :to_products, :source => :profile
  has_many :from_profiles, :through => :from_products, :source => :profile

  def from_product
    self.from_products.first
  end

end
