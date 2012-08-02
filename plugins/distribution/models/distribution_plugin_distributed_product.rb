class DistributionPluginDistributedProduct < DistributionPluginProduct

  def supplier_products
    from_products
  end

  alias_method :default_name_setting, :default_name
  def default_name
    dummy? ? nil : default_name_setting
  end
  alias_method :default_description_setting, :default_description
  def default_description
    dummy? ? nil : default_description_setting
  end

  def price
    price_with_margins = supplier_product ? supplier_product.price : self['price']
    return price_with_margins if price_with_margins.blank?

    if margin_percentage
      price_with_margins += (margin_percentage/100)*price_with_margins
    elsif node.margin_percentage
      price_with_margins += (node.margin_percentage/100)*price_with_margins
    end
    if margin_fixed
      price_with_margins += margin_fixed
    elsif node.margin_fixed
      price_with_margins += node.margin_fixed
    end

    price_with_margins
  end

  def self.json_for_category(c)
    {
      :id => c.id.to_s, :name => c.full_name(_(' > ')), :own_name => c.name,
      :hierarchy => c.hierarchy.map{ |c| {:id => c.id.to_s, :name => c.name, :own_name => c.name,
        :subcats => c.children.map{ |hc| {:id => hc.id.to_s, :name => hc.name} }} },
      :subcats => c.children.map{ |c| {:id => c.id.to_s, :name => c.name} },
    }
  end

  def json_for_category
    self.class.json_for_category(category) if category
  end

end
