# Google Spreadsheets

The functions declared here are used to prepare, format and upload data to the Google Spreadsheet API.

## smf_create_spreadsheet_entry

A spread sheet entry holds data for one line of the spread sheet, it is important that for each entry there is a value set.
If a value does not existent (e.g. nil) it should be set to an empty string, to ensure this, use `_smf_unwrap_value`.

### Example
```
sheet_entry = smf_create_spreadsheet_entry(single_sheet_entry)
```

## smf_create_sheet_data_from_entries

Takes sheet_entries (array) and reporting_type and creates a valid JSON (will all necessary keys).
The output JSON is to be used for online Google spreadsheet with the function `smf_google_api_append_data_to_spread_sheet`.

### Example
```
sheet_data = smf_create_sheet_data_from_entries([sheet_entry], :AUTOMATIC_REPORTING)
```

## smf_google_api_append_data_to_spread_sheet

Using a temporary access token, append the data to a given online spreadsheet.

### Example
```
sheet_id = "ID stored in the credentials store"
sheet_name = "Name as ruby constant"
smf_google_api_append_data_to_spread_sheet(sheet_id, sheet_name, sheet_data)
```
