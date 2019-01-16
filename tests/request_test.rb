require 'minitest/autorun'
require_relative '../request'
#frozen_string_literal: true

# pass some params to Request to debug.  If no parameter passed, this will look for params from cgi, or from command line


class RequestTest < Minitest::Test

  def setup
    # params are various cgi parameters for testing purposes
    @params = [{"labels" => ['La<>', 'Lb', 'Lc', '<a>foo</a><div>bar</div>baz'], "format" => ["form"], "illustrations" => ["on"], "qlist" => ["1719\r\n6560\r\n12332\r\n11643\r\n"]},
               {"labels" => ['Ma', 'Mb', 'Mc', 'Md'], "format" => ["xhtml"], "qlist" => ["7677\r\n6560\r\n"]},
               {"labels" => ['a', 'b', 'c', 'd'], "format" => ["docx"], "key" => ["on"], "illustrations" => ["on"], "qlist" => ["2107\r\n10635\r\n"]},
               {"labels" => ['a', 'b', 'c', 'd'], "format" => ["mmd"], "key" => ["on"], "qlist" => ["2107\r\n10635\r\n"]}]
    @exam = Request.new(@params[0])
  end

  def test_request_can_create_a_exam
    refute_nil Request.new(@params[1])
  end

  def test_request_with_empty_qlist_raises_error
    assert_raises RuntimeError do
      Request.new({'labels' => [], 'qlist' => [""]})
    end
  end

  def test_request_qlist_is_array_of_int
    assert_kind_of Array, @exam.qlist
    assert_kind_of Integer, @exam.qlist[0]
  end

  def test_request_labels_is_array_of_4_string
    labels = @exam.labels
    assert_kind_of Array, labels
    assert_equal 4, labels.length
    assert_equal true, labels.all? {|l| l.kind_of? String}

  end

  def test_request_show_pics_is_boolean
    assert_includes [true, false], @exam.show_pics
  end

  def test_request_show_answers_is_boolean
    assert_includes [true, false], @exam.show_answers
  end

  def test_request_ilist_is_an_array
    assert_equal ["GS-0173", "", "", ""], @exam.ilist
  end

  def test_request_labels_get_sanitized
    r = Request.new({'labels' => ["<a>href</a>", "<div><<<", "<br>", "&"], 'qlist' => ["1"]})
    assert_equal ["href", " &lt;&lt;&lt; ", " ", "&amp;"], r.labels
  end
end

