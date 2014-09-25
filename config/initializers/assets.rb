
ActionView::AssetPaths.class_eval do
  def compute_public_path source, dir, options = {}
    source = source.to_s
    return source if is_uri?(source)

    # This is the added code block when compared to the original.
    # 1) Do as javascript_path prepending javascripts directory
    # and the same for stylesheets.
    # 2) For local absolute files, serve them as assets, so they can
    # have js/css compiled too. This applies mainly for themes.
    if source[0] == '/'
      source = source[1..-1]
    else
      case options[:ext]
      when 'js'
        source = "javascripts/#{source}"
      when 'css'
        source = "stylesheets/#{source}"
      end
    end

    source = rewrite_extension(source, dir, options[:ext]) if options[:ext]
    source = rewrite_asset_path(source, dir, options)
    source = rewrite_relative_url_root(source, relative_url_root)
    source = rewrite_host_and_protocol(source, options[:protocol])
    source
  end
end
