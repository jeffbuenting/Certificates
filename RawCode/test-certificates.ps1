Import-Module '\\sl-jeffb\f$\OneDrive for Business\Scripts\certificatesadmin\certificateadmin.psm1'

$Cert = Get-Cert -certrootstore localmachine -certstore my | where subject -like "*stratuslive*"

$P = get-certificatepermissions -certificate $Cert 


#Set-CertificatePermission -certificate $Cert -ServiceAccount "NT Authority\network service" -Verbose

Remove-Module certificateadmin