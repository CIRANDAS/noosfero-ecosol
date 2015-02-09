
module DeliveryPlugin::DisplayHelper

  def supplier_delivery_options options = {}
    selected = options[:selected]
    methods = options[:methods] || profile.delivery_methods

    options = methods.map do |method|
      cost = if method.fixed_cost.present? then float_to_currency_cart(method.fixed_cost, environment) else nil end
      text = if cost.present? then "#{method.name} (#{cost})" else method.name end

      content_tag :option, text, value: method.id,
        data: {label: method.name, type: method.delivery_type},
        selected: if method == selected then 'selected' else nil end
    end.join
  end

end
