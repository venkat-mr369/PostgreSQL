Perfect. We'll build this as a real production lab. **Part 1** covers only the AWS infrastructure. We won't install PostgreSQL yet.

### Part 1 - AWS Infrastructure for a 3-Node Patroni PostgreSQL Cluster

#### Architecture

```text
VPC (10.10.0.0/16)

                Internet Gateway
                      |
              Public Subnet
             10.10.1.0/24
      --------------------------------
      |              |               |
      |              |               |
   pg1            pg2             pg3
10.10.1.11    10.10.1.12     10.10.1.13
 Ubuntu 24      Ubuntu 24       Ubuntu 24
 Patroni         Patroni          Patroni
 PostgreSQL      PostgreSQL       PostgreSQL
 etcd            etcd             etcd
```

### Step 1 - Create VPC

AWS Console:

* VPC Name: `patroni-vpc`
* IPv4 CIDR: `10.10.0.0/16`

AWS CLI:

```bash
aws ec2 create-vpc \
  --cidr-block 10.10.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=patroni-vpc}]'
```

---

### Step 2 - Enable DNS

```bash
aws ec2 modify-vpc-attribute \
  --vpc-id <VPC_ID> \
  --enable-dns-support
```

```bash
aws ec2 modify-vpc-attribute \
  --vpc-id <VPC_ID> \
  --enable-dns-hostnames
```

---

### Step 3 - Create Internet Gateway

```bash
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=patroni-igw}]'
```

Attach it:

```bash
aws ec2 attach-internet-gateway \
  --internet-gateway-id <IGW_ID> \
  --vpc-id <VPC_ID>
```

---

### Step 4 - Create Public Subnet

```bash
aws ec2 create-subnet \
  --vpc-id <VPC_ID> \
  --cidr-block 10.10.1.0/24 \
  --availability-zone ap-south-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=patroni-public-subnet}]'
```

---

### Step 5 - Enable Auto Assign Public IP

```bash
aws ec2 modify-subnet-attribute \
  --subnet-id <SUBNET_ID> \
  --map-public-ip-on-launch
```

---

### Step 6 - Create Route Table

```bash
aws ec2 create-route-table \
  --vpc-id <VPC_ID> \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=patroni-rt}]'
```

---

### Step 7 - Add Internet Route

```bash
aws ec2 create-route \
  --route-table-id <ROUTE_TABLE_ID> \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id <IGW_ID>
```

---

### Step 8 - Associate Route Table

```bash
aws ec2 associate-route-table \
  --route-table-id <ROUTE_TABLE_ID> \
  --subnet-id <SUBNET_ID>
```

---

### Step 9 - Create Security Group

```bash
aws ec2 create-security-group \
  --group-name patroni-sg \
  --description "Patroni Cluster Security Group" \
  --vpc-id <VPC_ID>
```

---

### Step 10 - Open Required Ports

| Port | Purpose          |
| ---- | ---------------- |
| 22   | SSH              |
| 5432 | PostgreSQL       |
| 2379 | etcd Client      |
| 2380 | etcd Peer        |
| 8008 | Patroni REST API |

SSH:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <SG_ID> \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

PostgreSQL:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <SG_ID> \
  --protocol tcp \
  --port 5432 \
  --cidr 10.10.0.0/16
```

etcd Client:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <SG_ID> \
  --protocol tcp \
  --port 2379 \
  --cidr 10.10.0.0/16
```

etcd Peer:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <SG_ID> \
  --protocol tcp \
  --port 2380 \
  --cidr 10.10.0.0/16
```

Patroni REST API:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id <SG_ID> \
  --protocol tcp \
  --port 8008 \
  --cidr 10.10.0.0/16
```

---

### Step 11 - Create a Key Pair

```bash
aws ec2 create-key-pair \
  --key-name patroni-key \
  --query 'KeyMaterial' \
  --output text > patroni-key.pem
```

```bash
chmod 400 patroni-key.pem
```

---

### Step 12 - Launch Three EC2 Instances

Use:

* Ubuntu Server 24.04 LTS AMI
* Instance Type: `t3.medium`
* Root Volume: `30 GB gp3`
* Security Group: `patroni-sg`
* Key Pair: `patroni-key`

Name the instances:

* `pg1`
* `pg2`
* `pg3`

---

### Step 13 - Connect to the Nodes

```bash
ssh -i patroni-key.pem ubuntu@<PUBLIC_IP_OF_PG1>
```

Repeat for `pg2` and `pg3`.

---

### Verify

On each node, run:

```bash
hostname
```

```bash
ip addr
```

```bash
ping -c 3 <private_ip_of_other_node>
```

All three nodes should be able to communicate over their private IP addresses.

---

In **Part 2**, we'll prepare the operating system by updating packages, setting hostnames, configuring `/etc/hosts`, disabling swap (if needed), tuning kernel parameters, and installing PostgreSQL 17 prerequisites before Patroni. This creates a solid foundation for the cluster.
