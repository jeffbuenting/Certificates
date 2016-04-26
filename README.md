# Certificates
Windows Certificate Powershell Module

The Microsoft Windows Certificate powershell module (PKI) is missing some functinality.  This module contains the functions that I have needed from time to time to automate various software installs.

Functions Contained in this module:

Get-Cert                              Retruieves certificates from the cert store.
Import-Cert

Get-CertWebsite                       Retrieves the certificate bound to a website.
Import-CertWebSite                    Binds a certificate to a website
Remove-CertWebSite                    Removes a certificate binding from a website

Get-CertPrivateKeyPermissions         Retrieves the permissions on a certificate's Private Key
Set-CertPrivateKeyPermissions         Sets private key permissions on certificates

