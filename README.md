# Web IKA JTK Polban — Integrated Alumni Platform

> An enterprise alumni management and electronic voting ecosystem developed for the **Ikatan Keluarga Alumni Jurusan Teknik Komputer dan Informatika (IKA JTK) Politeknik Negeri Bandung**, built during an industry internship at **PT. Pilar Timur Teknologi (Digital Oasis)**.

---

## 📌 Project Overview

**Web IKA JTK Polban** is a centralized multi-tier digital platform connecting alumni across cohorts and degree programs (D3 Informatics & D4 Software Engineering). The platform unifies membership management, career opportunities, official event publication, and secure digital democracy via electronic voting.

* **Repository:** [reinh20/Web_IKA_JTK-](https://github.com/reinh20/Web_IKA_JTK-)
* **Developer:** Reinbrandt Malikiyano Cahyono ([@reinh20](https://github.com/reinh20))
* **Role:** Full Stack Developer / Software Engineer Intern
* **Host Organization:** PT. Pilar Timur Teknologi (Digital Oasis), Bandung

---

## 🏛️ System Architecture

The platform follows a decoupled, three-tier microservice-inspired architecture communicating via RESTful APIs:

```text
Web_IKA_JTK/
├── ika-jtk-backend/                # Core RESTful API & Business Logic
│   ├── app/Controllers/           # Endpoint controllers with error masking
│   ├── app/Models/                # PostgreSQL data models & schema bindings
│   ├── db/migrations/             # Database versioning with Phinx
│   ├── docker-compose.yml         # Container orchestration (PHP-FPM, Postgres, Nginx)
│   └── router.php                 # API route definitions
│
├── ika-jtk-cms/                    # Administrative Control Panel (CMS)
│   ├── src/pages/                 # Admin modules (E-Voting, Users, Jobs, Audit)
│   ├── src/components/            # UI component library & Canvas image croppers
│   ├── package.json               # React + TypeScript + Vite tooling
│   └── vite.config.ts             # Bundler configuration
│
├── ika-jtk-portal/                 # User-Facing Public Alumni Portal
│   ├── lib/pages/                 # Mobile & Web responsive views (E-Voting, Directory)
│   ├── lib/services/              # Skia GPU image compression & HTTP Polling
│   └── pubspec.yaml               # Flutter Web dependencies
│
└── Docs & Reports/                 # Technical documentation & internship reports (BAB 3 & 4)
```

---

## 🛠️ Tech Stack

| Tier | Technologies & Frameworks |
| :--- | :--- |
| **Backend API** | PHP, PostgreSQL, Docker Compose, Phinx Migrations, RESTful API |
| **Admin Panel (CMS)** | React 18, TypeScript, Vite, TailwindCSS, HTML5 Canvas API |
| **Alumni Portal** | Flutter Web (Dart), `flutter_image_compress` (Skia GPU), HTTP Polling |
| **DevOps & Infrastructure** | Docker, Nginx Reverse Proxy, Git, Linux |

---

## 🚀 Key Engineering Contributions & Solutions

### 1. Full-Stack Electronic Voting (E-Voting) Engine
* Engineered an end-to-end organizational election module across all three tiers (Server, CMS, and Portal).
* Implemented an **asynchronous HTTP Polling mechanism (15-second interval)** on public aggregation endpoints, enabling live vote counting and statistical visualization without manual browser refreshes.
* Built concurrency protections and automated session time-locking to guarantee **1-account-1-vote** integrity.

### 2. Distributed Client-Side Image Preprocessing & GPU Downscaling
* **Problem:** Users frequently uploaded uncompressed 50MB photos from high-resolution smartphones, overwhelming server bandwidth and degrading page load times.
* **Solution:** Moved computationally expensive preprocessing to the client before network transmission:
  * **Portal (Flutter Web):** Leveraged Skia GPU hardware acceleration (`flutter_image_compress`) to downscale images to 1080px and compress files from ~50MB to <5MB (10x performance improvement).
  * **CMS (React):** Implemented high-resolution HTML5 Canvas manipulation with pixel-level alpha-channel preservation, eliminating transparency corruption on PNG files.

### 3. API Hardening & Error Masking
* Secured backend controllers against sensitive data leaks through structured exception logging (`catch` blocks).
* Implemented standardized **error masking** to return safe, client-friendly error envelopes rather than leaking raw database stack traces or server paths.

### 4. Membership Verification & Alumni Career Portal
* Developed multi-stage membership onboarding with email OTP verification and admin document approval workflows.
* Built an interactive career board with moderation queues, applicant submission handling, and automated SEO metadata/thumbnail generation.

---

## 🏁 Getting Started

### 1. Backend Service (Docker)
```bash
cd ika-jtk-backend
cp .env.example .env
docker-compose up -d --build
```

### 2. Admin CMS Panel (React)
```bash
cd ika-jtk-cms
cp .env.example .env
npm install
npm run dev
```

### 3. Alumni Portal (Flutter Web)
```bash
cd ika-jtk-portal
cp .env.example .env
flutter pub get
flutter run -d chrome
```

---

## 📜 Documentation & Academic Reports

This repository also contains the complete internship research chapters:
* [`BAB_3_Draf_Reinbrandt.md`](BAB_3_Draf_Reinbrandt.md) — Comprehensive implementation details & critical analysis.
* [`BAB_4_Draf_Reinbrandt.md`](BAB_4_Draf_Reinbrandt.md) — Conclusions and industry engineering recommendations.
* [`Flow_Implementasi_Fitur.md`](Flow_Implementasi_Fitur.md) — Feature architecture diagrams and workflow charts.
