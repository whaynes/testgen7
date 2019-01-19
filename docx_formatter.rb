#

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
                  xml['wp'].extent(cx: png.width, cy: png.height)
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
  EMU_per_inch = 12_700 * 72
  PAGE_WIDTH = 6 * EMU_per_inch

  def initialize(name)
    @img_path = "#{Request::DOCUMENT_ROOT}/#{Request::PATH_TO_IMAGES}#{name}.png"
    @img = Magick::Image.read(@img_path)[0]
    @name = name
    @name_ext = "#{name}.png"

    # for docx, if image is wider than page, pin it to page width, otherwise use natural width
    # if resizing, maintain aspect ratio
    if @img.rows * 12_700 > PAGE_WIDTH
      @width = PAGE_WIDTH
      @height = (@width * @img.rows / @img.columns).round
    else
      @width = @img.rows * 12_700
      @height = @img.columns * 12_700
    end
  end
end
