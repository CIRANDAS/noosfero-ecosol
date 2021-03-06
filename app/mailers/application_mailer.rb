class ApplicationMailer < ActionMailer::Base

  include AuthenticatedSystem

  helper ApplicationHelper

  attr_accessor :environment

  def default_url_options options = nil
    options ||= {}
    options[:host] = environment.default_hostname if environment
    options
  end

  def user
    nil
  end

end

