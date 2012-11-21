require('./lib/mass_matcher/residue')
require('./lib/mass_matcher/derivative')
require('./lib/mass_matcher/formula')

class OligoComp
  
  def initialize(residue_hash, derivative)
    @residue_hash = residue_hash ## {residue => count}
    @derivative = derivative
    
    @formula = Formula.new(@derivative.formula)
    @residue_hash.each { |residue, count| @formula.add!(Formula.new(residue.formula).multiply!(count)) }
  end
  
  def formula
    @formula.clone
  end
  def formula_string
    @formula.as_string
  end
  def mass
    @formula.mass
  end
  def derivative_code
    @derivative.code
  end
  def length
    length = 0
    @residue_hash.each_value { |count| length += count }
    length
  end
  def name
    name = "#{@derivative.code}-"
    @residue_hash.each do |residue, count|
      name += "#{residue.code}#{count.to_s}"
    end
    name
  end
  
  def basecomp_hash
    basecomp_hash = Hash.new(0)
    @residue_hash.each do |residue, count|
      basecomp_hash[residue.base_sym] += count unless count == 0
    end
    basecomp_hash
  end
  def [](residue)
    @residue_hash[residue]
  end
    
end