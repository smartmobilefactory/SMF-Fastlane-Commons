#!/usr/bin/ruby
require 'json'
require 'net/http'
require 'date'

# Retrieves a temporary access token to the google spread sheets
# use to then upload/add/append new data to google spread sheets
def _smf_google_api_get_bearer_token
  access_token_uri = URI.parse('https://accounts.google.com/o/oauth2/token')
  client_id = ENV[$REPORTING_GOOGLE_SHEETS_CLIENT_ID_KEY]
  client_secret = ENV[$REPORTING_GOOGLE_SHEETS_CLIENT_SECRET_KEY]
  refresh_token = ENV[$REPORTING_GOOGLE_SHEETS_REFRESH_TOKEN_KEY]

  request = Net::HTTP::Post.new(access_token_uri)
  request.set_form_data(
    'client_id' => client_id,
    'client_secret' => client_secret,
    'refresh_token' => refresh_token,
    'grant_type' => 'refresh_token'
  )

  response = Net::HTTP.start(access_token_uri.hostname, access_token_uri.port, use_ssl: true) do |client|
    client.request(request)
  end

  case response
  when Net::HTTPSuccess
    begin
      body = JSON.parse(response.body)
      return body.dig('access_token')
    rescue
      raise 'Error parsing response body'
    end
  else
    raise "Error fetching refresh token #{response.message}"
  end
end

def _smf_google_api_start_request(request, uri)
  # First renew the access token
  bearer_token = _smf_google_api_get_bearer_token

  # Delay of 5 seconds to let Google's servers propagate the new access_token
  # https://stackoverflow.com/a/42771170/2790648
  # Added on 14.09.2020 due to random "Internal Server Error (RuntimeError)"
  sleep(5)

  request.content_type = 'application/json'
  request['Accept'] = 'application/json'
  request['Authorization'] = "Bearer #{bearer_token}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |client|
    client.request(request)
  end

  case response
  when Net::HTTPSuccess
    begin
      body = JSON.parse(response.body)
      return body
    rescue
      raise 'Error parsing response body'
    end
  else
    raise "API error: #{response.code}:'#{response.message}' for request: #{uri}\n Body: #{response.body}"
  end
end

# Using a temporary access token, delete all data from a spreadsheet's page
def smf_google_api_delete_data_from_spreadsheet(sheet_id, sheet_name)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}:clear"
  request = Net::HTTP::Post.new(uri)

  _smf_google_api_start_request(request, uri)
end

