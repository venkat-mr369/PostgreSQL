#### Highly Available PostgreSQL 15 Cluster with Patroni on **Oracle Linux 9**, summarizing improvements, clarifications, and Oracle Linux 9 specifics.

## 1. System Preparation

- Ensure both Oracle Linux 9 base and EPEL repositories are enabled:
  ```bash
  sudo dnf install -y epel-release
  sudo dnf install -y yum-utils
  ```
- Use at least 4 vCPU, 4GB RAM, and 50GB disk per node.
- Network: Each VM should have two adaptors (one for host-only communication, one for NAT/internet).

## 2. Servers & IP Assignment
| Hostname | IP Address      | Main Services                                 |
|----------|-----------------|-----------------------------------------------|
| pgsql01  | 192.168.56.231  | Patroni, PostgreSQL, PgBouncer, etcd, HAProxy, Keepalived |
| pgsql02  | 192.168.56.232  | Patroni, PostgreSQL, PgBouncer, etcd, HAProxy, Keepalived |
| pgsql03  | 192.168.56.233  | Patroni, PostgreSQL, PgBouncer, etcd, HAProxy, Keepalived |

## 3. OS Configuration

- Set timezone:  
  `sudo timedatectl set-timezone Asia/Riyadh`
- Update `/etc/hosts` on all nodes with cluster hostnames and IPs.
- Disable SELinux (consider instead putting in permissive mode for OL9 security best practices):
  - Edit `/etc/selinux/config`, set `SELINUX=disabled`
  - Or run: `setenforce 0` (temporary)
- Open required firewall ports:
  ```bash
  sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=6432/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=8008/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=2379/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=2380/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=5000/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=5001/tcp --permanent
  sudo firewall-cmd --zone=public --add-port=7000/tcp --permanent
  sudo firewall-cmd --add-service=http --permanent
  sudo firewall-cmd --add-rich-rule='rule protocol value=\"vrrp\" accept' --permanent
  sudo firewall-cmd --reload
  ```

## 4. Installing PostgreSQL 15

- Oracle Linux 9 includes newer PostgreSQL in AppStream or use the official repo:
  ```bash
  sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  sudo dnf config-manager --enable pgdg15
  sudo dnf module disable -y postgresql
  sudo dnf -y install postgresql15-server postgresql15 postgresql15-devel
  sudo ln -s /usr/pgsql-15/bin/* /usr/sbin/
  ```

## 5. Install etcd

- You may need to add a compatible repo or build from source if official repo is missing in OL9:
  ```bash
  sudo nano /etc/yum.repos.d/etcd.repo
  # (add a valid etcd repo for OL9, refer to official sources)
  sudo dnf makecache
  sudo dnf install -y etcd
  ```

**Configure etcd Cluster:**  
- Create `/etc/etcd/etcd.conf` per host as described, with proper IPs.

## 6. Install Patroni & Dependencies

```bash
sudo dnf install -y python3 python3-devel python3-pip gcc libpq-devel
sudo pip3 install --upgrade setuptools psycopg2 python-etcd
sudo pip3 install patroni[etcd]
```
- (If needed, use `sudo dnf install -y patroni patroni-etcd watchdog` if available via package manager.)

## 7. Patroni Configuration

- Create `/etc/patroni/patroni.yml` for each node, customizing the `name`, `listen`, and `connect_address` for each.
- Confirm directories like `/var/lib/pgsql/15/data` exist and are owned by the correct user.
- Kernel modules for softdog may already be present in OL9; else load with: `sudo modprobe softdog`

## 8. PgBouncer, HAProxy, and Keepalived

### Installations (unchanged)
```bash
sudo dnf install -y pgbouncer haproxy keepalived
```
### PgBouncer
- Follow previous steps for user/password config, database lists, and authentication. Placement and format options remain the same in OL9.
### HAProxy
- Edit `/etc/haproxy/haproxy.cfg` per guide; config format is unchanged.
### Keepalived
- Edit `/etc/keepalived/keepalived.conf` per your topology.
- For shared/virtual IP, enable nonlocal_bind and ip_forward in `/etc/sysctl.conf`:
  ```conf
  net.ipv4.ip_nonlocal_bind = 1
  net.ipv4.ip_forward = 1
  ```
  Reload with:
  `sudo sysctl --system`

- Start and enable all services:
  ```bash
  sudo systemctl enable --now etcd patroni pgbouncer haproxy keepalived
  ```

## 9. Special Oracle Linux 9 Recommendations

- Network interface names may differ (use `ip a` to discover and adjust configurations).
- Confirm repo URLs point to EL9 if custom or external repos are added.
- SELinux: You may prefer to create policies for Patroni/PostgreSQL/HAProxy/PgBouncer rather than disabling entirely.

## 10. Validation, Operation & Testing

- Use the same commands and queries for cluster state validation and Patroni cluster management as in your OL8 guide.
- Ensure persistent services with:
  ```bash
  sudo systemctl enable etcd
  sudo systemctl enable patroni
  sudo systemctl enable pgbouncer
  sudo systemctl enable keepalived
  sudo systemctl enable haproxy
  ```

**Summary:**  
The overall process remains almost identical in Oracle Linux 9. Most changes are around updated repo URLs, compatibility of system packages, awareness of default network interface naming, and ensuring all services are available in or can be built for Oracle Linux 9. You benefit from all the security and performance improvements in the newer operating system, while the architecture, configuration syntax, and high availability approach do not change.

