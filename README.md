# sgx
> To setup and run the monitor
```
sudo ./monitor/scripts/certificates.sh
sudo ./monitor/scripts/main.sh
```

> To setup and run the manager
```
sudo ./manager/scripts/certificates.sh
sudo cp ./monitor/certificate/monitor-api-cert.pem ./manager/certificate/
sudo docker-compose up
```