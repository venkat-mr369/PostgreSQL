To prepare OS to start Postgre software
1. yum install readline-devel
2. yum install -y zlib-devel
3. yum install -y gcc
4. yum install -y flex
5. yum install -y perl

Above three steps we have to install with super user

#### Create Postgres OS user 
=====================
```bash
sudo useradd -d /home/postgres/ postgres
sudo passwd postgres 
```
Entered_pwd post123
```bash
sudo cat /etc/passwd |grep postgres
```
```bash
[venkat_gcp369@cassandra-1 ~]$ sudo cat /etc/passwd |grep postgres
postgres:x:1003:1004::/home/postgres/:/bin/bash

mkdir -p /pg_data
mkdir -p /pg_backups

[venkat_gcp369@cassandra-1 ~]$ sudo mkdir -p /pg_backups
[venkat_gcp369@cassandra-1 ~]$ sudo mkdir -p /pg_data
[venkat_gcp369@cassandra-1 ~]$ 

sudo chown -R postgres:postgres /pg_data/
sudo chown -R postgres:postgres /pg_backups/
```

output:-
[venkat_gcp369@cassandra-1 ~]$ sudo mkdir -p /pg_backups
[venkat_gcp369@cassandra-1 ~]$ sudo mkdir -p /pg_data
[venkat_gcp369@cassandra-1 ~]$ sudo chown -R postgres:postgres /pg_data/
[venkat_gcp369@cassandra-1 ~]$ sudo chown -R postgres:postgres /pg_backups/
[venkat_gcp369@cassandra-1 ~]$ 

[venkat_gcp369@cassandra-1 ~]$ su - postgres
Password: 
Last failed login: Wed Jan  8 04:46:22 UTC 2025 from 109.120.156.57 on ssh:notty
There were 25 failed login attempts since the last successful login.


