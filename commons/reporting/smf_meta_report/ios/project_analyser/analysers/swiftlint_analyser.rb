#!/usr/bin/ruby

module SwiftlintAnalyser

  SWIFT_LINT_JSON_PATH = ".MetaJSON/swiftlint.json"

  # returns a tupel describing the status and what the error is
  # first tupel entry is the status: OK, WARNING, ERROR
  # seconde tupel entry is a message
  def self.verification(src_root)
    UI.message("Verifying #{self.to_s}")
    # if File.exist?(File.join(src_root, SWIFT_LINT_JSON_PATH)) == true
    #   return :OK
    # else
    #   UI.important("Couldn't locate swiftlint.json at #{SWIFT_LINT_JSON_PATH}")
    #   return :WARNING
    # end
  end

  # returns the analysed property
  def self.analyse(src_root)
    UI.message("Analysing #{self.to_s} ...")
    # if self.validate(src_root) == :WARNING
    #   return
    # end

    # UI.message("Starting analysis")
    # return { :content => File.join(src_root, SWIFT_LINT_JSON_PATH), :is_raw => false, :file => :swiftlint_json }
  end
end


# TODO:
# - read and parse the swiftlint.report.json file
# - count the number of warnings and retain them with the key: 'swiftlint_warnings'

# Legacy code:
# swiftlint_json_content = FileHelper::file_content(swiftlint_report_path)
# swiftlint_json = JSON.parse(swiftlint_json_content)
# swiftlint_error_count = swiftlint_json.count
