# Spesifikasi Kontrak REST API (API Contract Documentation)

Dokumen ini mendefinisikan spesifikasi kontrak REST API lengkap yang menjadi jembatan komunikasi antara **Front-End SPA (Flutter Web)** di `vm-frontend-lb` dan **Application Server (Node.js/Express Container)** di `vm-backend`.

Seluruh request dan response menggunakan format **JSON** dengan header standar:
* `Content-Type: application/json`
* `Authorization: Bearer <JWT_TOKEN>` (untuk endpoint terproteksi)

---

## 1. Konvensi Header dan Indikator Load Balancing

Untuk membuktikan pendistribusian beban kerja (Load Balancing Round-Robin) pada pengujian Peran 5, **setiap response dari backend WAJIB menyertakan custom header**:
```http
X-Backend-Server: backend_instance_1 (atau backend_instance_2)
X-Server-Port: 5001 (atau 5002)
```

---

## 2. Endpoint Health Check (Pengujian Load Balancing)

### `GET /api/health`
Digunakan oleh Nginx dan QA Tester untuk mengecek kesehatan container serta memverifikasi pembagian trafik.

* **Akses:** Publik (Tanpa Token).
* **Response `200 OK`:**
  ```json
  {
    "status": "healthy",
    "timestamp": "2026-11-07T12:00:00.000Z",
    "server": {
      "instance": "backend_instance_1",
      "port": 5001,
      "uptime": 3600
    }
  }
  ```

---

## 3. Modul Autentikasi (`/api/auth`)

### A. Registrasi Karyawan Baru
`POST /api/auth/register`
* **Akses:** Publik.
* **Request Body:**
  ```json
  {
    "name": "Ahmad Dahlan",
    "email": "ahmad@company.com",
    "password": "karyawan123",
    "phone": "08123456789",
    "position": "Staff IT & Operasional",
    "department": "Teknologi Informasi"
  }
  ```
* **Response `201 Created`:**
  ```json
  {
    "success": true,
    "message": "Registrasi karyawan berhasil",
    "data": {
      "uid": "usr_99812",
      "name": "Ahmad Dahlan",
      "email": "ahmad@company.com",
      "role": "employee",
      "createdAt": "2026-11-07T12:05:00.000Z"
    }
  }
  ```

### B. Login Pengguna (Multi-Role: Admin & Karyawan)
`POST /api/auth/login`
* **Akses:** Publik.
* **Request Body:**
  ```json
  {
    "email": "budi@company.com",
    "password": "123456"
  }
  ```
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Login berhasil",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "uid": "karyawan_default_id",
      "name": "Budi Santoso",
      "email": "budi@company.com",
      "role": "employee",
      "department": "Teknologi Informasi",
      "position": "Staff IT & Operasional",
      "photoUrl": ""
    }
  }
  ```
* **Response `401 Unauthorized`:**
  ```json
  {
    "success": false,
    "message": "Email atau password salah"
  }
  ```

### C. Profil Pengguna yang Sedang Login
`GET /api/auth/me`
* **Akses:** Terproteksi (`Bearer Token`).
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "data": {
      "uid": "karyawan_default_id",
      "name": "Budi Santoso",
      "email": "budi@company.com",
      "role": "employee",
      "department": "Teknologi Informasi",
      "position": "Staff IT & Operasional",
      "phone": "081234567890",
      "isActive": true
    }
  }
  ```

---

## 4. Modul Presensi / Attendance (`/api/attendance`)

### A. Presensi Masuk (Check-In)
`POST /api/attendance/check-in`
* **Akses:** Terproteksi (`Bearer Token`).
* **Catatan:** Waktu check-in **diambil dari waktu server database (NOW())**, bukan dari HP.
* **Request Body:**
  ```json
  {
    "method": "camera",
    "photoUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "scheduleStart": "08:00"
  }
  ```
* **Response `201 Created`:**
  ```json
  {
    "success": true,
    "message": "Presensi masuk berhasil dicatat",
    "data": {
      "id": "att_20261107_01",
      "uid": "karyawan_default_id",
      "userName": "Budi Santoso",
      "date": "2026-11-07",
      "checkIn": "2026-11-07T07:55:10.000Z",
      "checkOut": null,
      "method": "camera",
      "status": "present",
      "workHours": 0.0,
      "note": ""
    }
  }
  ```

### B. Presensi Pulang (Check-Out)
`POST /api/attendance/check-out`
* **Akses:** Terproteksi (`Bearer Token`).
* **Request Body:**
  ```json
  {
    "note": "Pekerjaan hari ini selesai"
  }
  ```
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Presensi pulang berhasil dicatat",
    "data": {
      "id": "att_20261107_01",
      "checkIn": "2026-11-07T07:55:10.000Z",
      "checkOut": "2026-11-07T17:02:40.000Z",
      "workHours": 9.12,
      "status": "present"
    }
  }
  ```

### C. Cek Status Presensi Hari Ini
`GET /api/attendance/today`
* **Akses:** Terproteksi (`Bearer Token`).
* **Response `200 OK` (Jika Sudah Absen Masuk):**
  ```json
  {
    "success": true,
    "data": {
      "hasCheckedIn": true,
      "hasCheckedOut": false,
      "attendance": {
        "id": "att_20261107_01",
        "date": "2026-11-07",
        "checkIn": "2026-11-07T07:55:10.000Z",
        "checkOut": null,
        "method": "camera",
        "status": "present"
      }
    }
  }
  ```

### D. Riwayat Presensi Pengguna
`GET /api/attendance/history?limit=30`
* **Akses:** Terproteksi (`Bearer Token`).
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "att_20261107_01",
        "date": "2026-11-07",
        "checkIn": "2026-11-07T07:55:10.000Z",
        "checkOut": "2026-11-07T17:02:40.000Z",
        "method": "camera",
        "status": "present",
        "workHours": 9.12
      }
    ]
  }
  ```

