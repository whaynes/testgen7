# frozen_string_literal: true

require 'minitest/autorun'

class QuestionsTest < Minitest::Test
  def test_question_database_exists
    assert File.exist?(Question::QUESTIONS_DB)
  end

  def test_question_can_get_ans
    assert_includes %w[A B C D], Question.new(100)[:ans]
  end

  def test_question_can_get_html
    assert_kind_of String, Question.new(100)[:html]
  end

  def test_question_can_get_illustration
    assert_equal 'GS-0173', Question.new(1719)[:illustration]
  end

  def test_question_returns_empty_string_when_theres_no_illustration
    assert_equal '', Question.new(1000)[:illustration]
  end

  def test_question_can_get_docx
    assert_kind_of String, Question.new(100)[:docx]
  end

  def test_question_reqesting_an_invalid_field_raises_error
    assert_raises RuntimeError do
      Question.new(1000)[:bogus]
    end
  end

end
