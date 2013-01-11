class MassMatcherInput
  include ActiveModel::Validations
  
  attr_reader :errors
  attr_accessor :minimum_length, :maximum_length, :maximum_error, :product_sequence, :derivative_codes, :residue_codes, :input_file
  
  validates_with MatchParametersValidator
  validate :input_file_valid

  def initialize(attributes)
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
    @input_file = attributes[:input_file]
    
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
  
  def input_file_valid
    if @input_file.nil?
      errors.add(:input_file, "must be provided")
    elsif !@input_header.match(/Mass/) || @input_header.empty? || @file_data.empty?
      errors.add(:input_file, "must have a 'Mass' header and at least one row of data")
    end
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