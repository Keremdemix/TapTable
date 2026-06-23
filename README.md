# 🍽️ TapTable

TapTable is a modern **QR-based restaurant ordering, table management, and payment system** designed to digitize and streamline restaurant operations. It connects customers, waiters, kitchen staff, and restaurant owners in a single real-time ecosystem.

---

## 🚀 Project Overview

TapTable replaces traditional restaurant workflows with a **fully digital, real-time system**:

- Customers scan a QR code to access the menu
- Orders are placed directly from mobile/web
- Staff manages orders via admin and kitchen panels
- Payments are handled securely via Stripe
- All updates are synchronized in real-time

---

## 🎯 Goals

### Short Term
- QR menu & ordering system
- Staff/admin dashboard
- Basic Stripe payment integration
- Table-based order tracking

### Long Term
- Multi-tenant SaaS architecture
- AI-based recommendation system
- Advanced analytics dashboard
- Loyalty & promotion system
- Scalable restaurant network support
---

## 🧩 System Architecture

TapTable follows a **modular, scalable client-server architecture**:

```text
📱 Customer App (Flutter)
🧑‍💼 Staff Panel (Flutter Web)
            │
            ▼
🧠 Backend API (ASP.NET Core)
            │
            ▼
🗄️ Database (SQL Server / PostgreSQL)
            │
            ▼
⚡ Realtime Layer (SignalR)
            │
            ▼
💳 Payment Gateway (Stripe)
```
---

## 🏗️ Architecture Layers

### 🔹 Frontend
- Flutter (Mobile + Web)
- Responsive UI for customers and staff

### 🔹 Backend
- ASP.NET Core Web API
- JWT Authentication
- Order, menu, and table management

### 🔹 Realtime Communication
- SignalR
- Live order updates & status sync

### 🔹 Payment System
- Stripe Integration
- Payment Intent + Webhook flow
- Apple Pay / Google Pay support

---

## 👥 User Roles

- 👤 Customer → Scan QR, order, pay
- 🧑‍🍳 Waiter → Manage and update orders
- 👨‍💼 Admin → Manage restaurant, menu, tables, reports
- 🍳 Kitchen → Track and prepare orders

---

## 📱 Features

### Customer App
- QR code scanning
- Digital menu browsing
- Cart & order creation
- Real-time order tracking
- Stripe payment integration

### Staff System
- Order management dashboard
- Kitchen screen (real-time orders)
- Table management (drag & drop layout)
- Menu management
- Sales reports

---

## ⚙️ Core Modules

- Authentication (JWT)
- Order Management System
- Menu Management
- Table Management System
- Payment Processing (Stripe)
- Real-time updates (SignalR)

---

## 🗄️ Database Structure

- Users
- Roles
- Tables
- TableLayouts
- Orders
- OrderItems
- MenuItems
- Payments
- Categories

---

## 🔌 API Endpoints (Sample)

### Auth
- `POST /auth/login`
- `POST /auth/register`

### Orders
- `POST /orders`
- `GET /orders/{id}`
- `PUT /orders/status`

### Menu
- `GET /menu`
- `POST /menu`

### Payments
- `POST /payments/create-intent`
- `POST /payments/webhook`

### Tables
- `GET /tables`
- `POST /tables`

---

## 📊 KPIs

- ⏱️ 40% faster order processing
- ❌ 70% fewer order errors
- 📈 Increased staff efficiency
- 💬 Improved customer satisfaction
- ⚡ Reduced average service time

---

## 🧪 Tech Stack

### Frontend
- Flutter
- Dart
- Flutter Web

### Backend
- ASP.NET Core Web API
- C#

### Realtime
- SignalR

### Database
- SQL Server / PostgreSQL
- Entity Framework Core

### Payment
- Stripe API

---

## 🛣️ Roadmap

- [x] QR Menu System
- [x] Order Management
- [x] Staff Dashboard
- [ ] Multi-restaurant SaaS support
- [ ] AI recommendation system
- [ ] Loyalty program module
- [ ] Advanced analytics dashboard

---

## 📌 Status

🚧 In Development

---

## 📄 License

This project is currently private / in development phase.
