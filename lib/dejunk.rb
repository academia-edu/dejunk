require "dejunk/version"
require "yaml"
require "active_support/core_ext/string"

module Dejunk
  extend self

  # All characters on the middle row of a QWERTY keyboard
  MASH_CHARS = 'ASDFGHJKLasdfghjkl;: '

  # All neighboring key pairs on a QWERTY keyboard, except "er" and "re" which
  # each make up >1% of bigrams in our "good" sample, plus each letter repeated
  # or with a space
  MASH_BIGRAMS = (
    ("abcdefghijklmnopqrstuvwxyz".chars.flat_map { |l| ["#{l} ", "#{l}#{l}"] }) +
    %w( qw we rt ty yu ui op as sd df fg gh hj jk kl zx xd cv vb bn nm qa az ws sx ed dc rf fv tg gb yh hn uj jm ik ol )
  ).flat_map { |bigram| [bigram, bigram.reverse] }.to_set.freeze

  def is_junk?(string, min_alnum_chars: 3, whitelist_regexes: [], whitelist_strings: [])
    if string && (whitelist_strings.include?(string) || whitelist_regexes.any? { |re| string =~ re })
      return false
    end

    return :no_alpha if string.nil? || string !~ /[[:alpha:]]/

    normed = normalize_for_comparison(string)

    return :too_short if too_few_alphanumeric_chars?(normed, min_alnum_chars)
    return :one_char_repeat if excessive_single_character_repeats?(string, normed)
    return :starts_with_punct if starts_with_disallowed_punctuation?(string)
    return :too_many_short_words if too_many_short_words?(string)
    return :three_chars_repeat_twice if three_plus_chars_repeat_twice?(string)
    return :fuck if string =~ /\bfuck/i
    return :missing_vowels if missing_vowels?(string, normed)
    return :asdf_row if asdf_row_and_suspicious?(string)

    ascii_proportion = string.chars.count { |c| c.ord < 128 }.to_f / string.length

    # The bigrams look like the ones you'd get from keyboard mashing
    # (the probability shouldn't be taken too literally, > 0.25 is almost all
    # mashing in practice on our corpus)
    if string.length > 1 && ascii_proportion > 0.8
      if probability_of_keyboard_mashing(string) > 0.25
        return :mashing_bigrams
      end
    end

    # The bigrams don't look like the bigrams in legitimate strings
    if string.length > 6 && ascii_proportion > 0.8
      corpus_similarity = bigram_similarity_to_corpus(string)

      # The similarity is more accurate for longer strings, and with more ASCII,
      # so increase the value (= lower the threshold) for shorter strings and
      # strings with less ASCII.
      score = corpus_similarity * (1.0/ascii_proportion**2) * (1.0/(1 - Math.exp(-0.1*string.length)))

      if score < 0.03
        return :unlikely_bigrams
      elsif score < 0.08 && string !~ /\A([[:upper:]][[:lower:]]+ )*[[:upper:]][[:lower:]]+\z/
        # The similarity ignores casing, so instead use a higher threshold if
        # the casing looks wrong
        return :unlikely_bigrams
      elsif score < bigram_similarity_to_mashing(string)
        return :mashing_bigrams
      end
    end

    false
  end

  # Cosine similarity between vector of frequencies of bigrams within string,
  # and vector of frequencies of all bigrams within corpus
  def bigram_similarity_to_corpus(string)
    bigrams = bigrams(string)

    freqs = bigrams.
      each_with_object(Hash.new(0)) { |bigram, counts| counts[bigram] += 1 }.
      each_with_object({}) do |(bigram,count), freqs|
        freqs[bigram] = count.to_f / bigrams.length
      end

    numerator = freqs.
      map{ |bigram, freq| corpus_bigram_frequencies[bigram].to_f * freq }.inject(&:+)
    denominator = corpus_bigram_magnitude * ((freqs.values.map{ |v| v**2 }.inject(&:+)) ** 0.5)

    numerator / denominator
  end

  # Cosine similarity between vector of frequencies of bigrams within string,
  # and vector which assumes all bigrams made of neighboring pairs on the keyboard
  # are equally likely, and no others appear
  def bigram_similarity_to_mashing(string)
    bigrams = bigrams(string)

    freqs = bigrams.
      each_with_object(Hash.new(0)) { |bigram, counts| counts[bigram] += 1 }.
      each_with_object({}) do |(bigram,count), freqs|
        freqs[bigram] = count.to_f / bigrams.length
      end

    numerator = freqs.map{ |bigram, freq| freq * mashing_bigram_frequencies[bigram].to_f }.inject(&:+)
    denominator = mashing_bigram_magnitude * ((freqs.values.map{ |v| v**2 }.inject(&:+)) ** 0.5)

    numerator / denominator
  end

  def bigrams(string)
    return [] if string.nil?

    string = string.strip
    return [] if string.length < 2

    string.
      chars.
      zip(string.chars[1..-1]).
      map { |c1,c2| "#{c1.mb_chars.downcase}#{c2.mb_chars.downcase}" if c1 && c2 }.
      compact.
      map { |bigram| bigram.gsub(/[0-9]/, '0'.freeze) }.
      map { |bigram| bigram.gsub(/[[:space:]]/, ' '.freeze) }
  end

  # The Bayesian probability of a string being keyboard mashing, given the
  # probability of each bigram if drawn either from the legit corpus or from
  # mashing, and an a priori probability of mashing.
  #
  # The probability shouldn't be taken too literally, but it's a useful
  # indicator.
  def probability_of_keyboard_mashing(string, apriori_probability_of_mashing: 0.1)
    bigrams = bigrams(string)

    return 0 unless bigrams.present?

    prob_bigrams_given_mashing = bigrams.
      map { |bigram| BigDecimal(mashing_probability(bigram).to_s) }.
      inject(&:*)

    prob_bigrams_given_corpus = bigrams.
      map { |bigram| BigDecimal(corpus_probability(bigram).to_s) }.
      inject(&:*)

    numerator = prob_bigrams_given_mashing * apriori_probability_of_mashing

    numerator / (numerator + prob_bigrams_given_corpus * (1 - apriori_probability_of_mashing))
  end

  def normalize_for_comparison(string)
    string.
      mb_chars.
      normalize(:kd).
      gsub(/\p{Mn}+/, ''.freeze).
      gsub(/[^[:alnum:]]+/, ''.freeze).
      downcase
  end

  private

  def missing_vowels?(string, normed)
    # Missing vowels (and doesn't look like acronym, and is ASCII so we can tell)
    unless normed.chars.any? { |c| c.ord >= 128 } || string == string.upcase
      return true if normed !~ /[aeiouy]/i
    end

    false
  end

  # One character repeated 5 or more times, or 3 or more times and not an
  # acronym, roman numeral, or www
  def excessive_single_character_repeats?(string, normed)
    return true if normed.chars.uniq.count == 1

    if string =~ /([^[:space:]i])\1\1/i
      return true if normed =~ /([^0-9])\1\1\1\1/i

      string.split(/[[:space:][:punct:]]/).each do |word|
        return true if word =~ /([^iw0-9])\1\1/i && word != word.upcase
      end
    end

    false
  end

  def three_plus_chars_repeat_twice?(string)
    # At least 3 characters repeated at least twice in a row (but only on short
    # strings, otherwise there are false positives)
    string.length < 80 && string =~ /(....*)[[:space:][:punct:]]*\1[[:space:][:punct:]]*\1/
  end

  def asdf_row_and_suspicious?(string)
    # All characters from the same row of the keyboard is suspicious, but we
    # need additional confirmation
    if string.chars.all? { |c| MASH_CHARS.include?(c) }
      return true if string.length >= 16
      return true if string =~ /(...).*\1/ # Three-plus characters, repeated
      return true if string =~ /(..).*\1.*\1/ # Two characters, repeated twice
      return true if string =~ /\b[sdfghjkl]\b/ # Stray lowercase letter
      return true if string =~ /[^aeiouy]{3}/i && (string.length > 5 || string != string.upcase) # Three consonants in a row, non-acronym
    end

    false
  end

  def too_few_alphanumeric_chars?(normed, min_alnum_chars)
    # Too short (unless we're dealing with a large alphabet with legitimate
    # single-char words)
    if normed.length < min_alnum_chars
      unless normed =~ /\p{Han}|\p{Hangul}|\p{Hiragana}|\p{Katakana}/
        return true
      end
    end

    false
  end

  def starts_with_disallowed_punctuation?(string)
    # Starting punctuation, except opening parens or quote
    string =~ /\A[[:punct:]]/ && string !~ /\A(\p{Pi}|\p{Ps}|['"¿»’]).+/
  end

  def too_many_short_words?(string)
    words = string.split
    two_chars = words.select { |w| w.length < 3 }.count
    if two_chars > 2 && two_chars > 0.75 * words.length
      return true
    end

    false
  end

  def mashing_probability(bigram)
    if (f = mashing_bigram_frequencies[bigram])
      f
    else
      # An arbitrary (non-ASCII) bigram with mashing is slightly more probable than with legit strings
      1e-6
    end
  end

  def corpus_probability(bigram)
    corpus_bigram_frequencies[bigram] || 1e-7 # Around the smallest frequency we store for the corpus
  end

  def corpus_bigram_frequencies
    @corpus_bigram_frequencies ||= YAML.load_file(File.expand_path('../../resources/bigram_frequencies.yml', __FILE__)).freeze
  end

  def corpus_bigram_magnitude
    @corpus_bigram_magnitude ||= (corpus_bigram_frequencies.values.map{ |v| v**2 }.inject(&:+)) ** 0.5
  end

  def mashing_bigram_frequencies
    # This is a guess because we don't have a good corpus, but we assume that
    # 50% of mashing bigrams are a neighboring pair on the ASDF row or a duplicate
    # and the rest are evenly distributed among other neighboring pairs or char-
    # plus-space.
    @mashing_bigram_frequencies ||= MASH_BIGRAMS.each_with_object({}) do |bigram, freqs|
      if bigram.first == bigram.last || bigram.chars.all? { |c| c != ' '.freeze && MASH_CHARS.include?(c) }
        freqs[bigram] = 0.5 / (16 + 26)
      else
        freqs[bigram] = 0.5 / (MASH_BIGRAMS.length - 16 - 26)
      end
    end
  end

  def mashing_bigram_magnitude
    @mashing_bigram_magnitude ||= (mashing_bigram_frequencies.values.map{ |v| v**2 }.inject(&:+)) ** 0.5
  end
end
