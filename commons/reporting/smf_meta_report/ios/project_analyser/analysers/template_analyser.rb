#!/usr/bin/ruby

module Template

  KEY = ''

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification()

  end

  # returns the analysed property
  def self.analyse()
    UI.message("Analysing #{self.to_s} ...")
  end
end