##### Extract the software gzip to specific folder
========================================
```bash
To keep extracted software https://www.postgresql.org/ftp/source/ & https://www.postgresql.org/ftp/source/v17.0/
wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz
mkdir -p /pg_backups/software/v17_0_ver/
cd /pg_backups/software/v17_0_ver/

output:-
[postgres@cassandra-1 ~]$ mkdir -p /pg_backups/software/v17_0_ver/
[postgres@cassandra-1 ~]$ cd /pg_backups/software/v17_0_ver/
[postgres@cassandra-1 v17_0_ver]$ pwd
/pg_backups/software/v17_0_ver]$

To install repository binary folder location
mkdir -p /pg_data/app_repo/postgres/17.0/


[postgres@cassandra-1 v17_0_ver]$ wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz
-bash: wget: command not found

[venkat_gcp369@cassandra-1 ~]$ sudo yum install wget -y
Last metadata expiration check: 1:07:36 ago on Wed 08 Jan 2025 07:41:46 AM UTC.
...
...   
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                         1/1 
  Installing       : wget-1.21.1-8.el9.x86_64                                                                                                                1/1 
  Running scriptlet: wget-1.21.1-8.el9.x86_64                                                                                                                1/1 
  Verifying        : wget-1.21.1-8.el9.x86_64                                                                                                                1/1 

Installed:
  wget-1.21.1-8.el9.x86_64                                                                                                                                       

Complete!
```
```bash
[venkat_gcp369@cassandra-1 ~]$ su postgres
Password: 
[postgres@cassandra-1 venkat_gcp369]$ pwd
/home/venkat_gcp369
[postgres@cassandra-1 venkat_gcp369]$ cd /pg_backups/software/v17_0_ver/
[postgres@cassandra-1 v17_0_ver]$ pwd
/pg_backups/software/v17_0_ver
```
To install repository software folder location
```bash
mkdir -p /pg_data/postgres/17.0/
[postgres@cassandra-1 v17_0_ver]$ wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz
--2025-01-08 08:51:59--  https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz
Resolving ftp.postgresql.org (ftp.postgresql.org)... 147.75.85.69, 217.196.149.55, 72.32.157.246, ...
Connecting to ftp.postgresql.org (ftp.postgresql.org)|147.75.85.69|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 27865263 (27M) [application/octet-stream]
Saving to: ‘postgresql-17.0.tar.gz’

postgresql-17.0.tar.gz                   100%[===============================================================================>]  26.57M  18.9MB/s    in 1.4s    

2025-01-08 08:52:01 (18.9 MB/s) - ‘postgresql-17.0.tar.gz’ saved [27865263/27865263]
```
```bash
[postgres@cassandra-1 v17_0_ver]$ ls -l
total 27216
-rw-r--r--. 1 postgres postgres 27865263 Sep 23 20:05 postgresql-17.0.tar.gz

Extract gzip file to software folder
tar -xvf /pg_backup/software/postgresql-10.15.tar.gz   /pg_backup/software/v17_0_ver/

[postgres@cassandra-1 v17_0_ver]$ pwd
/pg_backups/software/v17_0_ver
[postgres@cassandra-1 v17_0_ver]$ ls -ll
total 27220
drwxr-xr-x. 6 postgres postgres     4096 Sep 23 20:02 postgresql-17.0
-rw-r--r--. 1 postgres postgres 27865263 Sep 23 20:05 postgresql-17.0.tar.gz
```
Install respository software to particular location
=============================
go to extracted folder
/pg_backups/software/v17_0_ver
cd postgresql-17.0
```bash
Now configure 
./configure --prefix=/pg_data/app_repo/postgres/17.0/
run the make and make install
#make
#make install

**Note --- only one Repository on one server

[postgres@cassandra-1 postgresql-17.0]$ make
-bash: make: command not found

make is not installed, need to install with super user 
[venkat_gcp369@cassandra-1 ~]$ sudo yum install make -y
```
after installing make switch to posgres user
```bash

[venkat_gcp369@cassandra-1 ~]$ su - postgres
Password: 
Last login: Wed Jan  8 09:10:21 UTC 2025 on pts/1
[postgres@cassandra-1 ~]$ ls -lrt
total 0
[postgres@cassandra-1 ~]$ cd /pg_backups/software/v17_0_ver/postgresql-17.0

[postgres@cassandra-1 v17_0_ver]$ cd 
[postgres@cassandra-1 postgresql-17.0]$ pwd
/pg_backups/software/v17_0_ver/postgresql-17.0
```
Now Configure, from software location
```bash
./configure --prefix=/pg_data/app_repo/postgres/17.0
```
```bash
[postgres@cassandra-1 postgresql-17.0]$ ./configure --prefix=/pg_data/app_repo/postgres/17.0
checking build system type... x86_64-pc-linux-gnu
checking host system type... x86_64-pc-linux-gnu
checking which template to use... linux
checking whether NLS is wanted... no
checking for default port number... 5432
checking for block size... 8kB
checking for segment size... 1GB
checking for WAL block size... 8kB
checking for gcc... no
checking for cc... no
configure: error: in `/pg_backups/software/v17_0_ver/postgresql-17.0':
configure: error: no acceptable C compiler found in $PATH
See `config.log' for more details
```
for this reason we have to install below 3 packages with super user 

