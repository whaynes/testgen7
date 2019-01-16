require 'minitest/autorun'
require_relative '../request'
#frozen_string_literal: true


class FormatTest < Minitest::Test
  def setup
    @params = [{"labels" => ['a', 'b', 'c', 'd'], "format" => ["form"], "illustrations" => ["on"], "qlist" => ["7677\r\n6560\r\n12332\r\n11643\r\n"]},
               {"labels" => ['a', 'b', 'c', 'd'], "format" => ["xhtml"], "qlist" => ["7677\r\n6560\r\n"]},
               {"labels" => ['a', 'b', 'c', 'd'], "format" => ["docx"], "key" => ["on"], "illustrations" => ["on"], "qlist" => ["2107\r\n10635\r\n"]},
               {"labels" => ['a', 'b', 'c', 'd'], "format" => ["mmd"], "key" => ["on"], "qlist" => ["2107\r\n10635\r\n"]}]
    @exam = Request.new(@params[0]).ilist
  end

  def test_format_illustrations_as_html
    result = %Q[<div id=\"pics\">\n  <h3>Illustrations</h3>\n  <figure>\n    <img src=\"/mewb7/illustrations/fullsize/GS-0173.png\" />\n    <figcaption>GS-0173</figcaption>\n  </figure>\n</div>\n]
    exam = Request.new({"labels" => ['L1', 'L2', 'L3', 'L4'], "qlist" => ["1719\r\n6560\r\n12332\r\n11643\r\n"]})
    assert_equal result, SourceFormatter.new.illustrations(exam)
  end

  def test_format_header_as_html
    result = <<-HEADER
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
    exam = Request.new({"labels" => ['L1', 'L2', 'L3', 'L4'], "qlist" => ["1719\r\n6560\r\n12332\r\n11643\r\n"]})
    assert_equal result, SourceFormatter.new.page_header(exam)
  end

  def test_format_can_find_image
    imagepath = Request::DOCUMENT_ROOT + Request::PATH_TO_IMAGES + "GS-0173.png"
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
    @exam = Request.new({"labels" => ["", "Name_____________", "", "Jan 16, 2019"],
                         "key" => ["on"],
                         "illustrations" => ["on"],
                         "qlist" =>
                             ["13609\r\n1658\r\n11853\r\n7379\r\n835\r\n395\r\n12667\r\n12108\r\n1509\r\n2664\r\n"],
                         "Make_Exam" => ["Make Exam"],
                         "format" => ["docx"]})
  end

  def test_format_as_docx
    #this test just creates an exam - no assertion about it
    TestGenerator.generate(@exam)
  end

  def test_docx_answerkey_part
    result = <<~XML
      <?xml version="1.0"?>
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <w:body>
          <w:tbl>
            <w:tblPr>
              <w:tblStyle w:val="TableNormal"/>
              <w:tblW w:type="pct" w:w="0"/>
            </w:tblPr>
            <w:tblGrid>
              <w:gridCol w:w="2000"/>
              <w:gridCol w:w="2000"/>
              <w:gridCol w:w="2000"/>
              <w:gridCol w:w="4000"/>
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
                    <w:pStyle w:val="Compact"/>
                    <w:jc w:val="left"/>
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
                    <w:pStyle w:val="Compact"/>
                    <w:jc w:val="left"/>
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
                    <w:pStyle w:val="Compact"/>
                    <w:jc w:val="left"/>
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
                    <w:pStyle w:val="Compact"/>
                    <w:jc w:val="left"/>
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
                    <w:t xml:space="preserve">13609.</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">2.</w:t>
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
                    <w:t xml:space="preserve">1658.</w:t>
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
                    <w:t xml:space="preserve">b</w:t>
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
                    <w:t xml:space="preserve">GS-0113</w:t>
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
                    <w:t xml:space="preserve">3.</w:t>
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
                    <w:t xml:space="preserve">11853.</w:t>
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
                    <w:t xml:space="preserve">c</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">4.</w:t>
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
                    <w:t xml:space="preserve">7379.</w:t>
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
                    <w:t xml:space="preserve">b</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">5.</w:t>
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
                    <w:t xml:space="preserve">835.</w:t>
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
                    <w:t xml:space="preserve">b</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">6.</w:t>
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
                    <w:t xml:space="preserve">395.</w:t>
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
                    <w:t xml:space="preserve">a</w:t>
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
                    <w:t xml:space="preserve">GS-0177</w:t>
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
                    <w:t xml:space="preserve">7.</w:t>
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
                    <w:t xml:space="preserve">12667.</w:t>
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
                    <w:t xml:space="preserve">c</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">8.</w:t>
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
                    <w:t xml:space="preserve">12108.</w:t>
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
                    <w:t xml:space="preserve">a</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">9.</w:t>
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
                    <w:t xml:space="preserve">1509.</w:t>
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
                    <w:t xml:space="preserve">c</w:t>
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
                    <w:t xml:space="preserve"/>
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
                    <w:t xml:space="preserve">10.</w:t>
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
                    <w:t xml:space="preserve">2664.</w:t>
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
                    <w:t xml:space="preserve">b</w:t>
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
                    <w:t xml:space="preserve">GS-0160</w:t>
                  </w:r>
                </w:p>
              </w:tc>
            </w:tr>
          </w:tbl>
          <w:p>
            <w:pPr>
              <w:sectPr>
                <w:headerReference w:type="default" r:id="rId8"/>
                <w:footerReference w:type="default" r:id="rId9"/>
                <w:pgNumType w:start="1"/>
              </w:sectPr>
            </w:pPr>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">You are in the planning stages of making up a portable cord for use on a ship with 110 VAC, 220 VAC, and 110 VDC outlets. According to 46 CFR, Subchapter J (Electrical Engineering), what statement is true concerning receptacle outlets?</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Each receptacle type may use the same plug configuration, but care must be exercised in plugging in cords.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">The 110 VAC and 220 VAC outlets may have the same plug configuration, whereas the 110 VDC outlets must be different to preclude plugging a cord into an outlet of incompatible power type.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">The 110 VAC and 110 VDC outlets may have the same plug configuration, whereas the 220 VAC outlets must be different to preclude plugging a cord into an outlet of incompatible voltage.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Each receptacle type must have a different plug configuration to preclude plugging a cord into an outlet of incompatible voltage or type of power.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">What will cause the throughput of the oily-water separator shown in the illustration to decrease when operating in the processing mode?</w:t>
            </w:r>
            <w:r>
              <w:t xml:space="preserve"/>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">See illustration</w:t>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve"/>
            </w:r>
            <w:r>
              <w:rPr>
                <w:rStyle w:val="Link"/>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">GS-0113</w:t>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">The flow control valve 'V-3' is open excessively wide and permitting an excessive amount of bilge water to enter the separator, resulting in an overload.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">A decrease in the processing ability may be caused by worn pump internals.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">The throughput of the separator may be reduced if the inlet valve 'V-4' remains open during processing mode.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">The throughput of the separator varies while in the processing mode as determined by the quantity of oil in the emulsion.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">What will happen to a copper wire when the current flow through the wire increases in value?</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">resistance will decrease</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">insulation will burn</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">temperature will increase</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">conductivity will increase</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">The primary operational difference between a huddling chamber type safety valve and a nozzle reaction type safety valve is the __________.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">manner in which steam pressure causes initial valve opening</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">principle by which blow down is accomplished</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">difference in valve relieving capacities</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">manner in which lifting pressure is adjusted</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">When comparing gate valves to globe valves, gate valves __________.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">are more effective at throttling flow.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">require more force to open against large differential pressures.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">produce a larger pressure decrease when fully open.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">are more effective as pressure regulating valves.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">According to the illustration, what would be the value of dimension "H" for a screw thread identified as 3/4-13 NF.</w:t>
            </w:r>
            <w:r>
              <w:t xml:space="preserve"/>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">See illustration</w:t>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve"/>
            </w:r>
            <w:r>
              <w:rPr>
                <w:rStyle w:val="Link"/>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">GS-0177</w:t>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">0.077 inches</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">0.133 inches</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">0.255 inches</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">0.333 inches</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">By what means is the voltage output of an AC generator accurately controlled?</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">changing the sensitivity of the prime mover to large changes in voltage</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">varying the reluctance of the air gap</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">varying the DC exciter voltage</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">shorting out part of the armature windings</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Which of the following statements describes the effects of ambient temperature on local action within lead-acid storage batteries?</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Increasing ambient temperature increases local action.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Increasing ambient temperature decreases local action.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Ambient temperature has no effect on local action.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">At 90&#xB0;F all local action virtually ceases.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Which of the following systems can be supplied by the auxiliary exhaust system?</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Main feed pump</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">High pressure evaporator</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Boiler air heaters</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">Boiler steam atomizers</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-stem"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">In the hydraulic anchor windlass system illustrated, replenishment pump fluid flow is provided to the main system for automatic replenishment and to __________.</w:t>
            </w:r>
            <w:r>
              <w:t xml:space="preserve"/>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">See illustration</w:t>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve"/>
            </w:r>
            <w:r>
              <w:rPr>
                <w:rStyle w:val="Link"/>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">GS-0160</w:t>
            </w:r>
            <w:r>
              <w:rPr>
                <w:i/>
              </w:rPr>
              <w:t xml:space="preserve">.</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">release the spring brake</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">provide actuating fluid flow to the horsepower torque limiter</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">shift valve "L" to line up the fluid motor relief valve</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="mewb-abcd"/>
              <w:keepNext w:val="0"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">move stored oil across the indicated filter to maintain the oil in a water free condition</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="Heading3"/>
            </w:pPr>
            <w:bookmarkStart w:id="26" w:name="pics"/>
            <w:bookmarkEnd w:id="26"/>
            <w:r>
              <w:t xml:space="preserve">Illustrations</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:jc w:val="center"/>
            </w:pPr>
            <w:r>
              <w:drawing>
                <wp:inline>
                  <wp:extent cx="5486400" cy="7603957"/>
                  <wp:docPr id="1" name="GS-0113.png"/>
                  <a:graphic>
                    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                      <pic:pic>
                        <pic:nvPicPr>
                          <pic:cNvPr id="1" name="GS-0113.png"/>
                          <pic:cNvPicPr>
                            <a:picLocks noChangeArrowheads="1" noChangeAspect="1"/>
                          </pic:cNvPicPr>
                        </pic:nvPicPr>
                        <pic:blipFill>
                          <a:blip r:embed="GS-0113"/>
                          <a:stretch>
                            <a:fillRect/>
                          </a:stretch>
                        </pic:blipFill>
                        <pic:spPr bwMode="auto">
                          <a:xfrm>
                            <a:off x="0" y="0"/>
                            <a:ext cx="5486400" cy="7603957"/>
                          </a:xfrm>
                          <a:prstGeom prst="rect">
                            <a:avLst/>
                          </a:prstGeom>
                          <a:noFill/>
                          <a:ln w="9525">
                            <a:noFill/>
                            <a:headEnd/>
                            <a:tailEnd/>
                          </a:ln>
                        </pic:spPr>
                      </pic:pic>
                    </a:graphicData>
                  </a:graphic>
                </wp:inline>
              </w:drawing>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="ImageCaption"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">GS-0113</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:jc w:val="center"/>
            </w:pPr>
            <w:r>
              <w:drawing>
                <wp:inline>
                  <wp:extent cx="5486400" cy="5779008"/>
                  <wp:docPr id="1" name="GS-0160.png"/>
                  <a:graphic>
                    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                      <pic:pic>
                        <pic:nvPicPr>
                          <pic:cNvPr id="1" name="GS-0160.png"/>
                          <pic:cNvPicPr>
                            <a:picLocks noChangeArrowheads="1" noChangeAspect="1"/>
                          </pic:cNvPicPr>
                        </pic:nvPicPr>
                        <pic:blipFill>
                          <a:blip r:embed="GS-0160"/>
                          <a:stretch>
                            <a:fillRect/>
                          </a:stretch>
                        </pic:blipFill>
                        <pic:spPr bwMode="auto">
                          <a:xfrm>
                            <a:off x="0" y="0"/>
                            <a:ext cx="5486400" cy="5779008"/>
                          </a:xfrm>
                          <a:prstGeom prst="rect">
                            <a:avLst/>
                          </a:prstGeom>
                          <a:noFill/>
                          <a:ln w="9525">
                            <a:noFill/>
                            <a:headEnd/>
                            <a:tailEnd/>
                          </a:ln>
                        </pic:spPr>
                      </pic:pic>
                    </a:graphicData>
                  </a:graphic>
                </wp:inline>
              </w:drawing>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="ImageCaption"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">GS-0160</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:jc w:val="center"/>
            </w:pPr>
            <w:r>
              <w:drawing>
                <wp:inline>
                  <wp:extent cx="5486400" cy="5333723"/>
                  <wp:docPr id="1" name="GS-0177.png"/>
                  <a:graphic>
                    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                      <pic:pic>
                        <pic:nvPicPr>
                          <pic:cNvPr id="1" name="GS-0177.png"/>
                          <pic:cNvPicPr>
                            <a:picLocks noChangeArrowheads="1" noChangeAspect="1"/>
                          </pic:cNvPicPr>
                        </pic:nvPicPr>
                        <pic:blipFill>
                          <a:blip r:embed="GS-0177"/>
                          <a:stretch>
                            <a:fillRect/>
                          </a:stretch>
                        </pic:blipFill>
                        <pic:spPr bwMode="auto">
                          <a:xfrm>
                            <a:off x="0" y="0"/>
                            <a:ext cx="5486400" cy="5333723"/>
                          </a:xfrm>
                          <a:prstGeom prst="rect">
                            <a:avLst/>
                          </a:prstGeom>
                          <a:noFill/>
                          <a:ln w="9525">
                            <a:noFill/>
                            <a:headEnd/>
                            <a:tailEnd/>
                          </a:ln>
                        </pic:spPr>
                      </pic:pic>
                    </a:graphicData>
                  </a:graphic>
                </wp:inline>
              </w:drawing>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr>
              <w:pStyle w:val="ImageCaption"/>
            </w:pPr>
            <w:r>
              <w:t xml:space="preserve">GS-0177</w:t>
            </w:r>
          </w:p>
          <w:sectPr>
            <w:headerReference w:type="default" r:id="rId8"/>
            <w:footerReference w:type="default" r:id="rId9"/>
            <w:type w:val="nextPage"/>
            <w:pgSz w:h="15840" w:w="12240"/>
            <w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:header="720" w:footer="720" w:gutter="0"/>
            <w:pgNumType w:start="1"/>
            <w:cols w:space="720"/>
          </w:sectPr>
        </w:body>
      </w:document>
    XML
    assert_equal result, DOCXFormatter::Word_document_part.new(@exam).to_s
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
    puts DOCXFormatter::Header_part.new(@exam).to_xml
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
    assert_equal result, DOCXFormatter::Word_document_rels_part.new(@exam).to_xml
    puts DOCXFormatter::Word_document_rels_part.new(@exam).to_xml
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
    assert_equal result, DOCXFormatter::Content_types_part.new(@exam).to_xml
  end
end