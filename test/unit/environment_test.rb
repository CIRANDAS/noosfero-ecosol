require File.dirname(__FILE__) + '/../test_helper'

class EnvironmentTest < Test::Unit::TestCase
  fixtures :environments

  def test_exists_default_and_it_is_unique
    Environment.delete_all
    vc = Environment.new(:name => 'Test Community')
    vc.is_default = true
    assert vc.save

    vc2 = Environment.new(:name => 'Another Test Community')
    vc2.is_default = true
    assert !vc2.valid?
    assert vc2.errors.invalid?(:is_default)

    assert_equal vc, Environment.default
  end

  def test_acts_as_configurable
    vc = Environment.new(:name => 'Testing Environment')
    assert_kind_of Hash, vc.settings
    vc.settings[:some_setting] = 1
    assert vc.save
    assert_equal 1, vc.settings[:some_setting]
  end

  def test_available_features
    assert_kind_of Hash, Environment.available_features
  end

  def test_mock
    assert_equal ['feature1', 'feature2', 'feature3'], Environment.available_features.keys.sort
  end

  def test_features
    v = Environment.new
    v.enable('feature1')
    assert v.enabled?('feature1')
    v.disable('feature1')
    assert !v.enabled?('feature1')
  end

  def test_enabled_features
    v = Environment.new
    v.enabled_features = [ 'feature1', 'feature2' ]
    assert v.enabled?('feature1') && v.enabled?('feature2') && !v.enabled?('feature3')
  end

  def test_enabled_features_no_features_enabled
    v = Environment.new
    v.enabled_features = nil
    assert !v.enabled?('feature1') && !v.enabled?('feature2') && !v.enabled?('feature3')
  end

  def test_name_is_mandatory
    v = Environment.new
    v.valid?
    assert v.errors.invalid?(:name)
    v.name = 'blablabla'
    v.valid?
    assert !v.errors.invalid?(:name)
  end

  def test_terms_of_use
    v = Environment.new(:name => 'My test environment')
    assert_nil v.terms_of_use
    v.terms_of_use = 'To be part of this environment, you must accept the following terms: ...'
    assert v.save
    id = v.id
    assert_equal 'To be part of this environment, you must accept the following terms: ...', Environment.find(id).terms_of_use
  end

  should "terms of use not be an empty string" do
    v = Environment.new(:name => 'My test environment')
    assert_nil v.terms_of_use
    v.terms_of_use = ""
    assert v.save
    assert !v.has_terms_of_use?
    id = v.id
    assert_nil Environment.find(v.id).terms_of_use
  end

  def test_has_terms_of_use
    v = Environment.new
    assert !v.has_terms_of_use?
    v.terms_of_use = 'some terms of use'
    assert v.has_terms_of_use?
  end

  def test_terms_of_enterprise_use
    v = Environment.new(:name => 'My test environment')
    assert_nil v.terms_of_enterprise_use
    v.terms_of_enterprise_use = 'To be owner of an enterprise in this environment, you must accept the following terms: ...'
    assert v.save
    id = v.id
    assert_equal 'To be owner of an enterprise in this environment, you must accept the following terms: ...', Environment.find(id).terms_of_enterprise_use
  end

  def test_has_terms_of_enterprise_use
    v = Environment.new
    assert !v.has_terms_of_enterprise_use?
    v.terms_of_enterprise_use = 'some terms of enterprise use'
    assert v.has_terms_of_enterprise_use?
  end

  def test_should_list_top_level_categories
    env = fast_create(Environment)
    cat1 = Category.create!(:name => 'first category', :environment_id => env.id)
    cat2 = Category.create!(:name => 'second category', :environment_id => env.id)
    subcat = Category.create!(:name => 'child category', :environment_id => env.id, :parent_id => cat2.id)

    cats = env.top_level_categories
    assert_equal 2, cats.size
    assert cats.include?(cat1)
    assert cats.include?(cat2)
    assert !cats.include?(subcat)
  end

  def test_should_list_all_categories
    env = fast_create(Environment)
    cat1 = Category.create!(:name => 'first category', :environment_id => env.id)
    cat2 = Category.create!(:name => 'second category', :environment_id => env.id)
    subcat = Category.create!(:name => 'child category', :environment_id => env.id, :parent_id => cat2.id)

    cats = env.categories
    assert_equal 3, cats.size
    assert cats.include?(cat1)
    assert cats.include?(cat2)
    assert cats.include?(subcat)
  end

  should 'list displayable categories' do
    env = fast_create(Environment)
    cat1 = env.categories.create(:name => 'category one', :display_color => 1)
    assert ! cat1.new_record?

    # subcategories should be ignored
    subcat1 = env.categories.create(:name => 'subcategory one', :parent_id => cat1.id)
    assert ! subcat1.new_record?

    cat2 = env.categories.create(:name => 'category two')
    assert !cat2.new_record?

    assert_equal 1,  env.display_categories.size
    assert env.display_categories.include?(cat1)
    assert !env.display_categories.include?(cat2)
  end

  should 'have regions' do
    env = fast_create(Environment)
    assert_kind_of Array, env.regions
    assert_raise ActiveRecord::AssociationTypeMismatch do
      env.regions << 1
    end
    assert_nothing_raised do
      env.regions << Region.new
    end
  end

  should 'have a contact email' do
    env = Environment.new
    assert_nil env.contact_email

    env.contact_email = 'test'
    env.valid?
    assert env.errors.invalid?(:contact_email)

    env.contact_email = 'test@example.com'
    env.valid?
    assert !env.errors.invalid?(:contact_email)
  end

  should 'provide a default hostname' do
    env = fast_create(Environment)
    env.domains << Domain.create(:name => 'example.com', :is_default => true)
    assert_equal 'example.com', env.default_hostname
  end

  should 'default to localhost as hostname' do
    env = Environment.new
    assert_equal 'localhost', env.default_hostname
  end

  should 'add www when told to force www' do
    env = fast_create(Environment); env.force_www = true; env.save!

    env.domains << Domain.create(:name => 'example.com', :is_default => true)
    assert_equal 'www.example.com', env.default_hostname
  end

  should 'not add www when requesting domain for email address' do
    env = fast_create(Environment)
    env.domains << Domain.create(:name => 'example.com', :is_default => true)
    assert_equal 'example.com', env.default_hostname(true)
  end

  should 'use default domain when there is more than one' do
    env = fast_create(Environment)
    env.domains << Domain.create(:name => 'example.com', :is_default => false)
    env.domains << Domain.create(:name => 'default.com', :is_default => true)
    assert_equal 'default.com', env.default_hostname
  end

  should 'use first domain when there is no default' do
    env = fast_create(Environment)
    env.domains << Domain.create(:name => 'domain1.com', :is_default => false)
    env.domains << Domain.create(:name => 'domain2.com', :is_default => false)
    assert_equal 'domain1.com', env.default_hostname
  end

  should 'provide default top URL' do
    env = Environment.new
    env.expects(:default_hostname).returns('www.lalala.net')
    assert_equal 'http://www.lalala.net', env.top_url
  end

  should 'include port in default top URL for development environment' do
    env = Environment.new
    env.expects(:default_hostname).returns('www.lalala.net')

    Noosfero.expects(:url_options).returns({ :port => 9999 }).at_least_once

    assert_equal 'http://www.lalala.net:9999', env.top_url
  end

  should 'use https when asked for a ssl url' do
    env = Environment.new
    env.expects(:default_hostname).returns('www.lalala.net')
    assert_equal 'https://www.lalala.net', env.top_url(true)
  end

  should 'provide an approval_method setting' do
    env = Environment.new

    # default value
    assert_equal :admin, env.organization_approval_method

    # valid values
    assert_nothing_raised do
      valid = %w[
        admin
        region
      ].each do |item|
        env.organization_approval_method = item
        env.organization_approval_method = item.to_sym
      end
    end

    # do not allow other values
    assert_raise ArgumentError do
      env.organization_approval_method = :lalala
    end

  end

  should 'provide environment name in to_s' do
    env = Environment.new(:name => 'my name')
    assert_equal 'my name', env.to_s
  end

  should 'fallback to "?" when calling to_s with empty name' do
    env = Environment.new(:name => nil)
    assert_nil env.name
    assert_equal "?", env.to_s
  end

  should 'remove boxes and blocks when removing environment' do
    Environment.any_instance.stubs(:create_templates) # avoid creating templates, it's expensive
    env = Environment.create!(:name => 'test environment')

    env_boxes = env.boxes.size
    env_blocks = env.blocks.size
    assert env_boxes > 0
    assert env_blocks > 0

    boxes = Box.count
    blocks = Block.count

    env.destroy

    assert_equal boxes - env_boxes, Box.count
    assert_equal blocks - env_blocks, Block.count
  end

  should 'destroy templates' do
    env = fast_create(Environment)
    templates = [mock, mock, mock]
    templates.each do |item|
      item.expects(:destroy)
    end

    env.stubs(:person_template).returns(templates[0])
    env.stubs(:community_template).returns(templates[1])
    env.stubs(:enterprise_template).returns(templates[2])

    env.destroy
  end

  should 'have boxes and blocks upon creation' do
    Environment.any_instance.stubs(:create_templates) # avoid creating templates, it's expensive
    environment = Environment.create!(:name => 'a test environment')
    assert environment.boxes.size > 0
    assert environment.blocks.size > 0
  end

  should 'have at least one MainBlock upon creation' do
    Environment.any_instance.stubs(:create_templates) # avoid creating templates, it's expensive
    environment = Environment.create!(:name => 'a test environment')
    assert(environment.blocks.any? { |block| block.kind_of? MainBlock })
  end

  should 'provide recent_documents' do
    environment = fast_create(Environment)

    p1 = environment.profiles.build(:identifier => 'testprofile1', :name => 'test profile 1'); p1.save!
    p2 = environment.profiles.build(:identifier => 'testprofile2', :name => 'test profile 2'); p2.save!

    # clear the articles
    Article.destroy_all

    # p1 creates one article
    doc1 = p1.articles.build(:name => 'text 1'); doc1.save!

    # p2 creates two articles
    doc2 = p2.articles.build(:name => 'text 2'); doc2.save!
    doc3 = p2.articles.build(:name => 'text 3'); doc3.save!

    # p1 creates another article
    doc4 = p1.articles.build(:name => 'text 4'); doc4.save!

    all_recent = environment.recent_documents
    [doc1,doc2,doc3,doc4].each do |item|
      assert_includes all_recent, item
    end

    last_three = environment.recent_documents(3)
    [doc2, doc3, doc4].each do |item|
      assert_includes last_three, item
    end
    assert_not_includes last_three, doc1

  end

  should 'have a description attribute' do
    env = Environment.new

    env.description = 'my fine environment'
    assert_equal 'my fine environment', env.description
  end

  should 'have admin role' do
    Role.expects(:find_by_key_and_environment_id).with('environment_administrator', Environment.default.id).returns(Role.new)
    assert_kind_of Role, Environment::Roles.admin(Environment.default.id)
  end

  should 'be able to add admins easily' do
    Environment.any_instance.stubs(:create_templates) # avoid creating templates, it's expensive
    env = Environment.create!(:name => 'bli')
    user = create_user('testuser').person
    env.add_admin(user)
    env.reload

    assert_includes env.admins, user
  end

  should 'have products through enterprises' do
    env = Environment.default
    e1 = fast_create(Enterprise)
    p1 = e1.products.create!(:name => 'test_prod1')

    assert_includes env.products, p1
  end

  should 'not have person through communities' do
    env = Environment.default
    com = fast_create(Community)
    person = fast_create(Person)
    assert_includes env.communities, com
    assert_not_includes env.communities, person
  end

  should 'not have person through enterprises' do
    env = Environment.default
    ent = fast_create(Enterprise)
    person = fast_create(Person)
    assert_includes env.enterprises, ent
    assert_not_includes env.enterprises, person
  end

  should 'not have enterprises through people' do
    env = Environment.default
    person = fast_create(Person)
    ent = fast_create(Enterprise)
    assert_includes env.people, person
    assert_not_includes env.people, ent
  end

  should 'have a message_for_disabled_enterprise attribute' do
    env = Environment.new
    env.message_for_disabled_enterprise = 'this enterprise was disabled'
    assert_equal 'this enterprise was disabled', env.message_for_disabled_enterprise
  end

  should 'have articles and text_articles' do
    # FIXME
    assert true
    #environment = Environment.create(:name => 'a test environment')

    ## creates profile
    #profile = environment.profiles.create!(:identifier => 'testprofile1', :name => 'test profile 1')

    ## profile creates one article
    #article = profile.articles.create!(:name => 'text article')

    ## profile creates one textile article
    #textile = TextileArticle.create!(:name => 'textile article', :profile => profile)
    #profile.articles << textile

    #assert_includes environment.articles, article
    #assert_includes environment.articles, textile

    #assert_includes environment.text_articles, textile
    #assert_not_includes environment.text_articles, article
  end

  should 'find by contents from articles' do
    environment = fast_create(Environment)
    assert_nothing_raised do
      environment.articles.find_by_contents('')
      # FIXME
      #environment.text_articles.find_by_contents('')
    end
  end

  should 'provide custom header' do
    assert_equal 'my header', Environment.new(:custom_header => 'my header').custom_header
  end

  should 'provide custom footer' do
    assert_equal 'my footer', Environment.new(:custom_footer => "my footer").custom_footer
  end

  should 'provide theme' do
    assert_equal 'my-custom-theme', Environment.new(:theme => 'my-custom-theme').theme
  end

  should 'give default theme' do
    assert_equal 'default', Environment.new.theme
  end

  should 'have a list of themes' do
    env = Environment.default
    t1 = mock
    t2 = mock

    t1.stubs(:id).returns('theme_1')
    t2.stubs(:id).returns('theme_2')

    Theme.expects(:system_themes).returns([t1, t2])
    env.themes = [t1, t2]
    env.save!
    assert_equal  [t1, t2], Environment.default.themes
  end

  should 'set themes to environment' do
    env = Environment.default
    t1 = mock

    t1.stubs(:id).returns('theme_1')

    env.themes = [t1]
    env.save
    assert_equal  [t1.id], Environment.default.settings[:themes]
  end

  should 'create templates' do
    e = Environment.create!(:name => 'test_env')
    e.reload

    # the templates must be created
    assert_kind_of Enterprise, e.enterprise_template
    assert_kind_of Community, e.community_template
    assert_kind_of Person, e.person_template

    # the templates must be private
    assert !e.enterprise_template.visible?
    assert !e.community_template.visible?
    assert !e.person_template.visible?
  end

  should 'set templates' do
    e = fast_create(Environment)

    comm = fast_create(Community)
    e.community_template = comm
    assert_equal comm, e.community_template

    person = fast_create(Person)
    e.person_template = person
    assert_equal person, e.person_template

    enterprise = fast_create(Enterprise)
    e.enterprise_template = enterprise
    assert_equal enterprise, e.enterprise_template
  end

  should 'not enable ssl by default' do
    e = Environment.new
    assert !e.enable_ssl
  end

  should 'be able to enable ssl' do
    e = Environment.new(:enable_ssl => true)
    assert_equal true, e.enable_ssl
  end

  should 'have a layout template' do
    e = Environment.new(:layout_template => 'mytemplate')
    assert_equal 'mytemplate', e.layout_template
  end

  should 'have a default layout template' do
    assert_equal 'default', Environment.new.layout_template
  end

  should 'return more than 10 enterprises by contents' do
    env = Environment.default
    Enterprise.destroy_all
    ('1'..'20').each do |n|
      Enterprise.create!(:name => 'test ' + n, :identifier => 'test_' + n)
    end

    assert_equal 20, env.enterprises.find_by_contents('test').total_entries
  end

  should 'set replace_enterprise_template_when_enable on environment' do
    e = Environment.new(:name => 'Enterprise test')
    e.replace_enterprise_template_when_enable = true
    e.save
    assert_equal true, e.replace_enterprise_template_when_enable
  end

  should 'not replace enterprise template when enable by default' do
    assert_equal false, Environment.new.replace_enterprise_template_when_enable
  end

  should 'set custom_person_fields with its dependecies' do
    env = Environment.new
    env.custom_person_fields = {'cell_phone' => {'required' => 'true', 'active' => '', 'signup' => ''}, 'comercial_phone'=>  {'required' => '', 'active' => 'true', 'signup' => '' }, 'description' => {'required' => '', 'active' => '', 'signup' => 'true'}}

    assert_equal({'cell_phone' => {'required' => 'true', 'active' => 'true', 'signup' => 'true'}, 'comercial_phone'=>  {'required' => '', 'active' => 'true', 'signup' => '' }, 'description' => {'required' => '', 'active' => 'true', 'signup' => 'true'}}, env.custom_person_fields)
  end

  should 'have no custom_person_fields by default' do
    assert_equal({}, Environment.new.custom_person_fields)
  end

  should 'not set in custom_person_fields if not in person.fields' do
    env = Environment.default
    Person.stubs(:fields).returns(['cell_phone', 'comercial_phone'])

    env.custom_person_fields = { 'birth_date' => {'required' => 'true', 'active' => 'true'}, 'cell_phone' => {'required' => 'true', 'active' => 'true'}}
    assert_equal({'cell_phone' => {'required' => 'true','signup' => 'true',  'active' => 'true'}}, env.custom_person_fields)
    assert ! env.custom_person_fields.keys.include?('birth_date')
  end

  should 'add schooling_status if custom_person_fields has schooling' do
    env = Environment.default
    Person.stubs(:fields).returns(['cell_phone', 'schooling'])

    env.custom_person_fields = { 'schooling' => {'required' => 'true', 'active' => 'true'}}
    assert_equal({'schooling' => {'required' => 'true', 'signup' => 'true', 'active' => 'true'}, 'schooling_status' => {'required' => 'true', 'signup' => 'true', 'active' => 'true'}}, env.custom_person_fields)
    assert ! env.custom_person_fields.keys.include?('birth_date')
  end

  should 'return person_fields status' do
    env = Environment.default

    env.expects(:custom_person_fields).returns({ 'birth_date' => {'required' => 'true', 'active' => 'false'}}).at_least_once

    assert_equal true, env.custom_person_field('birth_date', 'required')
    assert_equal false, env.custom_person_field('birth_date', 'active')
  end

  should 'select active fields from person' do
    env = Environment.default
    env.expects(:custom_person_fields).returns({ 'birth_date' => {'required' => 'true', 'active' => 'true'}, 'cell_phone' => {'required' => 'true', 'active' => 'false'}}).at_least_once

    assert_equal ['birth_date'], env.active_person_fields
  end

  should 'select required fields from person' do
    env = Environment.default
    env.expects(:custom_person_fields).returns({ 'birth_date' => {'required' => 'true', 'active' => 'true'}, 'cell_phone' => {'required' => 'false', 'active' => 'true'}}).at_least_once

    assert_equal ['birth_date'], env.required_person_fields
  end

  should 'provide a default invitation message for friend' do
    env = Environment.default
    message = [
      'Hello <friend>,',
      "<user> is inviting you to participate on <environment>.",
      'To accept the invitation, please follow this link:',
      '<url>',
      "--\n<environment>",
    ].join("\n\n")

    assert_equal message, env.message_for_friend_invitation
  end

  should 'provide a default invitation message for member' do
    env = Environment.default
    message = env.message_for_member_invitation
    ['<friend>', '<user>', '<community>', '<environment>'].each do |item|
      assert_match(item, message)
    end
  end

  should 'set custom_enterprise_fields with its dependencies' do
    env = Environment.new
    env.custom_enterprise_fields = {'contact_person' => {'required' => 'true', 'active' => '', 'signup' => ''}, 'contact_email'=>  {'required' => '', 'active' => 'true', 'signup' => '' }, 'description' => {'required' => '', 'active' => '', 'signup' => 'true'}}

    assert_equal({'contact_person' => {'required' => 'true', 'active' => 'true', 'signup' => 'true'}, 'contact_email'=>  {'required' => '', 'active' => 'true', 'signup' => '' }, 'description' => {'required' => '', 'active' => 'true', 'signup' => 'true'}} , env.custom_enterprise_fields)
  end

  should 'have no custom_enterprise_fields by default' do
    assert_equal({}, Environment.new.custom_enterprise_fields)
  end

  should 'not set in custom_enterprise_fields if not in enterprise.fields' do
    env = Environment.default
    Enterprise.stubs(:fields).returns(['contact_person', 'comercial_phone'])

    env.custom_enterprise_fields = { 'contact_email' => {'required' => 'true', 'active' => 'true'}, 'contact_person' => {'required' => 'true', 'active' => 'true'}}
    assert_equal({'contact_person' => {'required' => 'true', 'signup' => 'true', 'active' => 'true'}}, env.custom_enterprise_fields)
    assert ! env.custom_enterprise_fields.keys.include?('contact_email')
  end

  should 'return enteprise_fields status' do
    env = Environment.default

    env.expects(:custom_enterprise_fields).returns({ 'contact_email' => {'required' => 'true', 'active' => 'false'}}).at_least_once

    assert_equal true, env.custom_enterprise_field('contact_email', 'required')
    assert_equal false, env.custom_enterprise_field('contact_email', 'active')
  end

  should 'select active fields from enterprise' do
    env = Environment.default
    env.expects(:custom_enterprise_fields).returns({ 'contact_email' => {'required' => 'true', 'active' => 'true'}, 'contact_person' => {'required' => 'true', 'active' => 'false'}}).at_least_once

    assert_equal ['contact_email'], env.active_enterprise_fields
  end

  should 'select required fields from enterprise' do
    env = Environment.default
    env.expects(:custom_enterprise_fields).returns({ 'contact_email' => {'required' => 'true', 'active' => 'true'}, 'contact_person' => {'required' => 'false', 'active' => 'true'}}).at_least_once

    assert_equal ['contact_email'], env.required_enterprise_fields
  end

  should 'set custom_community_fields with its dependencies' do
    env = Environment.new
    env.custom_community_fields = {'contact_person' => {'required' => 'true', 'active' => '', 'signup' => ''}, 'contact_email'=>  {'required' => '', 'active' => 'true', 'signup' => '' }, 'description' => {'required' => '', 'active' => '', 'signup' => 'true'}}

    assert_equal({'contact_person' => {'required' => 'true', 'active' => 'true', 'signup' => 'true'}, 'contact_email'=>  {'required' => '', 'active' => 'true', 'signup' => '' }, 'description' => {'required' => '', 'active' => 'true', 'signup' => 'true'}} , env.custom_community_fields)
  end

  should 'have no custom_community_fields by default' do
    assert_equal({}, Environment.new.custom_community_fields)
  end

  should 'not set in custom_community_fields if not in community.fields' do
    env = Environment.default
    Community.stubs(:fields).returns(['contact_person', 'comercial_phone'])

    env.custom_community_fields = { 'contact_email' => {'required' => 'true', 'active' => 'true'}, 'contact_person' => {'required' => 'true', 'active' => 'true'}}
    assert_equal({'contact_person' => {'required' => 'true', 'signup' => 'true', 'active' => 'true'}}, env.custom_community_fields)
    assert ! env.custom_community_fields.keys.include?('contact_email')
  end

  should 'return community_fields status' do
    env = Environment.default

    env.expects(:custom_community_fields).returns({ 'contact_email' => {'required' => 'true', 'active' => 'false'}}).at_least_once

    assert_equal true, env.custom_community_field('contact_email', 'required')
    assert_equal false, env.custom_community_field('contact_email', 'active')
  end

  should 'select active fields from community' do
    env = Environment.default
    env.expects(:custom_community_fields).returns({ 'contact_email' => {'required' => 'true', 'active' => 'true'}, 'contact_person' => {'required' => 'true', 'active' => 'false'}}).at_least_once

    assert_equal ['contact_email'], env.active_community_fields
  end

  should 'select required fields from community' do
    env = Environment.default
    env.expects(:custom_community_fields).returns({ 'contact_email' => {'required' => 'true', 'active' => 'true'}, 'contact_person' => {'required' => 'false', 'active' => 'true'}}).at_least_once

    assert_equal ['contact_email'], env.required_community_fields
  end

  should 'set category_types' do
    env = Environment.new
    env.category_types = ['Category', 'ProductCategory']

    assert_equal ['Category', 'ProductCategory'], env.category_types
  end

  should 'have type /Category/ on category_types by default' do
    assert_equal ['Category'], Environment.new.category_types
  end

  should 'has tasks' do
    e = Environment.default
    assert_nothing_raised do
      e.tasks
    end
  end

  should 'provide icon theme' do
    assert_equal 'my-icons-theme', Environment.new(:icon_theme => 'my-icons-theme').icon_theme
  end

  should 'give default icon theme' do
    assert_equal 'default', Environment.new.icon_theme
  end

  should 'modify icon theme' do
    e = Environment.new
    assert_equal 'default', e.icon_theme
    e.icon_theme = 'non-default'
    assert_not_equal 'default', e.icon_theme
  end

  should 'have a portal community' do
    e = Environment.default
    c = fast_create(Community)

    e.portal_community = c; e.save!
    e.reload

    assert_equal c, e.portal_community
  end

  should 'unset the portal community' do
    e = Environment.default
    c = fast_create(Community)

    e.portal_community = c; e.save!
    e.reload
    assert_equal c, e.portal_community
    e.unset_portal_community!
    e.reload
    assert_nil e.portal_community 
    assert_equal [], e.portal_folders
    assert_equal 0, e.news_amount_by_folder
    assert_equal false, e.enabled?('use_portal_community')
  end

  should 'have a set of portal folders' do
    e = Environment.default

    c = e.portal_community = fast_create(Community)
    news_folder = Folder.create!(:name => 'news folder', :profile => c)

    e.portal_folders = [news_folder]
    e.save!; e.reload

    assert_equal [news_folder], e.portal_folders
  end

  should 'return empty array when no portal folders' do
   e = Environment.default

   assert_equal [], e.portal_folders
  end

  should 'remove all portal folders' do
    e = Environment.default

    e.portal_folders = nil
    e.save!; e.reload

    assert_equal [], e.portal_folders
  end

  should 'have roles with names independent of other environments' do
    e1 = fast_create(Environment)
    role1 = Role.create!(:name => 'test_role', :environment => e1)
    e2 = fast_create(Environment)
    role2 = Role.new(:name => 'test_role', :environment => e2)

    assert_valid role2
  end

  should 'have roles with keys independent of other environments' do
    e1 = fast_create(Environment)
    role1 = Role.create!(:name => 'test_role', :environment => e1, :key => 'a_member')
    e2 = fast_create(Environment)
    role2 = Role.new(:name => 'test_role', :environment => e2, :key => 'a_member')

    assert_valid role2
  end

  should 'have a help_message_to_add_enterprise attribute' do
    env = Environment.new

    assert_equal env.help_message_to_add_enterprise, ''

    env.help_message_to_add_enterprise = 'help message'
    assert_equal 'help message', env.help_message_to_add_enterprise
  end

  should 'have a tip_message_enterprise_activation_question attribute' do
    env = Environment.new

    assert_equal env.tip_message_enterprise_activation_question, ''

    env.tip_message_enterprise_activation_question = 'tip message'
    assert_equal 'tip message', env.tip_message_enterprise_activation_question
  end

  should 'have amount of news on portal folders' do
    e = Environment.default

    assert_respond_to e, :news_amount_by_folder

    e.news_amount_by_folder = 2
    e.save!; e.reload

    assert_equal 2, e.news_amount_by_folder
  end

  should 'have default amount of news on portal folders' do
    e = Environment.default

    assert_respond_to e, :news_amount_by_folder

    assert_equal 4, e.news_amount_by_folder
  end

  should 'list tags with their counts' do
    person = fast_create(Person)
    person.articles.build(:name => 'article 1', :tag_list => 'first-tag').save!
    person.articles.build(:name => 'article 2', :tag_list => 'first-tag, second-tag').save!
    person.articles.build(:name => 'article 3', :tag_list => 'first-tag, second-tag, third-tag').save!

    assert_equal({ 'first-tag' => 3, 'second-tag' => 2, 'third-tag' => 1 }, Environment.default.tag_counts)
  end

  should 'not list tags count from other environment' do
    e = fast_create(Environment)
    user = create_user('testinguser', :environment => e).person
    user.articles.build(:name => 'article 1', :tag_list => 'first-tag').save!

    assert_equal({}, Environment.default.tag_counts)
  end

  should 'have a list of local documentation links' do
    e = fast_create(Environment)
    e.local_docs = [['/doccommunity/link1', 'Link 1'], ['/doccommunity/link2', 'Link 2']]
    e.save!

    e = Environment.find(e.id)
    assert_equal [['/doccommunity/link1', 'Link 1'], ['/doccommunity/link2', 'Link 2']], e.local_docs
  end

  should 'have an empty list of local docs by default' do
    assert_equal [], Environment.new.local_docs
  end

  should 'provide right invitation mail template for friends' do
    env = Environment.default
    person = Person.new

    assert_equal env.message_for_friend_invitation, env.invitation_mail_template(person)
  end

  should 'provide right invitation mail template for members' do
    env = Environment.default
    community = Community.new

    assert_equal env.message_for_member_invitation, env.invitation_mail_template(community)
  end

  should 'filter fields with white_list filter' do
    environment = Environment.new
    environment.message_for_disabled_enterprise = "<h1> Disabled Enterprise </h1>"
    environment.valid?

    assert_equal "<h1> Disabled Enterprise </h1>", environment.message_for_disabled_enterprise
  end

  should 'escape malformed html tags' do
    environment = Environment.new
    environment.message_for_disabled_enterprise = "<h1> Disabled Enterprise /h1>"
    environment.valid?

    assert_no_match /[<>]/, environment.message_for_disabled_enterprise
  end

  should 'not sanitize html comments' do
    environment = Environment.new
    environment.message_for_disabled_enterprise = '<p><!-- <asdf> << aasdfa >>> --> <h1> Wellformed html code </h1>'
    environment.valid?

    assert_match  /<!-- .* --> <h1> Wellformed html code <\/h1>/, environment.message_for_disabled_enterprise
  end

  should "not crash when set nil as terms of use" do
    v = Environment.new(:name => 'My test environment')
    v.terms_of_use = nil
    assert v.save!
  end

  should "terms of use not be an blank string" do
    v = Environment.new(:name => 'My test environment')
    v.terms_of_use = "   "
    assert v.save!
    assert !v.has_terms_of_use?
  end

end
