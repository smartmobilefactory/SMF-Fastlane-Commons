require_relative './project_analysers/analysers/branch_name_analyser.rb'

def smf_meta_report_ios(options)

	############### SETUP ######################
	src_root = Git::clone(options[:repo_url], options[:branch])

	############### ANALYSIS ###################
	analysis_data = []
	analysis_data.push(IOSProjectAnalyser::analyse(src_root))
  analysis_data.compact!

  ############### UPLOAD #####################

  GoogleSpreadSheetUploader::report_to_google_sheets(
    analysis_data,
    options[:branch],
    src_root
  )

end