# Using a temporary access token, upload a CSV string to a spreadsheet's page
def smf_google_api_upload_csv_to_spreadsheet(spreadsheet_id, sheet_id, csv_data)

  #uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{spreadsheet_id}:batchUpdate"
  uri = URI.parse "https://hookb.in/033yPaQmwet3J0ooJLEY"
  request = Net::HTTP::Post.new(uri)

  data = {
    "requests" =>  [{
        "pasteData" => {
          "coordinate" => {
            "sheetId" => sheet_id,
            "rowIndex" => "0",
            "columnIndex" => "0"
          },
          "data" => csv_data,
          "type" => "PASTE_NORMAL",
          "delimiter" => ";"
        }
    }]
  }

  #data = '''{"requests":[{"pasteData":{"coordinate":{"sheetId":1795696148,"rowIndex":"0","columnIndex":"0"},"data":"Account;Project Name;Epic Link;Epic Name;Component Name;Fix Version Name;Original Estimate (Incl. Sub-tasks);1.2020;2.2020;3.2020;4.2020;5.2020;6.2020;7.2020;8.2020;9.2020;10.2020;11.2020;12.2020;1.2021;2.2021;3.2021;4.2021;5.2021;6.2021;7.2021;8.2021;9.2021;10.2021;11.2021;12.2021;Days\n365FarmNet;365FarmNet;-;-;iOS App;-;4800,00;15,69;11,13;21,44;11,75;11,94;12,69;8,63;22,27;8;11,25;5,69;2,56;7,63;1,19;1,88;1,19;1,31;10,75;2;0;0;0;0;0;168,99\n365FarmNet;365FarmNet;-;-;Android App;-;640,00;9,69;13,81;20,5;28,94;12,13;10,88;9,19;8,44;11;0;0;0;1,13;0,13;0;0,13;0;0,88;0,25;0;0;0;0;0;127,1\nBerliner Stadtreinigung;BSR Android;-;-;Projektmanagement;4,8;;0;0;0;0;0;0;3,97;0;0;0;5,13;3,28;4,53;0,06;0;0;0;0;0;0;0;0;0;0;16,97\nBerliner Stadtreinigung;BSR Android;-;-;QA;4,8;;0;0;0;0;0;0;0;0;1;0,63;2,25;0;1,5;0;0;0;0;0;0;0;0;0;0;0;5,38\nBerliner Stadtreinigung;BSR iOS;-;-;Design & Konzept;-;;0,06;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,06\nBerliner Stadtreinigung;BSR Android;-;-;Projektmanagement;4,9;;0;0;0;0;0;0;0;0;0;0;0;0;0;2,75;1,88;3,16;3,56;1,13;0;0;0;0;0;0;12,48\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;-;;0;0;0,56;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,56\nBerliner Stadtreinigung;BSR iOS;-;-;QA;5,7.1;20,00;0;0;0;0;0;0;0;0;1,88;1,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,13\nBerliner Stadtreinigung;BSR Android;-;-;QA;4,9;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,9;0;0;0;0;0;0;0;0;0;2,9\nBerliner Stadtreinigung;BSR iOS;-;-;Design & Konzept;No Version;;0;0;0;0;0;0;0;8,13;2;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;11,13\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;No Version;;1,91;4,38;0;0;0;0;0;0;0,06;0;3,75;0;0;0;0;0;0;0,75;0;0;0;0;0;0;10,85\nBerliner Stadtreinigung;BSR Android;BSRDROID-620;AND - User test feedback;Android App;4,7;8,00;0;0;0;1,56;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,56\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;5,7.1;8,00;0;0;0;0;0;0;0,75;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,75\nBerliner Stadtreinigung;BSR Android;BSRDROID-703;\"Redesign for \"\"Eigene Termine\"\" Feature  \";Design & Konzept;4,8;;0;0;0;0;0;0,38;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,38\nBerliner Stadtreinigung;BSR Android;-;-;Design & Konzept;No Version;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;4,13;0;0;0;0;0;0;0;0;0;4,13\nBerliner Stadtreinigung;BSR iOS;BSRIOS-647;iOS - Eigene Termine;iOS App;5,7.1;;0;0;0;0;0;0;0;0;1,5;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,5\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,7.1;8,00;0;0;0;0;0;0;2,31;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,31\nBerliner Stadtreinigung;BSR Backend;-;-;Backend;No Version;2,00;0;0;0;0;0;0;0;0;0;0;1,4;0,53;0;0;0;0;0;0;0;0;0;0;0;0;1,93\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,8;64,00;0;0;0;1,09;0;1,31;0;0;2,25;4,47;0;0;1,78;3,88;0;0;0;0;0;0;0;0;0;0;14,78\nBerliner Stadtreinigung;BSR Android;-;-;Design & Konzept;4,9;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,06;0;0;0;0;0;0;0;0;0;0,06\nBerliner Stadtreinigung;BSR Android;BSRDROID-620;AND - User test feedback;Android App;4,6;59,00;4,25;3,94;0,09;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;8,28\nBerliner Stadtreinigung;BSR iOS;BSRIOS-580;IOS - User test feedback;iOS App;5,7;16,00;0;0;2,63;0;0;0,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,76\nBerliner Stadtreinigung;BSR iOS;BSRIOS-685;iOS NochMall Map Feature;iOS App;5,9;40,00;0;0;0;0;0;0;0;0;0;0;3;0,5;0;0;0;0;0;0;0;0;0;0;0;0;3,5\nBerliner Stadtreinigung;BSR Android;BSRDROID-718;AND - Eigene Termine;Android App;4,7.1;2,00;0;0;0;0;0;0;0;0;0,19;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,44\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,5;4,00;0;0;0;0;0;0,06;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,06\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,6;4,00;1,13;1,31;1,38;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,82\nBerliner Stadtreinigung;BSR Android;BSRDROID-746;Android NochMall Map Feature;Android App;4,9;40,00;0;0;0;0;0;0;0;0;0;0;8,75;0;0;0;0;0;0;0;0;0;0;0;0;0;8,75\nBerliner Stadtreinigung;BSR iOS;BSRIOS-608;IOS - Tracking;iOS App;5,7;36,00;0;0;0;6,22;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;6,22\nBerliner Stadtreinigung;BSR Android;-;-;Projektmanagement;5,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,19;0;0;0;0;0;0,19\nBerliner Stadtreinigung;BSR iOS;-;-;Projektmanagement;5,6;;1,75;2,44;3,25;0,06;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;7,5\nBerliner Stadtreinigung;BSR iOS;-;-;QA;5,6;;0;0,56;2,5;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,06\nBerliner Stadtreinigung;BSR iOS;-;-;Projektmanagement;5,7;;0;0;0,19;4,13;1,88;4,03;4,22;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;14,45\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;5,7;19,00;0;0;0,16;0;0;4,13;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;4,54\nBerliner Stadtreinigung;BSR iOS;-;-;Projektmanagement;5,8;;0;0;0;0;0;0;0;0;0;4,47;4,84;3,38;4,13;0,06;0;0;0;0;0;0;0;0;0;0;16,88\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;5,8;0,50;0;0;0;0;0;0;0;0;1,31;0,75;0;0,38;0;0;0;0;0;0;0;0;0;0;0;0;2,44\nBerliner Stadtreinigung;BSR iOS;-;-;QA;5,8;;0;0;0;0;0;0;0;0;1,63;1,44;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,07\nBerliner Stadtreinigung;BSR iOS;-;-;Projektmanagement;5,9;;0;0;0;0;0;0;0;0;0;0;0;0;0;2,19;2,13;2,41;3,28;2;0;0;0;0;0;0;12,01\nBerliner Stadtreinigung;BSR Android;BSRDROID-683;AND - Tracking;Android App;5,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,5;0;0;0;0;0;0;2,5\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;5,6;0,00;0,94;0;1,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,07\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;6,0;40,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,31;0;0;0;0;0;0;0;2,31\nBerliner Stadtreinigung;BSR Android;-;-;Projektmanagement;4,7.1;;0;0;0;0;0;0;0;2,56;3,34;4,34;0;0;0;0;0;0;0;0;0;0;0;0;0;0;10,24\nBerliner Stadtreinigung;BSR Backend;BSRIOS-685;iOS NochMall Map Feature;Backend;No Version;3,00;0;0;0;0;0;0;0;0;0;0;0,51;0;0;0;0;0;0;0;0;0;0;0;0;0;0,51\nBerliner Stadtreinigung;BSR Android;BSRDROID-683;AND - Tracking;Android App;4,7;36,00;0;0;1,44;5,56;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;7\nBerliner Stadtreinigung;BSR iOS;-;-;Projektmanagement;5,7.1;;0;0;0;0;0;0;0;2,19;4,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;6,32\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,9;28,00;0;0;0;0;0;0;0;0;0;0;2,81;1,66;0,25;3,63;2,69;0;0;0;0;0;0;0;0;0;11,04\nBerliner Stadtreinigung;BSR iOS;BSRIOS-685;iOS NochMall Map Feature;Design & Konzept;5,9;;0;0;0;0;0;0;0;0;0;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25\nBerliner Stadtreinigung;BSR iOS;BSRIOS-608;IOS - Tracking;iOS App;6,0;32,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,94;0,63;0;0;0;0;0;3,57\nBerliner Stadtreinigung;BSR Android;-;-;Android App;-;11,00;16,63;7,75;0,69;0;0;1,66;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;26,73\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,6.1;24,00;0;0;0;6,34;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;6,34\nBerliner Stadtreinigung;BSR Android;-;-;Android App;No Version;11,00;3;9,75;0;0;0;0;0;0;0,91;0,75;0;0;1,06;0;0;1,47;0;0;0;0;0;0;0;0;16,94\nBerliner Stadtreinigung;BSR iOS;BSRDROID-703;\"Redesign for \"\"Eigene Termine\"\" Feature  \";Design & Konzept;-;;0;0;0;0;0;1,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,13\nBerliner Stadtreinigung;BSR Android;-;-;Android App;4,7;40,00;0;0;2,81;0,56;0,69;6,81;2,06;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;12,93\nBerliner Stadtreinigung;BSR Android;-;-;QA;No Version;;0;0,31;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,31\nBerliner Stadtreinigung;BSR Android;BSRDROID-718;AND - Eigene Termine;Android App;4,8;96,00;0;0;0;0;0;0;19,34;2,31;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;21,65\nBerliner Stadtreinigung;BSR iOS;BSRIOS-647;iOS - Eigene Termine;iOS App;5,8;;0;0;0;0;0;0;0;0;4,38;1,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;5,63\nBerliner Stadtreinigung;BSR iOS;-;-;Projektmanagement;6,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25;0;0;0;0;0;0,25\nBerliner Stadtreinigung;BSR iOS;-;-;iOS App;5,9;12,00;0;0;0;0;0;0;0;0;0;0;3,31;0,13;0;0,75;4,88;0;0;0;0;0;0;0;0;0;9,07\nBerliner Stadtreinigung;BSR Android;BSRDROID-703;\"Redesign for \"\"Eigene Termine\"\" Feature  \";Design & Konzept;-;;0;0;0;0;0;2,5;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,5\nBerliner Stadtreinigung;BSR Android;-;-;Android App;5,0;12,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1\nBerliner Stadtreinigung;BSR Android;BSRDROID-703;\"Redesign for \"\"Eigene Termine\"\" Feature  \";Design & Konzept;No Version;;0;0;0;0;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25\nBerliner Stadtreinigung;BSR Android;-;-;Design & Konzept;4,7.1;;0;0;0;0;0;0;0,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,13\nBerliner Stadtreinigung;BSR iOS;BSRIOS-580;IOS - User test feedback;iOS App;5,6;31,00;1,35;3,66;2,39;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;7,4\nBerliner Stadtreinigung;BSR iOS;BSRIOS-52;Basic structure / dashboard;iOS App;-;;0;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25\nBerliner Stadtreinigung;BSR Android;-;-;Projektmanagement;4,6;;1,56;2,5;1,31;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;5,37\nBerliner Stadtreinigung;BSR Android;-;-;QA;4,6;;0;1,38;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,63\nBerliner Stadtreinigung;BSR Android;-;-;Projektmanagement;4,7;;0;0;0,25;4,13;1,94;4,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;10,45\nCorporate Benefits;Corporate Benefits iOS;-;-;iOS App;-;6,00;0;0,5;0,25;0;0,38;0,38;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,76\nCorporate Benefits;Corporate Benefits iOS;-;-;iOS App;2,0.2;16,00;0;0;0;0;0;0;0,06;1,63;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,69\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;3,0;;0;0;0;0;0;0;0,13;0,31;0;0;0;0;0,13;0;0;0;0;0;0;0;0;0;0;0;0,57\nCorporate Benefits;Corporate Benefits Android;CBENEFDROID-218;Native MVP;Android App;3,0;;0;0;0;0;0;0;0;0;0;0;0;0;0,5;1,47;0;0;0;0;0;0;0;0;0;0;1,97\nCorporate Benefits;Corporate Benefits iOS;-;-;Projektmanagement;3,0;;0;0;0,81;0,13;1,66;1,53;2,88;4,91;2,72;1,56;0,63;0,78;1,06;0,09;0,38;0;0;0,25;0;0;0;0;0;0;19,39\nCorporate Benefits;Corporate Benefits Android;-;-;QA;2,0.3;;0;0;0,88;0,75;0,63;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,26\nCorporate Benefits;Corporate Benefits Android;-;-;QA;2,0.5;;0;0;0;0;0;2,09;0;0;1,63;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,72\nCorporate Benefits;Corporate Benefits Android;-;-;Projektmanagement;-;;0;0;0;2,09;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,09\nCorporate Benefits;Corporate Benefits Android;-;-;QA;-;;0;0,31;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,31\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;2,0.4.;16,00;0;0;0;2,69;0;2,63;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;5,32\nCorporate Benefits;Corporate Benefits iOS;-;-;iOS App;3,0;;0;0;0;0;0;0;0;0,25;0,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,38\nCorporate Benefits;Corporate Benefits iOS;CBENEFDROID-218;Native MVP;iOS App;3,0;;0;0;0;0;0;0;0;0;0;0;0;0;0,5;1,5;0;0;0;0;0;0;0;0;0;0;2\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;2,0.3;;0;0;2,22;0,5;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,72\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;2,0.5;;0;0;0;0;0;0;0;0;2;0;0,25;0;1;0,63;0,13;0;0;0;0;0;0;0;0;0;4,01\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;2,0.6;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,94;3,5;2,38;0,25;0;0;0;0;0;0;10,07\nCorporate Benefits;Corporate Benefits iOS;-;-;QA;2,0.2;;0;0;0;0;0;0;0;1,44;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,44\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;No Version;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,16;0;0;0;0;0;0;0;0,16\nCorporate Benefits;Corporate Benefits Android;CBENEFDROID-218;Native MVP;Android App;2,0.6;;0;0;0;0;0;0;0;0;2,47;2,06;0,94;0;0;5,75;1;0;0,63;0,25;0;0;0;0;0;0;13,1\nCorporate Benefits;Corporate Benefits Android;-;-;Android App;-;4,00;1,59;0,63;0,5;1,13;0,59;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;4,69\nCorporate Benefits;Corporate Benefits Android;-;-;Projektmanagement;3,0;;1,13;1,56;4,53;3,47;2,28;5,44;2,19;3,38;2,84;3,47;0,81;0,19;4,25;4,31;1,63;0,56;1,34;0,69;0;0;0;0;0;0;44,07\nCorporate Benefits;Corporate Benefits Android;CBENEFDROID-218;Native MVP;Projektmanagement;3,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,44;3,94;4,5;0;0;0;0;0;0;0;10,88\nCorporate Benefits;Corporate Benefits iOS;-;-;Design & Konzept;2,0.2;;0;0;0;0;0;0;0;0,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,13\nCorporate Benefits;Corporate Benefits Backend;-;-;Backend/API;-;;0;0;0,44;1,04;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,48\nCorporate Benefits;Corporate Benefits iOS;-;-;iOS App;2,0.3;4,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;3,5;3;0;0;0;0;0;0;0;7,5\nCorporate Benefits;Corporate Benefits iOS;-;-;Design & Konzept;-;;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25\nCorporate Benefits;Corporate Benefits iOS;-;-;iOS App;No Version;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;1\nDuden;Stowasser iOS;-;-;iOS App;1,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,25;0;0;0;0;0;0;0;0;1,25\nDuden;Duden iOS;-;-;Projektmanagement;1,0 D1 Duden;8,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,5;0;0,25;0;0;0;0;0;0;0,75\nDuden;Stowasser iOS;-;-;Design & Konzept;1,0;8,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,56;1,98;0;0;0;0;0;0;0;2,54\nDuden;Duden Web;-;-;Infrastruktur;1,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,31;0;0;0;0;0;0;0,31\nDuden;Duden Android;-;-;Projektmanagement;1,0 PoC;;0;0;0;0;0;0;0;0;0;0;0;0,13;5,96;4,69;0,31;0;0;0;0;0;0;0;0;0;11,09\nDuden;Duden iOS;-;-;Design & Konzept;1,0 PoC;;0;0;0;0;0;0;0;0;0;0;0;0;0;5,06;2,03;0;0;0;0;0;0;0;0;0;7,09\nDuden;Duden iOS;-;-;iOS App;1,0 PoC;;0;0;0;0;0;0;0;0;0;0;0;0;1;8,75;0;0;0;0;0;0;0;0;0;0;9,75\nDuden;Duden Web;-;-;Admin Panel;1,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3,82;7,4;1,31;0;0;0;0;0;12,53\nDuden;Duden Android;-;-;Design & Konzept;1,0 PoC;;0;0;0;0;0;0;0;0;0;0;0;0;0;3;0,75;0;0;0;0;0;0;0;0;0;3,75\nDuden;Duden Android;-;-;Android App;1,0 PoC;;0;0;0;0;0;0;0;0;0;0;0;0;3,69;18,99;0;0;0;0;0;0;0;0;0;0;22,68\nDuden;Stowasser iOS;-;-;Projektmanagement;1,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,13;0,13;0;0;0;0;0;0;0;0,26\nDuden;Duden iOS;-;-;iOS App;1,0 D1 Duden;48,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;4,25;8,88;14,38;32,47;0,99;0;0;0;0;0;60,97\nDuden;Duden iOS;-;-;Design & Konzept;1,0 D1 Duden;200,00;0;0;0;0;0;0;0;0;0;0;0;0;5,63;10,41;2,94;2,75;0;0,13;0;0;0;0;0;0;21,86\nDuden;Duden Web;-;-;Backend/API;1,0;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;3;6,08;10,83;11,2;0;0;0;0;0;0;31,11\nFrÃ¶bel;FrÃ¶bel Android;FROEBLANDR-187;Kotlin Update to 1,4.20;Android App;1,1;0,00;0;0;0;0;0;0;0;0;0;0;0;1,25;0;0;0;0;0;0;0;0;0;0;0;0;1,25\nFrÃ¶bel;FRÃ–BEL Terminal Android;FROEBTERMAND-12;Idle Screen;Android App;1,0;4,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,38;0,25;0;0,91;0,31;0;0;0;0;0;1,85\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-194;Blog items;Projektmanagement;1,1;;0;0;0;0;0;0;0;0;0;0;0;0;0;0,19;0;0;0;0;0;0;0;0;0;0;0,19\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-194;Blog items;QA;1,1;;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25;0;0;0;0;0;0;0;0;0;0;0,25\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-70;ANG - Display all shifts for a day on the dashboard;Projektmanagement;1,0;;0;0;0;0;0,25;0,25;0,5;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1\nFrÃ¶bel;FRÃ–BEL Terminal Android;FROEBTERMAND-9;Transponder Settings;Android App;1,0;1,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;11,78;1,31;0;0;0;0;0;0;14,09\nFrÃ¶bel;FrÃ¶bel Android;FROEBELIOS-10;Dashboard;Android App;1,0;;0;0;0;0;0;0,06;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,06\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-70;ANG - Display all shifts for a day on the dashboard;QA;1,0;;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-4;Absences funtionality;iOS App;1,0;24,00;0;0;0;3;0,94;0;0,38;0,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;4,45\nFrÃ¶bel;FrÃ¶bel Android;-;-;Android App;1,1.1;;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,5;0;0;0;0;0;0;0;0;0;0,5\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-50;Design Tasks for the MVP;Design & Konzept;1,0;8,00;0;0;0;5,31;1,5;3,63;2,63;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;13,07\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-90;\"ANG - Abesences within the \"\"Zeiterfassung\"\" screen\";Projektmanagement;1,0;;0;0;0;0;0,25;0,13;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,38\nFrÃ¶bel;FrÃ¶bel Android;FROEBLANDR-7;Intranet News / Blog;Android App;1,0;8,00;0;0;0;0;0;0;1,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,25\nFrÃ¶bel;FrÃ¶bel Android;FROEBLANDR-190;In-App Messages;Android App;1,1;4,00;0;0;0;0;0;0;0;0;0;0;0;0;0;0,88;0;0;0;0;0;0;0;0;0;0;0,88\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-8;Employee manual/ABC;iOS App;1,0;10,00;0;0;0;0;0;1,31;0;0;0,19;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1,5\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-90;\"ANG - Abesences within the \"\"Zeiterfassung\"\" screen\";QA;1,0;;0;0;0;0;0;0;0,25;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0,25\nFrÃ¶bel;FRÃ–BEL Terminal Android;FROEBTERMAND-10;User Login;Android App;1,0;14,50;0;0;0;0;0;0;0;0;0;0;0;0;0;0;2,63;8,34;2,34;13,81;0;0;0;0;0;0;27,12\nFrÃ¶bel;FrÃ¶bel iOS;FROEBELIOS-51;Project Management for MVP;Projektmanagement;1,0;40,00;0;0;0;3;0,63;2,06;0,69;1,63;1,44;0,75;0,47;0;0;0;0;0;0;0;0;0;0;0;0;0;10,67\n","type":"PASTE_NORMAL","delimiter":";"}}]}'''
  request.body = data
  #request.body = data.to_json
  #form_data = { "body" => data}
  #request.set_form_data(form_data)

  File.write("./debugging_data.json", data.to_json)

  _smf_google_api_start_request(request, uri)
