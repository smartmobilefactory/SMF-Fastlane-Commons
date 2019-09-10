##############
### Helper ###
##############

def smf_download_asset(asset_name, assets, token)

  asset_url = smf_asset_url_from_webhook_event(asset_name, assets)

  sh(
    "curl", "-X", "GET",
    "-H", "Accept: application/octet-stream", 
    "-LJ",
    "-o", asset_name,
    asset_url.gsub("https://", "https://#{token}@")
  )

  unzip_dir = "#{asset_name.downcase}-unzipped"
  sh "mkdir #{unzip_dir}"

  sh "cd #{unzip_dir} && unzip ../#{asset_name}"

  Dir.glob("#{unzip_dir}/*.*").each do |file|
    return file
  end

  raise "Couldn't find a asset download!"
end

def smf_asset_url_from_webhook_event(asset_name, assets)

  assets.each { |asset|
    if asset["name"] == asset_name
      return asset["url"]
    end
  }

  raise "Couldn't find a matching asset with the name \"#{asset_name}\" in \"#{assets}\""
end

# Download release from Github, by tag.
def smf_fetch_release_for_tag(tag, token, project)

  url = "https://#{token}@api.github.com/repos/#{project}/releases/tags/#{tag}"

  return JSON.parse(RestClient.get(url, {:params => {:access_token => token}}))
end

# return assets from the downloaded Asset.
def smf_fetch_assets_for_tag(tag, token, project)
  release = smf_fetch_release_for_tag(tag, token, project)

  return release["assets"]
end
