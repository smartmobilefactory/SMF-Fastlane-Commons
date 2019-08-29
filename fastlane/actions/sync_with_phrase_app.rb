module Fastlane
  module Actions
    class SyncWithPhraseAppAction < Action
      def self.run(params)
        branch= params[:branch]
        projectId = params[:project_id]
        uploadResourceDir = params[:upload_resource_dir]
        downloadResourceDir = params[:download_resource_dir]
        resourceDir = params[:resource_dir]
        languages = params[:languages]
        
        apiToken = ENV["PHRASE_APP_TOKEN"]

        if !apiToken
           raise "PHRASE_APP_TOKEN missing" 
        end
        
        if !resourceDir
          resourceDir = "./app/src/main/res/"
        end
        
        if !uploadResourceDir
          uploadResourceDir = resourceDir
        end
        
        if !downloadResourceDir
          downloadResourceDir = resourceDir
        end

        if !languages || !languages['default']
           raise "default language is not set"
        end

        hasMultipleTagsUploaded = uploadStrings(apiToken, projectId, uploadResourceDir, languages)
        downloadTranslations(apiToken, projectId, downloadResourceDir, languages, hasMultipleTagsUploaded)

        if branch
          commitChangesIfNeeded(downloadResourceDir, branch)
        end

      end

      def self.uploadStrings(apiToken, projectId, resourceDir, languages)
        defaultValuesDir = resourceDir + "values"
        uploadedTagCount = 0
        Dir.foreach(defaultValuesDir) do |item|
          next if item == '.' or item == '..'
          next if !item.start_with?("strings")
          tag = item.gsub(/(.*).xml/, '\1')
          uploadedTagCount = uploadedTagCount + 1
          sh(buildUploadStringsCommand(apiToken, projectId, languages['default'], defaultValuesDir + "/" + item, tag))
        end
        return uploadedTagCount > 1
      end

      def self.downloadTranslations(apiToken, projectId, resourceDir, languages, hasMultipleTagsUploaded)
        languages.each do |languageKey, languageId|
          print languageKey + " - " + languageId

          dir = resourceDir + "values-" + languageKey
          if languageKey == "default"
            dir = resourceDir + "values"
          end

          if languageKey == "default" and hasMultipleTagsUploaded
            downloadTranslationsWithTags(apiToken, projectId, dir, languageId)
          else
            outputFile = dir + "/strings.xml"
            sh("mkdir -p #{dir}")
            sh(buildDownloadTranslationShellCommand(apiToken, projectId, languageId, outputFile, nil))
          end
        end
      end

      def self.downloadTranslationsWithTags(apiToken, projectId, dir, languageId)
        Dir.foreach(dir) do |item|
          next if item == '.' or item == '..'
          next if !item.start_with?("strings")
          tag = item.gsub(/(.*).xml/, '\1')
          
          outputFile = dir + "/#{tag}.xml"
          sh(buildDownloadTranslationShellCommand(apiToken, projectId, languageId, outputFile, tag))
        end
      end

      def self.buildDownloadTranslationShellCommand(apiToken, projectId, languageId, outputFile, tag)
        #curl -H "Authorization: token <User/Access-Token>" "https://api.phraseapp.com/api/v2/projects/<Project-ID>/locales/<Locale-ID>/download?file_format=xml" > ./app/src/main/res/values<-XY>/$tag.xml

        tagString = ""
        if tag
            tagString = "&tag=#{tag}"
        end

        command = []
        command << "curl -H \"Authorization: token #{apiToken}\""
        command << " \"https://api.phraseapp.com/api/v2/projects/#{projectId}/locales/#{languageId}/download?file_format=xml#{tagString}\""
        command << " > #{outputFile}"
        command
      end

      def self.buildUploadStringsCommand(apiToken, projectId, languageId, inputFile, tags)
        #curl -H "Authorization: token <User/Access-Token>" -X POST -F file=<file> -F file_format=xml -F tags=<tag> -F locale_id=<local_id> "https://phraseapp.com/api/v2/projects/<projectId>/uploads"
        command = []
        command << "curl -H \"Authorization: token #{apiToken}\" -X POST"
        command << " -F file=@#{inputFile}"
        if tags
          command << " -F tags=#{tags}"
        end
        command << " -F locale_id=#{languageId}"
        command << " \"https://phraseapp.com/api/v2/projects/#{projectId}/uploads\""
      end

      def self.commitChangesIfNeeded(path, branch)
          nothing_to_commit = `git status --porcelain #{path}`.empty?
          if !nothing_to_commit
              pathToCommit = "../" + path
              other_action.git_add(path: pathToCommit)
              other_action.git_commit(path: pathToCommit, message: "Updated strings from PhraseApp")
              other_action.smf_push_to_git_remote(local_branch: branch)
          end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Sync app strings with phrase app"
      end

      def self.authors
        ["smf"]
      end

      def self.available_options
        [

          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: "FL_BRANCH",
                                       description: "branch to commit the changes",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :project_id,
                                       env_name: "FL_PHRASE_APP_PROJECT_ID",
                                       description: "",
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :resource_dir,
                                       env_name: "APP_RESOURCE_DIR",
                                       description: "",
                                       optional: true),
          
          FastlaneCore::ConfigItem.new(key: :upload_resource_dir,
                                       env_name: "APP_UPLOAD_RESOURCE_DIR",
                                       description: "",
                                       optional: true),
          
          FastlaneCore::ConfigItem.new(key: :download_resource_dir,
                                       env_name: "APP_DOWNLOAD_RESOURCE_DIR",
                                       description: "",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :languages,
                                       env_name: "APP_PHRASE_APP_LANGUAGES",
                                       type: Hash,
                                       description: "example: {\"de\" => \"locale_id\"}",
                                       optional: false)
        ]
      end

      def self.is_supported?(platform)
        [:android].include? platform
      end
    end
  end
end
