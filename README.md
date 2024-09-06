This is a Powershell script used to obtain temporary session credentials using AWS's IAM Roles Anywhere. [How To Setup AWS IAM Roles Anywhere](https://aws.amazon.com/blogs/security/extend-aws-iam-roles-to-workloads-outside-of-aws-with-iam-roles-anywhere/)
Uses the Signing Process from: [AWS IAM Roles Anywhere Signing Process](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/authentication-sign-process.html)
Usage:
```
./aws-iam-roles-anywhere.ps1 `
        -Certificate "path/to/cert.pem" `
        -PrivateKey "path/to/key.pem" `
        -RoleArn "arn:aws:iam::123456789012:role/role-arn" `
        -TrustAnchorArn "arn:aws:rolesanywhere:us-west-2:123456789012:trust-anchor/trust-anchor-arn" `
        -ProfileArn "arn:aws:rolesanywhere:us-west-2:123456789012:profile/profile-arn" `
        -Region "us-west-2"
```

optionally, you can specify the Session Duration with the `-Duration 900` parameter (Default is 900 seconds.)
e.g.
```
./aws-iam-roles-anywhere.ps1 `
        -Certificate "path/to/cert.pem" `
        -PrivateKey "path/to/key.pem" `
        -RoleArn "arn:aws:iam::123456789012:role/role-arn" `
        -TrustAnchorArn "arn:aws:rolesanywhere:us-west-2:123456789012:trust-anchor/trust-anchor-arn" `
        -ProfileArn "arn:aws:rolesanywhere:us-west-2:123456789012:profile/profile-arn" `
        -Region "us-west-2" `
        -Duration 900
```
