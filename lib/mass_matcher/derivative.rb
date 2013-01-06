require ('./lib/mass_matcher/formula')

class Derivative < Object
  
  DERIVATIVE = {:c => {:formula => 'C0', :name => 'cycle'},
                :o => {:formula => 'H1O-2P-1', :name => '5-OH'},
                :p => {:formula => 'H2O', :name => '5-phosphate'},
                :i => {:formula => 'C3H4N2', :name => 'phosphorimidazolide'},
                :m => {:formula => 'C4H6N2', :name => '5-phosphor-methylimidazolide'},
                :e => {:formula => 'C2H6O', :name => 'phosphorethanol'},
                :h => {:formula => 'C3H2OF6', :name => 'HFIP'},
                :t => {:formula => 'H4O7P2', :name => 'triphosphate'},
                :d => {:formula => 'H3O4P', :name => 'diphosphate'},
                :y => {:formula => 'C29H36N2O2', :name => 'Cy3'},
                :z => {:formula => 'C31H38N2O2', :name => 'Cy5'},
                :x => {:formula => '', :name => 'Custom'}
                }
  
  def initialize(derivative, formula='')
    @derivative = derivative.to_sym
    if @derivative == :x
      @formula = Formula.new(formula)
    else
      @formula = Formula.new(DERIVATIVE[@derivative][:formula])
    end
  end
  
  def formula
    @formula.clone
  end
  def mass
    @formula.mass
  end
  def code
    @derivative.to_s
  end
  def name
    DERIVATIVE[@derivative][:name]
  end
  
  def self.known_derivatives
    derivatives = {}
    DERIVATIVE.each { |derivative, info| derivatives[derivative.to_s] = info[:name] }
    derivatives
  end
  def self.known_codes
    derivatives = []
    DERIVATIVE.each_key { |code| derivatives << code.to_s }
    derivatives
  end
end