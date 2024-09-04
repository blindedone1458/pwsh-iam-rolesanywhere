#!/usr/bin/env pwsh

param (
    [string] $Certificate,
    [string] $PrivateKey,
    [string] $RoleArn,
    [string] $TrustAnchorArn,
    [string] $ProfileArn,
    [string] $Region,
    [int]    $Duration = 900
)

$DateNow = (Get-Date -AsUTC);

function Get-Sha256Hash {
    param (
        [string] $Plaintext
    )

    $algo = [System.Security.Cryptography.HashAlgorithm]::Create('SHA256');
    $hash_bytes = $algo.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Plaintext));
    $hash_string = [System.BitConverter]::ToString($hash_bytes);
    
    return $hash_string.Replace('-','').ToLower();
}

function Get-SignedSha256Hash {
    param (
        [string] $Plaintext,
        [System.Security.Cryptography.RSA] $RSAKey
    )
    
    $hash_algo = 'SHA256';
    $signed_bytes = $RSAKey.SignData(
        [System.Text.Encoding]::UTF8.GetBytes($Plaintext),
        $hash_algo,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
    );
    $signed_string = [System.BitConverter]::ToString($signed_bytes);

    return $signed_string.Replace('-','').ToLower();
}

$req_url = ('rolesanywhere.{0}.amazonaws.com' -f $Region);
$req_path = '/sessions';
$req_query = ''; # unused

$request_obj = @{
    uri = ('https://{0}{1}' -f $req_url,$req_path)
    method = 'POST'
    headers = @{}
    body = ('{"durationSeconds":{0}, "profileArn":"{1}", "roleArn":"{2}", "trustAnchorArn":"{3}"}' -f $Duration,$ProfileArn,$RoleArn,$TrustAnchorArn)
    contenttype = 'application/json'
    skipheadervalidation = $true
}

$cert_obj = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPemFile($Certificate, $PrivateKey);

$request_obj['headers'].Add('Content-Type', 'application/json');
$request_obj['headers'].Add('Host', $req_url);
$request_obj['headers'].Add('X-Amz-X509', [System.Convert]::ToBase64String($cert_obj.GetRawCertData()));
$request_obj['headers'].Add('X-Amz-Date', (Get-Date -Date $DateNow -Format 'yyyyMMddTHHmmssZ'));

$header_list = $request_obj['headers'].Keys.ToLower() | Sort-Object;

$signed_headers = $header_list -join ';';
$canonical_headers = '';
$header_list | ForEach-Object {
    $canonical_headers += ('{0}:{1}{2}' -f $_,$request_obj['headers'][$_],"`n");
}

$canonical_request = ('{1}{0}{2}{0}{3}{0}{4}{0}{5}{0}{6}{0}' -f
        "`n",
        $request_obj['method'],
        ([System.Web.HttpUtility]::UrlEncode($req_path) -replace '%2F','/'),
        ([System.Web.HttpUtility]::UrlEncode($req_query) -replace '%2F','/'),
        $canonical_headers,
        $signed_headers,
        (Get-Sha256Hash $request_obj['body'])
);

$scope = ('{0}/{1}/rolesanywhere/aws4_request' -f (Get-Date -Date $DateNow -Format 'yyyyMMdd'),$Region);

$string_to_sign = ('AWS4-X509-RSA-SHA256{0}{1}{0}{2}{0}{3}' -f "`n",$request_obj['headers']['X-Amz-Date'],$scope,(Get-Hash $canonical_request));

$signed_string = Get-SignedSha256Hash -Plaintext $string_to_sign -RSAKey $cert_obj.PrivateKey;

$request_obj['headers'].Add('X-Amz-Date', 
    ('AWS4-X509-RSA-SHA256 Credential={0}/{1}, SignedHeaders={2}, Signature={3}' -f [Numerics.BigInteger]::new($cert_obj.GetSerialNumber()),$scope,$signed_headers,$signed_string)
);

$request_obj