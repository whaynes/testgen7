# frozen_string_literal: true

require_relative 'docx_formatter'

class HTMLFormatter
  # descendants of this class return html to the browser
  def make(exam)
    puts "Content-Type: text/html\n\n"
    puts build(exam)
  end
end

class TextFormatter
  # descendants of this class return text to the browser
  def make(exam)
    puts "Content-Type: text/plain\n\n"
    puts build(exam)
  end
end

class ParamsFormatter < TextFormatter
  # this class returns the cgi parameters and the questions/answers/illustrations
  def build(exam)
    result = ['CGI Parameters:']
    result << exam.params.pretty_inspect
    exam.qlist.each_with_index { |q, i| result << format('%5d. | %5d | %s | %s ', i + 1, q, exam.alist[i], exam.ilist[i]) }
    result.join "\n"
  end
end

class SourceFormatter < TextFormatter
  # this class builds the html source for the exam, but returns it as text
  def build(exam)
    html = Nokogiri::HTML5::Document.parse '<!DOCTYPE html><html>'
    head = html.at_css('head')
    head.add_child "<link rel='stylesheet' href='#{Request::PATH_TO_CSS}' />"
    body = html.at_css('body')
    body.add_child page_header(exam)
    body.add_child answers(exam) if exam.show_answers
    body.add_child questions(exam)
    body.add_child illustrations(exam) if exam.show_pics
    html.to_xhtml
  end

  def page_header(exam)
    labels = exam.labels
    header = Nokogiri::XML::Builder.new do |xml|
      xml.header do |_header|
        xml.div do
          xml.div.left labels[0]
          xml.div.right labels[2]
        end
        xml.div do
          xml.div.left labels[1]
          xml.div.right labels[3]
        end
      end
    end
    header.doc.to_xhtml
  end

  def answers(exam)
    answers = Nokogiri::XML::Builder.new do |xml|
      xml.div(id: 'answers') do |sec|
        sec.h3 'Answer Key'
        sec.table do |table|
          table.thead do |thead|
            thead.th 'Questions'
            thead.th 'MEWB No.'
            thead.th 'Answer'
            thead.th 'Illustration'
          end
          table.tbody do |tbody|
            exam.qlist.each_with_index do |qnum, i|
              question = Question.new(qnum)
              tbody.tr do |tr|
                tr.td "#{i + 1}."
                tr.td question.qnum
                tr.td question[:ans]
                tr.td question[:illustration]
              end
            end
          end
        end
      end
    end
    answers.doc.to_xhtml
  end

  def question(q, i)
    # gets question from database, returns nokogiri node
    question = Question.new(q)[:html] # get <li><stem><choices></li>
    question.gsub!(/!-- 1\./, '!--') # remove 1. from comment
    question = Nokogiri::XML::DocumentFragment.parse question
    question.at_css('li')[:class] = "question #{i + 1}" # add css class
    question
  end

  def questions(exam)
    # returns a <div> node containing <li> elements, each containing the stem and choices of a question
    sec = Nokogiri::XML::Node.new 'section', Nokogiri::XML::Document.new
    sec[:id] = 'test'
    sec.add_child '<ol>'
    ol = sec.at_css 'ol'
    exam.qlist.each_with_index.map do |qnum, index|
      ol.add_child question(qnum, index)
    end
    sec
  end

  def illustrations(exam)
    ilist = exam.ilist.reject(&:empty?).uniq.sort
    illustrations = Nokogiri::XML::Builder.new do |xml|
      xml.div(id: 'pics') do |sec|
        sec.h3 'Illustrations'
        ilist.each do |img|
          sec.figure do |fig|
            fig.img(src: "#{Request::PATH_TO_IMAGES}#{img}.png")
            fig.figcaption img
          end
        end
      end
    end
    illustrations.doc.to_xhtml
  end
end

class XHTMLFormatter < HTMLFormatter
  # this class returns the html source as a web page
  def build(exam)
    SourceFormatter.new.build(exam)
  end
end

class XMLFormatter < TextFormatter
  # this class builds an xml version of the exam
  def build(exam)
    question_bank = Nokogiri::XML(File.open(Request::PATH_TO_XML))
    doc = Nokogiri::XML('<exam/>')
    exam.qlist.each do |q| # add questions to exam
      question = question_bank.xpath("//fmp:ROW[fmp:qnum = #{q}]", 'fmp' => 'http://www.filemaker.com/fmpdsoresult')
      doc.root.add_child(question)
    end
    doc.to_xml
  end
end

class MMDFormatter < TextFormatter
  # this class converts the xml version to markdown
  def build(exam)
    xml = Nokogiri::XML.parse XMLFormatter.new.build(exam)
    xslt = Nokogiri::XSLT(File.read('./xsl/fmp2md.xsl'))
    mmd = xslt.apply_to(xml, Nokogiri::XSLT.quote_params(
                               ['include_key', exam.show_answers, 'include_illustrations', exam.show_pics]
                             ))
    <<~meta + mmd
      ---
      title: MEWB Exam
      name: #{exam.labels[1]}
      date: #{exam.labels[3]}
      l1: #{exam.labels[0]}
      l2: #{exam.labels[2]}
      Markdown_Variant: Pandoc + yaml metadata
      ---
    meta
  end
end

class BBFormatter < TextFormatter
  # this class converts the html version to a version for import into blackboard
  def build(exam)
    xhtml = SourceFormatter.new.build(exam)
    xml = Nokogiri::XML(xhtml)
    xslt = Nokogiri::XSLT File.read('./xsl/html2bb.xsl')
    doc = xslt.apply_to(xml, Nokogiri::XSLT.quote_params(['include_illustrations', exam.show_pics]))
    munge(doc).encode(Encoding::ISO_8859_1) # return value, note blackboard expects windows latin 1 encoding
  end

  def munge(bb)
    bb.gsub(/₂/, '<sub>2</sub>') # replace unicode subscript 2 which cant be represented in encoding 8859-1
  end

  def make(exam)
    print "Content-type: text/text; charset=ISO8859-1\n"
    print "Content-Disposition: attachment; filename=mewb_bb.txt\n\n"
    print build(exam)
  end
end
