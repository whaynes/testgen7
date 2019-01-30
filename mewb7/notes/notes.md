# Steps to get this running

1.	Install xcode
2.	Install command line tools
3.	Install needed libraries
    1.	install macports
    2.	install libxml2 and libxslt
	3.	install imagemagick
	
install bundler gem and use it to install the required gems

	'bundle install' or 
	'sudo bundle install'

if this doesn't work using system ruby, install rbenv and a local ruby
	

install pandoc
install gem 'pandoc-ruby'


Move files to appropriate places on webserver:  

1.	MEWB7 in the document folder
2.	testgen7 in the cgi-bin folder

Make sure that  testgen.rb in cgi-bin has execute permission
    'chmod +x testgen7.rb'
    
Give apache write permission to output folder:  from testgen7 folder

	'chown _www output'
	
Uncomment the following line in /etc/apache2/httpd.conf to enable cgi
*\#LoadModule cgi_module libexec/apache2/mod_cgi.so*

Must restart apache to make config changes take.

#Improvement:
maybe: use apache scriptalias to clean up url


rbenv  http://qiita.com/lambdadbmal/items/c94a18b88364353a321e

If you are using rbenv, you have to set up more configuration (also me).
Most googled sites tell us 'set up envvars file for Apache'. But on Mac, that's not right.
You have to edit '/System/Library/LaunchDaemons/org.apache.httpd.plist'. offcourse you have to edit as root.
sudo vi /System/Library/LaunchDaemons/org.apache.httpd.plist
...
<key>EnvironmentVariables</key>
<dict>
    <key>PATH</key>
    <string>/usr/local/var/rbenv/shims:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin</string>
</dict>
...
You have to tell Apache a PATH where your favorite Ruby executable is. If not, Apache process can not find where your gem files are.
and then, restart apache.
sudo /usr/sbin/apachectl restart


#Contents

## MEWB7:
 	illustrations:
		fullsize:
			fullsize images
		medium:
			images resized to max 800 px wide, not currently used
		thumbs:
			100x100 px thumnails
	index.html
	llustration Note.txt  - instructions for imagemagick transforms
	notes.md  -- this doc
	testgen7Exam.css  stylesheet for the html version of the exam
	testGen7Form.css  stylesheet for index.html

##testgen7:
	fmp2md.xsl  --  xslt to convert from xml to markdown
	Gemfile		-- used by bundler for ruby gems
	Gemfile.lock -- used by bundler for ruby gems
	html2bb.xsl -- xslt to convert from html to text for blackboard
	MEWB7.rnc  -- defines expected xml -- used for validation
	mewb7.xml  -- xml file exported from filemaker, containing all the questions
				-- it should validate
	output:  -- place cgi writes files to; not used on apache
		output folder notes.txt
	reference.docx -- template file for docx export; feature is hidden because 				I'm unhappy with the output.  consider it to be experimental
	template.html --  used by pandoc to create the html version
	testgen7.rb -- the cgi
	word.rb -- uses a gem for creating docx files, the gem doesn't work, but may be usefull in the future.

##testgen7:


##requires 	
		
| Programs	| gems	|  
| -------------	| :-------------	|  
| libxslt	| nokogiri	|  
| pandoc	| pandoc-ruby	|  
					
##Logic
* gets data from cgi
* reads xml
* extracts only the requested questions
* converts them to markdown
* as requested
	* returns the markdown
	* converts markdown to html and returns it to browser
	* converts markdown to rtf and uploads the rtf file


##To Do
 Fix illustrations to fit properly in rtf output
 Shrink illustrations for download speed
 Speed up cgi response, cache binary versions of illustrations
 Get persistant storage to work on apache
 Get docx output to work the way I want it to.
 Get an ajax wait cursor to work for long operations.


January 2019
Trying to get this running for cruise 19
Updated ruby to 2.6.0
Changed shebang in testgen.rb in cgi folder: #!/Users/engineering/.rbenv/versions/2.6.0/bin/ruby
ran bundle got error installing libxml-ruby gem.

Got this error message

~~~
In file included from libxml.c:1:
In file included from ./ruby_libxml.h:7:
In file included from /opt/local/include/libxml2/libxml/parser.h:810:
/opt/local/include/libxml2/libxml/encoding.h:31:10: fatal error: 'unicode/ucnv.h' file not found
#include <unicode/ucnv.h>
         ^~~~~~~~~~~~~~~~
1 error generated.
make: *** [libxml.o] Error 1
~~~


To make gem libxml-ruby install work I had to edit 
Line 285 in /opt/local/include/libxml2/libxml/xmlversion.h

Change `if 1` to `if 0` to eliminate error when installing 	`gem install libxml-ruby`

There's probably a better way to do this.

~~~~
/**
 * LIBXML_ICU_ENABLED:
 *
 * Whether icu support is available
 */
#if 1
#define LIBXML_ICU_ENABLED
#endif
~~~


