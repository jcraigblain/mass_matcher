require('./lib/mass_matcher/oligo_comp_set')
require('./lib/mass_matcher/oligo_seq')

class MassMatcherInputsController < ApplicationController
  
  def file_match_form
    @bases = Residue.known_bases
    @sugars = Residue.known_sugars
    @derivatives = []
    Derivative.known_derivatives.each { |code, name| @derivatives << [name, code] }
  end
  
  def file_match_results
    mm_input = MassMatcherInput.new(params)
    download = params[:download]

    if mm_input.valid?
      @header, @output = mm_input.process
    else
      flash[:error] = mm_input.errors.full_messages
      redirect_to file_match_form_path
    end
    
    if download == "1"
      content = @header.join("\t")
      @output.each do |line|
        line = line.join("\t")
        content += "\n" + line
      end  
      send_data content, :type => 'text', :disposition => "attachment; filename=test_file.txt"
    end
  end
  
end