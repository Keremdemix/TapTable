# 🍽️ TapTable

TapTable is a restaurant management and digital ordering platform that connects **customers, restaurant staff, kitchen operations, payments, and real-time order management** through a single system.

The project consists of three main applications:

* 📱 **Customer App** — customer-facing mobile application
* 🧑‍💼 **Staff Panel** — restaurant management and operational dashboard
* 🧠 **TapTable API** — shared ASP.NET Core backend

Together, these applications provide a complete digital restaurant workflow from table QR access to ordering, kitchen processing, serving, and payment.

---

## 🚀 Project Overview

TapTable replaces traditional restaurant ordering workflows with a connected digital system.

### Customer Flow

```text
📱 Scan QR Code
      ↓
🍽️ Browse Menu
      ↓
🛒 Add Items to Cart
      ↓
📋 Place Order
      ↓
⚡ Track Order
      ↓
💳 Complete Payment
```

### Staff Flow

```text
📥 Receive Order
      ↓
🍳 Kitchen Preparation
      ↓
✅ Mark Items Ready
      ↓
🧑‍🍳 Serve Customer
      ↓
💳 Track Payment
```

All major operations are coordinated through the central TapTable API.

---

## 🧩 System Architecture

```text
                    ┌──────────────────────┐
                    │   Customer App       │
                    │     Flutter          │
                    └──────────┬───────────┘
                               │
                               │
                               ▼
                    ┌──────────────────────┐
                    │                      │
                    │    TapTable API      │
                    │    ASP.NET Core      │
                    │                      │
                    └───────┬───────┬──────┘
                            │       │
                ┌───────────┘       └────────────┐
                ▼                                ▼
       ┌────────────────┐                ┌────────────────┐
       │   SQL Server   │                │    SignalR     │
       │    Database    │                │ Realtime Layer │
       └────────────────┘                └────────────────┘
                            ▲
                            │
                    ┌───────┴────────┐
                    │                │
                    │   Staff Panel  │
                    │   Flutter Web  │
                    │                │
                    └────────────────┘
```

---

# 📱 Customer App

The Customer App is the customer-facing side of TapTable.

Guests use their phones to:

* Scan a table QR code
* Browse the digital menu
* Add items to a cart
* Place orders
* Track order status
* Complete payments

### Main Modules

* QR Scanner
* Digital Menu
* Cart Management
* Order Management
* Payment Processing
* Real-time Order Tracking

### Technology

* Flutter
* Dart

---

# 🧑‍💼 Staff Panel

The Staff Panel is the operational management application for restaurant employees.

It provides separate workflows for:

* Admin
* Waiter
* Kitchen Staff

### Main Modules

* Authentication
* Order Management
* Table Management
* Table Layout Editor
* Menu Management
* Kitchen Workflow
* Payment Management
* Real-time Notifications

### Admin

Admins can manage:

* Restaurant settings
* Restaurant branding
* Tables and layouts
* Menu items
* Categories
* Payment configuration

### Waiter

Waiters can:

* View active tables
* Manage orders
* Track customer requests
* Follow order progress
* Manage service workflow

### Kitchen

Kitchen staff can:

* View incoming orders
* Prepare order items
* Update preparation status
* Mark items as ready

### Technology

* Flutter Web
* Dart

---

# 🧠 TapTable API

The TapTable API is the central backend of the platform.

It provides:

* Authentication
* Authorization
* Restaurant management
* Table management
* Menu management
* Order management
* Customer sessions
* QR sessions
* Payment operations
* Real-time communication
* Image management

### Technology

* ASP.NET Core
* C#
* Entity Framework Core
* JWT
* SignalR

---

# 🔐 Authentication

TapTable uses JWT-based authentication for staff operations.

Supported functionality includes:

* Login
* Access tokens
* Refresh tokens
* Logout
* Profile management
* Password changes
* Role-based authorization

### Roles

```text
Admin
Waiter
Kitchen
```

---

# 🪑 Restaurant & Table Management

The platform supports digital management of restaurant tables.

Features include:

* Table creation
* Table status management
* Capacity management
* QR token generation
* Floor layout management
* Drag & drop positioning

