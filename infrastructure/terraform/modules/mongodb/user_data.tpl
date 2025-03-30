#!/bin/bash

echo "[INFO] Starting user data script..."
yum update -y
yum install -y jq

echo "[INFO] Retrieving secret from AWS Secrets Manager..."
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id ${secret_id} \
  --region us-east-1 \
  --query SecretString \
  --output text)
MONGO_USER=$(echo "$SECRET" | jq -r '.username')
MONGO_PASS=$(echo "$SECRET" | jq -r '.password')
MONGO_HOST=$(echo "$SECRET" | jq -r '.host')
MONGO_PORT=$(echo "$SECRET" | jq -r '.port')
MONGO_DB=$(echo "$SECRET" | jq -r '.dbname')
echo "[INFO] Secret retrieved successfully."
echo "[INFO] MONGO_USER=$MONGO_USER"
echo "[INFO] MONGO_HOST=$MONGO_HOST"
echo "[INFO] MONGO_PORT=$MONGO_PORT"
echo "[INFO] MONGO_DB=$MONGO_DB"

echo "[INFO] Removing old backup script (if any)..."
rm -f /usr/local/bin/mongo_backup.sh

echo "[INFO] Creating new /usr/local/bin/mongo_backup.sh with updated secret..."
cat <<EOF > /usr/local/bin/mongo_backup.sh
#!/bin/bash
set -euo pipefail

exec >> /var/log/mongo_backup.log 2>&1
echo "[INFO] Running mongo_backup.sh..."
REGION="us-east-1"
S3_BUCKET_NAME="783764584115-mongo-db-backup-buckets"
BACKUP_DIR="/var/backups/mongo"
SECRET_NAME="${secret_id}"

echo "[INFO] Fetching secrets again (in case they've changed)..."
SECRET=\$(aws secretsmanager get-secret-value --secret-id "\$SECRET_NAME" --region "\$REGION" --query SecretString --output text)
MONGO_USER=\$(echo "\$SECRET" | jq -r '.username')
MONGO_PASS=\$(echo "\$SECRET" | jq -r '.password')
MONGO_HOST=\$(echo "\$SECRET" | jq -r '.host')
MONGO_PORT=\$(echo "\$SECRET" | jq -r '.port')
MONGO_DB=\$(echo "\$SECRET" | jq -r '.dbname')

echo "[INFO] Creating backup directory if not present..."
mkdir -p "\$BACKUP_DIR"

TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="mongo_backup_\$${TIMESTAMP}.gz"
BACKUP_PATH="\$BACKUP_DIR/\$BACKUP_NAME"

echo "[INFO] Starting mongodump..."
mongodump --host "\$MONGO_HOST" --port "\$MONGO_PORT" --username "\$MONGO_USER" --password "\$MONGO_PASS" --authenticationDatabase "admin" --db "\$MONGO_DB" --archive | gzip > "\$BACKUP_PATH"
echo "[INFO] mongodump completed."

echo "[INFO] Uploading \$BACKUP_PATH to S3..."
aws s3 cp "\$BACKUP_PATH" "s3://\$S3_BUCKET_NAME/\$BACKUP_NAME"
echo "[INFO] Backup uploaded successfully: s3://\$S3_BUCKET_NAME/\$BACKUP_NAME"

echo "[INFO] Removing local backup file to save space..."
rm -f "\$BACKUP_PATH"

echo "[INFO] mongo_backup.sh completed."
EOF

chmod +x /usr/local/bin/mongo_backup.sh
echo "[INFO] Installed /usr/local/bin/mongo_backup.sh"

echo "[INFO] Adding cron job to run the backup script every 5 minutes..."
echo "*/5 * * * * root /usr/local/bin/mongo_backup.sh" >> /etc/crontab

echo "[INFO] Running an immediate backup for testing..."
/usr/local/bin/mongo_backup.sh

echo "[INFO] User data script completed. Check /var/log/cloud-init-output.log or /var/log/mongo_backup.log for details."
