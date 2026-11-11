# Panduan Praktis Provisioning AWS EC2 & Jaringan Cloud

Dokumen ini merupakan panduan operasional langkah-demi-langkah bagi **Peran 1, Peran 2, dan Peran 3** untuk melakukan provisioning infrastruktur cloud pada **AWS Management Console** di Region **`ap-southeast-1` (Singapore)**.

---

## 1. Persiapan Awal (Sebelum Membuat VM)

### A. Membuat SSH Key Pair (.pem)
1. Buka AWS Console $\rightarrow$ Masuk ke layanan **EC2**.
2. Di menu navigasi kiri, pilih **Network & Security** $\rightarrow$ **Key Pairs**.
3. Klik tombol **Create key pair**.
   * **Name:** `key-absensi-kelompok`
   * **Key pair type:** `RSA`
   * **Private key file format:** `.pem` (untuk OpenSSH / Termius / VS Code)
4. Klik **Create key pair**. File `key-absensi-kelompok.pem` otomatis terunduh ke komputer.
5. **PENTING (ATURAN KEAMANAN):**
   * Simpan file ini di Google Drive tim yang aman.
   * **JANGAN PERNAH** memasukkan file `.pem` ke dalam folder git atau meng-uploadnya ke GitHub.
   * Jika menggunakan terminal Linux/Mac/WSL, ubah permission file:
     ```bash
     chmod 400 key-absensi-kelompok.pem
     ```

---

## 2. Pembuatan AWS Security Group (3 Lapisan Keamanan)

Sebelum membuat instance VM, buat 3 Security Group terpisah pada menu **EC2 $\rightarrow$ Security Groups**:

### A. Security Group 1: `sg-frontend-lb` (Untuk Peran 1)
* **Name:** `sg-frontend-lb`
* **Description:** `Security Group untuk Front-End SPA dan Nginx Load Balancer`
* **Inbound Rules:**
  1. **SSH (TCP 22):** Source $\rightarrow$ `My IP` (atau IP publik masing-masing anggota tim).
  2. **HTTP (TCP 80):** Source $\rightarrow$ `Anywhere-IPv4 (0.0.0.0/0)`
  3. **HTTPS (TCP 443):** Source $\rightarrow$ `Anywhere-IPv4 (0.0.0.0/0)`

### B. Security Group 2: `sg-backend` (Untuk Peran 2)
* **Name:** `sg-backend`
* **Description:** `Security Group untuk Application Server Multi-Container`
* **Inbound Rules:**
  1. **SSH (TCP 22):** Source $\rightarrow$ `My IP` (anggota tim).
  2. **Custom TCP (Port 5001):** Source $\rightarrow$ Pilih Security Group `sg-frontend-lb` (atau masukkan IP Privat `vm-frontend-lb/32`).
  3. **Custom TCP (Port 5002):** Source $\rightarrow$ Pilih Security Group `sg-frontend-lb` (atau masukkan IP Privat `vm-frontend-lb/32`).
  *(Catatan: Jangan buka port 5001 dan 5002 ke 0.0.0.0/0).*

### C. Security Group 3: `sg-database` (Untuk Peran 3)
* **Name:** `sg-database`
* **Description:** `Security Group untuk Database MySQL Container`
* **Inbound Rules:**
  1. **SSH (TCP 22):** Source $\rightarrow$ `My IP` (anggota tim).
  2. **MySQL/Aurora (TCP 3306):** Source $\rightarrow$ Pilih Security Group `sg-backend` (atau masukkan IP Privat `vm-backend/32`).
  *(Catatan: Dilarang keras membuka port 3306 ke publik).*

---

## 3. Launching 3 Instance EC2

Buka menu **EC2 $\rightarrow$ Instances** $\rightarrow$ Klik **Launch Instances** untuk masing-masing mesin berikut:

| Parameter Konfigurasi | VM 1: `vm-frontend-lb` | VM 2: `vm-backend` | VM 3: `vm-database` |
|:---|:---|:---|:---|
| **Name and Tags** | `vm-frontend-lb` | `vm-backend` | `vm-database` |
| **Application & OS Image** | Ubuntu Server 22.04 LTS (HVM) | Ubuntu Server 22.04 LTS (HVM) | Ubuntu Server 22.04 LTS (HVM) |
| **Architecture** | 64-bit (x86) | 64-bit (x86) | 64-bit (x86) |
| **Instance Type** | `t3.micro` (1 vCPU, 1 GiB RAM) | `t3.micro` (1 vCPU, 1 GiB RAM) | `t3.micro` (1 vCPU, 1 GiB RAM) |
| **Key Pair** | `key-absensi-kelompok` | `key-absensi-kelompok` | `key-absensi-kelompok` |
| **VPC / Subnet** | Default VPC (Region ap-southeast-1) | Default VPC (Region ap-southeast-1) | Default VPC (Region ap-southeast-1) |
| **Auto-assign Public IP** | Enable | Enable | Enable |
| **Firewall (Security Group)** | Pilih `sg-frontend-lb` | Pilih `sg-backend` | Pilih `sg-database` |
| **Storage Configuration** | 20 GiB, Root Volume, `gp3` | 20 GiB, Root Volume, `gp3` | 20 GiB, Root Volume, `gp3` |

