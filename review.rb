
class Review
  attr_reader :body, :rating, :user, :date, :url, :qtype_id
  
  # def initialize
  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end unless args.nil?
  end

  def to_s
    "[#{user}@#{date}] writes \"#{body.delete('\n').delete('\t').squeeze(" ")}\"\n--"
  end

  def to_hash
    h = Hash.new
    instance_variables.each do |var|
      h[var.to_s.delete("@").to_sym] = instance_variable_get(var)
    end
    h
  end

  def in_db?
    Sequel.sqlite(DB_FILE)[:reviews].where(to_hash).reverse.first != nil
  end

end

