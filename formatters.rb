

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

class ErrorFormatter < TextFormatter
  def build(error)
    "MEWB Error:\n #{error}"
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
    head.add_child "<link rel='stylesheet' href='#{PATH_TO_CSS}' />"
    head.add_child "<meta charset='utf-8'>"
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
    question = question.gsub(/!-- 1\./, '!--') # remove 1. from comment
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
            fig.img(src: "#{PATH_TO_IMAGES}#{img}.png")
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
    question_bank = Nokogiri::XML(File.open(PATH_TO_XML))
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

class DOCXFormatter
  TEMPLATE = 'templates/exam.docx'

  def make(exam)
    print "Content-type: text/docx; charset=utf-8\n"
    print "Content-Disposition: attachment; filename=mewb_exam.docx\n\n" # change zip to docx for production
    print build_docx(exam)
  end

  def build_docx(exam)
    template = Zip::File.open(TEMPLATE) # this is the template-copy boilerplate from here
    my_entries = [Word_document_part.new(exam), # makes the exam
                  Word_document_rels_part.new(exam), # update illustration references
                  Content_types_part.new(exam), # update illustration content types
                  Header_part.new(exam)] # update header

    buffer = Zip::OutputStream.write_buffer do |zos|
      add_media(exam.unique_illustrations, zos) # copy the images into the zip file
      exclusions = my_entries.map(&:name)
      template.entries.each {|entry| add_to_zip(entry, zos) unless exclusions.include?(entry.name)} # add default entries from template file
      my_entries.each {|e| e.add_part_to(zos)} # then add my entries
    end
    buffer.string
  end

  def add_to_zip(entry, zos)
    zos.put_next_entry(entry.name)
    zos.write entry.get_input_stream.read
  rescue NoMethodError # traps directories, #<NoMethodError: undefined method `read' for Zip::NullInputStream:Module>
  end


  class DOCX_part
    attr_accessor :document, :name

    def initialize(doc_path)
      @name = doc_path
      Zip::File.open(TEMPLATE) do |zf|
        contents = zf.find_entry(doc_path) # find the part's entry
        @document = Nokogiri::XML(contents.get_input_stream.read) # get the part's contents
      end
    end

    def add_part_to(buffer)
      buffer.put_next_entry @name
      buffer.write to_xml
    end

    def to_s # pretty version
      Nokogiri::XML(@document.to_s.gsub(/>\s*</i, '><')).to_xml(indent: 2)
    end

    def to_xml # compact version
      @document.to_xml
    end
  end
  class Word_document_part < DOCX_part

    def initialize(exam)
      super 'word/document.xml' # get the template document
      add answer_key(exam) if exam.show_answers
      add questions(exam)
      add illustrations(exam) if exam.show_pics # adds references to the text, must still add media and rels
      add sect_br
    end

    def add(xml)
      body = @document.at('//w:body')
      body.add_child xml
    end

    def sect_br
      Nokogiri::XML.fragment(<<~SECTIONBREAK)
        <w:sectPr>
                 <w:headerReference w:type="default" r:id="rId8" />
                 <w:footerReference w:type="default" r:id="rId9" />
                 <w:type w:val="nextPage" />
                 <w:pgSz  w:h="15840" w:w="12240"/>
                 <w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:header="720" w:footer="720" w:gutter="0" />
                 <w:pgNumType w:start="1" />
                 <w:cols w:space="720" />
        </w:sectPr>
      SECTIONBREAK
    end

    def tr(i, q)
      Nokogiri::XML.fragment <<~TABLEROW
        <w:tr>
                  <w:tc>
                     <w:p>
                        <w:pPr>
                           <w:pStyle w:val="Compact" />
                           <w:jc w:val="left" />
                        </w:pPr>
                        <w:r>
                           <w:t xml:space="preserve">#{i + 1}.</w:t>
                        </w:r>
                     </w:p>
                  </w:tc>
                  <w:tc>
                     <w:p>
                        <w:pPr>
                           <w:pStyle w:val="Compact" />
                           <w:jc w:val="left" />
                        </w:pPr>
                        <w:r>
                           <w:t xml:space="preserve">#{q.qnum}.</w:t>
                        </w:r>
                     </w:p>
                  </w:tc>
                  <w:tc>
                     <w:p>
                        <w:pPr>
                           <w:pStyle w:val="Compact" />
                           <w:jc w:val="left" />
                        </w:pPr>
                        <w:r>
                           <w:t xml:space="preserve">#{q[:ans].downcase}</w:t>
                        </w:r>
                     </w:p>
                  </w:tc>
                  <w:tc>
                     <w:p>
                        <w:pPr>
                           <w:pStyle w:val="Compact" />
                           <w:jc w:val="left" />
                        </w:pPr>
                        <w:r>
                           <w:t xml:space="preserve">#{q[:illustration]}</w:t>
                        </w:r>
                     </w:p>
                  </w:tc>
               </w:tr>
      TABLEROW
    end

    def answer_key(exam)
      xml = Nokogiri::XML.fragment(<<~HEADER)
        <w:tbl>
        	<w:tblPr>
        		<w:tblStyle w:val="TableNormal" /> <w:tblW w:type="pct" w:w="0" /> 
        	</w:tblPr>
        	<w:tblGrid>
        		<w:gridCol w:w="2000" /> <w:gridCol w:w="2000" /> <w:gridCol w:w="2000" /> <w:gridCol w:w="4000" /> 
        	</w:tblGrid>
        	<w:tr>
        		<w:tc>
        			<w:tcPr>
        				<w:tcBorders>
        					<w:bottom w:val="single" /> 
        				</w:tcBorders>
        				<w:vAlign w:val="bottom" /> 
        			</w:tcPr>
        			<w:p>
        				<w:pPr>
        					<w:pStyle w:val="Compact" /> <w:jc w:val="left" /> 
        				</w:pPr>
        				<w:r>
        					<w:t xml:space="preserve">Question</w:t>
        				</w:r>
        			</w:p>
        		</w:tc>
        		<w:tc>
        			<w:tcPr>
        				<w:tcBorders>
        					<w:bottom w:val="single" /> 
        				</w:tcBorders>
        				<w:vAlign w:val="bottom" /> 
        			</w:tcPr>
        			<w:p>
        				<w:pPr>
        					<w:pStyle w:val="Compact" /> <w:jc w:val="left" /> 
        				</w:pPr>
        				<w:r>
        					<w:t xml:space="preserve">MEWB No.</w:t>
        				</w:r>
        			</w:p>
        		</w:tc>
        		<w:tc>
        			<w:tcPr>
        				<w:tcBorders>
        					<w:bottom w:val="single" /> 
        				</w:tcBorders>
        				<w:vAlign w:val="bottom" /> 
        			</w:tcPr>
        			<w:p>
        				<w:pPr>
        					<w:pStyle w:val="Compact" /> <w:jc w:val="left" /> 
        				</w:pPr>
        				<w:r>
        					<w:t xml:space="preserve">Answer</w:t>
        				</w:r>
        			</w:p>
        		</w:tc>
        		<w:tc>
        			<w:tcPr>
        				<w:tcBorders>
        					<w:bottom w:val="single" /> 
        				</w:tcBorders>
        				<w:vAlign w:val="bottom" /> 
        			</w:tcPr>
        			<w:p>
        				<w:pPr>
        					<w:pStyle w:val="Compact" /> <w:jc w:val="left" /> 
        				</w:pPr>
        				<w:r>
        					<w:t xml:space="preserve">Illustration</w:t>
        				</w:r>
        			</w:p>
        		</w:tc>
        	</w:tr>
        </w:tbl>
      HEADER
      table = xml.at_xpath '*[1]'
      exam.qlist.each_with_index do |qnum, i|
        question = Question.new(qnum)
        table.add_child tr(i, question)
      end
      xml.add_child Nokogiri::XML.fragment(<<~BREAK)
        <w:p>
        	<w:pPr>
        		<w:sectPr>
        			<w:headerReference w:type="default" r:id="rId8" /> <w:footerReference w:type="default" r:id="rId9" /> <w:pgNumType w:start="1" /> 
        		</w:sectPr>
        	</w:pPr>
        </w:p>
      BREAK

      xml
    end

    def questions(exam)
      questions = exam.qlist.map do |qnum|
        Question.new(qnum)[:docx]
      end
      Nokogiri::XML.fragment questions.join
    end

    def illustration(i)
      png = Illustration.new(i) # get the illustration data from the imagenumber
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.wrapper('xmlns:w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
                    'xmlns:wp' => 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
                    'xmlns:a' => 'http://schemas.openxmlformats.org/drawingml/2006/main',
                    'xmlns:pic' => 'http://schemas.openxmlformats.org/drawingml/2006/picture') do
          xml['w'].p_ do
            xml['w'].pPr do
              xml['w'].jc('w:val': 'center')
            end
            xml['w'].r do
              xml['w'].drawing do
                xml['wp'].inline do
                  xml['wp'].extent(cx: png.width.to_s, cy: png.height.to_s)
                  xml['wp'].docPr(id: '1', name: png.name_ext.to_s)
                  xml['a'].graphic do
                    xml['a'].graphicData(uri: 'http://schemas.openxmlformats.org/drawingml/2006/picture') do
                      xml['pic'].pic do
                        xml['pic'].nvPicPr do
                          xml['pic'].cNvPr(id: 1, name: png.name_ext.to_s)
                          xml['pic'].cNvPicPr do
                            xml['a'].picLocks(noChangeArrowheads: '1', noChangeAspect: '1')
                          end
                        end
                        xml['pic'].blipFill do
                          xml['a'].blip('r:embed': png.name.to_s)
                          xml['a'].stretch do
                            xml['a'].fillRect
                          end
                        end
                        xml['pic'].spPr(bwMode: 'auto') do
                          xml['a'].xfrm do
                            xml['a'].off(x: '0', y: '0')
                            xml['a'].ext(cx: png.width.to_s, cy: png.height.to_s)
                          end
                          xml['a'].prstGeom(prst: 'rect') do
                            xml['a'].avLst
                          end
                          xml['a'].noFill
                          xml['a'].ln(w: 9525) do
                            xml['a'].noFill
                            xml['a'].headEnd
                            xml['a'].tailEnd
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      builder.doc.at('//w:p').to_s # extract the w:p from the wrapper and add to body
    end

    def illustrations(exam)
      xml = <<~heading
        <w:p>
        	<w:pPr><w:pStyle w:val="Heading3" /></w:pPr>
        	<w:bookmarkStart w:id="26" w:name="pics" /> <w:bookmarkEnd w:id="26" /> 
        	<w:r><w:t xml:space="preserve">Illustrations</w:t></w:r>
        </w:p>
      heading
      exam.unique_illustrations.each do |i|
        xml << illustration(i)
        xml << <<~caption
          <w:p>
          	<w:pPr>
          		<w:pStyle w:val="ImageCaption" /> 
          	</w:pPr>
          	<w:r>
          		<w:t xml:space="preserve">#{i}</w:t>
          	</w:r>
          </w:p>
        caption
      end
      Nokogiri::XML.fragment(xml)
    end

  end
  class Word_document_rels_part < DOCX_part
    def initialize(exam)
      super 'word/_rels/document.xml.rels'
      relationships = @document.at('Relationships')
      exam.unique_illustrations.each do |i|
        relationships.add_child Nokogiri::XML.fragment("<Relationship Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image' Id='#{i}' Target='media/#{i}.png' />")
      end
    end
  end
  class Content_types_part < DOCX_part
    def initialize(exam)
      super('[Content_Types].xml')
      content_types = @document.at('Types')
      exam.unique_illustrations.each do |i|
        content_types.add_child Nokogiri::XML.fragment("<Override PartName='/word/media/#{i}.png' ContentType='image/png' />")
      end
    end
  end
  class Header_part < DOCX_part
    def initialize(exam)
      heading_text = exam.labels
      super('word/header1.xml')
      hdr = document.at('//w:hdr')
      hdr.add_child Nokogiri::XML.fragment(<<~header)
        <w:p>
        <w:pPr>
        <w:pStyle w:val="Header" />
                  <w:rPr>
        <w:rtl w:val="0" />
               </w:rPr>
              </w:pPr>
        <w:r>
        <w:rPr>
        <w:rFonts w:ascii="Cambria" w:cs="Arial Unicode MS" w:hAnsi="Arial Unicode MS" w:eastAsia="Arial Unicode MS" />
        <w:rtl w:val="0" />
               </w:rPr>
                 <w:t>#{heading_text[0]}</w:t>
        <w:tab />
                 <w:tab />
               <w:t>#{heading_text[1]}</w:t>
        </w:r>
           </w:p>
        <w:p>
        <w:pPr>
        <w:pStyle w:val="Header" />
                  </w:pPr>
              <w:r>
                 <w:rPr>
                    <w:rFonts w:ascii="Cambria" w:cs="Arial Unicode MS" w:hAnsi="Arial Unicode MS" w:eastAsia="Arial Unicode MS" />
                  <w:rtl w:val="0" />
                         </w:rPr>
                 <w:t>#{heading_text[2]}</w:t>
        <w:tab />
                 <w:tab />
               <w:t>#{heading_text[3]}</w:t>
        </w:r>
           </w:p>
      header
    end
  end

  def add_media(ilist, zos)
    ilist.each do |i|
      png = Illustration.new(i)
      zos.put_next_entry('word/media/' + png.name_ext)
      zos.write png.img.to_blob
    end
  end
