class MassMatcherInput
  include ActiveModel::Validations
  
  attr_reader :errors
  attr_accessor :minimum_length, :maximum_length, :maximum_error, :product_sequence, :derivative_codes, :residue_codes, :input_file, :input_header, :mass_list
  
  validates_with MatchParametersValidator, InputDataValidator

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
    @product_sequence = attributes[:product_seq].upcase.gsub(/[^A-Z]/,'')
    @input_file = attributes[:input_file]
    
    if !@input_file.nil?
      @mass_list = @input_file.read
      @mass_list = @mass_list.split(/[\r\n]+/)
      @input_header = @mass_list.shift
      @mass_index = @input_header.split("\t").index("Mass")
    elsif !attributes[:mass_list].empty?
      @mass_list = attributes[:mass_list].gsub(/[^0-9\.,]/,'').split(',')
      @mass_list.map! {|mass| mass.to_f}
      @mass_index = 0;
    end
    
  end
  
  def output_filename
    if !@input_file.nil?
      output_filename = @input_file.original_filename.gsub(/\.txt/,'')
    else
      output_filename = "MassMatcher"
    end
    output_filename += '_output.txt'
    output_filename
  end
  
  def header
    header = []
    if !@input_file.nil?
      header += @input_header.split(/\t/)
    else
      header << "Mass"
    end
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
    meta_info = {}
    if !@input_file.nil?
      meta_info['Filename'] = @input_file.original_filename
    else
      meta_info['Mass list'] = @mass_list.join("\t")
    end
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
    unless @product_sequence.empty?
      product = true
      fragcomps_array = MassMatcherInput.fragment_product_sequence(@product_sequence)
    end
    
    matches = []
    @mass_list.each do |row|
      if row.is_a? Numeric
        mass = row
        row = [mass]
      else
        row = row.split("\t")
        mass = row[@mass_index].to_f
      end
      oligo_set.each do |oligo|
        error = 1000000*(((oligo.mass - mass)/oligo.mass).abs)
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
          matches << match
        end
      end
    end
    matches
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