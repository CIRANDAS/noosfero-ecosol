class OrdersPluginProductController < MyProfileController
  no_design_blocks

  def new
    @offered_product = SuppliersPlugin::OfferedProduct.find params[:offered_product_id]
    return render_not_found unless @offered_product

    if params[:order_id] == 'new'
      @session = @offered_product.session
      raise 'Cycle closed for orders' unless @session.orders?
      @order = OrdersPlugin::Order.create! :session => @session, :consumer => @user_node
    else
      @order = OrdersPlugin::Order.find params[:order_id]
      @session = @order.session
    end

    raise 'Order confirmed or cycle is closed for orders' unless @order.open?
    raise 'You are not logged or is not the owner of this order' if @user_node.nil? or @user_node != @order.consumer

    @ordered_product = OrdersPlugin::OrderedProduct.find_by_order_id_and_product_id @order.id, @offered_product.id
    @quantity_asked = CurrencyHelper.parse_localized_number(params[:quantity_asked]) || 1
    min = @offered_product.minimum_selleable

    if @ordered_product.nil? and @quantity_asked > 0
      if @quantity_asked < min
        @quantity_asked = min
        @quantity_asked_less_than_minimum = true
      end
      @ordered_product = OrdersPlugin::OrderedProduct.create! :order_id => @order.id, :product_id => @offered_product.id, :quantity_asked => @quantity_asked
      @quantity_asked_less_than_minimum = @ordered_product if @quantity_asked_less_than_minimum
    else
      if @quantity_asked <= 0
        @ordered_product.destroy if @ordered_product
        render :action => :destroy
      else
        if @quantity_asked < min
          @quantity_asked = min
          @quantity_asked_less_than_minimum = @ordered_product.id
        end
        @ordered_product.update_attributes! :quantity_asked => @quantity_asked
      end
    end
  end

  def edit
    if @admin_edit
      redirect_to params.merge!(:action => :admin_edit)
      return
    end
    @ordered_product = OrdersPlugin::OrderedProduct.find params[:id]
    @offered_product = @ordered_product.offered_product
    @order = @ordered_product.order
    @session = @order.session
    raise 'Order confirmed or cycle is closed for orders' unless @order.open?
    raise 'You are not logged or is not the owner of this order' if @user_node.nil? or @user_node != @order.consumer

    if params[:ordered_product][:quantity_asked].to_f <= 0
      @ordered_product.destroy
      render :action => :destroy
    else
      if @ordered_product.product.minimum_selleable and params[:ordered_product][:quantity_asked].to_f < @ordered_product.product.minimum_selleable
        params[:ordered_product][:quantity_asked] = @ordered_product.product.minimum_selleable
        @quantity_asked_less_than_minimum = @ordered_product.id
      end
      @ordered_product.update_attributes params[:ordered_product]
    end
  end

  def admin_edit
    @ordered_product = OrdersPlugin::OrderedProduct.find params[:id]
    @order = @ordered_product.order
    @session = @order.session
    #update on association for total
    @order.products.each{ |p| p.attributes = params[:ordered_product] if p.id == @ordered_product.id }
    @ordered_product.attributes = params[:ordered_product]
  end

  def destroy
    @ordered_product = OrdersPlugin::OrderedProduct.find params[:id]
    @offered_product = @ordered_product.offered_product
    @order = @ordered_product.order
    @session = @order.session
    @ordered_product.destroy
  end

  def session_destroy
    @ordered_product = OrdersPlugin::OrderedProduct.find params[:id]
    @order = @ordered_product.order
    @session = @order.session
  end

end
