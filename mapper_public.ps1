$MurderName = 'C:\MapFiles\' + $date.Month +"-"+ $date.Year + '_murder.csv' #This script originally created a bunch of files, pared back for simplicity's sake
If (Test-Path $MurderName){Remove-Item $MurderName} #Deletes any old files still lingering around

$SleepTime = 100 #Sleep Duration in MS.  This is required to avoid hitting Google's API limits on the Geocode free-tier.

$DBServer = "server-name"
$databasename = "db-name"
$user = "db-username"
$password = Get-Content \\path-to\password-file\mapper.pwf #There are many secure ways to handle password-storing in PS.  This is one (lame) method that works for me.

$Connection = new-object system.data.sqlclient.sqlconnection #Set new object to connect to sql database
$Connection.ConnectionString ="server=$DBServer;database=$databasename; user id=$user; password=$password" #trusted_connection=True" # Connectiongstring setting for local machine database with window authentication

# Connect to Database and Run Query
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand #setting object to use sql commands
$Connection.open()

#region Murder
#Replace with your query.  Wherever your "to be geocoded" address exists, either select it AS ADDRESS or replace the $Row.ADDRESS references below...
$SqlQuery = @"
USE db
SELECT *
FROM TABLE
WHERE CRITERIA
"@

$SqlCmd.CommandText = $SqlQuery
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$SqlCmd.Connection = $Connection
$DataSet = New-Object System.Data.DataSet

Write-Host 'Murder Query Returned' $SqlAdapter.Fill($DataSet) 'Rows' -foregroundcolor DarkYellow #For debug purposes, to make sure data was selected.

#This writes a header-row to the table, so long as more than 0 rows were returned.
If ($SqlAdapter.Fill($DataSet) -gt 0) {
'lat,lon,murder' | Out-File $MurderName -Append -Encoding ascii
}

#This loop steps through each row that's returned.
ForEach($Row in $DataSet.Tables[0])
{
#In my specific case, two columns "XCOORD" and "YCOORD" store the LAT/LON if available.  If those columns are empty, the address is passed to Google's geocoder.
If ($Row.XCOORD -eq '') {

#Builds the URL to be passed.  Replaces spaces in the address with "+"
#I also hard-code the city/state, as those are known for me.
#Finally, make sure to replace API_KEY with your own API Key
$URL = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + $Row.ADDRESS.Replace(' ','+') + ',+CityName,+STATE&key=API_KEY'
$Geocode = Invoke-RestMethod $URL | Select -Property results
Sleep -m $SleepTime #This is required, as you can easily hit the 10 queries per second limit.
$xy = $Geocode[0].results.geometry.location.lat.ToString()+','+$Geocode[0].results.geometry.location.lng.ToString() #This is the returned LAT/LON
}
Else 
{
    $xy = $Row.YCOORD.ToString()+','+$Row.XCOORD.ToString() #Uses the XCOORD and YCOORD columns, if not empty
}

$xy +',murder' | Out-File $MurderName -Append -Encoding ascii #Output to CSV
}
#endregion



$Connection.Close()