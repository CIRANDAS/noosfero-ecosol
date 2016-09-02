class SuppliersPlugin::ProductController < MyProfileController

  include SuppliersPlugin::TranslationHelper

  no_design_blocks

  protect 'edit_profile', :profile

  serialization_scope :view_context

  helper SuppliersPlugin::TranslationHelper
  helper SuppliersPlugin::DisplayHelper

  def index
    respond_to do |format|
      format.html{ render template: 'suppliers_plugin/product/index' }
      format.js{ render partial: 'suppliers_plugin/product/search' }
    end
  end

  def search
    if params[:page].present?
      render partial: 'suppliers_plugin/product/results'
    else
      render partial: 'suppliers_plugin/product/search'
    end
  end

  def create
    @product = Product.new(params[:product])
  end

  def edit
    @product = profile.products.supplied.find params[:id]
    @product.update params.require(:product).permit(:name, :product_category_id, :price, :margin, :available, :unit_id, :supplier_price)

    render nothing: true
  end

  def set_image
    params[:image_builder] = {uploaded_data: params[:image_builder]} if params[:image_builder].present?
    @product = profile.products.supplied.find params[:id]
    @product.update params.permit(image_builder: [:uploaded_data])

    render json: @product, serializer: SuppliersPlugin::ProductSerializer
  end

  def unavailable
    params[:available] = 'false'
    respond_to do |format|
      format.js{ render partial: 'suppliers_plugin/product/search' }
    end
  end

  def import
    if params[:csv].present?
      if params[:remove_all_suppliers] == 'true'
        profile.suppliers.except_self.find_each(batch_size: 40){ |s| s.delay.destroy }
      end
      SuppliersPlugin::Import.delay.products profile, params[:csv].read

      respond_to{ |format| format.js{ render nothing: true } }
    end
  end

  def destroy
    @product = SuppliersPlugin::DistributedProduct.find params[:id]
    @product.destroy
    render text: t('controllers.myprofile.product_controller.product_removed_succe')
  end

  def distribute_to_consumers
    params[:consumers] ||= {}

    @product = profile.products.find params[:id]
    @consumers = profile.consumers.find(params[:consumers].keys.to_a).collect(&:profile)
    to_add = @consumers - @product.consumers
    to_remove = @product.consumers - @consumers

    to_add.each{ |c| @product.distribute_to_consumer c }

    to_remove = to_remove.to_set
    @product.to_products.each{ |p| p.destroy if to_remove.include? p.profile }

    @product.reload
  end

  def activate
    ret = Product.where(id: params[:ids]).update_all(available: true)
    render text: ret > 0 ? "success" : "fail"
  end

  def deactivate
    ret = Product.where(id: params[:ids]).update_all(available: false)
    render text: ret > 0 ? "success" : "fail"
  end

  def categories
    @categories = environment.product_categories.where("LOWER(name) like ?", "%#{params[:query].downcase}%")
    render json: @categories, each_serializer: SuppliersPlugin::ProductCategorySerializer
  end

  def createAllocation
    @product = profile.products.find params[:product_id]
    @product.update_attribute(:use_stock, params[:use_stock] == 'true') if params[:use_stock].present?

    if params[:place_id].nil?
      if @product.stock_places.count == 0
        place = @product.profile.stock_places.create! name: 'default', description: 'default place'
        place = place.id
      else
        place = @product.stock_places.first.id
      end
    end

    m = params[:stock_action] == "adition" ? 1 : -1
    if params[:use_stock]
      a = @product.stock_allocations.create!(
        quantity: m * params[:quantity].to_f.abs,
        description: params[:description],
        place_id: place
      )
      render text: "fail" if !a
    end

    render json: @product
  end

  protected

  extend HMVC::ClassMethods
  hmvc SuppliersPlugin

  # inherit routes from core skipping use_relative_controller!
  def url_for options
    options[:controller] = "/#{options[:controller]}" if options.is_a? Hash and options[:controller] and not options[:controller].to_s.starts_with? '/'
    super options
  end
  helper_method :url_for

end
