import Foundation

enum DashboardSampleData {
    static func make() -> DashboardData {
        let calendar = Calendar.current
        let now = Date()
        let storeId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let managerId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let stylistId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let cashierId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let shiftId = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let nextShiftId = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let customerA = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let customerB = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        let productA = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let productB = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let productC = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let categoryId = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!

        let store = Store(
            id: storeId,
            storeName: "Maison South Delhi",
            pinCode: "110017",
            region: "North",
            country: "India",
            city: "New Delhi",
            status: "active",
            managerId: managerId,
            createdAt: now
        )

        let users = [
            User(id: managerId, fullName: "Aanya Mehra", username: "aanya", email: "aanya@maison.test", roleId: UUID(), storeId: storeId, shiftId: shiftId, isVerified: true),
            User(id: stylistId, fullName: "Kabir Sethi", username: "kabir", email: "kabir@maison.test", roleId: UUID(), storeId: storeId, shiftId: shiftId, isVerified: true),
            User(id: cashierId, fullName: "Naina Rao", username: "naina", email: "naina@maison.test", roleId: UUID(), storeId: storeId, shiftId: nextShiftId, isVerified: true)
        ]

        let shifts = [
            Shift(id: shiftId, storeId: storeId, shiftName: "Opening Floor", startTime: "09:00", endTime: "17:00", status: "active", createdBy: managerId, createdAt: now),
            Shift(id: nextShiftId, storeId: storeId, shiftName: "Evening Clienteling", startTime: "17:00", endTime: "22:00", status: "active", createdBy: managerId, createdAt: now)
        ]

        let products = [
            Product(id: productA, sku: "MSN-BLAZER-01", productName: "Ivory Linen Blazer", brand: "Maison", categoryId: categoryId, price: 18500, description: "Tailored linen blazer", qrValue: "MSN-BLAZER-01", createdAt: now),
            Product(id: productB, sku: "MSN-SCARF-07", productName: "Silk Monogram Scarf", brand: "Maison", categoryId: categoryId, price: 7200, description: "Printed silk scarf", qrValue: "MSN-SCARF-07", createdAt: now),
            Product(id: productC, sku: "MSN-DRESS-14", productName: "Black Satin Dress", brand: "Maison", categoryId: categoryId, price: 24600, description: "Evening satin dress", qrValue: "MSN-DRESS-14", createdAt: now)
        ]

        let sale1 = Sale(id: UUID(), customerId: customerA, userId: stylistId, storeId: storeId, totalAmount: 50300, paymentMethod: "card", saleStatus: "completed", saleDate: calendar.date(byAdding: .hour, value: -2, to: now) ?? now, createdAt: now)
        let sale2 = Sale(id: UUID(), customerId: customerB, userId: managerId, storeId: storeId, totalAmount: 31800, paymentMethod: "upi", saleStatus: "completed", saleDate: calendar.date(byAdding: .day, value: -1, to: now) ?? now, createdAt: now)
        let sale3 = Sale(id: UUID(), customerId: customerA, userId: stylistId, storeId: storeId, totalAmount: 42800, paymentMethod: "card", saleStatus: "completed", saleDate: calendar.date(byAdding: .day, value: -3, to: now) ?? now, createdAt: now)

        return DashboardData(
            stores: [store],
            sales: [sale1, sale2, sale3],
            saleItems: [
                SaleItem(id: UUID(), saleId: sale1.id, productId: productA, quantity: 1, unitPrice: 18500, createdAt: now),
                SaleItem(id: UUID(), saleId: sale1.id, productId: productB, quantity: 2, unitPrice: 7200, createdAt: now),
                SaleItem(id: UUID(), saleId: sale1.id, productId: productC, quantity: 1, unitPrice: 17400, createdAt: now),
                SaleItem(id: UUID(), saleId: sale2.id, productId: productB, quantity: 1, unitPrice: 7200, createdAt: now),
                SaleItem(id: UUID(), saleId: sale3.id, productId: productC, quantity: 2, unitPrice: 21400, createdAt: now)
            ],
            salesTargets: [
                SalesTarget(id: UUID(), storeId: storeId, periodType: "day", periodStart: calendar.startOfDay(for: now), periodEnd: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now, targetAmount: 125000, createdBy: managerId, createdAt: now)
            ],
            shifts: shifts,
            shiftAssignments: [
                ShiftAssignment(id: UUID(), shiftId: shiftId, userId: managerId, assignmentDate: now, status: "scheduled", createdBy: managerId, createdAt: now),
                ShiftAssignment(id: UUID(), shiftId: shiftId, userId: stylistId, assignmentDate: now, status: "scheduled", createdBy: managerId, createdAt: now)
            ],
            attendance: [
                Attendance(id: UUID(), employeeId: managerId, attendanceDate: now, checkIn: calendar.date(bySettingHour: 8, minute: 55, second: 0, of: now), checkOut: nil, status: "present", workingHours: nil, createdAt: now),
                Attendance(id: UUID(), employeeId: stylistId, attendanceDate: now, checkIn: calendar.date(bySettingHour: 9, minute: 8, second: 0, of: now), checkOut: nil, status: "present", workingHours: nil, createdAt: now)
            ],
            users: users,
            inventory: [
                InventoryItem(id: UUID(), productId: productA, storeId: storeId, warehouseId: nil, locationType: "store", quantity: 0, reorderLevel: 3, lastVerifiedAt: now, createdAt: now),
                InventoryItem(id: UUID(), productId: productB, storeId: storeId, warehouseId: nil, locationType: "store", quantity: 2, reorderLevel: 8, lastVerifiedAt: now, createdAt: now),
                InventoryItem(id: UUID(), productId: productC, storeId: storeId, warehouseId: nil, locationType: "store", quantity: 1, reorderLevel: 4, lastVerifiedAt: now, createdAt: now)
            ],
            products: products,
            customers: [
                Customer(id: customerA, name: "Riya Malhotra", phone: "+91 98765 12345", email: "riya@example.com", createdAt: now),
                Customer(id: customerB, name: "Dev Arora", phone: "+91 98765 67890", email: "dev@example.com", createdAt: now)
            ],
            appointments: [
                Appointment(id: UUID(), storeId: storeId, customerId: customerA, assignedUserId: stylistId, appointmentStart: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: now) ?? now, appointmentEnd: calendar.date(bySettingHour: 16, minute: 15, second: 0, of: now) ?? now, purpose: "Wedding edit styling", priority: "vip", status: "confirmed", notes: "Prefers ivory and gold palette.", createdAt: now),
                Appointment(id: UUID(), storeId: storeId, customerId: customerB, assignedUserId: managerId, appointmentStart: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now, appointmentEnd: calendar.date(bySettingHour: 18, minute: 30, second: 0, of: now) ?? now, purpose: "Alteration pickup", priority: "medium", status: "confirmed", notes: nil, createdAt: now)
            ],
            stockRequests: []
        )
    }
}

