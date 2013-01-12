require('./lib/mass_matcher/oligo_comp_set')
require('./lib/mass_matcher/oligo_seq')

class MassMatcherInputsController < ApplicationController
  
  def mass_match_form
    @bases = Residue.known_bases
    @sugars = Residue.known_sugars
    @derivatives = []
    Derivative.known_derivatives.each { |code, name| @derivatives << [name, code] }
  end
  
  def mass_match_results
    mm_input = MassMatcherInput.new(params)
    download = params[:download]

    if mm_input.valid?
      @header = mm_input.header
      @output = mm_input.process_file
    else
      flash[:error] = mm_input.errors.full_messages
      redirect_to mass_match_form_path
    end
    
    if download == "1"
      meta_info = mm_input.meta_info
      content = ''
      meta_info.each do |key, value|
        content += "#{key}\t#{value}\n"
      end
      content += @header.join("\t")
      @output.each do |line|
        line = line.join("\t")
        content += "\n" + line
      end  
      send_data content, :type => 'text', :disposition => "attachment; filename=#{mm_input.output_filename}"
    end
  end
  
end