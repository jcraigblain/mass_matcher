require('./lib/mass_matcher/formula')
require('./lib/mass_matcher/residue')
require('./lib/mass_matcher/derivative')

class OligoSeq
  
  def initialize(residue_array, derivative)
    @residue_array = residue_array
    @derivative = derivative
    
    @formula = Formula.new(@derivative.formula)
    @residue_array.each do |residue|
      @formula.add!(residue.formula)
    end
    
  end
  
  def mass
    @formula.mass
  end
  def formula
    @formula.clone
  end
  def formula_string
    @formula.as_string
  end
  def name
    name = "#{@derivative.code}-"
    @residue_array.each do |residue|
      name += residue.code
    end
    name
  end
  def length
    @residue_array.length
  end
  def derivative
    @derivative.clone
  end
  def derivative_code
    @derivative.code
  end
  
  def all_fragment_basecomps
    fragment_basecomps = []
    1.upto(@residue_array.length) do |length|
      0.upto(@residue_array.length - length) do |start_base|
        fragment_hash = Hash.new(0)
        @residue_array[start_base,length].each do |residue|
          fragment_hash[residue.base_sym] += 1
        end
        fragment_basecomps << fragment_hash unless fragment_basecomps.include?(fragment_hash)
      end
    end
    fragment_basecomps
  end
  
end