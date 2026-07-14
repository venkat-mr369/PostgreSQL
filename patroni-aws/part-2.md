Excellent. Before installing PostgreSQL, let's prepare the operating system on **all three nodes (`pg1`, `pg2`, and `pg3`)**.

### Part 2 – Operating System Preparation (Run on all 3 Nodes)

> Execute every command in this section on **pg1**, **pg2**, and **pg3** unless stated otherwise.

---

### Step 1 – Connect to the Server

```bash
ssh -i patroni-key.pem ubuntu@<PUBLIC_IP>
```

---

### Step 2 – Update the Operating System

```bash
sudo apt update
```

```bash
sudo apt upgrade -y
```

```bash
sudo apt autoremove -y
```

---

### Step 3 – Verify the OS Version

```bash
cat /etc/os-release
```

Expected:

```text
Ubuntu 24.04 LTS
```

---

### Step 4 – Set Hostnames

On **pg1**:

```bash
sudo hostnamectl set-hostname pg1
```

On **pg2**:

```bash
sudo hostnamectl set-hostname pg2
```

On **pg3**:

```bash
sudo hostnamectl set-hostname pg3
```

Verify:

```bash
hostname
```

---

### Step 5 – Configure `/etc/hosts`

Open the file:

```bash
sudo vi /etc/hosts
```

Append:

```text
10.10.1.11   pg1
10.10.1.12   pg2
10.10.1.13   pg3
```

Save and exit.

---

### Step 6 – Test Name Resolution

From **pg1**:

```bash
ping -c 3 pg2
```

```bash
ping -c 3 pg3
```

From **pg2**:

```bash
ping -c 3 pg1
```

---

### Step 7 – Install Required Packages

```bash
sudo apt install -y \
curl \
wget \
vim \
net-tools \
unzip \
zip \
git \
jq \
tree \
htop \
software-properties-common \
apt-transport-https \
ca-certificates \
gnupg \
lsb-release
```

---

### Step 8 – Verify Network Connectivity

```bash
ip addr
```

```bash
hostname -I
```

```bash
ip route
```

---

### Step 9 – Verify DNS

```bash
nslookup google.com
```

If `nslookup` is missing:

```bash
sudo apt install dnsutils -y
```

---

### Step 10 – Synchronize Time

Install Chrony:

```bash
sudo apt install chrony -y
```

Enable it:

```bash
sudo systemctl enable chrony
```

```bash
sudo systemctl start chrony
```

Check status:

```bash
chronyc tracking
```

```bash
chronyc sources
```

---

### Step 11 – Verify Open Ports (Later)

```bash
ss -tulnp
```

At this stage, only SSH (22) should be listening.

---

### Step 12 – Disable Unattended Upgrades (Recommended for Labs)

```bash
sudo systemctl stop unattended-upgrades
```

```bash
sudo systemctl disable unattended-upgrades
```

---

### Step 13 – Configure Firewall (If UFW Is Enabled)

Check status:

```bash
sudo ufw status
```

If enabled:

```bash
sudo ufw allow 22/tcp
```

```bash
sudo ufw allow 5432/tcp
```

```bash
sudo ufw allow 2379/tcp
```

```bash
sudo ufw allow 2380/tcp
```

```bash
sudo ufw allow 8008/tcp
```

Reload:

```bash
sudo ufw reload
```

---

### Step 14 – Verify Memory and Disk

```bash
free -h
```

```bash
df -h
```

```bash
lsblk
```

---

### Step 15 – Verify Connectivity Between Nodes

From **pg1**:

```bash
ping pg2
```

```bash
ping pg3
```

From **pg2**:

```bash
ping pg1
```

From **pg3**:

```bash
ping pg1
```

Stop the ping with **Ctrl+C** after confirming connectivity.

---

### Step 16 – Final Validation Checklist

Run:

```bash
hostname
```

```bash
hostname -I
```

```bash
date
```

```bash
chronyc tracking
```

```bash
free -h
```

```bash
df -h
```

At the end of Part 2, verify that:

* ✅ All three servers can communicate using private IPs and hostnames.
* ✅ Hostnames are correctly configured (`pg1`, `pg2`, `pg3`).
* ✅ Time synchronization (Chrony) is working.
* ✅ Required utility packages are installed.
* ✅ Network and disk checks are successful.

In **Part 3**, we'll install **PostgreSQL 17**, add the official PostgreSQL repository, install **Patroni**, **etcd**, required Python libraries, and prepare the PostgreSQL data directory for cluster initialization. This is where the Patroni cluster software installation begins.
