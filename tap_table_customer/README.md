# 📱 TapTable Customer App

TapTable Customer App is the customer-facing side of **TapTable**, enabling guests to order and pay directly from their phones using a QR code placed on restaurant tables.

It eliminates the need to wait for manual service during ordering and payment, creating a faster and smoother dining experience.

---

## 🚀 Project Overview

Customers interact with the restaurant digitally:

* Scan table QR code
* Browse digital menu
* Add items to cart
* Place orders instantly
* Track order status in real time
* Pay securely from mobile

This creates a seamless and contactless ordering flow.

---

## 🎯 Goals

### Short Term

* QR code access
* Menu browsing
* Cart & checkout
* Secure payments

### Long Term

* AI food recommendations
* Loyalty system
* Personalized offers
* Saved favorite orders

---

## 🧩 System Architecture

```text
📱 Customer App (Flutter)
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
💳 Stripe Payment Gateway
```

---

## 📱 Features

### QR Ordering

* Scan table QR
* Automatic table detection

### Digital Menu

* Categories
* Product details
* Images & pricing

### Order System

* Add to cart
* Edit quantities
* Place order

### Live Tracking

* Order received
* Preparing
* Ready / served

### Payment

* Stripe integration
* Fast checkout
* Secure payment flow

---

## ⚙️ Core Modules

* QR Scanner
* Menu System
* Cart Management
* Order Management
* Payment Processing
* Realtime Tracking

---

## 🗄️ Database Structure

* Tables
* Orders
* OrderItems
* MenuItems
* Categories
* Payments

---

## 🔌 API Endpoints (Sample)

### Menu

* `GET /menu?table={id}`

### Orders

* `POST /orders`
* `GET /orders/{id}`

### Payments

* `POST /payments/create-intent`
* `POST /payments/webhook`

---

## 📊 KPIs

* ⏱️ Faster ordering
* 📈 Higher order volume
* 💬 Better customer experience
* ⚡ Reduced waiting time

---

## 🧪 Tech Stack

### Frontend

* Flutter
* Dart

### Backend

* ASP.NET Core
* C#

### Realtime

* SignalR

### Payment

* Stripe API

---

## 📌 Status

🚧 In Development
