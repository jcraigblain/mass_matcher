# Load the rails application
require File.expand_path('../application', __FILE__)

MAXIMUM_PPM = 100
MAXIMUM_LENGTH = 20
MAXIMUM_RESIDUES = 5

# Initialize the rails application
MassMatcher::Application.initialize!