### E. Statistik Presensi Bulanan
`GET /api/attendance/monthly-stats?month=11&year=2026`
* **Akses:** Terproteksi (`Bearer Token`).
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "data": {
      "present": 20,
      "late": 2,
      "absent": 0,
      "permission": 1,
      "totalWorkHours": 178.5
    }
  }
  ```

---

## 5. Modul Jadwal Kerja (`/api/schedules`)

### A. Mengambil Daftar Jadwal
`GET /api/schedules`
* **Akses:** Terproteksi (`Bearer Token`).
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "data": [
      { "id": "sch_mon", "dayOfWeek": "monday", "dayLabel": "Senin", "startTime": "08:00", "endTime": "17:00", "isActive": true },
      { "id": "sch_tue", "dayOfWeek": "tuesday", "dayLabel": "Selasa", "startTime": "08:00", "endTime": "17:00", "isActive": true },
      { "id": "sch_wed", "dayOfWeek": "wednesday", "dayLabel": "Rabu", "startTime": "08:00", "endTime": "17:00", "isActive": true },
      { "id": "sch_thu", "dayOfWeek": "thursday", "dayLabel": "Kamis", "startTime": "08:00", "endTime": "17:00", "isActive": true },
      { "id": "sch_fri", "dayOfWeek": "friday", "dayLabel": "Jumat", "startTime": "08:00", "endTime": "17:00", "isActive": true },
      { "id": "sch_sat", "dayOfWeek": "saturday", "dayLabel": "Sabtu", "startTime": "--:--", "endTime": "--:--", "isActive": false },
      { "id": "sch_sun", "dayOfWeek": "sunday", "dayLabel": "Minggu", "startTime": "--:--", "endTime": "--:--", "isActive": false }
    ]
  }
  ```

---

## 6. Modul Pengajuan Izin / Cuti (`/api/requests`)

### A. Mengirim Pengajuan Izin Baru (Karyawan)
`POST /api/requests`
* **Akses:** Terproteksi (`Bearer Token`).
* **Request Body:**
  ```json
  {
    "type": "leave",
    "reason": "Acara pernikahan keluarga di luar kota",
    "startDate": "2026-11-10",
    "endDate": "2026-11-12"
  }
  ```
* **Response `201 Created`:**
  ```json
  {
    "success": true,
    "message": "Pengajuan cuti berhasil dikirim",
    "data": {
      "id": "req_101",
      "uid": "karyawan_default_id",
      "userName": "Budi Santoso",
      "type": "leave",
      "reason": "Acara pernikahan keluarga di luar kota",
      "startDate": "2026-11-10",
      "endDate": "2026-11-12",
      "status": "pending",
      "createdAt": "2026-11-07T12:30:00.000Z"
    }
  }
  ```

### B. Daftar Pengajuan Karyawan
`GET /api/requests/my`
* **Akses:** Terproteksi (`Bearer Token`).
* **Response `200 OK`:** Mengembalikan array seluruh pengajuan milik user yang sedang login.

### C. Persetujuan / Penolakan Pengajuan (Khusus Admin)
`PATCH /api/requests/:id/status`
* **Akses:** Terproteksi Khusus Role Admin (`role: "admin"`).
* **Request Body:**
  ```json
  {
    "status": "approved",
    "adminNote": "Disetujui, selamat berlibur"
  }
  ```
* **Response `200 OK`:**
  ```json
  {
    "success": true,
    "message": "Status pengajuan berhasil diperbarui",
    "data": {
      "id": "req_101",
      "status": "approved",
      "adminNote": "Disetujui, selamat berlibur",
      "updatedAt": "2026-11-07T12:45:00.000Z"
    }
  }
  ```

---

## 7. Format Penanganan Error Standar (Error Handling)

Setiap request yang gagal akan mengembalikan format konsisten:

| Kode HTTP | Arti | Contoh Response JSON |
|:---:|:---|:---|
| `400 Bad Request` | Parameter input tidak lengkap atau tidak valid | `{"success": false, "message": "Email dan password wajib diisi"}` |
| `401 Unauthorized` | Token tidak disertakan atau sudah kedaluwarsa | `{"success": false, "message": "Sesi telah berakhir, silakan login kembali"}` |
| `403 Forbidden` | User tidak memiliki hak akses (bukan Admin) | `{"success": false, "message": "Akses ditolak: Hanya untuk Admin HRD"}` |
| `404 Not Found` | Data atau endpoint tidak ditemukan | `{"success": false, "message": "Data pengajuan tidak ditemukan"}` |
| `500 Server Error` | Terjadi kesalahan pada query atau database | `{"success": false, "message": "Terjadi kesalahan internal server"}` |

