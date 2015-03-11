require "test_helper"

class OpenGraphPlugin::PublisherTest < ActiveSupport::TestCase

  def setup
    @actor = create_user.person
    User.current = @actor.user
    @stories = OpenGraphPlugin::Stories::Definitions
    @publisher = OpenGraphPlugin::Stories.publishers.first
    @publisher.stubs(:context).returns(:open_graph)
  end

  should "publish only tracked stuff" do
    @other_actor = create_user.person

    @myenterprise = @actor.environment.enterprises.create! name: 'mycoop', identifier: 'mycoop'
    @myenterprise.add_member @actor
    @enterprise = @actor.environment.enterprises.create! name: 'coop', identifier: 'coop'

    @community = @actor.environment.communities.create! name: 'comm', identifier: 'comm', closed: false

    @actor.update_attributes!({
      open_graph_settings: {
        activity_track_enabled: "true",
        enterprise_track_enabled: "true",
        community_track_enabled: "true",
      },
      open_graph_activity_track_configs_attributes: {
        0 => { tracker_id: @actor.id, object_type: 'blog_post', },
        1 => { tracker_id: @actor.id, object_type: 'gallery_image', },
        2 => { tracker_id: @actor.id, object_type: 'favorite_enterprise', },
      },
      open_graph_enterprise_profiles_ids: [@enterprise.id],
      open_graph_community_profiles_ids: [@community.id],
    })

    # active
    User.current = @actor.user

    blog = Blog.create! profile: @actor, name: 'blog'
    blog_post = TinyMceArticle.new profile: User.current.person, parent: blog, name: 'blah', author: User.current.person
    @publisher.expects(:publish).with(User.current.person, @stories[:create_an_article], @publisher.url_for(blog_post.url))
    blog_post.save!

    # upload_image verb uses custom_target
    #gallery = create Gallery, name: 'gallery', profile: User.current.person
    #image = create UploadedFile, uploaded_data: fixture_file_upload('/files/rails.png', 'image/png'), parent: gallery, profile: User.current.person
    #@publisher.expects(:publish).with(User.current.person, @stories[:add_an_image], @publisher.url_for(image.url))

    @publisher.expects(:publish).with(User.current.person, @stories[:favorite_a_sse_initiative], @publisher.url_for(@enterprise.url))
    @enterprise.fans << User.current.person

    # active but published as passive
    User.current = @actor.user

    blog_post = TinyMceArticle.new profile: @enterprise, parent: @enterprise.blog, name: 'blah', author: User.current.person
    story = @stories[:announce_news_from_a_sse_initiative]
    @publisher.expects(:publish).with(User.current.person, story, @publisher.passive_url_for(blog_post.url, story))
    blog_post.save!

    # passive
    User.current = @other_actor.user

    blog_post = TinyMceArticle.new profile: @enterprise, parent: @enterprise.blog, name: 'blah2', author: User.current.person
    story = @stories[:announce_news_from_a_sse_initiative]
    @publisher.expects(:publish).with(@actor, story, @publisher.passive_url_for(blog_post.url, story))
    blog_post.save!

    blog_post = TinyMceArticle.new profile: @community, parent: @community.blog, name: 'blah', author: User.current.person
    story = @stories[:announce_news_from_a_community]
    @publisher.expects(:publish).with(@actor, story, @publisher.passive_url_for(blog_post.url, story))
    blog_post.save!
  end

end
