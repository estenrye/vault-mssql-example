echo 'listing /consul/certs'
ls /consul/certs
cat /consul/certs/chain.pem

if [ -f /consul/certs/fullchain.pem ]
then
    cp /consul/certs/fullchain.pem /usr/local/share/ca-certificates/fullchain.pem.crt
else
    echo '/consul/certs/fullchain.pem could not be found.  Are you missing a volume mapping to /consul/certs?'
    exit 1
fi


if [ -f /consul/certs/chain.pem ]
then
    cp /consul/certs/chain.pem /usr/local/share/ca-certificates/chain.pem.crt
else
    echo '/consul/certs/chain.pem could not be found.  Are you missing a volume mapping to /consul/certs?'
    exit 1
fi

if [ -f /consul/certs/cert.pem ]
then
    cp /consul/certs/cert.pem /usr/local/share/ca-certificates/cert.pem.crt
else
    echo '/consul/certs/cert.pem could not be found.  Are you missing a volume mapping to /consul/certs?'
    exit 1
fi

echo 'Updating ca certificates'
update-ca-certificates

echo 'launching app'
dotnet vault-example.dll