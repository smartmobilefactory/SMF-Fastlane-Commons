#!/usr/bin/ruby

module SwiftlintAnalyser

  SWIFT_LINT_JSON_PATH = ".MetaJSON/swiftlint.json"

  @swiftlint_error_count = nil

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    UI.message("Verifying #{self.to_s}")

    if File.file?(smf_swift_lint_output_path) == false
      UI.important("Couldn't locate swiftlint report at #{smf_swift_lint_output_path}")
      return :WARNING
    end

    swiftlint_report = File.read(swiftlint_report_path)
    swiftlint_json = JSON.parse(swiftlint_report)
    @swiftlint_error_count = swiftlint_json.count

    return :OK
  end

  # returns the analysed property
  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")
    return @swiftlint_error_count
  end
end
