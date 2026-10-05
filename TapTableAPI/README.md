# 🧠 TapTable API

TapTable API is the backend service of **TapTable**, providing the core business logic and data services for both the **Customer App** and **Staff Panel**.

Built with **ASP.NET Core Web API**, the backend manages authentication, restaurant data, tables, menus, orders, payments, QR sessions, customer sessions, and real-time restaurant operations.

---

## 🚀 Project Overview

The TapTable API acts as the central communication layer between the TapTable applications and the database.

It is responsible for:

* User authentication and authorization
* Restaurant and table management
* Digital menu management
* Customer sessions
* Order processing
* Payment operations
* QR session management
* Restaurant branding
* Real-time communication
* Image upload operations

The API provides secure and centralized access to restaurant data and business operations.

---

## 🧩 System Architecture

```text
📱 Customer App (Flutter)
            │
            ▼
🧑‍💼 Staff Panel (Flutter Web)
            │
            ▼
🧠 TapTable API (ASP.NET Core)
            │
            ├──────────────► 🗄️ SQL Server Database
            │
            ├──────────────► ⚡ SignalR
            │
            ├──────────────► 💳 Payment Services
            │
            └──────────────► ☁️ Cloudinary
```

---

## 🏗️ Architecture Layers

### 🔹 Controllers

The API exposes HTTP endpoints through dedicated controllers.

Main areas include:

* Authentication
* Customers
* Customer sessions
* Images
* iyzico sub-merchant management
* Menu
* Orders
* Payments
* Public menu
* Public orders
* Public payments
* QR sessions
* Restaurants
* Tables

---

### 🔹 Services

Business logic is handled through service interfaces and implementations.

Main services include:

* Authentication Service
* Customer Service
* Menu Service
* Order Service
* Payment Service
* QR Session Service
* Restaurant Service
* Table Service
* Image Upload Service
* iyzico Sub-Merchant Service

This keeps business rules separated from the HTTP layer.

---

### 🔹 Repositories

Repositories provide database access for the application's domain entities.

Main repositories include:

* User / Authentication
* Customer
* Category
* Menu Item
* Order
* Payment
* QR Session
* Restaurant
* Split Payment Plan
* Table
* Table Layout

---

## 🔐 Authentication & Authorization

TapTable API uses **JWT-based authentication**.

Authentication supports:

* Staff login
* Access tokens
* Refresh tokens
* Logout
* Profile management
* Password change
* Role-based authorization

### User Roles

* 🧑‍💼 Admin
* 🧑‍🍳 Waiter
* 🍳 Kitchen

Protected endpoints require a valid JWT access token.

---

## 🍽️ Restaurant Management

The API provides restaurant-level management functionality including:

* Restaurant information
* Restaurant branding
* Theme configuration
* Table management
* Table layouts
* Table capacity
* Table status
* QR tokens

---

## 📋 Menu Management

The menu system supports:

* Categories
* Menu items
* Item pricing
* Item images
* Availability management
* Restaurant-specific menu configuration

Both customer-facing and staff-facing applications consume menu data through the API.

---

## 🛎️ Order Management

The order system handles the complete order lifecycle.

Supported operations include:

* Creating orders
* Updating orders
* Retrieving active orders
* Updating order item statuses
* Kitchen workflow
* Ready item handling
* Serving ready items
* Order completion
* Order cancellation

Order processing is shared between the Customer App and Staff Panel.

---

#
