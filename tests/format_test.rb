require 'minitest/autorun'
require_relative '../request'
# frozen_string_literal: true

class FormatTest < Minitest::Test
  def setup
    @params = [{'labels' => %w[a b c d], 'format' => ['form'], 'illustrations' => ['on'], 'qlist' => ["7677\r\n6560\r\n12332\r\n11643\r\n"]},
               {'labels' => %w[a b c d], 'format' => ['xhtml'], 'qlist' => ["7677\r\n6560\r\n"]},
               {'labels' => %w[a b c d], 'format' => ['docx'], 'key' => ['on'], 'illustrations' => ['on'], 'qlist' => ["2107\r\n10635\r\n"]},
               {'labels' => %w[a b c d], 'format' => ['mmd'], 'key' => ['on'], 'qlist' => ["2107\r\n10635\r\n"]}]
    @exam = Request.new(@params[0]).ilist
  end

  def test_format_illustrations_as_html
    result = %(<div id=\"pics\">\n  <h3>Illustrations</h3>\n  <figure>\n    <img src=\"/mewb7/illustrations/fullsize/GS-0173.png\" />\n    <figcaption>GS-0173</figcaption>\n  </figure>\n</div>\n)
    exam = Request.new('labels' => %w[L1 L2 L3 L4], 'qlist' => ["1719\r\n6560\r\n12332\r\n11643\r\n"])
    assert_equal result, SourceFormatter.new.illustrations(exam)
  end

  def test_format_header_as_html
    result = <<~HEADER
      <header>
        <div>
          <div class=\"left\">L1</div>
          <div class=\"right\">L3</div>
        </div>
        <div>
          <div class=\"left\">L2</div>
          <div class=\"right\">L4</div>
        </div>
      </header>
    HEADER
    exam = Request.new('labels' => %w[L1 L2 L3 L4], 'qlist' => ["1719\r\n6560\r\n12332\r\n11643\r\n"])
    assert_equal result, SourceFormatter.new.page_header(exam)
  end

  def test_format_can_find_image
    imagepath = Request::DOCUMENT_ROOT + Request::PATH_TO_IMAGES + 'GS-0173.png'
    assert File.exist?(imagepath)
  end

  def test_format_can_find_css
    csspath = Request::DOCUMENT_ROOT + Request::PATH_TO_CSS
    assert File.exist?(csspath)
  end

  def test_format_bb_converts_subscripts_to_html
    assert_equal 'H<sub>2</sub>O', BBFormatter.new.munge('H₂O')
  end

  def test_format_exam_as_html
    exam = Request.new(@params[2]) # pass params to debug.
    html = XHTMLFormatter.new.build(exam)
    result = <<~result
      <!DOCTYPE html>
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
          <link rel="stylesheet" href="/sieve/css/exam.css" />
        </head>
        <body><header>
        <div>
          <div class="left">a</div>
          <div class="right">c</div>
        </div>
        <div>
          <div class="left">b</div>
          <div class="right">d</div>
        </div>
      </header>
      <div id="answers">
        <h3>Answer Key</h3>
        <table>
          <thead>
            <tr><th>Questions</th>
            <th>MEWB No.</th>
            <th>Answer</th>
            <th>Illustration</th>
          </tr></thead>
          <tbody>
            <tr>
              <td>1.</td>
              <td>2107</td>
              <td>D</td>
              <td></td>
            </tr>
            <tr>
              <td>2.</td>
              <td>10635</td>
              <td>A</td>
              <td>MO-0127</td>
            </tr>
          </tbody>
        </table>
      </div>
      <section id="test"><ol><li class="question 1">
      <p><!-- mewb7: 2107 ans: D -->In the production of freshwater from seawater through a process of heating and cooling, the cooling phase of production is usually called __________.</p>
      <ol type="a">
      <li>evaporation</li>
      <li>distillation</li>
      <li>dehydration</li>
      <li>condensation</li>
      </ol>
      </li><li class="question 2">
      <p><!-- mewb7: 10635 ans: A -->If the regulating valve V4 shown in the illustration vibrated open, which of the following alarm conditions would be indicated at the program unit panel? <em>See illustration <a href="http://weh.maritime.edu/mewb7/illustrations/fullsize/MO-0127.png">MO-0127</a>.</em></p>
      <ol type="a">
      <li>Low pressure in oil outlet.</li>
      <li>Low oil temperature after preheater.</li>
      <li>High oil temperature after preheater.</li>
      <li>No discharge.</li>
      </ol>
      </li></ol></section><div id="pics">
        <h3>Illustrations</h3>
        <figure>
          <img src="/mewb7/illustrations/fullsize/MO-0127.png" />
          <figcaption>MO-0127</figcaption>
        </figure>
      </div>
      </body>
      </html>
    result
    assert_equal result, html
  end
end

class DOCXTest < Minitest::Test
  def setup
    @exam = Request.new('labels' => ['', 'Name_____________', '', 'Jan 16, 2019'],
                        'key' => ['on'],
                        'illustrations' => ['on'],
                        'qlist' =>
                            ["13609\r\n1658\r\n11853\r\n7379\r\n835\r\n395\r\n12667\r\n12108\r\n1509\r\n2664\r\n"],
                        'Make_Exam' => ['Make Exam'],
                        'format' => ['docx'])
  end

  def test_docx_document_is_well_formed
    doc = DOCXFormatter::Word_document_part.new(@exam).document
    p =  Nokogiri::XML(doc.to_s) { |config| config.options = Nokogiri::XML::ParseOptions::STRICT }
    assert_equal [], doc.errors
  end


  def test_docx_answer_key
    exam = Request.new('labels' => ['', 'Name_____________', '', 'Jan 16, 2019'],
                       'key' => ['on'],
                       'qlist' => ["1"],
                       'Make_Exam' => ['Make Exam'],
                       'format' => ['docx'])
    result = <<~XML
      <w:tbl>
      	<w:tblPr>
      		<w:tblStyle w:val="TableNormal"/> <w:tblW w:type="pct" w:w="0"/> 
      	</w:tblPr>
      	<w:tblGrid>
      		<w:gridCol w:w="2000"/> <w:gridCol w:w="2000"/> <w:gridCol w:w="2000"/> <w:gridCol w:w="4000"/> 
      	</w:tblGrid>
      	<w:tr>
      		<w:tc>
      			<w:tcPr>
      				<w:tcBorders>
      					<w:bottom w:val="single"/> 
      				</w:tcBorders>
      				<w:vAlign w:val="bottom"/> 
      			</w:tcPr>
      			<w:p>
      				<w:pPr>
      					<w:pStyle w:val="Compact"/> <w:jc w:val="left"/> 
      				</w:pPr>
      				<w:r>
      					<w:t xml:space="preserve">Question</w:t>
      				</w:r>
      			</w:p>
      		</w:tc>
      		<w:tc>
      			<w:tcPr>
      				<w:tcBorders>
      					<w:bottom w:val="single"/> 
      				</w:tcBorders>
      				<w:vAlign w:val="bottom"/> 
      			</w:tcPr>
      			<w:p>
      				<w:pPr>
      					<w:pStyle w:val="Compact"/> <w:jc w:val="left"/> 
      				</w:pPr>
      				<w:r>
      					<w:t xml:space="preserve">MEWB No.</w:t>
      				</w:r>
      			</w:p>
      		</w:tc>
      		<w:tc>
      			<w:tcPr>
      				<w:tcBorders>
      					<w:bottom w:val="single"/> 
      				</w:tcBorders>
      				<w:vAlign w:val="bottom"/> 
      			</w:tcPr>
      			<w:p>
      				<w:pPr>
      					<w:pStyle w:val="Compact"/> <w:jc w:val="left"/> 
      				</w:pPr>
      				<w:r>
      					<w:t xml:space="preserve">Answer</w:t>
      				</w:r>
      			</w:p>
      		</w:tc>
      		<w:tc>
      			<w:tcPr>
      				<w:tcBorders>
      					<w:bottom w:val="single"/> 
      				</w:tcBorders>
      				<w:vAlign w:val="bottom"/> 
      			</w:tcPr>
      			<w:p>
      				<w:pPr>
      					<w:pStyle w:val="Compact"/> <w:jc w:val="left"/> 
      				</w:pPr>
      				<w:r>
      					<w:t xml:space="preserve">Illustration</w:t>
      				</w:r>
      			</w:p>
      		</w:tc>
      	</w:tr>
      <w:tr>
                <w:tc>
                   <w:p>
                      <w:pPr>
                         <w:pStyle w:val="Compact"/>
                         <w:jc w:val="left"/>
                      </w:pPr>
                      <w:r>
                         <w:t xml:space="preserve">1.</w:t>
                      </w:r>
                   </w:p>
                </w:tc>
                <w:tc>
                   <w:p>
                      <w:pPr>
                         <w:pStyle w:val="Compact"/>
                         <w:jc w:val="left"/>
                      </w:pPr>
                      <w:r>
                         <w:t xml:space="preserve">1.</w:t>
                      </w:r>
                   </w:p>
                </w:tc>
                <w:tc>
                   <w:p>
                      <w:pPr>
                         <w:pStyle w:val="Compact"/>
                         <w:jc w:val="left"/>
                      </w:pPr>
                      <w:r>
                         <w:t xml:space="preserve">d</w:t>
                      </w:r>
                   </w:p>
                </w:tc>
                <w:tc>
                   <w:p>
                      <w:pPr>
                         <w:pStyle w:val="Compact"/>
                         <w:jc w:val="left"/>
                      </w:pPr>
                      <w:r>
                         <w:t xml:space="preserve">GS-0012</w:t>
                      </w:r>
                   </w:p>
                </w:tc>
             </w:tr>
      </w:tbl>
      <w:p>
      	<w:pPr>
      		<w:sectPr>
      			<w:headerReference w:type="default" r:id="rId8"/> <w:footerReference w:type="default" r:id="rId9"/> <w:pgNumType w:start="1"/> 
      		</w:sectPr>
      	</w:pPr>
      </w:p>
    XML
    doc = DOCXFormatter::Word_document_part.new(exam)
    assert_equal result, doc.answer_key(exam).to_s
  end

  def test_docx_header_part
    result = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <w:hdr xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mo="http://schemas.microsoft.com/office/mac/office/2008/main" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:mv="urn:schemas-microsoft-com:mac:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" mc:Ignorable="w14 wp14">
        <w:p>
          <w:pPr>
            <w:pStyle w:val="Header"/>
            <w:rPr>
              <w:rtl w:val="0"/>
            </w:rPr>
          </w:pPr>
          <w:r>
            <w:rPr>
              <w:rFonts w:ascii="Cambria" w:cs="Arial Unicode MS" w:hAnsi="Arial Unicode MS" w:eastAsia="Arial Unicode MS"/>
              <w:rtl w:val="0"/>
            </w:rPr>
            <w:t/>
            <w:tab/>
            <w:tab/>
            <w:t>Name_____________</w:t>
          </w:r>
        </w:p>
        <w:p>
          <w:pPr>
            <w:pStyle w:val="Header"/>
          </w:pPr>
          <w:r>
            <w:rPr>
              <w:rFonts w:ascii="Cambria" w:cs="Arial Unicode MS" w:hAnsi="Arial Unicode MS" w:eastAsia="Arial Unicode MS"/>
              <w:rtl w:val="0"/>
            </w:rPr>
            <w:t/>
            <w:tab/>
            <w:tab/>
            <w:t>Jan 16, 2019</w:t>
          </w:r>
        </w:p>
      </w:hdr>
    XML
    assert_equal result, DOCXFormatter::Header_part.new(@exam).to_s
  end

  def test_docx_rels_part
    result = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId3" Type="http://schemas.microsoft.com/office/2007/relationships/stylesWithEffects" Target="stylesWithEffects.xml"/>
        <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
        <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/webSettings" Target="webSettings.xml"/>
        <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes" Target="footnotes.xml"/>
        <Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes" Target="endnotes.xml"/>
        <Relationship Id="rId8" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
        <Relationship Id="rId9" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
        <Relationship Id="rId10" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
        <Relationship Id="rId11" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        <Relationship Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Id="GS-0113" Target="media/GS-0113.png"/>
        <Relationship Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Id="GS-0160" Target="media/GS-0160.png"/>
        <Relationship Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Id="GS-0177" Target="media/GS-0177.png"/>
      </Relationships>
    XML
    assert_equal result, DOCXFormatter::Word_document_rels_part.new(@exam).to_s
  end

  def test_docx_content_types_part
    result = <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="xml" ContentType="application/xml"/>
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
        <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
        <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
        <Override PartName="/word/stylesWithEffects.xml" ContentType="application/vnd.ms-word.stylesWithEffects+xml"/>
        <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
        <Override PartName="/word/webSettings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml"/>
        <Override PartName="/word/footnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"/>
        <Override PartName="/word/endnotes.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"/>
        <Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
        <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
        <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
        <Override PartName="/word/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
        <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
        <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
        <Override PartName="/word/media/GS-0113.png" ContentType="image/png"/>
        <Override PartName="/word/media/GS-0160.png" ContentType="image/png"/>
        <Override PartName="/word/media/GS-0177.png" ContentType="image/png"/>
      </Types>
    XML
    assert_equal result, DOCXFormatter::Content_types_part.new(@exam).to_s
  end
end
