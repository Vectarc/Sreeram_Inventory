# Mobile Application Test Cases - Sree Ram Company

This document provides a detailed list of test cases for the Sree Ram Company mobile application.

## 1. Authentication & Session Management

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| AUTH-01 | Splash Screen (Logged Out) | Open the app while not logged in. | App displays splash screen animation for ~2.3 seconds and redirects to **HomePage**. |
| AUTH-02 | Splash Screen (Logged In) | Open the app while a session exists (Token saved). | App displays splash screen and redirects to **AdminDashboard** (if role is admin) or **UserDashboard** (if staff). |
| AUTH-03 | Admin Login | Navigate to Login, enter valid **Admin** username and password. | Redirects to AdminDashboard with all management icons visible. "Login Successful" notification appears. |
| AUTH-04 | Staff/User Login | Navigate to Login, enter valid **Staff** username and password. | Redirects to UserDashboard. management icons restricted based on permissions. |
| AUTH-05 | Invalid Login | Enter incorrect username or password. | Displays error message "Invalid credentials" or similar. Access denied. |
| AUTH-06 | Logout | Tap "Logout" in the Dashboard/Drawer. | Session token is cleared. User is redirected back to **HomePage**. |

## 2. Dashboard & Navigation

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| DASH-01 | Theme Toggle | Tap the Theme Toggle icon (Sun/Moon). | App instantly switches between Light and Dark mode. Colors adapt according to `AppColors` definitions. |
| DASH-02 | Admin Menu Visibility | Log in as Admin. | Dashboard displays icons for Branch, User, Vendor, Product, Stock, and Contact Management. |
| DASH-03 | Drawer Navigation | Open Sidebar Drawer from HomePage. | Displays links to Products, Contacts, and Login. All links navigate to respective screens. |
| DASH-04 | Pull-to-Refresh | Swipe down on any listing screen (Product/Stock). | Loading indicator appears. Data is re-fetched from the API and updated in the UI. |

## 3. Product Management (Tables/Lists)

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| PROD-01 | View Product List | Navigate to Product Management. | A list/table of products is displayed with Name, Code, Brand, Category, and image placeholder. |
| PROD-02 | Search Product | Enter product name or code in the search bar. | The list dynamically filters to show only matching products. Matches are case-insensitive. |
| PROD-03 | Filter by Category | Select a category (e.g., 'PLASTISOL') from the filter bar. | The list shows only products belonging to the selected category. |
| PROD-04 | Filter by Vendor | Select a vendor from the dropdown filter. | The list shows only products associated with that vendor. |
| PROD-05 | Create Product | Click 'Add Product', fill Code, Name, Brand, Unit, and Category. | Product is saved to backend. App shows "Product added!" notification and refreshes list. |
| PROD-06 | Update Product | Tap existing product, change details (e.g., Name), and click 'Update'. | Changes are saved. List reflects updated information. |
| PROD-07 | Delete Product | Long press or open edit and tap 'Delete'. | Confirmation dialog appears. Product is removed upon confirmation. |
| PROD-08 | Image Upload | In Create/Edit, tap image area and select a file (< 2MB). | Selected image preview is shown. Saving successfully uploads image to server. |
| PROD-09 | Image Size Validation | Attempt to upload an image > 5MB. | App shows error: "Image is too large. Please choose a smaller image." |
| PROD-10 | Unit Management | In Product Dialog, type a new unit name in searchable dropdown. | Unit is added to the system and selectable for future products. |

## 4. Stock Management

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| STK-01 | View Global Stock | Navigate to Stock Management as Admin. | Displays list of products with their total stock quantity across all/selected branches. |
| STK-02 | Branch Filter | Select a specific branch from the dropdown. | Stock levels updated to show quantities only for chosen branch. |
| STK-03 | Update Stock | Select a product, enter new quantity, Click 'Save'. | Stock is updated in database. UI reflects new count immediately. |
| STK-04 | Stock Search | Search for product in stock page. | Correct product is found with its specific stock metrics. |

## 5. Contact Management

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| CON-01 | View Contacts | Open Public/Internal Contact page. | List of contacts displayed with Name, Phone, and Category (Transport, Staff, etc.). |
| CON-02 | Filter by Contact Type | Tap 'Transport' category filter. | Only transport-related contacts are visible. |
| CON-03 | Create Contact | Click 'Add Contact', enter details and category. | Contact is saved. Notification shows "Contact added!". |
| CON-04 | Direct Call | Tap the Phone icon/number on a contact card. | App triggers system dialer with the contact's number. |

## 6. Management Modules (Admin Only)

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| MGMT-01 | Branch Management | Create/Edit/Delete a branch. | Branch details (Name, Location, Phone, isMain) are saved and reflected globally. |
| MGMT-02 | User Management | Create a new user with 'staff' role. | New user can log in using their credentials and access UserDashboard. |
| MGMT-03 | Vendor Management | List and edit vendor details. | Vendors are available for selection in the Product creation screen. |

## 7. UI/UX & Responsive Design

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| UI-01 | Loading States | Slow network simulation. | Shimmer or CircularProgressIndicator is shown while data fetches. |
| UI-02 | Error Handling | Backend server down. | "Network error" or "Server unreachable" notification appears with a Retry button. |
| UI-03 | Form Validation | Submit empty 'Add Product' form. | Red validation messages/notifications appear: "Please fill required fields". |

## 8. Backend API (System Integration)

These test cases cover the server-side logic and database interactions.

| Test Case ID | Test Case | Input | Expected Output |
| :--- | :--- | :--- | :--- |
| API-AUTH-01 | Login Request | POST `/api/auth/login` with `{username, password}` | Status 200. JSON: `{success: true, token, user: {username, role}}`. |
| API-PROD-01 | Get Products | GET `/api/products` | Status 200. JSON: `{success: true, products: [...]}`. |
| API-PROD-02 | Create Product (Admin) | POST `/api/products` with valid fields + Auth Token | Status 201. JSON: `{success: true, message: "Product created.", product: {...}}`. |
| API-PROD-03 | Create Product (Duplicate) | POST `/api/products` with existing Code | Status 409. JSON: `{success: false, message: "Product code already exists."}`. |
| API-STK-01 | Update Stock | PUT `/api/stock/:id` with `{quantity, branch}` | Status 200. JSON: `{success: true, message: "Stock updated.", stock: {...}}`. |
| API-STK-02 | Unauthorized Update | POST `/api/products` without Valid Admin Token | Status 401 or 403. Access denied. |
| API-BRCH-01 | List Branches | GET `/api/branches` | Status 200. JSON: `{success: true, branches: [...]}`. |
| API-IMG-01 | Image Upload Logic | POST `/api/products` with Multipart/form-data | Status 201. Image is saved to Supabase Storage; `image_url` is stored in DB. |