To prepare OS to start Postgre software
1. yum install readline-devel 
2. yum install -y zlib-devel
3. yum install -y gcc
```bash
sudo yum install readline-devel zlib-devel gcc
```
after installing you can configure with postgres user 
```bash
postgres@cassandra-1 postgresql-17.0]$ ./configure --prefix=/pg_data/app_repo/postgres/17.0
checking build system type... x86_64-pc-linux-gnu
checking host system type... x86_64-pc-linux-gnu
checking which template to use... linux
checking whether NLS is wanted... no
checking for default port number... 5432
checking for block size... 8kB
checking for segment size... 1GB
checking for WAL block size... 8kB
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
checking for gcc option to accept ISO C99... none needed
checking for g++... no
checking for c++... no
checking whether we are using the GNU C++ compiler... no
checking whether g++ accepts -g... no
checking for gawk... gawk
checking whether gcc supports -Wdeclaration-after-statement, for CFLAGS... yes
checking whether gcc supports -Werror=vla, for CFLAGS... yes
checking whether gcc supports -Werror=unguarded-availability-new, for CFLAGS... no
checking whether g++ supports -Werror=unguarded-availability-new, for CXXFLAGS... no
checking whether gcc supports -Wendif-labels, for CFLAGS... yes
checking whether g++ supports -Wendif-labels, for CXXFLAGS... no
checking whether gcc supports -Wmissing-format-attribute, for CFLAGS... yes
checking whether g++ supports -Wmissing-format-attribute, for CXXFLAGS... no
checking whether gcc supports -Wimplicit-fallthrough=3, for CFLAGS... yes
checking whether g++ supports -Wimplicit-fallthrough=3, for CXXFLAGS... no
checking whether gcc supports -Wcast-function-type, for CFLAGS... yes
checking whether g++ supports -Wcast-function-type, for CXXFLAGS... no
checking whether gcc supports -Wshadow=compatible-local, for CFLAGS... yes
checking whether g++ supports -Wshadow=compatible-local, for CXXFLAGS... no
checking whether gcc supports -Wformat-security, for CFLAGS... yes
checking whether g++ supports -Wformat-security, for CXXFLAGS... no
checking whether gcc supports -fno-strict-aliasing, for CFLAGS... yes
checking whether g++ supports -fno-strict-aliasing, for CXXFLAGS... no
checking whether gcc supports -fwrapv, for CFLAGS... yes
checking whether g++ supports -fwrapv, for CXXFLAGS... no
checking whether gcc supports -fexcess-precision=standard, for CFLAGS... yes
checking whether g++ supports -fexcess-precision=standard, for CXXFLAGS... no
checking whether gcc supports -funroll-loops, for CFLAGS_UNROLL_LOOPS... yes
checking whether gcc supports -ftree-vectorize, for CFLAGS_VECTORIZE... yes
checking whether gcc supports -Wunused-command-line-argument, for NOT_THE_CFLAGS... no
checking whether gcc supports -Wcompound-token-split-by-macro, for NOT_THE_CFLAGS... no
checking whether gcc supports -Wformat-truncation, for NOT_THE_CFLAGS... yes
checking whether gcc supports -Wstringop-truncation, for NOT_THE_CFLAGS... yes
checking whether gcc supports -Wcast-function-type-strict, for NOT_THE_CFLAGS... no
checking whether gcc supports -fvisibility=hidden, for CFLAGS_SL_MODULE... yes
checking whether g++ supports -fvisibility=hidden, for CXXFLAGS_SL_MODULE... no
checking whether g++ supports -fvisibility-inlines-hidden, for CXXFLAGS_SL_MODULE... no
checking whether the C compiler still works... yes
checking how to run the C preprocessor... gcc -E
checking for pkg-config... /usr/bin/pkg-config
checking pkg-config is at least version 0.9.0... yes
checking whether to build with ICU support... yes
checking for icu-uc icu-i18n... no
configure: error: ICU library not found
If you have ICU already installed, see config.log for details on the
failure.  It is possible the compiler isn't looking in the proper directory.
Use --without-icu to disable ICU support.
```
./configure --prefix=/pg_data/app_repo/postgres/17.0 --without-icu
```bash
postgres@cassandra-1 postgresql-17.0]$ ./configure --prefix=/pg_data/app_repo/postgres/17.0 --without-icu
checking build system type... x86_64-pc-linux-gnu
checking host system type... x86_64-pc-linux-gnu
checking which template to use... linux
checking whether NLS is wanted... no
checking for default port number... 5432
checking for block size... 8kB
checking for segment size... 1GB
checking for WAL block size... 8kB
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no
checking for suffix of object files... o
checking whether we are using the GNU C compiler... yes
checking whether gcc accepts -g... yes
checking for gcc option to accept ISO C89... none needed
checking for gcc option to accept ISO C99... none needed
checking for g++... no
checking for c++... no
checking whether we are using the GNU C++ compiler... no
checking whether g++ accepts -g... no
checking for gawk... gawk
checking whether gcc supports -Wdeclaration-after-statement, for CFLAGS... yes
checking whether gcc supports -Werror=vla, for CFLAGS... yes
checking whether gcc supports -Werror=unguarded-availability-new, for CFLAGS... no
checking whether g++ supports -Werror=unguarded-availability-new, for CXXFLAGS... no
checking whether gcc supports -Wendif-labels, for CFLAGS... yes
checking whether g++ supports -Wendif-labels, for CXXFLAGS... no
checking whether gcc supports -Wmissing-format-attribute, for CFLAGS... yes
checking whether g++ supports -Wmissing-format-attribute, for CXXFLAGS... no
checking whether gcc supports -Wimplicit-fallthrough=3, for CFLAGS... yes
checking whether g++ supports -Wimplicit-fallthrough=3, for CXXFLAGS... no
checking whether gcc supports -Wcast-function-type, for CFLAGS... yes
checking whether g++ supports -Wcast-function-type, for CXXFLAGS... no
checking whether gcc supports -Wshadow=compatible-local, for CFLAGS... yes
checking whether g++ supports -Wshadow=compatible-local, for CXXFLAGS... no
checking whether gcc supports -Wformat-security, for CFLAGS... yes
checking whether g++ supports -Wformat-security, for CXXFLAGS... no
checking whether gcc supports -fno-strict-aliasing, for CFLAGS... yes
checking whether g++ supports -fno-strict-aliasing, for CXXFLAGS... no
checking whether gcc supports -fwrapv, for CFLAGS... yes
checking whether g++ supports -fwrapv, for CXXFLAGS... no
checking whether gcc supports -fexcess-precision=standard, for CFLAGS... yes
checking whether g++ supports -fexcess-precision=standard, for CXXFLAGS... no
checking whether gcc supports -funroll-loops, for CFLAGS_UNROLL_LOOPS... yes
checking whether gcc supports -ftree-vectorize, for CFLAGS_VECTORIZE... yes
checking whether gcc supports -Wunused-command-line-argument, for NOT_THE_CFLAGS... no
checking whether gcc supports -Wcompound-token-split-by-macro, for NOT_THE_CFLAGS... no
checking whether gcc supports -Wformat-truncation, for NOT_THE_CFLAGS... yes
checking whether gcc supports -Wstringop-truncation, for NOT_THE_CFLAGS... yes
checking whether gcc supports -Wcast-function-type-strict, for NOT_THE_CFLAGS... no
checking whether gcc supports -fvisibility=hidden, for CFLAGS_SL_MODULE... yes
checking whether g++ supports -fvisibility=hidden, for CXXFLAGS_SL_MODULE... no
checking whether g++ supports -fvisibility-inlines-hidden, for CXXFLAGS_SL_MODULE... no
checking whether the C compiler still works... yes
checking how to run the C preprocessor... gcc -E
checking for pkg-config... /usr/bin/pkg-config
checking pkg-config is at least version 0.9.0... yes
checking whether to build with ICU support... no
checking whether to build with Tcl... no
checking whether to build Perl modules... no
checking whether to build Python modules... no
checking whether to build with GSSAPI support... no
checking whether to build with PAM support... no
checking whether to build with BSD Authentication support... no
checking whether to build with LDAP support... no
checking whether to build with Bonjour support... no
checking whether to build with SELinux support... no
checking whether to build with systemd support... no
checking whether to build with XML support... no
checking whether to build with LZ4 support... no
checking whether to build with ZSTD support... no
checking for strip... strip
checking whether it is possible to strip libraries... yes
checking for ar... ar
checking for a BSD-compatible install... /usr/bin/install -c
checking for tar... /usr/bin/tar
checking whether ln -s works... yes
checking for a thread-safe mkdir -p... /usr/bin/mkdir -p
checking for bison... no
configure: error: bison not found

#error bison not found 
```
[venkat_gcp369@cassandra-1 postgresql-17.0]$ sudo yum update -y

