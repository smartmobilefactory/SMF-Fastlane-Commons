#!/usr/bin/ruby

module Logger

  # Colors
  RED = "\033[31m"
  YELLOW = "\033[33m"
  GREEN = "\033[32m"
  RESET = "\033[0m"

  def self.error(msg)
    UI.error("#{RED}[ERROR] #{msg}#{RESET}")
  end

  def self.warning(msg)
    UI.important("#{YELLOW}[WARNING] #{msg}#{RESET}")
  end

  def self.info(msg)
    UI.message("#{GREEN}[INFO] #{msg}#{RESET}")
  end

  def self.status(status, msg)
    if status == :ERROR
      UI.error("#{RED}[#{status.to_s}] #{msg}#{RESET}")
    elsif status == :WARNING
      UI.important("#{YELLOW}[#{status.to_s}] #{msg}#{RESET}")
    elsif msg != nil
      UI.message("#{GREEN}[#{status.to_s}] #{msg}#{RESET}")
    end
  end
end