end

# Using a temporary access token, get the identifier of a sheet based on its name
def smf_google_api_get_sheet_id_from_spreadsheet(spreadsheet_id, sheet_name)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{spreadsheet_id}"
  request = Net::HTTP::Get.new(uri)

  response_body = _smf_google_api_start_request(request, uri)
  sheet_id = nil
  response_body.dig('sheets').each do |sheet|
    if sheet.dig('properties', 'title') == sheet_name
      sheet_id = sheet.dig('properties', 'sheetId')
    end
  end

  return sheet_id
end

# Using a temporary access token, append the data to a given online spreadsheet
def smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, data)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}:append?valueInputOption=USER_ENTERED"
  request = Net::HTTP::Post.new(uri)
  request.body = data

  _smf_google_api_start_request(request, uri)
end

# Using a temporary access token, get the data from an online spreadsheet
def smf_google_api_get_data_from_spread_sheet(sheet_id, sheet_name)

  uri = URI.parse"https://sheets.googleapis.com/v4/spreadsheets/#{sheet_id}/values/#{sheet_name}"
  request = Net::HTTP::Get.new(uri)

  response_body = _smf_google_api_start_request(request, uri)
  return response_body.dig('values')
end

# Takes sheet_entries (array) and reporting_type to gather the necessary keys
# for a valid JSON reporting to the online spreadsheet.
def smf_create_sheet_data_from_entries(sheet_entries, reporting_type)

  values = []

  sheet_entries.each do |entry|
    if reporting_type == :AUTOMATIC_REPORTING
      values.push(_smf_automatic_reporting_spreadsheet_entry_to_line(entry))
    elsif reporting_type == :APPLE_META_REPORTING
      values.push(_smf_apple_meta_reporting_spreadsheet_entry_to_line(entry))
    elsif reporting_type == :ANDROID_META_REPORTING
      values.push(_smf_android_meta_reporting_spreadsheet_entry_to_line(entry))
    elsif reporting_type == :FINANCIAL_REPORTING
      values.push(_smf_financial_reporting_spreadsheet_entry_to_line(entry))
    end
  end

  data = {
    'values' => values,
    'majorDimension' =>'ROWS'
  }

  data.to_json
