require_dependency 'search_controller'
require_dependency 'solr_plugin/facets_browse'
require_dependency 'solr_plugin/search_helper'

SearchController.helper SolrPlugin::SearchHelper
SearchController.send :include, SolrPlugin::FacetsBrowse

SearchController.class_eval do
  before_filter :solr_enterprise, only: [:enterprises]

  protected

  def solr_enterprise
    redirect_to params.merge(facet: {solr_plugin_f_enabled: true}) if params[:facet].blank? and params[:query].blank?
  end

end
