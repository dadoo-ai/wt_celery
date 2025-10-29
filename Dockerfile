# RabbitMQ + Flower dans UN SEUL conteneur
FROM rabbitmq:3-management

USER root

# Installer Python + pip + Flower
RUN apt-get update && \
    apt-get install -y python3 python3-pip procps && \
    pip3 install --no-cache-dir flower && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Variables d'env (login UI RabbitMQ + URL broker pour Flower)
ENV RABBITMQ_DEFAULT_USER=admin \
    RABBITMQ_DEFAULT_PASS=admin \
    CELERY_BROKER_URL=amqp://admin:admin@localhost:5672//

# Exposer ports
EXPOSE 5672 15672 5555

# Optionnel mais utile : healthcheck RabbitMQ
HEALTHCHECK --interval=10s --timeout=5s --retries=10 \
  CMD rabbitmqctl status >/dev/null 2>&1 || exit 1

# Tout lancer au démarrage (sans script externe)
CMD bash -lc '\
  echo "Starting RabbitMQ..." && \
  rabbitmq-server -detached && \
  echo "Waiting for RabbitMQ..." && \
  for i in {1..60}; do rabbitmqctl status >/dev/null 2>&1 && break; sleep 1; done && \
  echo "Starting Flower..." && \
  exec flower --broker="${CELERY_BROKER_URL}" --port=5555 \
'
