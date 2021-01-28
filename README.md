# Certificates

## Windows Certificate Powershell Module

The Microsoft Windows Certificate powershell module (PKI) is missing some functinality.  This module contains the functions that I have needed from time to time to automate various software installs.

### Master

Version: 1.6.9

[![Build status](https://ci.appveyor.com/api/projects/status/0upkoy1odny5totn/branch/master?svg=true)](https://ci.appveyor.com/project/jeffbuenting/certificates/branch/master)

This is the branch containing the latest stable version.

## Functions

**Get-Cert**                              
  - Retrieves certificates from the cert store.
  
**Import-Cert**

**Get-CertWebsite**
  - Retrieves the certificate bound to a website.
  
**Import-CertWebSite**
  - Binds a certificate to a website
  
**Remove-CertWebSite**
  - Removes a certificate binding from a website
  
**Get-CertPrivateKeyPermissions**
  - Retrieves the permissions on a certificate's Private Key
  
**Set-CertPrivateKeyPermissions**
  - Sets private key permissions on certificates

