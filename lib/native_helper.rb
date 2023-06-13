# Extend Numeric class
class Numeric
  Alpha26 = ("A".."Z").to_a

  # add method to convert from alphabet numeric to equivalent letter
  def to_s26
    return "" if self < 1
    s, q = "", self
    loop do
      q, r = (q - 1).divmod(26)
      s.prepend(Alpha26[r]) 
      break if q.zero?
    end
    s
  end
end

# Extend String class
class String
  Alpha26 = ("A".."Z").to_a

  # add method to convert from letters to equivalent alphabet numeric (NOTE: this is not used, added just to complete the reverse function above)
  def to_i26
    result = 0
    downcased = self.downcase
    (1..length).each do |i|
      char = downcased[-i]
      result += 26**(i-1) * (Alpha26.index(char) + 1)
    end
    result
  end

  # for some reasons, WS decided to express some numbers in cents rather than regular dollar units. We need to add zeros padding the front if needed (i.e.: 1 cent is represented as 1 -> 001) and then add the floating number separator in the right place (i.e.: 100 -> 1.00)
  def cents_to_units
    self.rjust(2, '0')&.insert(-3, '.')&.to_f
  end
end

# Extend Hash class
class Hash
  # convert regular _flat_ JSON to symbolized keys
  # TODO: handle deeper JSONs or use external gem
  def to_sym
    self.map { |key, value| [key.to_sym, value] }.to_h
  end
end
