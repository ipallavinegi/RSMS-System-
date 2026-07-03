#!/bin/bash
set -e

DIR="Admin_RSMS"
cd $DIR

# 1. Create all directories
mkdir -p App/Navigation
mkdir -p Core/Components Core/Theme Core/Helpers Core/Extensions
mkdir -p Features/Authentication/Views Features/Authentication/ViewModels Features/Authentication/Services
mkdir -p Features/Dashboard/Views Features/Dashboard/Components Features/Dashboard/ViewModels Features/Dashboard/Services
mkdir -p Features/Stores/Views Features/Stores/Components Features/Stores/ViewModels Features/Stores/Services
mkdir -p Features/Managers/Views Features/Managers/Components Features/Managers/ViewModels Features/Managers/Services
mkdir -p Features/Products/Views Features/Products/Components Features/Products/Models Features/Products/Theme Features/Products/ViewModels Features/Products/Services
mkdir -p Features/Promos/Views Features/Promos/ViewModels Features/Promos/Services
mkdir -p Features/Audit/Views Features/Audit/Components Features/Audit/ViewModels Features/Audit/Services
mkdir -p Shared/Models Shared/Services
mkdir -p Resources
mkdir -p Assets

# Function to safely move a file if it exists
move_file() {
    if [ -f "$1" ]; then
        mv "$1" "$2"
        echo "Moved $1 to $2"
    fi
}

# App
move_file App/Admin_RSMSApp.swift App/Admin_RSMSApp.swift
move_file App/ContentView.swift App/RootView.swift
move_file App/Navigation/SidebarItem.swift App/Navigation/SidebarItem.swift
# Or if it's named something else at the root
move_file Admin_RSMSApp.swift App/Admin_RSMSApp.swift
move_file ContentView.swift App/RootView.swift
move_file SidebarItem.swift App/Navigation/SidebarItem.swift

# Core/Theme
move_file Core/Theme/Constants.swift Core/Theme/Constants.swift
move_file Core/Components/ComingSoonView.swift Core/Components/ComingSoonView.swift

# Features/Authentication
move_file Features/Authentication/Views/LoginView.swift Features/Authentication/Views/LoginView.swift
move_file Features/Authentication/Services/AuthService.swift Features/Authentication/Services/AuthService.swift
move_file Features/Authentication/Services/AuthManager.swift Features/Authentication/Services/AuthManager.swift # Keep it there for now

# Features/Products
move_file Features/Products/ViewModels/ProductApprovalViewModel.swift Features/Products/ViewModels/ProductApprovalViewModel.swift
move_file Features/Products/Models/ProductPriceUpdate.swift Features/Products/Models/ProductPriceUpdate.swift
move_file Features/Products/Models/ApprovalStatus.swift Features/Products/Models/ApprovalStatus.swift
move_file Features/Products/Models/ProductStatusUpdate.swift Features/Products/Models/ProductStatusUpdate.swift
move_file Features/Products/Theme/Theme+Products.swift Features/Products/Theme/Theme+Products.swift
move_file Features/Products/Views/FitImageView.swift Features/Products/Views/FitImageView.swift
move_file Features/Products/Views/ProductCard.swift Features/Products/Components/ProductCard.swift
move_file Features/Products/Views/ProductsView.swift Features/Products/Views/ProductsView.swift
move_file Features/Products/Views/ProductDetailView.swift Features/Products/Views/ProductDetailView.swift

# Features/Managers
move_file Features/Managers/Views/ManagerCard.swift Features/Managers/Components/ManagerCard.swift
move_file Features/Managers/Views/ManagersView.swift Features/Managers/Views/ManagersView.swift

# Features/Stores
move_file Features/Stores/Views/StoreCard.swift Features/Stores/Components/StoreCard.swift
move_file Features/Stores/Views/StoresView.swift Features/Stores/Views/StoresView.swift

# Features/Create -> Move to respective domains
move_file Features/Create/Views/ManagerForm.swift Features/Managers/Views/ManagerForm.swift
move_file Features/Create/Views/AddStoreSidebarView.swift Features/Stores/Views/AddStoreSidebarView.swift
move_file Features/Create/Views/StoreForm.swift Features/Stores/Views/StoreForm.swift

# Shared/Models
move_file Shared/Models/Report.swift Shared/Models/Report.swift
move_file Shared/Models/ManagerModel.swift Shared/Models/Manager.swift
move_file Shared/Models/Role.swift Shared/Models/Role.swift
move_file Shared/Models/StoreModel.swift Shared/Models/Store.swift
move_file Shared/Models/Shift.swift Shared/Models/Shift.swift
move_file Shared/Models/Customer.swift Shared/Models/Customer.swift
move_file Shared/Models/Shipment.swift Shared/Models/Shipment.swift
move_file Shared/Models/InventoryException.swift Shared/Models/InventoryException.swift
move_file Shared/Models/User.swift Shared/Models/User.swift
move_file Shared/Models/HealthScore.swift Shared/Models/HealthScore.swift
move_file Shared/Models/Warehouse.swift Shared/Models/Warehouse.swift
move_file Shared/Models/Inventory.swift Shared/Models/Inventory.swift
move_file Shared/Models/Sale.swift Shared/Models/Sale.swift
move_file Shared/Models/AuditLog.swift Shared/Models/AuditLog.swift
move_file Shared/Models/Notification.swift Shared/Models/Notification.swift
move_file Shared/Models/Attendance.swift Shared/Models/Attendance.swift
move_file Shared/Models/CycleCount.swift Shared/Models/CycleCount.swift
move_file Shared/Models/SaleItem.swift Shared/Models/SaleItem.swift
move_file Shared/Models/Category.swift Shared/Models/Category.swift
# Shared/Models/Store.swift and Product.swift might exist, let's see
move_file Shared/Models/Product.swift Shared/Models/Product.swift
move_file Shared/Models/ProductImage.swift Shared/Models/ProductImage.swift
move_file Shared/Models/ShipmentItem.swift Shared/Models/ShipmentItem.swift
move_file Shared/Models/StockRequest.swift Shared/Models/StockRequest.swift
move_file Shared/Models/Task.swift Shared/Models/Task.swift
move_file Shared/Models/Transfer.swift Shared/Models/Transfer.swift

# Shared/Services
move_file Shared/Services/InventoryService.swift Shared/Services/InventoryService.swift
move_file Shared/Services/UserService.swift Shared/Services/UserService.swift
move_file Shared/Services/ProductService.swift Shared/Services/ProductService.swift
move_file Shared/Services/DatabaseService.swift Shared/Services/DatabaseService.swift
move_file Shared/Services/RSMSDataManager.swift Shared/Services/RSMSDataManager.swift
move_file Shared/Services/SupabaseManager.swift Shared/Services/SupabaseManager.swift

# Clean up empty directories
find . -type d -empty -delete

echo "Restructuring completed."
