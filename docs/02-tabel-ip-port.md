# Tabel Alokasi IP, Port, dan Aturan Firewall

Dokumen ini berfungsi sebagai acuan konfigurasi jaringan antarmesin (inter-VM) pada AWS EC2 Region `ap-southeast-1`. 

> **Catatan Penggunaan:**
> Nilai IP Publik dan IP Privat dikosongkan terlebih dahulu dalam template ini dan akan diisi secara berkala oleh **Peran 3** bersama **Peran 1** dan **Peran 2** saat proses provisioning VM di AWS Management Console selesai, lalu disinkronkan ke Google Sheets kelompok.

---

## 1. Tabel Alokasi VM dan IP Address

| Nama VM | Hostname | Instance Type | OS | IP Privat (VPC Subnet) | IP Publik / Elastic IP | Peran Penanggung Jawab |
|:---|:---|:---:|:---:|:---:|:---:|:---:|
| **`vm-frontend-lb`** | `frontend-lb` | `t3.micro` | Ubuntu Server 22.04 LTS | *(Kosongkan - diisi saat VM dibuat)* | *(Diisi nilai AWS Elastic IP)* | Peran 1 |
| **`vm-backend`** | `backend-apps` | `t3.micro` | Ubuntu Server 22.04 LTS | *(Kosongkan - diisi saat VM dibuat)* | *(Kosongkan - IP Publik dinamis)* | Peran 2 |
| **`vm-database`** | `database-mysql` | `t3.micro` | Ubuntu Server 22.04 LTS | *(Kosongkan - diisi saat VM dibuat)* | *(Kosongkan - IP Publik dinamis)* | Peran 3 |

---

## 2. Tabel Layanan, Port, dan Alokasi Container

| VM Induk | Komponen / Service | Tipe Deployment | Port Host | Port Container | Protokol | Akses Diizinkan Dari |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| `vm-frontend-lb` | OpenSSH Server | Bare-metal OS | `22` | - | TCP | IP Publik Anggota Tim (Termius) |
| `vm-frontend-lb` | Nginx (SPA Web Server) | Bare-metal OS | `80` | - | TCP | `0.0.0.0/0` (Publik Internet) |
| `vm-frontend-lb` | Nginx (HTTPS - Opsi) | Bare-metal OS | `443` | - | TCP | `0.0.0.0/0` (Publik Internet) |
| `vm-backend` | OpenSSH Server | Bare-metal OS | `22` | - | TCP | IP Publik Anggota Tim (Termius) |
| `vm-backend` | Backend Instance 1 | Docker Container | `5001` | `5000` | TCP | **HANYA** IP Privat `vm-frontend-lb` |
| `vm-backend` | Backend Instance 2 | Docker Container | `5002` | `5000` | TCP | **HANYA** IP Privat `vm-frontend-lb` |
| `vm-database` | OpenSSH Server | Bare-metal OS | `22` | - | TCP | IP Publik Anggota Tim (Termius) |
| `vm-database` | MySQL Server | Docker Container | `3306` | `3306` | TCP | **HANYA** IP Privat `vm-backend` |

---

## 3. Matriks Konfigurasi AWS Security Group

### A. Security Group: `sg-frontend-lb` (Melekat pada `vm-frontend-lb`)
* **Inbound Rules:**
  | Tipe Trafik | Protokol | Rentang Port | Source (Sumber) | Keterangan |
  |:---|:---:|:---:|:---|:---|
  | SSH | TCP | `22` | `IP-Publik-Mahasiswa/32` | Remote administrasi via Termius |
  | HTTP | TCP | `80` | `0.0.0.0/0` | Akses web SPA Flutter & API proxy oleh publik |
  | HTTPS | TCP | `443` | `0.0.0.0/0` | Trafik aman SSL (opsional jika aktif) |
* **Outbound Rules:**
  | Tipe Trafik | Protokol | Rentang Port | Destination (Tujuan) | Keterangan |
  |:---|:---:|:---:|:---|:---|
  | Custom TCP | TCP | `5001` | `IP-Privat-vm-backend/32` | Meneruskan request proxy ke Backend Instance 1 |
  | Custom TCP | TCP | `5002` | `IP-Privat-vm-backend/32` | Meneruskan request proxy ke Backend Instance 2 |
  | All Traffic | All | All | `0.0.0.0/0` | Pembaruan paket OS / apt update |

