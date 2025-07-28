# sgx
This project has been developed as part of a Master Thesis, which can be found [here](https://acervodigital.ufpr.br/xmlui/bitstream/handle/1884/95957/R%20-%20D%20-%20JOAO%20PEDRO%20CURVELO.pdf?sequence=1&isAllowed=y).

## Architecture
<img width="987" height="279" alt="arquitetura-simplificada" src="https://github.com/user-attachments/assets/c2c94ef8-57bc-4300-a351-3c06634f7969" />

## APIs and contracts

### Metrics API docummentation
<img width="523" height="224" alt="image" src="https://github.com/user-attachments/assets/f24a4a67-e609-4021-816a-dc7e8055ca8d" />

### Manager API docummentation
<img width="493" height="182" alt="image" src="https://github.com/user-attachments/assets/24d305df-0b2a-4371-968f-0d43bebfaa63" />

### Metrics data model
<img width="484" height="273" alt="image" src="https://github.com/user-attachments/assets/e8fff698-eea8-4792-958d-d9fb50dbe582" />


## Sequence Diagrams

### Metrics sequence diagram
<img width="936" height="1153" alt="metrics" src="https://github.com/user-attachments/assets/5940393b-4950-4780-8a87-ff614ab18cae" />
> Test Method

### Metrics API sequence diagram
<img width="1033" height="1135" alt="metrics-api" src="https://github.com/user-attachments/assets/36823c91-3164-4cc5-a5c9-431014eaf2f3" />

### Manager sequence diagram
<img width="1160" height="925" alt="manager" src="https://github.com/user-attachments/assets/fdae90f0-79de-44b8-b97c-5aa34c43e0d7" />

### Manager API sequence diagram
<img width="1131" height="957" alt="manager-api" src="https://github.com/user-attachments/assets/8ac4b8f7-5feb-4d9d-b743-4f27868d2668" />

## Running the project

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
