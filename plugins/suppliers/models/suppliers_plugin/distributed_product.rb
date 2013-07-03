class SuppliersPlugin::DistributedProduct < SuppliersPlugin::Product

  after_save :save_supplier_product

  alias_method :super_default_name, :default_name
  def default_name
    dummy? ? nil : super_default_name
  end
  alias_method :super_default_description, :default_description
  def default_description
    dummy? ? nil : super_default_description
  end

  def price
    return self['price'] if own?
    supplier_price = supplier_product ? supplier_product.price : nil
    return self['price'] if supplier_price.blank?

    price_with_margins supplier_price
  end

  def supplier_product
    return @supplier_product if @supplier_product

    @supplier_product = super
    # automatically create a product if supplier is dummy
    if !own? and dummy?
      @supplier_product ||= DistributionPluginDistributedProduct.new(:node => supplier.node, :supplier => supplier.node.self_supplier)
    end

    @supplier_product
  end
  def supplier_product=(value)
    if value.is_a?(Hash)
      supplier_product.attributes = value if supplier_product
    else
      @supplier_product = value
    end
  end

  def supplier_product_id
    supplier_product.id if supplier_product
  end
  def supplier_product_id=(id)
    distribute_from DistributionPluginProduct.find(id) unless id.blank?
  end

  # Set _product_ and its supplier as the origin of this product
  def distribute_from(product)
    s = node.suppliers.from_profile(product.profile).first
    raise "Supplier not found" if s.blank?

    @supplier_product = product
    self.name ||= product.name
    self.supplier = s
    self.save!
  end

  def self.json_for_category(c)
    {
      :id => c.id.to_s, :name => c.full_name(I18n.t('distribution_plugin.models.distributed_product. > ')), :own_name => c.name,
      :hierarchy => c.hierarchy.map{ |c| {:id => c.id.to_s, :name => c.name, :own_name => c.name,
        :subcats => c.children.map{ |hc| {:id => hc.id.to_s, :name => hc.name} }} },
      :subcats => c.children.map{ |c| {:id => c.id.to_s, :name => c.name} },
    }
  end
  def json_for_category
    self.class.json_for_category(self.category) if self.category
  end

  protected

  def save_supplier_product
    return unless supplier_product
    self.from_products << supplier_product unless self.from_products.include? supplier_product
    # force save on update
    self.supplier_product.save
  end

end
