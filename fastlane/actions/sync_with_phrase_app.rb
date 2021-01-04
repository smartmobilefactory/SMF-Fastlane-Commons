module Fastlane
  module Actions
    class SyncWithPhraseAppAction < Action
      def self.run(params)
        projectId = params[:project_id]
        uploadResourceDir = params[:upload_resource_dir]
        downloadResourceDir = params[:download_resource_dir]
        resourceDir = params[:resource_dir]
        languages = params[:languages]
        isKmpp = params[:is_kmpp]
        
        apiToken = ENV["PHRASE_APP_TOKEN"]

        if !apiToken
           raise "PHRASE_APP_TOKEN missing" 
        end
        
        if !resourceDir
          if isKmpp
            resourceDir = "./core/src/commonMain/resources/MR/"
          else
            resourceDir = "./app/src/main/res/"
          end
        end

        if !uploadResourceDir
          if isKmpp
            uploadResourceDir = resourceDir + "base"
          else
            uploadResourceDir = resourceDir + "values"
          end
        end
        
        if !downloadResourceDir
          downloadResourceDir = resourceDir
        end

        if !languages || !languages['default']
           raise "default language is not set"
        end

        if isKmpp
          hasMultipleTagsUploaded = uploadKmppStrings(apiToken, projectId, uploadResourceDir, languages)
        else
          hasMultipleTagsUploaded = uploadStrings(apiToken, projectId, uploadResourceDir, languages)
        end
        downloadTranslations(apiToken, projectId, downloadResourceDir, languages, hasMultipleTagsUploaded, isKmpp)

        commitChangesIfNeeded(downloadResourceDir)

      end

      def self.uploadStrings(apiToken, projectId, resourceDir, languages)
        uploadedTagCount = 0
        Dir.foreach(resourceDir) do |item|
          next if item == '.' or item == '..'
          next if !item.start_with?("strings")
          tag = item.gsub(/(.*).xml/, '\1')
          uploadedTagCount = uploadedTagCount + 1
          sh(buildUploadStringsCommand(apiToken, projectId, languages['default'], resourceDir + "/" + item, tag))
        end
        return uploadedTagCount > 1
      end

      def self.downloadTranslations(apiToken, projectId, resourceDir, languages, hasMultipleTagsUploaded, isKmpp)

        languages.each do |languageKey, languageId|
          print languageKey + " - " + languageId

          if isKmpp
            dir = resourceDir + languageKey
            if languageKey == "default"
              dir = resourceDir + "base"
            end
          else
            dir = resourceDir + "values-" + languageKey
            if languageKey == "default"
              dir = resourceDir + "values"
            end
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

      def self.commitChangesIfNeeded(path)
          nothing_to_commit = `git status --porcelain #{path}`.empty?
          if !nothing_to_commit
              other_action.git_add(path: path)
              other_action.git_commit(path: path, message: "Updated strings from PhraseApp")
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
                                       optional: false),

          FastlaneCore::ConfigItem.new(key: :is_kmpp,
                                       env_name: "IS_KMPP",
                                       default_value: false,
                                       is_string: false
                                       description: "when true the naming conventions of moko/resources are used to support shared translations",
                                       optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:android].include? platform
      end
    end
  end
end
