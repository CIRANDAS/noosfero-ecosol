require File.dirname(__FILE__) + '/../test_helper'

class BlogArchivesBlockTest < ActiveSupport::TestCase

  def setup
    @profile = create_user('flatline').person
    @profile.articles << Blog.new(:name => 'blog-test', :profile => @profile)
  end
  attr_reader :profile

  should 'default describe' do
    assert_not_equal Block.description, BlogArchivesBlock.description
  end

  should 'is editable' do
    l = BlogArchivesBlock.new
    assert l.editable?
  end

  should 'list amount posts by year' do
    date = DateTime.parse('2008-01-01')
    blog = profile.blog
    for i in 1..10 do
      post = TextileArticle.create!(:name => "post #{i} test", :profile => profile, :parent => blog)
      post.update_attribute(:published_at, date)
    end
    block = BlogArchivesBlock.new
    block.stubs(:owner).returns(profile)
    assert_tag_in_string block.content, :tag => 'li', :content => '2008 (10)'
  end

  should 'list amount posts by month' do
    date = DateTime.parse('2008-01-01')
    blog = profile.blog
    for i in 1..10 do
      post = TextileArticle.create!(:name => "post #{i} test", :profile => profile, :parent => blog)
      post.update_attribute(:published_at, date)
    end
    block = BlogArchivesBlock.new
    block.stubs(:owner).returns(profile)
    assert_tag_in_string block.content, :tag => 'a', :content => 'January (10)', :attributes => {:href => /^http:\/\/.*\/flatline\/blog\?month=01&year=2008$/ }
  end

  should 'order list of amount posts' do
    blog = profile.blog
    for i in 1..10 do
      post = TextileArticle.create!(:name => "post #{i} test", :profile => profile, :parent => blog)
      post.update_attribute(:published_at, DateTime.parse("2008-#{i}-01"))
    end
    block = BlogArchivesBlock.new
    block.stubs(:owner).returns(profile)
    assert_tag_in_string block.content, :tag => 'li', :content => 'January (1)',
      :sibling => {:tag => 'li', :content => 'February (1)',
        :sibling => {:tag => 'li', :content => 'March (1)',
          :sibling => {:tag => 'li', :content => 'April (1)',
            :sibling => {:tag => 'li', :content => 'May (1)'}}}}
  end

  should 'order years' do
    blog = profile.blog
    for year in 2005..2009
      post = TextileArticle.create!(:name => "post #{year}", :profile => profile, :parent => blog, :published_at => Date.new(year, 1, 1))
    end
    block = BlogArchivesBlock.new
    block.stubs(:owner).returns(profile)
    assert_match(/2009.*2008.*2007.*2006.*2005/m, block.content)
  end

  should 'order months from later to former' do
    blog = profile.blog
    for month in 1..3
      post = TextileArticle.create!(:name => "post #{month}", :profile => profile, :parent => blog, :published_at => Date.new(2009, month, 1))
    end
    block = BlogArchivesBlock.new
    block.stubs(:owner).returns(profile)
    assert_match(/.*March.*February.*January.*/m, block.content)
  end

  should 'not display any content if has no blog' do
    profile.stubs(:has_blog?).returns(false)
    assert !profile.has_blog?
    block = BlogArchivesBlock.new
    block.stubs(:owner).returns(profile)
    assert_nil block.content
  end

end