---

### B. Security Group: `sg-backend` (Melekat pada `vm-backend`)
* **Inbound Rules:**
  | Tipe Trafik | Protokol | Rentang Port | Source (Sumber) | Keterangan |
  |:---|:---:|:---:|:---|:---|
  | SSH | TCP | `22` | `IP-Publik-Mahasiswa/32` | Remote administrasi via Termius |
  | Custom TCP | TCP | `5001` | `IP-Privat-vm-frontend-lb/32` | Menerima beban request dari Nginx Load Balancer |
  | Custom TCP | TCP | `5002` | `IP-Privat-vm-frontend-lb/32` | Menerima beban request dari Nginx Load Balancer |
* **Outbound Rules:**
  | Tipe Trafik | Protokol | Rentang Port | Destination (Tujuan) | Keterangan |
  |:---|:---:|:---:|:---|:---|
  | MySQL/Aurora | TCP | `3306` | `IP-Privat-vm-database/32` | Query transaksi data ke MySQL Database |
  | All Traffic | All | All | `0.0.0.0/0` | Pull image Docker / update sistem |

---

### C. Security Group: `sg-database` (Melekat pada `vm-database`)
* **Inbound Rules:**
  | Tipe Trafik | Protokol | Rentang Port | Source (Sumber) | Keterangan |
  |:---|:---:|:---:|:---|:---|
  | SSH | TCP | `22` | `IP-Publik-Mahasiswa/32` | Remote administrasi via Termius |
  | MySQL/Aurora | TCP | `3306` | `IP-Privat-vm-backend/32` | **HANYA** koneksi query dari container backend |
* **Outbound Rules:**
  | Tipe Trafik | Protokol | Rentang Port | Destination (Tujuan) | Keterangan |
  |:---|:---:|:---:|:---|:---|
  | All Traffic | All | All | `0.0.0.0/0` | Pull image Docker MySQL / update OS |

---

## 4. Matriks Konfigurasi Firewall UFW (Di Dalam OS VM)

Selain AWS Security Group, lapisan keamanan kedua (Defense in Depth) dikonfigurasi langsung di dalam level OS Ubuntu menggunakan UFW:

### A. UFW pada `vm-frontend-lb`
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### B. UFW pada `vm-backend`
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow from <IP_PRIVAT_VM_FRONTEND_LB> to any port 5001 proto tcp
sudo ufw allow from <IP_PRIVAT_VM_FRONTEND_LB> to any port 5002 proto tcp
sudo ufw enable
```

### C. UFW pada `vm-database`
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow from <IP_PRIVAT_VM_BACKEND> to any port 3306 proto tcp
sudo ufw enable
```

---

## 5. Matriks Verifikasi Konektivitas Antar-VM

| Dari Sumber | Menuju Tujuan | Melalui Jalur | Target Port | Status Uji yang Diharapkan |
|:---|:---|:---|:---:|:---|
| Laptop / Browser Klien | `vm-frontend-lb` | IP Publik (Elastic IP) | `80` | **BERHASIL (HTTP 200 OK - Memuat SPA)** |
| Laptop / Browser Klien | `vm-backend` | IP Publik / Privat | `5001` / `5002` | **DITOLAK / TIMEOUT (Terblokir Firewall)** |
| Laptop / DBeaver Klien | `vm-database` | IP Publik / Privat | `3306` | **DITOLAK / TIMEOUT (Terblokir Firewall)** |
| `vm-frontend-lb` | `vm-backend` | IP Privat | `5001` | **BERHASIL (HTTP 200 OK via Nginx Upstream)** |
| `vm-frontend-lb` | `vm-backend` | IP Privat | `5002` | **BERHASIL (HTTP 200 OK via Nginx Upstream)** |
| `vm-backend` | `vm-database` | IP Privat | `3306` | **BERHASIL (MySQL Handshake Connected)** |
| `vm-frontend-lb` | `vm-database` | IP Privat | `3306` | **DITOLAK / TIMEOUT (Tidak ada izin SG/UFW)** |

