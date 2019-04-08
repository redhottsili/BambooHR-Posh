$API_URL = "https://api.bamboohr.com/api/gateway.php"
$API_Version = "v1"
$company = ""   # Your company name here
$API_Key = ""   # Your API key

function Get-BambooReport {
    param(
        [Parameter(Mandatory = $false)]
        [string]$ReportFormat = "CSV",
        [Parameter(Mandatory = $false)]
        [string]$Path = ".\",
        [Parameter(Mandatory = $false)]
        [string]$ReportID = "517",
        [Parameter(Mandatory = $false)]
        [string]$Username = "$API_Key", #This is the API_Key
        [Parameter(Mandatory = $false)]
        [string]$Pass = "randomstring" #This can be any random string
    )

    $params = @{
        uri     = "$API_URL/$company/$API_Version/reports/$ReportID?format=$ReportFormat";
        Method  = 'GET';
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pass")); "Accept" = 'application/json'; "Content-Type" = 'application/json'}
    }
    
    #Use TLS 1.2, not 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    #Download the report to a CSV file in the $path location
    Invoke-RestMethod @params -OutFile $Path\report.csv
    
    #Load the CSV into memory
    $results = Import-Csv -Path $Path\report.csv

    #Remove the CSV file
    Get-Item -Path $Path\report.csv

    Return $results
}

function Get-BambooChangedEmployee {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Date,
        [Parameter(Mandatory = $false)]
        [ValidateSet("inserted", "updated", "deleted")]
        [string]$Type,
        [Parameter(Mandatory = $false)]
        $TimeZone = "-05:00",
        [Parameter(Mandatory = $false)]
        [string]$Username = "$API_Key", #This is the API_Key
        [Parameter(Mandatory = $false)]
        [string]$Pass = "randomstring" #This can be any random string

    )

    $TimeZone = "-05:00"
    #Convert to ISO 8601 as Bamboo API specifies
    $Date = Get-date -Date $Date -Format "yyyy-MM-ddTHH:mm:ss$TimeZone"

    $params = @{
        uri     = "$API_URL/$company/$API_Version/employees/changed/?since=$Date&type=$Type";
        Method  = 'GET';
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pass")); "Accept" = 'application/json'; "Content-Type" = 'application/json'}
    }

    #Use TLS 1.2, not 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12    
    
    #Download the report to a CSV file in the $path location
    $results = (Invoke-RestMethod @params).employees

    $IDs = ($results | Get-Member | Where-Object membertype -eq "Noteproperty").name
    
    $Employees = @()

    foreach ($number in $IDs) {
        $TempEmployee = [PSObject]@{
            ID          = $results.$number.id
            action      = $results.$number.action
            lastChanged = $results.$number.lastChanged
        }

        $Employees += $TempEmployee
    }

    Return $Employees
}

function Get-BambooEmployees {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Username = "$API_Key", #This is the API_Key
        [Parameter(Mandatory = $false)]
        [string]$Pass = "randomstring" #This can be any random string
    )

    $params = @{
        uri     = "$API_URL/$company/$API_Version/employees/directory";
        Method  = 'GET';
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pass")); "Accept" = 'application/json'; "Content-Type" = 'application/json'}
    }

    #Use TLS 1.2, not 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12    
    
    #Download the report to a CSV file in the $path location
    $results = (Invoke-RestMethod @params).employees

    Return $results
}