configure: error: flex not found

sudo yum install flex -y 

configure: using flex 2.6.4
checking for perl... no
configure: error: Perl not found

configure: using flex 2.6.4
checking for perl... no

sudo yum install perl -y 

then again configure it willget success

make -- this will take some time 
make install 



==========================
yum install readline-devel
yum install -y zlib-devel
yum install -y gcc
yum install -y flex
yum install -y perl
yum install -y wget

sudo useradd -d /home/postgres/ postgres
sudo passwd postgres 

sudo mkdir -p /pg_data
sudo chown -R postgres:postgres /pg_data/
sudo chown -R postgres:postgres /pg_backups/

su - postgres

mkdir -p /pg_backups/software/v17_0_ver/
cd /pg_backups/software/v17_0_ver/
wget https://ftp.postgresql.org/pub/source/v17.0/postgresql-17.0.tar.gz

tar -xvf /pg_backup/software/postgresql-10.15.tar.gz   /pg_backup/software/v17_0_ver/

cd /pg_backups/software/v17_0_ver/postgresql-17.0

./configure --prefix=/pg_data/app_repo/postgres/17.0 --without-icu 

make 
make install 

cd /pg_data/app_repo/postgres/17.0/bin$./initdb -D /pg_data/cluster1
cd /pg_data/app_repo/postgres/17.0/bin$./pg_ctl -D /pg_data/cluster1 -l logfile start
cd /pg_data/app_repo/postgres/17.0/bin$./pg_ctl -D /pg_data/cluster1 -l logfile status


================================


