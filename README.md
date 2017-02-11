# Dejunk

[![CircleCI](https://circleci.com/gh/academia-edu/dejunk.svg?style=svg)](https://circleci.com/gh/academia-edu/dejunk)

Detect keyboard mashing and other junk in your data.

For example, if you allow user-entered tags, but want to hide bad ones. Or if
you want to detect user frustration filling out a particular field, and do
something about it!

Uses a variety of heuristics, the most sophisticated being a comparison of
bigrams in the input to the frequencies in a "known-good" corpus vs. their
proximity on a keyboard. Achieves pretty good precision on Academia.edu's data,
but might need adjustment for yours.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dejunk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dejunk

## Usage

The main interface is `Dejunk.is_junk?`. Pass a string, and get a truthy value
if it looks junky, and false otherwise.

```ruby
$ Dejunk.is_junk?('Hello World')
=> false
$ Dejunk.is_junk?('qwefqwef')
=> :mashing_bigrams

$ Dejunk.is_junk?('asdf')
=> :asdf_row
$ Dejunk.is_junk?('fads')
=> false

$ Dejunk.is_junk?('Hi')
=> :too_short
$ Dejunk.is_junk?('Hi', whitelist_regexes: [/\Ahi\z/i])
=> false
```

Returns a reason when junk is detected for aid in debugging. Optional parameters
are `min_alnum_chars` (defaults to 3), and `whitelist_strings` and
`whitelist_regexes` (both default to none).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/academia-edu/dejunk

## License

Apache 2.0
