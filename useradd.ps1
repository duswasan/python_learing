New-SSHSession -computername 'yeti.pdlab.com -credential (get-credential ssinha)
Invoke-SSHCommand -Index 0 -Command "uname -a"
Invoke-SSHCommand -command 'who ' -sessionid 0

