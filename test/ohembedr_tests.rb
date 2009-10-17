require 'lib/ohembedr.rb'
require 'test/unit'

class OhEmbedrTest < Test::Unit::TestCase
  def test_url_required
    assert_raise(ArgumentError) {OhEmbedr::OhEmbedr.new()}
  end
  
  def test_wrong_protocol
    assert_raise(OhEmbedr::UnsupportedError) {OhEmbedr::OhEmbedr.new(:url => "mailto:ben@benmcredmond.com")}
  end
  
  def test_provider_check
    assert_raise(OhEmbedr::UnsupportedError)          { OhEmbedr::OhEmbedr.new(:url => "http://google.com") }
    assert_nothing_raised(OhEmbedr::UnsupportedError) { OhEmbedr::OhEmbedr.new(:url => "http://vimeo.com") }
  end
  
  def test_gets
    o = OhEmbedr::OhEmbedr.new(:url => "http://vimeo.com/6382511")
    o.gets
    
    # Make sure we got an hash
    assert_equal o.hash.class, Hash
    
    # Make sure there's the right kinda stuff in there
    assert_equal o.hash["type"], "video"
  end  
  
  def test_gem_build
    assert_nothing_raised(LoadError) do 
      require 'ohembedr'
    end
  end
end