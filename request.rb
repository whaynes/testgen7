#!/usr/bin/ruby
# frozen_string_literal: true

require 'sanitize'
require 'cgi'
require 'sqlite3'
require 'nokogiri'
require 'pp'
require 'zip'
require 'rmagick'

require_relative 'Formatters'
require_relative 'Question'

class Request
  DOCUMENT_ROOT = '/Library/WebServer/Documents/'
  PATH_TO_CSS = '/sieve/css/exam.css'
  PATH_TO_IMAGES = '/mewb7/illustrations/fullsize/'
  PATH_TO_XML = 'questions/MEWB7.xml'
  PATH_TO_MARKDOWN_XSLT = 'xsl/fmp2md.xsl'

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
      raise "Unsupported type of exam: #{format}"
    end
  end
end

class TestGenerator
  def self.generate(exam)
    Formatter.for(exam.format).make(exam)
  end
end
