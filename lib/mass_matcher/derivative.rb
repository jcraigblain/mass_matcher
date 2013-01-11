class Derivative < Object
  
  DERIVATIVE = {:c => {:formula => 'C0', :name => 'Cycle'},
                :o => {:formula => 'H1O-2P-1', :name => '5-OH'},
                :p => {:formula => 'H2O', :name => '5-Phosphate'},
                :i => {:formula => 'C3H4N2', :name => 'Phosphorimidazolide'},
                :m => {:formula => 'C4H6N2', :name => '5-Phosphor-methylimidazolide'},
                :e => {:formula => 'C2H6O', :name => 'Phosphorethanol'},
                :h => {:formula => 'C3H2OF6', :name => 'HFIP'},
                :t => {:formula => 'H4O7P2', :name => 'Triphosphate'},
                :d => {:formula => 'H3O4P', :name => 'Diphosphate'},
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
  def formula_as_string
    @formula.as_string
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
    DERIVATIVE.each { |derivative, info| derivatives[derivative.to_s] = info[:name] unless derivative == :x }
    derivatives
  end
  def self.known_codes
    derivatives = []
    DERIVATIVE.each_key { |code| derivatives << code.to_s }
    derivatives
  end
end