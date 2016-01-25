$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ariblib'
  RSpec.configure do |config|
    config.filter_run :debug => true
    config.run_all_when_everything_filtered = true
  end
  