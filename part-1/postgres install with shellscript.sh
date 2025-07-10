#!/bin/bash

# Update the system and install required dependencies
echo "Installing dependencies..."
yum install -y readline-devel zlib-devel gcc flex perl wget bison make libxml2-devel libxslt-devel openssl-devel

# Create a postgres user with a home directory
echo "Creating postgres user..."
sudo useradd -d /home/postgres/ postgres
sudo passwd postgres

# Create necessary directories and set permissions
echo "Setting up directories..."
sudo mkdir -p /pg_data /pg_backups
sudo chown -R postgres:postgres /pg_data/
sudo chown -R postgres:postgres /pg_backups/

# Switch to the postgres user
echo "Switching to postgres user..."
su - postgres <<EOF

# Create directories for PostgreSQL source code
mkdir -p /pg_backups/software/v17_0_ver/
cd /pg_backups/software/v17_0_ver/

# Download the PostgreSQL source code
echo "Downloading PostgreSQL 17.0 source code..."
wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz

# Extract the source code
echo "Extracting PostgreSQL 17.0 source code..."
tar -xvf postgresql-17.0.tar.gz

# Change directory to the extracted folder
cd postgresql-17.0

# Script ends here; further steps (configure, make, install) should follow as needed
EOF

echo "Setup completed!"

after that 
cd /pg_backups/software/v17_0_ver/postgresql-17.0

./configure --prefix=/pg_data/app_repo/postgres/17.0 --without-icu 

make 
make install 
cd /pg_data/app_repo/postgres/17.0/bin$./initdb -D /pg_data/cluster1
/pg_data/app_repo/postgres/17.0/bin$./pg_ctl -D /pg_data/cluster1 -l logfile start
/pg_data/app_repo/postgres/17.0/bin$./pg_ctl -D /pg_data/cluster1 -l logfile status
=============================================================================

#!/bin/bash
# Success_script by Venkat.mr369@gmail.com
# Update the system and install required dependencies
echo "Installing required packages..."
yum install -y readline-devel zlib-devel gcc flex perl wget bison make libxml2-devel libxslt-devel openssl-devel || {
    echo "Failed to install dependencies."
    exit 1
}

# Create the postgres user with a home directory
echo "Creating postgres user..."
sudo useradd -d /home/postgres/ postgres
sudo passwd postgres || {
    echo "Failed to set password for postgres user."
    exit 1
}

# Create necessary directories and set permissions
echo "Setting up directories..."
sudo mkdir -p /pg_data /pg_backups
sudo chown -R postgres:postgres /pg_data/
sudo chown -R postgres:postgres /pg_backups/

# Switch to the postgres user to perform the rest of the operations
echo "Switching to postgres user for PostgreSQL setup..."
su - postgres <<EOF

# Create directory for PostgreSQL source code
mkdir -p /pg_backups/software/v17_0_ver/
cd /pg_backups/software/v17_0_ver/

# Download the PostgreSQL source code
echo "Downloading PostgreSQL 17.0 source code..."
wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz || {
    echo "Failed to download PostgreSQL source code."
    exit 1
}

# Extract the source code
echo "Extracting PostgreSQL 17.0 source code..."
tar -xvf postgresql-17.0.tar.gz || {
    echo "Failed to extract PostgreSQL source code."
    exit 1
}

# Change directory to the extracted folder
cd postgresql-17.0

# Configure the build with the specified prefix and options
echo "Configuring PostgreSQL 17.0 build..."
./configure --prefix=/pg_data/app_repo/postgres/17.0 --without-icu || {
    echo "Configuration failed."
    exit 1
}

# Build PostgreSQL

echo "Building PostgreSQL 17.0... & Make...."

# >1 means only output >2 error out 2>&1 error and output
make >make_file.txt 2>&1 || {
    echo "Build process failed."
    exit 1
}

# Install PostgreSQL
echo "Installing PostgreSQL 17.0...& Make Install...."
make install >makeinstall_file.txt 2>&1 || {
    echo "Installation failed."
    exit 1
}

echo "PostgreSQL 17.0 setup completed successfully!"

#Init PostgreSQL
echo "Initializing PostgreSQL 17.0..."
cd /pg_data/app_repo/postgres/17.0/bin/
./initdb -D /pg_data/cluster1
# Starting PostgreSQL 17.0
echo "Starting PostgreSQL 17.0..."
./pg_ctl -D /pg_data/cluster1 -l logfile start

# Status of PostgreSQL 17.0
echo "Status PostgreSQL 17.0..."
./pg_ctl -D /pg_data/cluster1 -l logfile status

EOF


