class Formula
  
  MASS = {:C => 12.0,
          :H => 1.00783,
          :N => 14.00307,
          :O => 15.99491,
          :P => 30.97376,
          :S => 31.97207,
          :F => 18.9984,
          :Cl => 34.96885,
          :Se => 79.9165213,
          :e => 0.00055}
  
  def initialize(formula='C0')
    @formula = Formula.formula_as_hash(formula)
  end
  
  def as_string
    Formula.formula_as_string(@formula)
  end
  
  def as_hash
    @formula.clone
  end
  
  def mass
    mass = 0
    @formula.each { |element, count| mass += MASS[element]*count }
    mass
  end
  
  def add!(formula)
    formula = Formula.formula_as_hash(formula)
    formula.each do |element, count|
      @formula[element] += count
    end
    return self
  end
  
  def subtract!(formula)
    formula = Formula.formula_as_hash(formula)
    formula.each do |element, count|
      @formula[element] -= count
      @formula.delete(element) if @formula[element] == 0
    end
    return self
  end
  
  def multiply!(number)
    @formula.each_key do |element|
      @formula[element] *= number
    end
  end
  
  def self.formula_as_string(formula)
    if formula.is_a?(self)
      formula.as_string 
    elsif formula.is_a?({}.class)
      Formula.hash_to_string(formula)
    elsif formula.is_a?("".class)
      formula.clone
    end
  end
  
  def self.formula_as_hash(formula)
    if formula.is_a?(self)
      formula.as_hash
    elsif formula.is_a?("".class)
      Formula.string_to_hash(formula)
    elsif formula.is_a?({}.class)
      formula.clone
    end
  end
  
  def self.hash_to_string(formula_hash)
    formula_string = ""
    formula_hash.each do |element, count|
      if count == 1
        formula_string << element.to_s
      elsif count > 0
        formula_string << element.to_s << count.to_s
      end
    end
    formula_string
  end
  
  def self.string_to_hash(formula_string)
    formula_hash = Hash.new(0)
    formula_string.scan(/([A-Z][a-z]?)(-)?([0-9]{0,4})\W*/) do |element, should_subtract, count|
      element = element.to_sym
      if MASS.has_key?(element)
        if count == ""
          formula_hash[element] += 1
        else
          change = count.to_i
          change *= -1 if should_subtract == '-'
          formula_hash[element] += change
        end
      end
    end
    formula_hash
  end
  
  def self.known_elements
    elements = []
    MASS.each_key { |element| elements << element.to_s }
    elements
  end
  
end
