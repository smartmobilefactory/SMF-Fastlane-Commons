#!/usr/bin/ruby

def smf_analyse_swiftlint_warnings()
  UI.message("Analyser: #{__method__.to_s} ...")

  if File.file?(smf_swift_lint_output_path) == false
    raise "Couldn't locate swiftlint report at #{smf_swift_lint_output_path}"
  end

  swiftlint_report = File.read(smf_swift_lint_output_path)
  swiftlint_json = JSON.parse(swiftlint_report)
  return swiftlint_json.count
end
