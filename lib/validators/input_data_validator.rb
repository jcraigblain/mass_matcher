class InputDataValidator < ActiveModel::Validator
  def validate(record)
    if record.input_file.nil?
      if record.mass_list.nil?
        record.errors[:input_file] << "or mass list must be provided"
      else
        error = false
        record.mass_list.each do |mass|
           error = true unless mass.is_a? Numeric
        end
        record.errors[:mass_list] << "must contain only numbers" if error
      end
    elsif !record.input_header.match(/Mass/) || record.input_header.empty? || record.mass_list.empty?
      record.errors[:input_file] << "must have a 'Mass' header and at least one row of data"
    end
  end
end