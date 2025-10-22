aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin 592172380963.dkr.ecr.us-east-2.amazonaws.com && \

# Check if models container exists and stop/remove it if it does
if sudo docker ps -a --format "table {{.Names}}" | grep -q "^models$"; then
    echo "Stopping and removing existing models container..."
    sudo docker stop models && \
    sudo docker rm models
else
    echo "No existing models container found, proceeding with deployment..."
fi

sudo docker image prune -a -f && \
sudo docker pull 592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-models-ecr-dev:latest && \
sudo docker run -d --name models \
	-e REDIS_XICORRS_DB=1 \
	-e REDIS_DEFAULT_DB=0 \
	-e N_JOBS=10  \
	-e N_TRIALS=300 \
	-e 'MODELS=sarima,autoreg,sarimaX,autoregX' \
	-e  REGRESSORS=LGBM \
	-e 'RESULT_BACKEND=cache+memory://' \
	-e 'REDIS_HOST=master.senna-redis-elasticache-dev-rg.bq7cs9.use2.cache.amazonaws.com' \
	-e 'REDIS_USER=senna-app-user-dev' \
	-e 'REDIS_PASSWORD=N4p7Xq2B9d6L1yF3' \
	-e 'REDIS_SSL=True' \
	-e 'REDIS_SCHEME=rediss' \
	-e 'REDIS_CLUSTER_ENABLED=False'\
      	-e 'CELERY_BROKER=redis'\
	-e REDIS_PORT=6379 \
	-e USE_STORED_FEATURES=True \
       	-e 'SQS_QUEUE_URL=https://sqs.us-east-2.amazonaws.com/592172380963/senna-celery-tasks-uat' \
      	592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-models-ecr-dev:latest
