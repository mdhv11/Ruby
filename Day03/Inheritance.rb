class User
  attr_accessor :name

  def initialize(name)
    @Name = name
  end

end

class Teacher < User

  KNOWLEDGE = []