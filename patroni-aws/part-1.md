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
   pg1            pg2               pg3
10.10.1.11    10.10.1.12        10.10.1.13
 Ubuntu 24      Ubuntu 24        Ubuntu 24
 Patroni         Patroni          Patroni
 PostgreSQL      PostgreSQL       PostgreSQL
 etcd            etcd             etcd
```

### Step 1 - Create VPC

AWS Console:

* VPC Name: `patroni-vpc`
* IPv4 CIDR: `10.20.0.0/16`

AWS CLI:

```bash
aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=patroni-vpc}]'
```

---

### Step 2 - Enable DNS

```bash
aws ec2 modify-vpc-attribute --vpc-id vpc-0b0103f5b17d027f0 --enable-dns-support
```

```bash
aws ec2 modify-vpc-attribute --vpc-id vpc-0b0103f5b17d027f0 --enable-dns-hostnames
```

---

### Step 3 - Create Internet Gateway

```bash
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=patroni-igw}]'
```

Attach it:

```bash
aws ec2 attach-internet-gateway --internet-gateway-id igw-049feb52b8748748c --vpc-id vpc-0b0103f5b17d027f0
```

---

### Step 4 - Create Public Subnet

```bash
aws ec2 create-subnet --vpc-id vpc-0b0103f5b17d027f0 --cidr-block 10.20.1.0/24 --availability-zone ap-south-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=patroni-public-subnet}]'
```

---

### Step 5 - Enable Auto Assign Public IP

```bash
aws ec2 modify-subnet-attribute --subnet-id subnet-090add89d781facac --map-public-ip-on-launch
```

---

### Step 6 - Create Route Table

```bash
aws ec2 create-route-table --vpc-id vpc-0b0103f5b17d027f0 --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=patroni-rt}]'
```

---

### Step 7 - Add Internet Route

```bash
aws ec2 create-route --route-table-id rtb-08c8dfe8d0bef3b33 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-049feb52b8748748c
```

---

### Step 8 - Associate Route Table

```bash
aws ec2 associate-route-table --route-table-id rtb-08c8dfe8d0bef3b33 --subnet-id subnet-090add89d781facac
```

---

### Step 9 - Create Security Group

```bash
aws ec2 create-security-group --group-name patroni-sg --description "Patroni Cluster Security Group" --vpc-id vpc-0b0103f5b17d027f0
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
aws ec2 authorize-security-group-ingress --group-id sg-003b987963418b914 --protocol tcp --port 22 --cidr 0.0.0.0/0
```

```bash
aws ec2 authorize-security-group-ingress --group-id sg-003b987963418b914 --ip-permissions '[
    {
      "IpProtocol":"icmp",
      "FromPort":-1,
      "ToPort":-1,
      "IpRanges":[{"CidrIp":"10.20.0.0/16"}]
    }
  ]'
```


```bash
--SG_ID < --group-id sg-003b987963418b914 >
aws ec2 authorize-security-group-ingress --group-id sg-003b987963418b914 --protocol tcp --port 5432 --cidr 10.20.0.0/16
```

etcd Client:

```bash
--SG_ID < --group-id sg-003b987963418b914 >
aws ec2 authorize-security-group-ingress --group-id sg-003b987963418b914 --protocol tcp --port 2379 --cidr 10.20.0.0/16
```

etcd Peer:

```bash
aws ec2 authorize-security-group-ingress --group-id sg-003b987963418b914 --protocol tcp --port 2380 --cidr 10.20.0.0/16
```

Patroni REST API:

```bash
aws ec2 authorize-security-group-ingress --group-id sg-003b987963418b914  --protocol tcp --port 8008 --cidr 10.20.0.0/16
```

---

### Step 11 - Create a Key Pair

```bash
aws ec2 create-key-pair --key-name patroni-key --query 'KeyMaterial' --output text > patroni-key.pem
```

```bash
chmod 400 patroni-key.pem
```
verify
```
ls -l ~/.ssh/patroni-key.pem
```
You should see something similar to:
```
-r-------- 1 venkat 197121 1675 Jul 15 patroni-key.pem
```
Then connect to your instance with:
```
ssh -i ~/.ssh/patroni-key.pem ubuntu@<PUBLIC_IP>
```
Verify the key pair exists in AWS
```
aws ec2 describe-key-pairs --key-names patroni-key
```
---

### Step 12 - Launch Three EC2 Instances & Get the Ubuntu 24.04 AMI ID

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

First, retrieve the latest Ubuntu 24.04 LTS AMI for your region (`ap-south-1`):

```bash
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters \
    "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" \
    "Name=state,Values=available" \
  --query "sort_by(Images,&CreationDate)[-1].ImageId" \
  --output text)

echo "$AMI_ID"
```

Example output:

```text
ami-07e5ce642bbc48c0d
```
Export AMI_ID
```
export AMI_ID=ami-07e5ce642bbc48c0d
```
```
echo $AMI_ID
```
### Step 13 - Launch EC2 Instance pg1

```bash
aws ec2 run-instances \
  --image-id ami-07e5ce642bbc48c0d \
  --instance-type t3.small \
  --key-name patroni-key \
  --security-group-ids sg-003b987963418b914 \
  --subnet-id subnet-090add89d781facac \
  --private-ip-address 10.20.1.11 \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=pg1}]'
```

---

## Step 14 - Launch EC2 Instance pg2

```bash
aws ec2 run-instances \
  --image-id ami-07e5ce642bbc48c0d \
  --instance-type t3.small \
  --key-name patroni-key \
  --security-group-ids sg-003b987963418b914 \
  --subnet-id subnet-090add89d781facac \
  --private-ip-address 10.20.1.12 \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=pg2}]'
```

---

## Step 15 - Launch EC2 Instance pg3

```bash
aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.medium \
  --key-name patroni-key \
  --security-group-ids sg-003b987963418b914 \
  --subnet-id subnet-090add89d781facac \
  --private-ip-address 10.20.1.13 \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=pg3}]'
```

---

## Step 16 - Wait Until All Instances Are Running

```bash
aws ec2 wait instance-running --filters "Name=tag:Name,Values=pg1,pg2,pg3"
```

---

## Step 17 - Verify the Instances

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=pg1,pg2,pg3" \
  --query 'Reservations[].Instances[].{
      Name:Tags[?Key==`Name`]|[0].Value,
      State:State.Name,
      PrivateIP:PrivateIpAddress,
      PublicIP:PublicIpAddress
  }' \
  --output table
```

Expected output:

```text
-----------------------------------------------------
|                 DescribeInstances                 |
+------+--------------+------------------+----------+
| Name |  PrivateIP   |    PublicIP      |  State   |
+------+--------------+------------------+----------+
|  pg2 |  10.20.1.12  |  3.111.219.179   |  running |
|  pg3 |  10.20.1.13  |  13.127.133.180  |  running |
|  pg1 |  10.20.1.11  |  3.110.32.127    |  running |
+------+--------------+------------------+----------+

```

> **Note:** AWS assigns **private IP addresses dynamically** unless you explicitly request them. You should not assume they'll automatically be `10.20.1.11`, `10.20.1.12`, and `10.20.1.13`.

If you want those exact IPs, use the `--private-ip-address` option when launching each instance.

For example, for **pg1**:

```bash
--private-ip-address 10.20.1.11
```

For **pg2**:

```bash
--private-ip-address 10.20.1.12
```

For **pg3**:

```bash
--private-ip-address 10.20.1.13
```

---

## Step 18 - Connect to Each Instance

```bash
ssh -i ~/.ssh/patroni-key.pem ubuntu@3.111.219.179
```

Repeat for `pg2` and `pg3`.

---