end # class

class Illustration
  attr_reader :img, :img_path, :name, :name_ext, :width, :height
  # see https://startbigthinksmall.wordpress.com/2010/01/04/points-inches-and-emus-measuring-units-in-office-open-xml
  POINTS_per_inch = 72
  POINTS_per_column = 1
  EMU_per_point = 12_700
  EMU_per_inch = POINTS_per_inch * EMU_per_point
  PAGE_WIDTH = 6 * EMU_per_inch
  PAGE_HEIGHT = 8 * EMU_per_inch

  def initialize(name)
    @img_path = "#{DOCUMENT_ROOT}/#{PATH_TO_IMAGES}#{name}.png"
    @img = Magick::Image.read(@img_path)[0]
    @name = name
    @name_ext = "#{name}.png"

    # for docx, if image is wider and/or taller than the page, scale it to fit
    # These questions have images which need scaling 11762, 9524, 2797, 14219

    @width = @img.columns * POINTS_per_column * EMU_per_point
    @height = @img.rows *  POINTS_per_column * EMU_per_point

    if @width > PAGE_WIDTH then
      @height = @height * PAGE_WIDTH/@width
      @width = PAGE_WIDTH
    end

    if @height > PAGE_HEIGHT then
      @width = @width * PAGE_HEIGHT/@height
      @height = PAGE_HEIGHT
    end
  end
end
