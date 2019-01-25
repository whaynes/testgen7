#!/usr/bin/ruby
# frozen_string_literal: true

require_relative 'testgenerator'

begin
  params = {'labels' => ['mmd request', 'Name_____________', '', 'Jan 05, 2019'], '_num' => ['10'], '_start' => ['1'], '_end' => ['14427'], 'format' => ['mmd'], 'key' => ['on'], 'qlist' => ["2107\r\n10635\r\n11112\r\n7147\r\n"], 'Make_Exam' => ['Make Exam']}
  exam = Request.new # pass params to debug.
  TestGenerator.generate(exam)
rescue StandardError => e
  ErrorFormatter.new.make(e)
end
