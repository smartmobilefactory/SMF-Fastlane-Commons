#!/usr/bin/ruby

def smf_analyse_programming_language()
    UI.message("Analyser: #{__method__.to_s} ...")
    return @smf_fastlane_config[:project][:programming_language]
end