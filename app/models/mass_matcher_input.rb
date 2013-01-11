require('./lib/mass_matcher/residue')
require('./lib/mass_matcher/derivative')
require('./lib/mass_matcher/residue')
require('./lib/mass_matcher/oligo_seq')

class MassMatcherInput
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  
  attr_reader :errors
  attr_accessor :minimum_length, :maximum_length, :maximum_error, :product_sequence, :derivative_codes, :residue_codes, :input_file
  
  validate :derivatives_valid, :residues_valid, :min_len_less_than_max_len, :product_sequence_valid, :residue_count_valid, :input_file_valid
  validates :minimum_length, :presence => true, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => MAXIMUM_LENGTH}
  validates :maximum_length, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => MAXIMUM_LENGTH}
  validates :maximum_error, :presence => true, :numericality => { :greater_than => 0, :less_than_or_equal_to => MAXIMUM_PPM }

  def initialize(attributes = {})
    @errors = ActiveModel::Errors.new(self)
    
    @minimum_length = attributes[:min_len].to_i
    @maximum_length = attributes[:max_len].to_i
    @maximum_error = attributes[:max_ppm].to_f
    @residue_codes = attributes[:residues]
    @derivative_codes = attributes[:derivatives] || []
    if attributes[:custom_derivative].length > 0
      @derivative_codes << 'x'
      @custom_derivative_formula = attributes[:custom_derivative]
    end
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
    if @derivative_codes.length == 0
      errors.add(:derivatives, "must be selected")
    elsif @derivative_codes != @derivative_codes & Derivative.known_codes
      errors.add(:derivatives, "not valid")
    end
  end
  def residues_valid
    errors.add(:residues, "not valid") unless @residue_codes == @residue_codes & Residue.known_codes
  end
  def min_len_less_than_max_len
    errors.add(:minimum_length, "must be less than or equal to maximum length") unless @minimum_length <= @maximum_length
  end
  def residue_count_valid
    if @residue_codes.nil?
      errors.add(:residues, "must be selected")
    elsif @residue_codes.length > MAXIMUM_RESIDUES
      errors.add(:residues, "cannot exceed 5 in count")
    end 
  end
  def input_file_valid
    if @input_file.nil?
      errors.add(:input_file, "must be provided")
    elsif !@input_header.match(/Mass/) || @input_header.empty? || @file_data.empty?
      errors.add(:input_file, "must have a 'Mass' header and at least one row of data")
    end
  end
  def product_sequence_valid
    error = false
    acceptable_bases = Residue.known_base_codes
    @product_sequence.split('').each { |base| error = true if !acceptable_bases.include?(base) }
    errors.add(:product_sequence, "contains invalid bases") if error 
  end
  
  def output_filename
    output_filename = @input_file.original_filename.gsub(/\.txt/,'')
    output_filename += '_output.txt'
    output_filename
  end
  
  def header
    header = @input_header.split(/\t/)
    header << "Length"
    header << "Derivative"
    @residue_codes.each do |residue|
      header << residue
    end
    header << 'Formula'
    header << 'Exp Mass'
    header << 'Error'
    header << 'Match' unless @product_sequence.empty?
    header
  end
  
  def meta_info
    meta_info = {'Filename' => @input_file.original_filename}
    meta_info['Product'] = @product_sequence unless @product_sequence.empty?
    meta_info['Minimum length'] = @minimum_length
    meta_info['Maximum length'] = @maximum_length
    meta_info['Maximum error (ppm)'] = @maximum_error
    meta_info['Residues'] = @residue_codes.join("\t")
    meta_info['Derivatives'] = @derivative_codes.join("\t")
    meta_info['Custom derivative'] = @custom_derivative_formula if @derivative_codes.include? 'x'
    meta_info
  end
  
  def process_file
    residues = MassMatcherInput.parse_residue_codes(@residue_codes)
    derivatives = MassMatcherInput.parse_derivative_codes(@derivative_codes, @custom_derivative_formula)
    oligo_set = OligoCompSet.new(@minimum_length,@maximum_length,residues,derivatives)
    mass_index = @input_header.split("\t").index("Mass")
    unless @product_sequence.empty?
      product = true
      fragcomps_array = MassMatcherInput.fragment_product_sequence(@product_sequence)
    end
    
    output = []
    @file_data.each do |row|
      row = row.split("\t")
      oligo_set.each do |oligo|
        error = 1000000*(((oligo.mass - row[mass_index].to_f)/oligo.mass).abs)
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
    output
  end
  
  class << self
    def parse_residue_codes(code_array)
      residues = []
      code_array.each do |residue_code|
        residue_code.scan(/([a-z]+)([A-Z]+)/) do |sugar, base|
          residues << Residue.new(sugar,base)
        end
      end
      residues
    end
    def parse_derivative_codes(code_array, custom_formula = '')
      derivatives = []
      code_array.each do |derivative_code|
        if derivative_code == 'x'
          derivatives << Derivative.new(derivative_code, custom_formula) 
        else
          derivatives << Derivative.new(derivative_code)
        end
      end
      derivatives
    end
    def fragment_product_sequence(product_base_string)
      residue_array = []
      base_array = product_base_string.split('')
      base_array.each { |base| residue_array << Residue.new('r', base) }
      fragcomps_array = OligoSeq.new(residue_array, Derivative.new('p')).all_fragment_basecomps
      fragcomps_array
    end
  end
  
end