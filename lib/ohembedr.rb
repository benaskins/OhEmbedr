# OhEmbedr is an easy to use ruby library for using OEmbed services
# in your applications. See http://oembed.com for information on 
# the OEmbed standard. This library supports the following services
# by default:
# * YouTube
# * Vimeo
# * Flickr
# * Qik
# * Revision 3
# * Viddler
# * Hulu
#
# See the OhEmbedr class page for usage details.
#
# *Author*::    Ben McRedmond
# *Copyright*:: Copyright (c) 2009 Ben McRedmond
# *License*::   Licensed under the MIT license

require 'rubygems'
require 'net/http'
require 'cgi'

module OhEmbedr
  # Standard error raised for errors with OhEmbedr
  class Error < RuntimeError; end
  
  # This error is raised when OhEmbedr comes across something that
  # either it or the specified provider doesn't support.
  class UnsupportedError < Error; end
  
  # == Using OhEmbedr
  # Using OhEmbedr is super simple. Below is an example
  #   begin
  #     o = OhEmbedr::OhEmbedr.new(:url => "http://vimeo.com/6382511", :maxwidth => 600)
  #     embed_data = o.gets
  #   rescue OhEmbedr::UnsupportedError => error
  #     # URL not supported
  #   end
  #
  # Wrapping in a <em>begin rescue</em> block allows us to pass any url to OhEmbedr if an UnsupportedError exception is raised then we know the url is not supported and can continue
  class OhEmbedr
    # The providers supported by default in this class
    @@default_providers = {"youtube.com"    => {:base => "http://www.youtube.com/oembed",           :dot_format => false}, 
                           "vimeo.com"      => {:base => "http://vimeo.com/api/oembed",             :dot_format => true }, 
                           "flickr.com"     => {:base => "http://www.flickr.com/services/oembed",   :dot_format => false}, 
                           "qik.com"        => {:base => "http://qik.com/api/oembed",               :dot_format => true }, 
                           "revision3.com"  => {:base => "http://revision3.com/api/oembed",         :dot_format => false},
                           "viddler.com"    => {:base => "http://lab.viddler.com/services/oembed",  :dot_format => false},
                           "hulu.com"       => {:base => "http://www.hulu.com/api/oembed",          :dot_format => true}}
        
    # A mapping of supported formats to the methods which parse them
    @@formats = {"xml"  => {:require => "xmlsimple", :oembed_parser => "parse_xml_oembed" }, 
                 "json" => {:require => "json",      :oembed_parser => "parse_json_oembed"}}

    # Format we will try first if none is specified
    @@default_format = 'json'
    
    # Options can be any of the following:
    # * <tt>:url</tt> - The url we want to embed, or attempt to embed (required)
    # * <tt>:providers</tt> - A hash of providers, if not provided the default list is used. Must be in the format. <tt>:base</tt> is the base url for the oembed service provider and <tt>:dot_format</tt> is true if the format is specified like <tt>http://example.com/api/oembed.format</tt> opposed to a GET paramater:
    #
    #     {"example.com" => {:base => "http://example.com/api/oembed", :dot_format => true}}  
    #
    # * <tt>:format</tt> - The format you want to make the request in, the default is json. You may also use xml. If you're using json you need to have the json gem installed and you need the xml-simple gem for xml.
    # * Any other items in the options hash are appended to the oembed url as GET paramaters. Can be used to specify maxwidth, maxheight, etc.
    def initialize(options)
      raise ArgumentError, "No url provided in options hash" if options[:url].nil?
      
      if !options[:format].nil?
        load_format(options[:format])
      else
        load_format
      end            
      
      @providers = options[:providers] || @@default_providers      
      
      # Split the url up and check it's an ok protocol
      broken_url = options[:url].split("/")
      raise UnsupportedError, "Unspported protocol" if broken_url.count == 1 || (broken_url[0] != "http:" && broken_url[0] != "https:")
      
      @domain = broken_url[2].sub("www.", "")      
      raise UnsupportedError, "Unsupported provider" if @providers[@domain] == nil      
      
      @url = options[:url] 
      
      # Delete the options we used, the rest get passed to oembed provider
      options.delete(:url)
      options.delete(:providers) unless options[:providers].nil?      
      options.delete(:format) unless options[:format].nil?
      
      @url_params = options                       
      @request_url = url_for_request      
      @hash = {}
    end
    
    attr_reader :url, :request_url, :hash, :format
    
    # Calling +gets+ returns a hash containing the oembed data.
    def gets
      begin
        data = make_http_request
        @hash = send(@@formats[@format][:oembed_parser], data) # Call the method specified in default_formats hash above
      rescue RuntimeError => e
        if e.message == "401"
          # Embedding disabled
          return nil        
        elsif e.message == "501"
          # Format not supported
          raise UnsupportedError, "#{@format} not supported by #{@domain}"
        elsif e.message == "404"
          # Not found
          raise Error, "#{@url} not found"
        end
      end
    end
    
    private
    def url_for_request
      base = @providers[@domain][:base]
      if @providers[@domain][:dot_format]
        url = "#{base}.#{@format}?url=#{CGI::escape(@url)}"
      else
        url = "#{base}?url=#{CGI::escape(@url)}&format=#{@format}"
      end
      
      unless @url_params.empty?
        @url_params.each do |key,value|
          url += "&#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"
        end
      end
      
      url
    end
    
    def make_http_request      
      response = Net::HTTP.get_response(URI.parse(@request_url))      
      raise response.code if response.code != "200"      
      return response.body      
    end
    
    def parse_json_oembed data
      JSON.parse(data)
    end
    
    def parse_xml_oembed data
      XmlSimple.xml_in(data, 'ForceArray' => false)
    end
    
    # Call with no argument to use default
    def load_format requested_format = nil
      raise ArgumentError, "Requested format not supported" if !requested_format.nil? && @@formats[requested_format].nil?
      @format = requested_format || @@default_format
      attempted_formats = ""

      begin
        attempted_formats += @@formats[@format][:require]
        require @@formats[@format][:require]
        return true
      rescue LoadError
        # If the user requested the format and it failed. Just give up!
        raise Error "Please install: '#{@@formats[@format][:require]}' to use #{@format} format." unless requested_format.nil?

        # Otherwise lets exhaust all our other options first
        available_formats = @@formats
        available_formats.delete(@format)
        
        available_formats.each_key do |format|
          begin
            attempted_formats += ", "            
            require @@formats[format][:require]
            
            @format = format
            return true
          rescue LoadError
            attempted_formats += @@formats[format][:require]
          end
        end
        
        raise Error, "Could not find any suitable library to parse response with, tried: #{attempted_formats}. Please install one of these to use OEmbed."
      end      
    end
    
  end
end