// MARK: - Mock Initializers for existing models
extension User {
    init(id: UUID, fullName: String, username: String, email: String, roleId: UUID, storeId: UUID?, shiftId: UUID?, isVerified: Bool) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.email = email
        self.roleId = roleId
        self.storeId = storeId
        self.shiftId = shiftId
        self.isVerified = isVerified
        
        self.employeeCode = "EMP-\(id.uuidString.prefix(4))"
        self.employeeStatus = "active"
        self.profileImageURL = nil
        self.lastLogin = Date()
        self.designation = nil
        self.phone = nil
        self.gender = nil
        self.dateOfBirth = nil
        self.address = nil
        self.joiningDate = nil
        self.createdBy = nil
        self.createdAt = Date()
    }
}

extension Customer {
    init(id: UUID, name: String, phone: String, email: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.customerStatus = "active"
        self.loyaltyPoints = 0
        self.createdAt = createdAt
        
        self.gender = nil
        self.dateOfBirth = nil
        self.anniversaryDate = nil
        self.lastVisitDate = nil
        self.preferredBrand = nil
        self.preferredCategory = nil
        self.preferredContactMethod = nil
        self.wishlist = nil
        self.notes = nil
        self.assignedSalesAssociateId = nil
        self.assignedStoreId = nil
        self.customerTier = "bronze"
        self.privacyConsent = true
        self.isVip = false
        self.isActive = true
    }
}

extension Product {
    init(id: UUID, sku: String, productName: String, brand: String, categoryId: UUID, price: Double, description: String, qrValue: String, createdAt: Date) {
        self.id = id
        self.sku = sku
        self.productName = productName
        self.barcode = qrValue
        self.shortDescription = description
        self.description = description
        self.brand = brand
        self.categoryId = categoryId
        self.price = price
        self.material = nil
        self.color = nil
        self.size = nil
        self.weight = nil
        self.collectionName = nil
        self.modelNumber = nil
        self.serialNumber = nil
        self.certificateNumber = nil
        self.warrantyDuration = nil
        self.status = "active"
        self.approvalStatus = "approved"
        self.isNewArrival = false
        self.isBestSeller = false
        self.isLimitedEdition = false
        self.createdAt = createdAt
    }
}
