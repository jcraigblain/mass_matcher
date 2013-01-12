class MatchParametersValidator < ActiveModel::Validator
  def validate(record)
    record.errors[:minimum_length] << 'must be an integer' unless record.minimum_length.is_a? Integer
    record.errors[:minimum_length] << "must be greater than zero and less than maximum length" if record.minimum_length < 1 || record.minimum_length > record.maximum_length
    
    record.errors[:maximum_length] << 'must be an integer' unless record.maximum_length.is_a? Integer
    record.errors[:maximum_length] << "must be at least minimum length and at most #{MAXIMUM_LENGTH}" if record.maximum_length < record.minimum_length || record.maximum_length > MAXIMUM_LENGTH
    
    record.errors[:maximum_error] << 'must be a number' unless record.maximum_error.is_a? Numeric
    record.errors[:maximum_error] << "must be greater than zero and at most #{MAXIMUM_PPM}" if record.maximum_error <= 0 || record.maximum_error > MAXIMUM_PPM
    
    if record.derivative_codes.length == 0
      record.errors[:derivatives] << "must be selected"
    elsif record.derivative_codes.length > MAXIMUM_DERIVATIVES
      record.errors[:derivatives] << "cannot exceed #{MAXIMUM_DERIVATIVES} in number"
    elsif record.derivative_codes != record.derivative_codes & Derivative.known_codes
      record.errors[:derivatives] << "not valid"
    end
    
    if record.residue_codes.nil?
      record.errors[:residues] << "must be selected"
    elsif record.residue_codes.length > MAXIMUM_RESIDUES
      record.errors[:residues] << "cannot exceed #{MAXIMUM_RESIDUES} in number"
    elsif record.residue_codes != record.residue_codes & Residue.known_codes
      record.errors[:residues] << 'not valid'
    end
    
    product_error = false
    acceptable_bases = Residue.known_base_codes
    record.product_sequence.split('').each { |base| product_error = true if !acceptable_bases.include?(base) }
    record.errors[:product_sequence] << "contains invalid bases" if product_error
    
  end
end