function Get-BambooEmployeeDetails {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EmployeeID,
        [Parameter(Mandatory = $false)]
        [switch]$AllFields,
        [Parameter(Mandatory = $false)]
        [ValidateSet("address1", "address2", "age", "bestEmail", "birthday", "city", "country", "dateOfBirth", "department", "division", "eeo", "employeeNumber", "employmentHistoryStatus", "ethnicity", `
                "exempt", "firstName", "flsaCode", "fullName1", "fullName2", "fullName3", "fullName4", "fullName5", "displayName", "gender", "hireDate", "originalHireDate", "homeEmail", "homePhone", "id", "jobTitle", `
                "lastChanged", "lastName", "location", "maritalStatus", "middleName", "mobilePhone", "payChangeReason", "payGroup", "payGroupId", "payRate", "payRateEffectiveDate", "payType", "payPer", "paidPer", `
                "paySchedule", "payScheduleId", "payFrequency", "includeInPayroll", "preferredName", "ssn", "sin", "state", "stateCode", "status", "supervisor", "supervisorId", "supervisorEId", "terminationDate" `
                , "workEmail", "workPhone", "workPhonePlusExtension", "workPhoneExtension", "zipcode", "isPhotoUploaded", "standardHoursPerWeek", "bonusDate", "bonusAmount", "bonusReason", "bonusComment", "commissionDate" `
                , "commisionDate", "commissionAmount", "commissionComment", "employmentStatus", "nickname", "payPeriod", "photoUploaded")]
        [string[]]$fields="displayname",
        [Parameter(Mandatory = $false)]
        [switch]$HelpMe,
        [Parameter(Mandatory = $false)]
        [string]$Username = "$API_Key", #This is the API_Key
        [Parameter(Mandatory = $false)]
        [string]$Pass = "randomstring", #This can be any random string
        [Parameter(Mandatory = $false)]
        [switch]$AllEmployees
    )

    if ($HelpMe) {
        Import-Csv C:\API_Fields.csv | `
            Format-Table    @{Label = "API Field Name"; Expression = {$_."API Field Name"}; Width = 40}, `
        @{Label = "Input Type"; Expression = {$_.Type}; Width = 20}, `
        @{Label = "Description"; Expression = {$_.Description}}
        Return
    }

    if ($AllFields) {
        $fields = "address1", "address2", "age", "bestEmail", "birthday", "city", "country", "dateOfBirth", "department", "division", "eeo", "employeeNumber", "employmentHistoryStatus", "ethnicity", `
        "exempt", "firstName", "flsaCode", "fullName1", "fullName2", "fullName3", "fullName4", "fullName5", "displayName", "gender", "hireDate", "originalHireDate", "homeEmail", "homePhone", "id", "jobTitle", `
        "lastChanged", "lastName", "location", "maritalStatus", "middleName", "mobilePhone", "payChangeReason", "payGroup", "payGroupId", "payRate", "payRateEffectiveDate", "payType", "payPer", "paidPer", `
        "paySchedule", "payScheduleId", "payFrequency", "includeInPayroll", "preferredName", "ssn", "sin", "state", "stateCode", "status", "supervisor", "supervisorId", "supervisorEId", "terminationDate" `
        , "workEmail", "workPhone", "workPhonePlusExtension", "workPhoneExtension", "zipcode", "isPhotoUploaded", "standardHoursPerWeek", "bonusDate", "bonusAmount", "bonusReason", "bonusComment", "commissionDate" `
        , "commisionDate", "commissionAmount", "commissionComment", "employmentStatus", "nickname", "payPeriod", "photoUploaded"
    }

    $fieldsQuery = ""

    foreach ($field in $fields) {
        $fieldsQuery += "$field,"
    }

    #Remove the last comma
    $fieldsQuery = $fieldsQuery.Substring(0, $fieldsQuery.Length - 1)
    
    $params = @{
        uri     = "$API_URL/$company/$API_Version/employees/$EmployeeID`?fields=$fieldsQuery";
        Method  = 'GET';
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pass")); "Accept" = 'application/json'; "Content-Type" = 'application/json'}
    }

    if ($AllEmployees) {
        $params.uri = "$API_URL/$company/$API_Version/employees/all`?fields=$fieldsQuery";
    }

    #Use TLS 1.2, not 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12    

    $results = Invoke-RestMethod @params

    Return $results
}

function Get-ITDetailsFromBamboo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$fullName
    )

    $ID = (Get-BambooEmployees | Where-Object displayName -eq $fullName).id

    $HR_Employee = Get-BambooEmployeeDetails -EmployeeID $ID -fields firstName, lastName, employeeNumber, hireDate, jobTitle, supervisor, supervisorEId, supervisorId

    $IT_Employee = [psobject]@{
        BambooID  = $HR_Employee.id
        FirstName = $HR_Employee.firstName
        LastName  = $HR_Employee.lastName
        HR_ID     = $HR_Employee.employeeNumber
        StartDate = $HR_Employee.hireDate
        TiTle     = $HR_Employee.jobTitle
        Manager   = [psobject]@{
            Name     = $HR_Employee.supervisor
            BambooID = $HR_Employee.supervisorEId
            HR_ID    = $HR_Employee.supervisorId
        }
    }

    Return $IT_Employee
}

function Get-BambooTable {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Username = "$API_Key", #This is the API_Key
        [Parameter(Mandatory = $false)]
        [string]$Pass = "randomstring", #This can be any random string
        [Parameter(Mandatory = $true)]
        [string]$EmployeeID,
        [Parameter(Mandatory = $false)]
        [ValidateSet("jobinfo","employmentStatus","compensation","dependents","contacts")]
        [string]$TableName = "jobInfo",
        [Parameter(Mandatory = $false)]
        [switch]$MostRecent,
        [Parameter(Mandatory = $false)]
        [switch]$AllEmployees
    )

    $params = @{
        uri     = "$API_URL/$company/$API_Version/employees/$EmployeeID/tables/$TableName/";
        Method  = 'GET';
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pass")); "Accept" = 'application/json'; "Content-Type" = 'application/json'}
    }
    
    #Use TLS 1.2, not 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    if ($AllEmployees) {
        $params.uri = "$API_URL/$company/$API_Version/employees/all/tables/$TableName/"
    }
    
    #Download the report to a CSV file in the $path location
    $results = Invoke-RestMethod @params

    if ($MostRecent) {
        $results = $results[$results.Length - 1]
    }

    Return $results
}

function Get-BambooEmployeePhoto {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Username = "$API_Key", #This is the API_Key
        [Parameter(Mandatory = $false)]
        [string]$Pass = "randomstring", #This can be any random string
        [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName)]
        [string]$id,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName
            )]
        #[ValidateScript({Test-Path -Path $_})]
        [string]$Path,
        [Parameter(Mandatory = $true,ValueFromPipelineByPropertyName)]
        [ValidateSet("small","medium","large","original")]
        [string]$Size = "small"
    )

    $params = @{
        uri     = "$API_URL/$company/$API_Version/employees/$id/photo/$size";
        Method  = 'GET';
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Pass")); "Accept" = 'application/json'; "Content-Type" = 'application/json'}
    }

    #Use TLS 1.2, not 1.1
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12    
    
    #Download the report to a CSV file in the $path location
    Invoke-RestMethod @params -OutFile $Path

    #Return $results
}
