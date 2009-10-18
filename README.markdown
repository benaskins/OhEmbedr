# OhEmbedr
OhEmbedr is the easiest way to avail of OEmbed services in ruby.

## Install
To install you must add the gemcutter source to your gem sources, as follows:

	gem sources -a http://gemcutter.org
	
After you've done that just install the gem:

	gem install ohembedr
	
## Usage
Using OhEmbed is super easy below is an example for getting OEmbed data for a vimeo video.

	begin
		o = OhEmbedr::OhEmbedr.new(:url => "http://vimeo.com/6382511", :maxwidth => 600)
		embed_data = o.gets
	rescue OhEmbedr::UnsupportedError => error
		# URL not supported
	end

`embed_data` now contains an hash with all the data about embedding the specified url. By wrapping our OhEmbed call with a `begin rescue` block we can pass any url to OhEmbed and take that the url isn't supported if `UnsupportedError` is raised. OhEmbed currently supports the following OEmbed providers:

* YouTube
* Vimeo
* Flickr
* Qik
* Revision 3
* Viddler
* Hulu

If you would like a provider to be added just open a GitHub ticket.