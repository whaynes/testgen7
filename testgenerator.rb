#!/usr/bin/ruby
# frozen_string_literal: true

require 'sanitize'
require 'cgi'
require 'sqlite3'
require 'nokogiri'
require 'pp'
require 'zip'
require 'rmagick'

require_relative 'formatters'

DOCUMENT_ROOT = '/var/www/weh'
PATH_TO_CSS = '/mewb7/css/exam.css'
PATH_TO_IMAGES = '/mewb7/illustrations/fullsize/'
PATH_TO_XML = 'questions/MEWB7.xml'
PATH_TO_MARKDOWN_XSLT = 'xsl/fmp2md.xsl'

class Request
  attr_accessor :params, :format, :qlist, :labels, :show_answers, :show_pics, :ilist, :unique_illustrations, :alist
  def initialize(params = CGI.new.params)
    @params = params
    @format = params['format'].first.to_sym if params.key? 'format'
    raise 'You must select some questions to make an exam.' if params['qlist'] == ['']

    @qlist = params['qlist'].first.split("\n").map(&:to_i)
    @alist = @qlist.map { |q| Question.new(q)[:ans] }
    @ilist = @qlist.map { |q| Question.new(q)[:illustration] } # all illustrations used by questions, may have duplicates
    @unique_illustrations = @ilist.reject(&:empty?).uniq.sort
    @labels = params['labels'].map { |label| Sanitize.fragment(label, Sanitize::Config::RESTRICTED) }
    @show_pics = params.key? 'illustrations'
    @show_answers = params.key? 'key'
  end
end

class Formatter
  def self.for(format)
    case format
    when :form
      ParamsFormatter.new
    when :xhtml
      XHTMLFormatter.new
    when :xhtml_source
      SourceFormatter.new
    when :xml
      XMLFormatter.new
    when :mmd
      MMDFormatter.new
    when :blackboard
      BBFormatter.new
    when :docx
      DOCXFormatter.new
    else
      raise RuntimeError.new("Unsupported type of exam: #{format}")
    end
  end
end

class TestGenerator
  def self.generate(exam)
    Formatter.for(exam.format).make(exam)
  end
end

class Question
  # Reads pre-constructed question from database

  attr_reader :qnum
  QUESTIONS_DB = 'questions/mewb7.sqlite'
  VALID_FIELDS = %i[html docx ans illustration].freeze

  def initialize(qnum)
    @qnum = qnum
  end

  def [](field)
    raise 'Invalid Field.' unless VALID_FIELDS.include? field

    @db = SQLite3::Database.open(QUESTIONS_DB)
    @db.execute("SELECT #{field} FROM testdata WHERE qnum = #{@qnum}")[0][0]
  rescue SQLite3::Exception => e
    puts "SQLite Exception occurred accessing qnum: #{@qnum}"
    puts e
  ensure
    @db.close if @db
  end
end
