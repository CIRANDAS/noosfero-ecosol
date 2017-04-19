class OrdersPluginItemController < MyProfileController

  include OrdersPlugin::TranslationHelper

  #protect 'edit_profile', :profile
  before_filter :set_actor_name

  helper OrdersPlugin::DisplayHelper

  def edit
    @consumer  = user
    @item      = OrdersCyclePlugin::Item.where id: params[:id]
    if (@item.empty?)
      render json: {notfound: true}.to_hash
      return
    else
      @item = @item.first
    end
    @order  = @item.send(self.order_method)

    @errors = []
    if @order.may_edit? @consumer
      if params[:item].present? and set_quantity_consumer_ordered params[:item][:quantity_consumer_ordered]
        params[:item][:quantity_consumer_ordered] = @quantity_consumer_ordered
        @item.update! params[:item]
      end
    else
      @errors << 'order_confirmed_or_cycle_is_closed' unless @order.open?
      @errors << 'Please login to place an order' if @consumer.blank?
      @errors << 'not_the_owner' if @consumer != @order.consumer
    end

    serializer = OrdersPlugin::OrderSerializer.new @item.order.reload, scope: self, actor_name: @actor_name, errors: @errors
    render json: serializer.to_hash
  end

  def destroy
    item = OrdersPlugin::Item.where(id: params[:id]).first
    @offered_product = item.offered_product
    item.destroy
  end

  protected

  def set_quantity_consumer_ordered value
    @quantity_consumer_ordered = CurrencyFields.parse_localized_number value

    # the item quantity ordered can be
    # - less than minimum allowed
    # - more than stock if has stock
    # - between minimum and stock
    # - stock is less than minimum?
    if @quantity_consumer_ordered > 0
      min = @item.product.minimum_selleable rescue nil
      if min and @quantity_consumer_ordered < min
        @quantity_consumer_ordered = min
        @quantity_consumer_ordered_less_than_minimum = @item.id || true
      end

      if defined? StockPlugin and @item.from_product.use_stock
        if @quantity_consumer_ordered > @item.from_product.stored
          @quantity_consumer_ordered = @item.from_product.stored
          @quantity_consumer_ordered_more_than_stored = @item.id || true
        end
      end
    end
    if @quantity_consumer_ordered <= 0 && @item
      @quantity_consumer_ordered = nil
      destroy if params[:id]
    end

    @quantity_consumer_ordered
  end

  def order_method
    'sale'
  end

  # default value, may be overwriten
  def set_actor_name
    @actor_name = :consumer
  end

  extend HMVC::ClassMethods
  hmvc OrdersPlugin

end
