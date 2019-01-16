require 'sqlite3'

class Question
  attr_reader :qnum
  QUESTIONS_DB = 'questions/mewb7.sqlite'
  VALID_FIELDS = [:html, :docx, :ans, :illustration]

  def initialize (qnum)
    @qnum = qnum
  end

  def [](field)
    raise "Invalid Field." unless VALID_FIELDS.include? field
    @db = SQLite3::Database.new(QUESTIONS_DB)
    return @db.execute("SELECT #{field} FROM testdata WHERE qnum = #{@qnum}")[0][0]
  rescue SQLite3::Exception => e
    puts "SQLite Exception occurred accessing qnum: #{@qnum}"
    puts e
  ensure
    @db.close if @db
  end
end

