#!/bin/bash
# Script to import MySQL database dump into the Docker container

# Set variables from docker-compose
DB_CONTAINER="juliuswirth-db-1"  # Updated container name
DB_NAME="juliush761"
DB_USER="drupal7"
DB_PASS="drupal7"
DUMP_FILE="juliush761_mysql_db.sql"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Drupal 7 Database Import Script${NC}"
echo "----------------------------------------"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
  exit 1
fi

# Check if the container is running
if ! docker ps | grep -q "$DB_CONTAINER"; then
  # Get the actual container name if it's different
  DB_CONTAINER=$(docker ps | grep "mysql:5.7" | awk '{print $NF}')
  
  if [ -z "$DB_CONTAINER" ]; then
    echo -e "${RED}Error: MySQL container is not running. Run 'docker-compose up -d' first.${NC}"
    exit 1
  fi
fi

# Check if dump file exists
if [ ! -f "$DUMP_FILE" ]; then
  echo -e "${RED}Error: Database dump file '$DUMP_FILE' not found.${NC}"
  exit 1
fi

echo -e "${YELLOW}Importing database dump into MySQL container...${NC}"
echo "This may take a few minutes depending on the size of the dump."

# Option 1: Using docker exec to import the database
echo "Importing using docker exec..."
docker exec -i "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$DUMP_FILE"

# Check if import was successful
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Database import completed successfully!${NC}"
  echo "You can now access your Drupal site at http://localhost:8080"
else
  echo -e "${RED}Database import failed. See error messages above.${NC}"
  echo "Alternative import methods:"
  echo "1. Try logging into phpMyAdmin at http://localhost:8081"
  echo "   - Username: $DB_USER"
  echo "   - Password: $DB_PASS"
  echo "2. Or use this command for importing as root:"
  echo "   docker exec -i $DB_CONTAINER mysql -uroot -proot_password $DB_NAME < $DUMP_FILE"
fi
