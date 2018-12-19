#From mdedeboer



Function Get-DependentCollections{
    Param($collID)
    #Settings
    $strSQLServer = 'SCCM-SQL-01'
    $strSQLDB = 'CCM_CCM'

    #Server Connection
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Data Source=$strSQLServer;Initial Catalog=$strSQLDB;Integrated Security=SSPI;"
    $conn.open()
    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.connection = $conn
    
    #Execute the query
    $cmd.CommandText = "SELECT col1.Name AS DependentCollection, col1.CollectionID As DependentColID, CASE When vSMS_CollectionDependencies.RelationshipType = 1 then 'Limited To'  When vSMS_CollectionDependencies.RelationshipType = 2 then 'Include'  When vSMS_CollectionDependencies.RelationshipType = 3 then 'Exclude' End As RelationShipType FROM vSMS_CollectionDependencies INNER JOIN v_Collection as col1   ON vSMS_CollectionDependencies.DependentCollectionID = col1.CollectionID INNER JOIN v_Collection as col2   ON vSMS_CollectionDependencies.SourceCollectionID = col2.CollectionID Where col2.CollectionID = '${collID}'"
    $reader = $cmd.ExecuteReader()
    $arrReturns = @()
    While ($reader.Read())
    {
     $row = @{ }
     for ($i = 0; $i -lt $reader.FieldCount; $i++)
     {
      $row[$reader.GetName($i)] = $reader.GetValue($i)
     }
     $arrReturns += new-object psobject -property $row
    }
    $conn.close()
    $arrReturns
}

