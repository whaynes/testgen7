#!/usr/bin/ruby

require_relative 'testgenerator'

# Testgenerator rewrite January 2019
# ++++++++++++++++++++++++++++++++++
# this is the main starting point for the cgi call.
# The work is done by the Request and TestGenerator Classes, in separate files.
# It will recieve the CGI parameters from the calling web page.
#
# To debug, pass variable 'params' below to Request.new(params) to simulate a CGI Call.
# Calling page has hidden parameters which when called
# The test folder contains functional tests
#
# When moved to a different serve, update paths in testgenerator.rb

begin
  params = {'labels' => ['DUMMY PARAMETERS', 'Name_____________', '', 'Jan 05, 2019'], '_num' => ['10'], '_start' => ['1'], '_end' => ['14427'], 'format' => ['docx'], 'key' => ['on'], 'qlist' => ["2107\r\n10635\r\n11112\r\n7147\r\n"], 'Make_Exam' => ['Make Exam']}
  exam = Request.new() # pass params to debug.
  TestGenerator.generate(exam)
rescue StandardError => e
  ErrorFormatter.new.make(e)
end
