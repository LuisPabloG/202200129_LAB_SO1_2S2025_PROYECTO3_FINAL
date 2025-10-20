# Locust - Generador de Carga

## Instalación
```bash
pip install -r requirements.txt
```

## Uso
Para 10,000 peticiones con 10 usuarios concurrentes:
```bash
locust -f locustfile.py --host=http://<INGRESS_IP> --users 10 --spawn-rate 2 --run-time 5m --headless
```

O con interfaz web:
```bash
locust -f locustfile.py --host=http://<INGRESS_IP>
```
Luego acceder a http://localhost:8089
