$ConfigFileToConvert = "Path goes here"
$VaultName = "Name of your keyvault"

$lines = Get-Content $ConfigFileToConvert | Where {$_.ToString().Contains("<add key")} 

foreach ($line in $lines) {
    
    #Extracting keys and values
    $ContentSplit = $line.Split('"')
    $Key = $ContentSplit[1]
    $Key = $Key -replace "\.|:|-",""
    $Value = $ContentSplit[3]
   
    #Create the secret in the Vault
        Write-Host "Creating key: $Key"
    $SecretPasswordConverted = ConvertTo-SecureString -String $Value -AsPlainText -Force
    $KeyVaultSecret = Set-AzureKeyVaultSecret -VaultName $VaultName -Name $Key -SecretValue $SecretPasswordConverted 
    $KeyId = $KeyVaultSecret.Id
    Write-Host "Key created - $KeyId" -ForegroundColor Green
}