This allows the restaurant's physical layout to be represented digitally in the Staff Panel.

---

# 🍽️ Menu System

The menu system provides restaurant-specific digital menus.

Supported functionality includes:

* Categories
* Menu items
* Pricing
* Availability
* Product images
* Restaurant branding

Customers consume the menu through the Customer App while staff manage it through the Staff Panel.

---

# 📋 Order Workflow

TapTable connects the complete order lifecycle:

```text
Customer places order
        ↓
Order received
        ↓
Kitchen prepares items
        ↓
Items become Ready
        ↓
Ready items are served
        ↓
Order completed
```

The Staff Panel provides operational control while the Customer App provides order status visibility.

---

# ⚡ Real-Time System

TapTable uses **SignalR** for real-time synchronization.

This enables:

* Instant new order notifications
* Kitchen status updates
* Table status updates
* Customer order tracking
* Service coordination

The goal is to keep customer and staff views synchronized without unnecessary refresh operations.

---

# 💳 Payment

TapTable includes payment functionality for customer and restaurant workflows.

The platform contains:

* Payment processing
* Payment tracking
* Split payments
* Payment items
* iyzico integration
* Customer payment flow

Payment-related functionality is coordinated through the TapTable API.

---

# ☁️ Image Management

The platform supports image management for restaurant and menu content.

The backend integrates with **Cloudinary** for image storage and upload operations.

---

# 🗄️ Database

The backend uses Entity Framework Core to manage application data.

Core entities include:

* Users
* Roles
* Restaurants
* Tables
* Table Layouts
* Categories
* Menu Items
* Orders
* Order Items
* Payments
* Payment Items
* Split Payment Plans
* QR Sessions

---

# 📁 Repository Structure

This repository is organized as a monorepo containing all three applications:

```text
TapTable/
│
├── tap_table_customer/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── web/
│
├── tap_table_staff/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── linux/
│   ├── macos/
│   ├── web/
│   └── windows/
│
└── TapTableAPI/
    ├── Configuration/
    ├── Controllers/
    ├── Data/
    ├── DTOs/
    ├── Migrations/
    ├── Repositories/
    ├── Services/
    └── Program.cs
```

---

# 🛠️ Tech Stack

## Frontend

* Flutter
* Dart
* Flutter Web

## Backend

* ASP.NET Core
* C#

## Database

* SQL Server

## ORM

* Entity Framework Core

## Authentication

* JWT
* Refresh Tokens
* Role-based Authorization

## Realtime

* SignalR

## Payments

* iyzico

## Image Storage

* Cloudinary

---

# ▶️ Running the Projects

Each application can be run independently from its own directory.

### Customer

```bash
cd tap_table_customer
flutter pub get
flutter run
```

### Staff

```bash
cd tap_table_staff
flutter pub get
flutter run
```

### API

```bash
cd TapTableAPI
dotnet restore
dotnet build
dotnet run
```

---

# 🌐 Development Architecture

A typical local development setup can use:

```text
Customer App
http://localhost:8080

Staff Panel
http://localhost:8083

TapTable API
http://localhost:5014
```

The frontend applications communicate with the central API.

For external testing, the API can also be exposed through a Cloudflare Tunnel.

Example:

```text
Cloudflare Tunnel
        ↓
http://192.168.0.37:5014
        ↓
IIS
        ↓
TapTable API
```

---

# 📊 Project Goals

### Short Term

* QR-based customer access
* Digital menu
* Customer ordering
* Real-time kitchen workflow
* Table management
* Secure payments
* Restaurant administration

### Long Term

* Multi-branch restaurant support
* Advanced analytics
* Staff performance reporting
* Customer loyalty system
* Personalized offers
* AI-powered food recommendations
* AI-powered demand forecasting

---

# 📈 KPIs

TapTable aims to improve:

* ⏱️ Ordering speed
* ⚡ Service speed
* ❌ Order accuracy
* 📈 Order volume
* 🧑‍💼 Staff productivity
* 💬 Customer experience
* 📉 Customer waiting time

---

# 📌 Project Status

🚧 **In Development**

TapTable is actively being developed as a unified restaurant ordering and management platform.
