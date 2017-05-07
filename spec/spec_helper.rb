$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dejunk'

support_path = File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))
Dir[support_path].each { |f| require f }
