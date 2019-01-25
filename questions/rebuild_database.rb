#!/usr/bin/ruby

require 'Nokogiri'
require 'pandoc-ruby'
require 'zip/filesystem'
require 'sqlite3'

BANK = Nokogiri::XML(File.open 'questions/MEWB7.xml') #relative paths from cgi
MD_XSLT = Nokogiri::XSLT(File.read 'xsl/fmp2md.xsl')
DOCX_XSLT = Nokogiri::XSLT(File.read 'xsl/fix_docx.xsl')
DBNAME='questions/mewb7.sqlite'
DOCX_TEMPLATE='templates/template_db.docx'

class Question
  attr_accessor :qnum, :xml, :mmd

  def initialize (qnum) #makes xml and multimarkdown versions of question qnum
    @qnum = qnum
    @xml = Nokogiri::XML('<exam/>')
    @xml.root.add_child(BANK.xpath("//fmp:ROW[fmp:qnum = #{qnum}]", 'fmp' => 'http://www.filemaker.com/fmpdsoresult'))
    @mmd = MD_XSLT.apply_to(@xml, Nokogiri::XSLT.quote_params(['include_key', false, 'include_illustrations', false]))
  end

  def pix #  extracts the illustrations as a comma separated list
    pix=@xml.xpath("//fmp:ROW[fmp:qnum = #{@qnum}]/fmp:illustration/fmp:DATA/text()", 'fmp' => 'http://www.filemaker.com/fmpdsoresult')
    pix.map { |p| p.text }.join(', ')
  end

  def answer #extracts the question's answer
    @xml.xpath("//fmp:ans/text()", 'fmp' => 'http://www.filemaker.com/fmpdsoresult').to_s
  end

  def as_html #formats the question as a html list item <li>
    Nokogiri::HTML.fragment(PandocRuby.convert(@mmd, :to => :html5)).xpath("ol/*").to_s #xpath strips enclosing <ol type="1"> html
  end

  def as_docx
    # open a temporary document, use pandoc to create a docx version from markdown version
    tempfile = Tempfile.new('mewb')
    tempfile.write PandocRuby.convert(@mmd, :to => :docx, 'reference-docx' => DOCX_TEMPLATE)

    #extract the docx version and save a copy

    Zip::File.open(tempfile) { |zf| @document = Nokogiri::XML.parse(zf.read('word/document.xml')) }
    File.open("output/document.xml", 'w') { |f| f << @document }

    #apply my xslt to the document to use my styles
    doc = DOCX_XSLT.transform(@document)

    #return just the document fragment which is the question, no surrounding <body>
    doc.xpath('w:document/w:body/*', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').to_s
  ensure
    tempfile.close
  end

end

def stuff_db(list)
  begin
    File.rename(DBNAME,DBNAME+'.bak') if File.exists? DBNAME
    db = SQLite3::Database.new(DBNAME)
    db.execute("CREATE TABLE testdata(qnum INTEGER PRIMARY KEY, ans TEXT, illustration TEXT, docx TEXT, html TEXT)")

# Looping through some Ruby data classes
# This is the same insert query we'll use for each insert statement
    insert_query = "INSERT INTO testdata(qnum, ans, illustration, docx, html) VALUES(?, ?, ?, ?, ?)"
    list.each do |q|
      puts q
      question = Question.new(q)
      db.execute(insert_query, q, question.answer, question.pix, question.as_docx, question.as_html)
    end


  rescue SQLite3::Exception => e

    puts "Exception occurred"

    puts e

  ensure
    db.close if db
  end
end


problematic = [3433, 8223, 99, 2713, 65, 14072, 13413, 13414, 2532, 5554, 4865, 4866, 1373]
pics210 = [2532, 1373, 99]
all = 1..14427

stuff_db(all)


