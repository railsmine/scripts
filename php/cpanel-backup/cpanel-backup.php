<?php

// PHP script to allow periodic cPanel backups automatically, optionally to a remote FTP server.
// This script contains passwords. KEEP ACCESS TO THIS FILE SECURE! (place it in your home dir, not /www/)

// ********* THE FOLLOWING ITEMS NEED TO BE CONFIGURED *********

// Info required for cPanel access
$cpuser = "username"; // Username used to login to CPanel
$cppass = "password"; // Password used to login to CPanel
$domain = "example.com"; // Domain name where CPanel is run
$skin = "x"; // Set to cPanel skin you use (script won't work if it doesn't match). Most people run the default x theme

// Info required for FTP host
$ftpuser = "ftpusername"; // Username for FTP account
$ftppass = "ftppassword"; // Password for FTP account
$ftphost = "ftp.example.com"; // Full hostname or IP address for FTP host
$ftpmode = "ftp"; // FTP mode ("ftp" for active, "passiveftp" for passive)
$ftpport = "21"; // Port (default = 21)
$rdir = "/"; // Remote dir (defaut = / )

// Notification information
$notifyemail = "you@example.com"; // Email address to send results

// Secure or non-secure mode
$secure = 0; // Set to 1 for SSL (requires SSL support), otherwise will use standard HTTP

// Set to 1 to have web page result appear in your cron log
$debug = 0;

// *********** NO CONFIGURATION ITEMS BELOW THIS LINE *********

if ($secure) {
$url = "ssl://".$domain;
$port = 2083;
} else {
$url = $domain;
$port = 2082;
}

$socket = fsockopen($url,$port);
if (!$socket) { echo "Failed to open socket connection… Bailing out!\n"; exit; }

// Encode authentication string
$authstr = $cpuser.":".$cppass;
$pass = base64_encode($authstr);

$params = "dest=$ftpmode&email=$notifyemail&server=$ftphost&user=$ftpuser&pass=$ftppass&port=$ftpport&rdir=$rdir&submit=Generate Backup";

// Make POST to cPanel
fputs($socket,"POST /frontend/".$skin."/backup/dofullbackup.html?".$params." HTTP/1.0\r\n");
fputs($socket,"Host: $domain\r\n");
fputs($socket,"Authorization: Basic $pass\r\n");
fputs($socket,"Connection: Close\r\n");
fputs($socket,"\r\n");

// Grab response even if we don't do anything with it.
while (!feof($socket)) {
$response = fgets($socket,4096);
if ($debug) echo $response;
}

fclose($socket);

?>
