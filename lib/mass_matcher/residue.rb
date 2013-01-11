class Residue
  SUGAR = { :n => {:formula => 'C5H9NO4P', :name => 'amino-dideoxyribo'},
            :r => {:formula => 'C5H8O6P', :name => 'ribo'},
            :d => {:formula => 'C5H8O5P', :name => 'deoxyribo'},
            :t => {:formula => 'C4H6O5P', :name => 'threo'},
            :m => {:formula => 'C4H7NO4P', :name => 'amino-deoxyribo'},
            :s => {:formula => 'C6H10O6P', :name => 'O-methylribo'}}
              
  BASE = {  :G => {:formula => 'C5H4N5O', :name => 'guanine'},
            :C => {:formula => 'C4H4N3O', :name => 'cytosine'},
            :A => {:formula => 'C5H4N5', :name => 'adenine'},
            :T => {:formula => 'C5H5N2O2', :name => 'thymine'},
            :U => {:formula => 'C4H3N2O2', :name => 'uracil'},
            :D => {:formula => 'C5H5N6', :name => 'diaminopurine'},
            :P => {:formula => 'C7H5N2O2', :name => 'propynyluracil'},
            :I => {:formula => 'C5H3N4O', :name => 'inosine'},
            :S => {:formula => 'C4H3N2OS', :name => '2-thiouracil'},
            :R => {:formula => 'C5H5N2OS', :name => '2-thiothymine'}}
            
  def initialize(sugar, base)
    @sugar = sugar.to_sym
    @base = base.to_sym
    
    @formula = Formula.new(SUGAR[@sugar][:formula]).add!(BASE[@base][:formula])
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
  def code
    "#{@sugar.to_s}#{@base.to_s}"
  end
  def name
    "#{SUGAR[@sugar][:name]}-#{BASE[@base][:name]}"
  end
  def base_sym
    @base
  end
  
  def self.known_sugars
    sugars = {}
    SUGAR.each { |sugar, info| sugars[sugar.to_s] = info[:name] }
    sugars
  end
  def self.known_bases
    bases = {}
    BASE.each { |base, info| bases[base.to_s] = info[:name] }
    bases
  end
  def self.known_codes
    residues = []
    SUGAR.each_key do |sugar|
      BASE.each_key do |base|
        residues << "#{sugar}#{base}"
      end
    end
    residues
  end
  def self.known_base_codes
    bases = []
    BASE.each_key { |base| bases << base.to_s }
    bases
  end
  
end