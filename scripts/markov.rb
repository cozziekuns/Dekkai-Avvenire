#!/bin/env ruby
# encoding: utf-8

#==============================================================================
# ** Markov
#==============================================================================

module Markov

  English_Data_Filename = "scripts/markov_eng.dat"
  Japanese_Data_Filename = "scripts/markov_jp.dat"

  English_Min_Tweet_Length = 60
  English_Max_Tweet_Length = 100

  Japanese_Min_Tweet_Length = 30
  Japanese_Max_Tweet_Length = 80

end

#==============================================================================
# ** Markov_Chain
#-----------------------------------------------------------------------------
# A basic, functioning Markov Chain for text.
#==============================================================================

class Markov_Chain

  def initialize
    @hash = {}
    @hash_sizes = {}
    load_database
  end

  def save_database
    File.open(filename, "w") { |file|
      Marshal.dump(@hash, file)
      Marshal.dump(@hash_sizes, file)
    }
  end

  def load_database
    return if not File.exist?(filename)
    File.open(filename, "r") { |file|
      @hash = Marshal.load(file)
      @hash_sizes = Marshal.load(file)
    }
  end

  def end_of_sentence?(word)
    # Check if the last "letter" in the work is a punctuation mark that ends
    # the sentence.
    return [".", "?", "!"].include?(word[-1])
  end

  def space_modifier
    return " "
  end

  def min_tweet_length
    Markov::English_Min_Tweet_Length
  end

  def max_tweet_length
    Markov::English_Max_Tweet_Length
  end

  def add_tweet(tweet)
    # Just split by spaces (might fix this in the future)
    parse_array_into_hash(tweet.split(" "))
  end

  def parse_array_into_hash(words)
    words.each_with_index { |word, i|
      # Stop if its the last word in the tweet
      break if i == words.size - 1
      # Initialise if the hash doesn't have the word
      add_word_to_hash(word) if not @hash.has_key?(word)
      # Initialise if the word pair has never been seen before
      @hash[word][words[i + 1]] ||= 0
      @hash[word][words[i + 1]] += 1
      # Increment total
      @hash_sizes[word] += 1
    }
  end

  def add_word_to_hash(word)
    # Initialise the word in the hash
    @hash[word] = {}
    @hash_sizes[word] = 0
  end

  def generate_tweet(mention_length)
    # Make tweets a random length.
    tweet = ""
    length = [rand(min_tweet_length - mention_length), max_tweet_length].max
    curr_word = get_first_word
    return "でっかいぶぶです。" if curr_word.nil?
    until (tweet + curr_word).size > length
      tweet += curr_word + space_modifier
      curr_word = get_next_word(curr_word)
    end
    tweet += get_last_word(curr_word)
    return tweet
  end

  def get_first_word
    # Get a random capitalised word to use as the first word in the sentence.
    first_word = @hash.keys.select { |word|
      word[0].upcase == word[0] and not word[0][/p{Punct}/]
    }.sample
    return (first_word ? first_word : @hash.keys.sample)
  end

  def get_next_word(curr_word)
    wordlist = @hash[curr_word]
    return get_first_word if not wordlist or end_of_sentence?(curr_word)
    curr_index = 0
    dest_index = rand(@hash_sizes[curr_word])
    # Iterate through the wordlist, incrementing the current index by the
    # number of times each pair has been seen until the destination index is
    # reached.
    wordlist.keys.each { |key|
      curr_index += wordlist[key]
      return key if curr_index > dest_index
    }
  end

  def get_last_word(curr_word)
    return "" if end_of_sentence?(curr_word)
    if @hash[curr_word]
      best_candidates = @hash[curr_word].keys.select { |word|
        word.size < 16 and end_of_sentence?(word)
      }
      return best_candidates.sample if not best_candidates.empty?
    end
    candidates = @hash.keys.select { |word|
      word.size < 16 and end_of_sentence?(word)
    }
    # If there have been no full stops, then just use a random word to finish
    # the sentence.
    return candidates.sample if not candidates.empty?
    return @hash.keys.sample
  end

end

#==============================================================================
# ** Markov_English
#-----------------------------------------------------------------------------
# A basic, functioning Markov Chain for english text.
#==============================================================================

class Markov_English < Markov_Chain

  def filename
    return Markov::English_Data_Filename
  end

end

#==============================================================================
# ** Markov_Japanese
#-----------------------------------------------------------------------------
# A basic, functioning Markov Chain for Japanese text.
#==============================================================================

class Markov_Japanese < Markov_Chain

  def filename
    return Markov::Japanese_Data_Filename
  end

  def end_of_sentence?(word)
    return word[-1][/[。？！]/]
  end

  def space_modifier
    return ""
  end

  def min_tweet_length
    Markov::Japanese_Min_Tweet_Length
  end

  def max_tweet_length
    Markov::Japanese_Max_Tweet_Length
  end

  def get_first_word
    first_word = @hash.keys.reject { |word| word[/[。？！]/] }.sample
    return (first_word ? first_word : @hash.keys.sample)
  end

  def add_tweet(tweet)
    # Here, words are just five characters...
    words = tweet.encode("utf-8", "utf-8").scan(/.{1,5}/)
    parse_array_into_hash(words)
  end

end

#===============================================================================
# Speak jibberish to anyone that mentions Dekkai.
#===============================================================================

class Dekkai

  #---------------------------------------------------------------------------
  # * Initialisation
  #---------------------------------------------------------------------------

  alias init_all_scripts_markov init_all_scripts
  def init_all_scripts
    @markov_english = Markov_English.new
    @markov_japanese = Markov_Japanese.new
    init_all_scripts_markov
  end

  #----------------------------------------------------------------------------
  # * Stream Handlers
  #----------------------------------------------------------------------------

  alias parse_received_tweet_markov parse_received_tweet
  def parse_received_tweet(tweet)
    parse_received_tweet_markov(tweet)
    text = filter_links(strip_mentions(tweet.text))
    if english?(text)
      @markov_english.add_tweet(text)
    elsif japanese?(text)
      @markov_japanese.add_tweet(text)
    end
  end

  #----------------------------------------------------------------------------
  # * Mention Handling
  #----------------------------------------------------------------------------

  alias update_mention_markov update_mention
  def update_mention(mention)
    update_mention_markov(mention)
    return if @replied_to_mention
    chain = get_markov_chain(mention)
    name = mention.user.screen_name
    reply = sprintf("@%s %s", name, chain.generate_tweet(name.size))
    tweet = Tweet.new(Time.now + 1, :standard, reply)
    reply_to_mention(mention, tweet)
  end

  def get_markov_chain(mention)
    text = strip_mentions(mention.text)
    return @markov_english if english?(text)
    return @markov_japanese if japanese?(text)
    return (rand(2) == 0 ? @markov_english : @markov_japanese)
  end

  #----------------------------------------------------------------------------
  # * Internationalisation
  #----------------------------------------------------------------------------

  def english?(text)
    # Sorry, I am baka gaijin
    return false if text[/\p{Han}|\p{Katakana}|\p{Hiragana}/]
    return true
  end

  def japanese?(text)
    # ごめん、英語はちょっと
    return false if text[/p{L}/]
    return true if text[/\p{Han}|\p{Katakana}|\p{Hiragana}/]
    return false
  end

  #----------------------------------------------------------------------------
  # * Exit Routine
  #----------------------------------------------------------------------------

  alias exit_gracefully_markov exit_gracefully
  def exit_gracefully
    @markov_english.save_database
    @markov_japanese.save_database
    exit_gracefully_markov
  end

end
