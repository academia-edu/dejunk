RSpec::Matchers.define :be_junk do
  match do |string|
    Dejunk.is_junk?(string)
  end

  failure_message_when_negated do |string|
    "expected that #{actual} wouldn't be junk, but was junk of type " +
      Dejunk.is_junk?(string).inspect
  end
end
