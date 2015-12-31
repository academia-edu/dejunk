require 'spec_helper'

describe Dejunk do
  it 'has a version number' do
    expect(Dejunk::VERSION).not_to be nil
  end

  it 'does not flag various research fields' do
    fields = YAML.load_file(File.expand_path('../../spec/fields.yml', __FILE__))
    fields.each do |field|
      expect(Dejunk.is_junk? field).to be_falsey
    end
  end

  it 'does not flag some words with less common bigrams' do
    ["Unknown", "Weight", "e-book", "Hockey", "Zimbabwe", "Kyrgyz", "Kyrgyzstan", "Uyghur"].each do |word|
      expect(Dejunk.is_junk? word).to be_falsey
    end
  end

  it 'does not flag various paper titles' do
    [
      "BOYD, M. J. & R. WATSON. 1983. A fossil fish forged by Flint Jack. Geological Curator, 3 (7), 444-446.",
      "Osho International Meditation Resort (Pune, 2000s): Anthropological Analysis of Sannyasin Therapies and the Rajneesh Legacy (Journal of Humanistic Psychology)",
      "Base Catalysis of Chromophore Formation in Arg96 and Glu222 Variants of Green Fluorescent Protein",
      "Hargrove, D.L. and Bryan, V.C. ( 1999, Oct.). Malcolm Knowles would be proud of instructional technologies. 17th ICTE Proceedings,Tampa, FL: 17th ICTE",
      "Problems of Crime and Violence in Europe 1750-2000",
      "Bryan, V.C. (2001, Feb.). Editorial review: Designing an online course. Columbus, OH: Merrill Prentice Hall",
      "‘Legitimate Violence’ in the Prose of Counterinsurgency : an Impossible Necessity?”, Alternatives: Global, Local, Political (Sage), vol 38, n°2, 2013, p. 155-171",
      "»Der gotische Mensch will sehen«. Die Schaufrömmigkeit und ihre Deutungen in der Zeit des Nationalsozialismus",
      "Balderramo D, Cárdenas A. Diagnóstico y tratamiento de las complicaciones biliares asociadas al trasplante hepático. Revista Gen 2013;67(2):111-115",
      "Assessment of the diagnostic potential of Immunocapture-PCR and Immuno-PCR for Citrus Variegated Chlorosis",
      "Gluten-free Diet in Psoriasis Patients with Antibodies to Gliadin Results in Decreased Expression of Tissue Transglutaminase and Fewer Ki67&#x0002B; Cells in the Dermis",
      "Words or deeds? Analysing corporate sustainability strategies in the largest European pulp and paper companies during the 2000s",
      "Effect of Urbanization on the Forest Land Use Change in Alabama: A Discrete Choice Approach",
      "Differential in Vivo Sensitivity to Inhibition of P-glycoprotein Located in Lymphocytes, Testes, and the Blood-Brain Barrier",
      "Psychoanalysis and its role in brain plasticity: much more than a simple bla, bla, bla",
    ].each do |title|
      expect(Dejunk.is_junk? title).to be_falsey
    end
  end

  it 'flags mashing' do
    ["RKJM", "Asdf", "Y5egrdfvc", "Asdfghjkl", "qwee", "asasasasa", "Asdf", "DFFF", "Asd Asd", "Zaza", "Nawwww"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags unlikely bigrams' do
    ["MJA 2008; 188 (4): 209-213", "PEDS20140694 1001..1008", "Hkygj,n", "LH-ftyy", "4D4U-QSRT-5F76-JBT9-EACE", "Guia-ev-v2", "Bell-pdf"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags missing vowels' do
    ["Cvgj", "Gm-Csf", "Cxfd", "Mcnp", "Fbmc", "RT qPCR", "Ppwk 2 ppwk 2"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags missing alphabetical chars' do
    ["081280622019", "01:32"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags bad punctuation' do
    ["#iranelection on The Page 99 Test.", "-Biodescodificacion, dicc", "• Problems of Crime and Violence in Europe 1750-2000"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags repeated chars' do
    ["Aaaa", "Iiiiiiiii", "Economiaaaaaa", "Engineeering", "Sssaj-75-1-102[1] - Aiken 2011"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags multi-character repeats' do
    ["draft draft draft", "Bla Bla Bla"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end

  it 'flags excessive short words' do
    ["t i Qu n l i m h c sinh trung h c ph th ng - Lu n v n n t i t t nghi p", "H T M L", "case s t r o k e", "Oresajo et al 15 1"].each do |string|
      expect(Dejunk.is_junk? string).to be_truthy
    end
  end
end
