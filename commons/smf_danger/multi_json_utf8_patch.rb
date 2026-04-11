# CBENEFIOS-2241: octokit 10.0 / sawyer 0.9.3 hand GitHub response bodies to
# MultiJson tagged as ASCII-8BIT. Under Ruby 3.3 + json stdlib this raises
# MultiJson::ParseError on any non-ASCII byte (e.g. 0xE2 em-dash).
#
# Two earlier attempts failed:
#   1. Patching Sawyer::Serializer#decode — Sawyer 0.9.3 routes through #call
#      internally so the decode override was never hit.
#   2. Patching MultiJson.load in the Fastlane parent process — the `danger`
#      gem is invoked via a shell subprocess (`sh 'danger ...'`) with a fresh
#      Ruby VM that never sees the parent's monkey-patch.
#
# This file is loaded into the danger subprocess via RUBYOPT=-r<this file>
# (set in smf_danger.rb before calling danger()). It runs before any other
# Ruby code in the subprocess, so it covers Danger's own GitHub#fetch_details
# call which happens before the Dangerfile is evaluated.
#
# MultiJson.load is the common endpoint for every JSON decode path regardless
# of which HTTP client (Sawyer, Faraday, Octokit internals) sits above it.

require 'multi_json'

unless MultiJson.singleton_class.method_defined?(:_smf_orig_load_cb_2241)
  MultiJson.singleton_class.class_eval do
    alias_method :_smf_orig_load_cb_2241, :load
    def load(string, options = {})
      if string.is_a?(String) && string.encoding == Encoding::ASCII_8BIT
        string = string.dup.force_encoding('UTF-8')
      end
      _smf_orig_load_cb_2241(string, options)
    end
  end
  warn '🩹 Applied MultiJson UTF-8 load patch (CBENEFIOS-2241)'
end
