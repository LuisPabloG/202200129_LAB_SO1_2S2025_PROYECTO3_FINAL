FROM python:3.9-slim

WORKDIR /app

RUN pip install locust

COPY locustfile.py .

EXPOSE 8089

CMD ["locust", "--host", "http://ingress-nginx-controller", "--web-host", "0.0.0.0"]