class SnifferPluginMyprofileController < MyProfileController

  before_filter :fetch_sniffer_profile

  helper CmsHelper
  helper_method :profile_hash

  def edit
    if request.post?
      begin
        @sniffer_profile.update_attributes(params[:sniffer])
        @sniffer_profile.enabled = true
        @sniffer_profile.save!
        session[:notice] = _('Consumer interests updated')
      rescue Exception => exception
        flash[:error] = _('Could not save consumer interests')
      end
    end
  end

  def product_categories
    @categories = environment.categories.all :limit => 10,
      :conditions => ["type = 'ProductCategory' and LOWER(name) LIKE ?", "%#{params[:q]}%"]

    respond_to do |format|
      format.json{ render :json => @categories.map{ |i| {:id => i.id, :name => i.name} } }
    end
  end

  def product_category_search
    @categories = environment.categories.all :limit => 10,
      :conditions => ["type = 'ProductCategory' and LOWER(name) LIKE ?", "%#{params[:term]}%"]

    respond_to do |format|
      format.json{ render :json => @categories.map{ |pc| {:value => pc.id, :label => pc.name} } }
    end
  end

  #FIXME: move into class
  ProductCategory.has_many :enterprises, :through => :products

  def product_category_add
    @product_category = environment.categories.find params[:id]
    @profiles = @product_category.enterprises
  end

  def search
    self.class.no_design_blocks

    @suppliers_products = @sniffer_profile.suppliers_products
    @consumers_products = @sniffer_profile.consumers_products
    @no_results = @suppliers_products.count == 0 and @consumers_products.count == 0

    build_products @suppliers_products.collect(&:attributes)
    build_products @consumers_products.collect(&:attributes)

    @suppliers_categories = @suppliers_products.collect &:product_category
    @consumers_categories = @consumers_products.collect &:product_category
    @categories = (@suppliers_categories + @consumers_categories).sort_by(&:name)

    suppliers = @suppliers_products.group_by{ |p| @id_profiles[p['profile_id'].to_i] }
    consumers = @consumers_products.group_by{ |p| @id_profiles[p['profile_id'].to_i] }
    consumers.each{ |k, v| suppliers[k] ||= [] }
    suppliers.each{ |k, v| consumers[k] ||= [] }
    @profiles = suppliers.merge!(consumers) do |profile, suppliers_products, consumers_products|
      {:suppliers_products => suppliers_products, :consumers_products => consumers_products}
    end
  end

  def map_balloon
    @profile = Profile.find params[:id]

    suppliers_products = params[:suppliers_products].empty? ? [] : params[:suppliers_products].values
    consumers_products = params[:consumers_products].empty? ? [] : params[:consumers_products].values
    @empty = suppliers_products.empty? and consumers_products.empty?

    @suppliers_hashes = build_products(suppliers_products).values.first
    @consumers_hashes = build_products(consumers_products).values.first

    render :layout => false
  end

  def my_map_balloon
    render :layout => false
  end

  protected

  def fetch_sniffer_profile
    @sniffer_profile = SnifferPluginProfile.find_or_create profile
  end

  def profile_hash profile
    methods = [:id, :name, :lat, :lng, :distance]
    profile_hash = {}; methods.each{ |m| profile_hash[m] = profile.send m }
    profile_hash
  end

  def build_products data
    @id_profiles ||= {}
    @id_products ||= {}
    @id_categories ||= {}
    @id_my_products ||= {}
    @id_knowledges ||= {}

    results = {}
    return results if data.blank?

    grab_id = proc{ |field| data.map{|h| h[field].to_i }.uniq }

    profiles = Profile.all :conditions => {:id => grab_id.call('profile_id')}
    profiles.each{ |p| @id_profiles[p.id] ||= p }
    products = Product.all :conditions => {:id => grab_id.call('id')}, :include => [:enterprise, :product_category]
    products.each{ |p| @id_products[p.id] ||= p }
    my_products = Product.all :conditions => {:id => grab_id.call('my_product_id')}, :include => [:enterprise, :product_category]
    my_products.each{ |p| @id_my_products[p.id] ||= p }
    categories = ProductCategory.all :conditions => {:id => grab_id.call('product_category_id')}
    categories.each{ |c| @id_categories[c.id] ||= c }
    knowledges = Article.all :conditions => {:id => grab_id.call('knowledge_id')}
    knowledges.each{ |k| @id_knowledges[k.id] ||= k}

    data.each do |attributes|
      profile = @id_profiles[attributes['profile_id'].to_i]
      profile.distance = attributes['profile_distance']

      results[profile] ||= []
      results[profile] << {
        :profile => profile, :partial => attributes['view'], :product => @id_products[attributes['id'].to_i],
        :category => @id_categories[attributes['product_category_id'].to_i],
        :my_product => @id_my_products[attributes['my_product_id'].to_i], :partial => attributes['view'],
        :knowledge => @id_knowledges[attributes['knowledge_id'].to_i], :partial => attributes['view'],
      }
    end
    results
  end

end
