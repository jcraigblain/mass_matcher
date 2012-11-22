require('./lib/mass_matcher/residue')
require('./lib/mass_matcher/derivative')
require('./lib/mass_matcher/residue')
require('./lib/mass_matcher/oligo_seq')

class MassMatcherInput
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_reader :errors
  attr_accessor :minimum_length, :maximum_length, :maximum_error, :product_sequence, :derivatives, :residues, :input_file
  
  validate :derivatives_valid, :residues_valid, :min_len_less_than_max_len, :product_sequence_valid, :residue_count_valid, :input_file_valid
  validates :minimum_length, :presence => true, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => MAXIMUM_LENGTH}
  validates :maximum_length, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => MAXIMUM_LENGTH}
  validates :maximum_error, :presence => true, :numericality => { :greater_than => 0, :less_than_or_equal_to => MAXIMUM_PPM }

  def initialize(attributes = {})
    @errors = ActiveModel::Errors.new(self)
    
    @minimum_length = attributes[:min_len].to_i
    @maximum_length = attributes[:max_len].to_i
    @maximum_error = attributes[:max_ppm].to_r
    @residues = attributes[:residues]
    @derivatives = attributes[:derivatives]
    @product_sequence = attributes[:product_seq].upcase.gsub(/\W/,'')
    @input_file = attributes[:input_data]
    
    unless @input_file.nil?
      @file_data = @input_file.read
      if @file_data =~ /\r\n/
        @file_data = @file_data.split("\r\n")
      else
        @file_data = @file_data.split("\n")
      end
      @input_header = @file_data.shift
    end
  end
  
  def persisted?
    false
  end
    
  def derivatives_valid
    errors.add(:derivatives, "not valid") unless @derivatives == @derivatives & Derivative.known_codes
  end
  def residues_valid
    errors.add(:residues, "not valid") unless @residues == @residues & Residue.known_codes
  end
  def min_len_less_than_max_len
    errors.add(:minimum_length, "must be less than or equal to maximum length") unless @minimum_length <= @maximum_length
  end
  def residue_count_valid
    errors.add(:residues, "cannot exceed 5 in count") unless @residues.length <= MAXIMUM_RESIDUES
  end
  def input_file_valid
    if @input_file.nil?
      errors.add(:input_file, "must be provided")
    elsif !@input_header.match(/\tMass\t/) || @input_header.empty? || @file_data.empty?
      errors.add(:input_file, "must have a 'Mass' header and at least one row of data")
    end
  end
  def product_sequence_valid
    error = false
    acceptable_bases = Residue.known_base_codes
    @product_sequence.split('').each { |base| error = true if !acceptable_bases.include?(base) }
    errors.add(:product_sequence, "contains invalid bases") if error 
  end
  
  def process
    
    residues = []
    @residues.each do |residue_code|
      residue_code.scan(/([a-z]+)([A-Z]+)/) do |sugar, base|
        residues << Residue.new(sugar,base)
      end
    end
    
    derivatives = []
    @derivatives.each do |derivative_code|
      derivatives << Derivative.new(derivative_code)
    end
    
    oligo_set = OligoCompSet.new(@minimum_length,@maximum_length,residues,derivatives)
    
    mass_index = @input_header.split("\t").index("Mass")
    
    unless @product_sequence.empty?
      product = true
      residue_array = []
      base_array = @product_sequence.split('')
      base_array.each { |base| residue_array << Residue.new('r', base) }
      fragcomps_array = OligoSeq.new(residue_array, Derivative.new('p')).all_fragment_basecomps
    end
    
    header = @input_header.split(/\t/)
    header << "Length"
    header << "Derivative"
    @residues.each do |residue|
      header << residue
    end
    header << 'Formula'
    header << 'Exp Mass'
    header << 'Error'
    header << 'Match' if @match
    
    output = []
    @file_data.each do |row|
      row = row.split("\t")
      oligo_set.each do |oligo|
        error = 1000000*(((oligo.mass - row[mass_index].to_r)/oligo.mass).abs)
        if error < @maximum_error
          match = Array.new(row)
          match << oligo.length
          match << oligo.derivative_code
          residues.each do |residue|
            match << oligo[residue]
          end
          match << oligo.formula_string << oligo.mass.round(4) << error.round(2)
          if product
            if fragcomps_array.include?(oligo.basecomp_hash)
              match << 1
            else
              match << 0
            end
          end
          output << match
        end
      end
    end
    
    [header, output]
    
  end
    
end