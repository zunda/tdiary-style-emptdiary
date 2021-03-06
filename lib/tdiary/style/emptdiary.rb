# -*- coding: utf-8; -*-

require 'tdiary/style/tdiary'

=begin
== Classes and methods defined in this style
Please note that not all are documented.
=end

module TDiary
	module Style
=begin
=== TDiary::Emptdiary::EmptdiaryString < String
Extended String class not to divide things between <% and %>.

--- TDiary::Emptdiary::EmptdiaryString.split_unless_plugin ( delimiter = "\n\n" )
      Returns an array of EmptdiaryString splitted at ((|delimiter|))
      which is outside of <% and %> pairs. Specify ((|delimiter|)) as a
      String showing a fragment of Regexp. This will be combined in a
      Regexp like: /(#{delimiter)|<%|%>)/.
=end
		class Emptdiary
			class EmptdiaryString < String
				def split_unless_plugin( delimiter = "\n\n+" )
					result = Array.new
					fragment = ''
					nest = 0
					remain = self.gsub(/.*?(#{delimiter}|<%|%>)/m) do
						fragment += $&
						case $1
						when '<%'
							nest += 1
						when '%>'
							nest -= 1
						else
							if nest == 0 then
								fragment.sub!( /#{delimiter}\z/, '' )
								result << Emptdiary::EmptdiaryString.new( fragment ) unless fragment.empty?
								fragment = ''
							end
						end
						''
					end
					fragment += remain
					fragment.sub!( /#{delimiter}\z/, '' )
					result << Emptdiary::EmptdiaryString.new( fragment ) unless fragment.empty?
					result
				end
			end
		end

=begin
=== TDiary::EmptdiartySection < TdiarySection
Almost the same as TdiarySection but usess split_unless_plugin instead
of split. initialize method is overrideen.
=end
		class EmptdiarySection < TdiarySection
			def initialize( fragment, author = nil )
				@author = author
				lines = fragment.split_unless_plugin( "\n+" )
				if lines.size > 1 then
					if /\A<</ =~ lines[0]
						@subtitle = lines.shift.chomp.sub( /\A</, '' )
					elsif /\A[　 <]/u !~ lines[0]
						@subtitle = lines.shift.chomp
					end
				end
				@body = Emptdiary::EmptdiaryString.new( lines.join( "\n" ) )
				@categories = get_categories
				@stripped_subtitle = strip_subtitle
			end

			def body_to_html
				html = ""
				@body.split_unless_plugin( "\n" ).each do |p|
					if /\A</ =~ p then
						html << p
					else
						html << "<p>#{p}</p>"
					end
				end
				html
			end
		end

=begin
=== TDiary::EmptdiaryDiary < TdiaryDiary
Almost the same as TdiarySection but usess split_unless_plugin instead
of split. append method is overriden and makes EmptdiarySection with
body being an EmptdiaryString. Also, to_html4 and to_chtml methods are
overridden to split_unless_plugin before collect'ing the body of the
sections.
=end
		class EmptdiaryDiary < TdiaryDiary
			def style
				'emptdiary'
			end
			
			def append( body, author = nil )
				Emptdiary::EmptdiaryString.new(body.gsub( /\r/, '' )).split_unless_plugin( "\n\n+" ).each do |fragment|
					section = EmptdiarySection::new( fragment, author )
					@sections << section if section
				end
				@last_modified = Time::now
				self
			end

			def to_html4( opt )
				r = ''
				each_section do |section|
					r << %Q[<div class="section">\n]
					r << %Q[<%=section_enter_proc( Time::at( #{date.to_i} ) )%>\n]
					if section.subtitle then
						r << %Q[<h3><%= subtitle_proc( Time::at( #{date.to_i} ), #{section.subtitle.dump.gsub( /%/, '\\\\045' )} ) %></h3>\n]
					end
					if /\A</ =~ section.body then
						r << %Q[#{section.body}]
					elsif section.subtitle
						r << %Q[<p>#{section.body.split_unless_plugin( "\n+" ).collect{|l|l.chomp.sub( /\A[　 ]/u, '')}.join( "</p>\n<p>" )}</p>]
					else
						r << %Q[<p><%= subtitle_proc( Time::at( #{date.to_i} ), nil ) %>]
						r << %Q[#{section.body.split_unless_plugin( "\n+" ).collect{|l|l.chomp.sub( /\A[　 ]/u, '' )}.join( "</p>\n<p>" )}</p>]
					end
					r << %Q[<%=section_leave_proc( Time::at( #{date.to_i} ) )%>\n]
					r << %Q[</div>]
				end
				r
			end

			def to_chtml( opt )
				r = ''
				each_section do |section|
					r << %Q[<%=section_enter_proc( Time::at( #{date.to_i} ) )%>\n]
					if section.subtitle then
						r << %Q[<H3><%= subtitle_proc( Time::at( #{date.to_i} ), #{section.subtitle.dump.gsub( /%/, '\\\\045' )} ) %></H3>\n]
					end
					if /\A</ =~ section.body then
						r << section.body
					elsif section.subtitle
						r << %Q[<P>#{section.body.split_unless_plugin( "\n+" ).collect{|l|l.chomp.sub( /\A[　 ]/u, '' )}.join( "</P>\n<P>" )}</P>]
					else
						r << %Q[<P><%= subtitle_proc( Time::at( #{date.to_i} ), nil ) %>]
						r << %Q[#{section.body.split_unless_plugin( "\n+" ).collect{|l|l.chomp.sub( /\A[　 ]/u, '' )}.join( "</P>\n<P>" )}</P>]
					end
					r << %Q[<%=section_leave_proc( Time::at( #{date.to_i} ) )%>\n]
				end
				r
			end
		end
	end
end

# Local Variables:
# mode: ruby
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# End:
