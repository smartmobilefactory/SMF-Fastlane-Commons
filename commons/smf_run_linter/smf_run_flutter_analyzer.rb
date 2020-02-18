private_lane :smf_run_flutter_analyzer do |options|
  FLUTTER_ANALYZER_OUTPUT_PATH = "#{smf_workspace_dir}/flutter_analyzer.xml"
  flutter_analyzer_output = sh("cd #{smf_workspace_dir} && #{smf_get_flutter_binary_path} analyze || true")
  flutter_analyzer_file = File.new(FLUTTER_ANALYZER_OUTPUT_PATH, 'w+')

  flutter_analyzer_xml = _smf_flutter_analyzer_output_to_xml(flutter_analyzer_output)

  File.write(flutter_analyzer_file, flutter_analyzer_xml)
end

def _smf_flutter_analyzer_output_to_xml(output)
  lines = output.split(/\n/)

  builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml.checkstyle {
      lines.each do |l|
        parts = l.split(/ • /)
        xml.file {
          xml.name parts[2].split(/:/)[0]
          xml.error(line: parts[2].split(/:/)[1], column: parts[2].split(/:/)[2], severity: parts[0].strip, message: parts[1], source: parts[3])
        }
      end
    }
  end
  builder.to_xml
end