---

## 4. Alokasi dan Asosiasi AWS Elastic IP (Khusus `vm-frontend-lb`)

Agar alamat IP publik front-end tidak berubah-ubah saat VM di-restart:

1. Di navigasi kiri EC2, pilih **Network & Security** $\rightarrow$ **Elastic IPs**.
2. Klik **Allocate Elastic IP address** $\rightarrow$ Network border group: `ap-southeast-1` $\rightarrow$ Klik **Allocate**.
3. Pilih Elastic IP yang baru terbuat $\rightarrow$ Klik menu **Actions** $\rightarrow$ **Associate Elastic IP address**.
   * **Resource type:** `Instance`
   * **Instance:** Pilih `vm-frontend-lb`
   * **Private IP address:** Pilih IP privat internal `vm-frontend-lb`.
4. Klik **Associate**.
5. Salin IP Publik ini ke file `docs/02-tabel-ip-port.md` dan bagikan ke seluruh anggota tim.

---

## 5. Panduan Koneksi SSH Menggunakan Termius

Setiap engineer menyambungkan laptopnya ke VM masing-masing via **Termius**:

1. Buka aplikasi **Termius** di laptop.
2. Masuk ke tab **Keychain** $\rightarrow$ Klik **Add Key**:
   * Label: `Key AWS Absensi`
   * Private Key: Klik tombol impor dan pilih file `key-absensi-kelompok.pem`.
3. Masuk ke tab **Hosts** $\rightarrow$ Klik **New Host**:
   * **Label:** `AWS - vm-frontend-lb` (sesuaikan nama VM).
   * **Address / IP:** Masukkan IP Publik instance (atau Elastic IP untuk vm-frontend-lb).
   * **Port:** `22`
   * **Username:** `ubuntu` (default untuk Ubuntu AMI).
   * **Keys:** Pilih `Key AWS Absensi`.
4. Klik **Connect**. Jika muncul jendela sidik jari host (Host authenticity), pilih **Continue/Add and Continue**.

---

## 6. Perintah Standarisasi Awal Setelah Login Pertama Kali

Jalankan perintah berikut di terminal masing-masing VM setelah berhasil login via SSH:

### A. Di Seluruh VM (Update Sistem & Hostname)
```bash
# Update repository dan paket
sudo apt update && sudo apt upgrade -y

# Beri nama hostname yang rapi (sesuai VM)
# Contoh di VM 1:
sudo hostnamectl set-hostname vm-frontend-lb
# Contoh di VM 2:
# sudo hostnamectl set-hostname vm-backend
# Contoh di VM 3:
# sudo hostnamectl set-hostname vm-database

# Buat shortcut log out dan login kembali
exit
```

### B. Di `vm-backend` dan `vm-database` (Instalasi Docker Engine Resmi)
```bash
# Instal dependensi instalasi Docker
sudo apt install -y ca-certificates curl gnupg lsb-release

# Tambahkan GPG key resmi Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Konfigurasi repository Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instal Docker Engine dan Docker Compose Plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Tambahkan user ubuntu ke grup docker (agar tidak perlu sudo saat docker)
sudo usermod -aG docker ubuntu

# Verifikasi instalasi
docker --version
docker compose version
```

### C. Di `vm-frontend-lb` (Instalasi Nginx Web Server)
```bash
# Instal Nginx
sudo apt install -y nginx

# Verifikasi status Nginx
sudo systemctl status nginx
```

---

## 7. Checklist Penyerahan IP Antar-Peran

Setelah ketiga VM running, catat dan bagikan parameter berikut ke grup WhatsApp tim:

- [ ] **IP Privat `vm-frontend-lb`:** `172.31.xx.xx` $\rightarrow$ Diserahkan ke **Peran 2** untuk whitelist firewall backend.
- [ ] **IP Privat `vm-backend`:** `172.31.yy.yy` $\rightarrow$ Diserahkan ke **Peran 1** (untuk upstream Nginx) dan **Peran 3** (untuk whitelist database).
- [ ] **IP Privat `vm-database`:** `172.31.zz.zz` $\rightarrow$ Diserahkan ke **Peran 2** (untuk variabel `DB_HOST` backend).
- [ ] **Elastic IP `vm-frontend-lb`:** `54.xxx.xxx.xxx` $\rightarrow$ Diserahkan ke **Peran 5** untuk pengujian dan demo URL.