end

# A spread sheet entry holds data for one line of the spread sheet
# It is important that for each entry there is a value set.
# If a value does not existent (e.g. nil) it should be set to
# an empty string, to ensure this, use '_smf_unwrap_value'.
def smf_create_spreadsheet_entry(data)
  # The project_name is required.
  return nil if data[:project_name].nil?

  entry = {
    :date => Date.today.to_s,
    :repo => data[:project_name],
    :build_variant => _smf_unwrap_value(data[:build_variant]),
    :branch => _smf_unwrap_value(data[:branch]),
    :platform => _smf_unwrap_value(data[:platform]),
    :test_coverage => _smf_unwrap_value(data[:test_coverage]),
    :covered_lines => _smf_unwrap_value(data[:covered_lines]),
    :unit_test_count => _smf_unwrap_value(data[:unit_test_count])
  }

  entry
end

############### SPREAD SHEET HELPER ###############

def _smf_automatic_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:branch], entry[:platform], entry[:build_variant], entry[:test_coverage], entry[:covered_lines], entry[:unit_test_count]]
end

def _smf_apple_meta_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:platform], entry[:branch], entry[:xcode_version], entry[:idfa], entry[:bitcode], entry[:swiftlint_warnings], entry[:ats], entry[:swift_version], entry[:deployment_target]]
end

def _smf_android_meta_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:repo], entry[:platform], entry[:branch], entry[:min_sdk_version], entry[:target_sdk_version], entry[:kotlin_version], entry[:gradle_version]]
end

def _smf_financial_reporting_spreadsheet_entry_to_line(entry)
  # The order of the elements in this array directly correspond to the table columns in the google spread sheet
  # thus it is VERY IMPORTANT to not change the order!
  [entry[:date], entry[:project], entry[:sales], entry[:expenses], entry[:target], entry[:actual], entry[:daily_rate]]
end

def _smf_unwrap_value(value)
  value.nil? ? '' : value
end
