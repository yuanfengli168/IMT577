-- ====================================
-- Author: Yuanfeng Li
-- Date: 5/24/2021


-- Create dimension Tables
-- ====================================


--dim date
IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimDate')
BEGIN
	DROP TABLE dbo.dimDate;
END
GO

CREATE TABLE dbo.dimDate
(
dimDateID INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dimDate PRIMARY KEY,
FullDate DATE NOT NULL,
DayNumberOfWeek TINYINT NOT NULL,
DayNameOfWeek VARCHAR (9) NOT NULL,
DayNumberOfMonth TINYINT NOT NULL,
DayNumberOfYear INT NOT NULL,
WeekdayFlag INT NOT NULL,
WeekNumberOfYear TINYINT NOT NULL,
[MonthName] VARCHAR(9) NOT NULL,
MonthNumberOfYear TINYINT NOT NULL,
CalendarQuarter TINYINT NOT NULL,
CalendarYear INT NOT NULL,
CalendarSemester TINYINT NOT NULL,
CreatedDate DATETIME NOT NULL
,CreatedBy NVARCHAR(255) NOT NULL
,ModifiedDate DATETIME NULL
,ModifiedBy NVARCHAR(255) NULL
);
GO

--dim product
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimProduct')
BEGIN
	CREATE TABLE dbo.dimProduct
	(
	dimProductID INT IDENTITY(1,1) CONSTRAINT PK_dimProduct PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	SourceProductID INT NOT NUll, --Natural Key
	SourceProductTypeID INT NOT NUll, --Natural Key
    SourceProductCategoryID INT NOT NUll, --Natural Key
    ProductName VARCHAR(50) NOT NULL,
    ProductType VARCHAR(50) NOT NULL,
	ProductCategoryName VARCHAR(50) NOT NULL,
	ProductRetailPrice DECIMAL(18,2) NOT NULL, --? allow null
    ProductWholesalePrice DECIMAL(18,2) NOT NULL,
	ProductCost DECIMAL(18,2) NOT NULL,
    ProductRetailProfit DECIMAL(18,2) NOT NULL, 
    ProductWholesaleUnitProfit DECIMAL(18,2) NOT NULL, 
    ProductProfitMarginUnitPercent DECIMAL(18,2) NOT NULL
	);
END
GO


--dim location, parent of dimStore, dimReseller, and dim Customer, and dimChannel
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimLocation')
BEGIN
	CREATE TABLE dbo.dimLocation
	(
	dimLocationID INT IDENTITY(1,1) CONSTRAINT PK_dimLocation PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
    Address VARCHAR(255) NOT NULL,
    City VARCHAR(255) NOT NULL,
	PostalCode VARCHAR(255) NOT NULL,
	StateProvince VARCHAR(255) NOT NULL, 
    Country VARCHAR(255) NOT NULL
	);
END
GO


--dim store
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimStore')
BEGIN
	CREATE TABLE dbo.dimStore
	(
	dimStoreID INT IDENTITY(1,1) CONSTRAINT PK_dimStore PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	dimLocationID INTEGER FOREIGN KEY REFERENCES dimLocation(dimLocationID) NOT NULL,
    SourceStoreID INT NOT NUll, --Natural Key
    StoreName VARCHAR(50) NOT NULL,
    StoreNumber INT NOT NULL,
	StoreManager VARCHAR(50)  
	);
END
GO


--dim channel
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimChannel')
BEGIN
	CREATE TABLE dbo.dimChannel
	(
	dimChannelID INT IDENTITY(1,1) CONSTRAINT PK_dimChannel PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	SourceChannelID INT NOT NUll, --Natural Key
	SourceCategoryID INT NOT NUll, --Natural Key
	ChannelCategoryName VARCHAR(50) NOT NULL,
	ChannelName VARCHAR(50) NOT NULL
	);
END
GO

--dim reseller
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimReseller')
BEGIN
	CREATE TABLE dbo.dimReseller
	(
	dimResellerID INT IDENTITY(1,1) CONSTRAINT PK_dimReseller PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	dimLocationID INTEGER FOREIGN KEY REFERENCES dimLocation(dimLocationID) NOT NULL,
    SourceResellerID NVARCHAR(255) NOT NUll, --Natural Key
    ResellerName VARCHAR(50) NOT NULL,
	ContactName VARCHAR(50) NOT NULL,
    PhoneNumber VARCHAR(50) NOT NULL,
    Email VARCHAR(50) NOT NULL
	);
END
GO

--dim customer
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimCustomer')
BEGIN
	CREATE TABLE dbo.dimCustomer
	(
	dimCustomerID INT IDENTITY(1,1) CONSTRAINT PK_dimCustomer PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	dimLocationID INTEGER FOREIGN KEY REFERENCES dimLocation(dimLocationID) NOT NULL,
    SourceCustomerID NVARCHAR(255) NOT NUll, --Natural Key
    CustomerFullName VARCHAR(50) NOT NULL,
    CustomerFirstName VARCHAR(50) NOT NULL,
    CustomerLastName VARCHAR(50) NOT NULL,
	CustomerGender VARCHAR(20) NOT NULL
	);
END
GO



-- ====================================
-- Create fact Tables
-- ====================================

--fact sales actual
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'factSalesActual')
BEGIN
	CREATE TABLE dbo.factSalesActual
	(
	factSalesActualID INT IDENTITY(1,1) CONSTRAINT PK_factSalesActual PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	dimProductID INTEGER FOREIGN KEY REFERENCES dimProduct(dimProductID) NOT NULL,
	dimStoreID INTEGER FOREIGN KEY REFERENCES dimStore(dimStoreID) NOT NULL,
	dimResellerID INTEGER FOREIGN KEY REFERENCES dimReseller(dimResellerID) NOT NULL,
	dimCustomerID INTEGER FOREIGN KEY REFERENCES dimCustomer(dimCustomerID) NOT NULL,
	dimChannelID INTEGER FOREIGN KEY REFERENCES dimChannel(dimChannelID) NOT NULL,
	dimSalesDateID INTEGER FOREIGN KEY REFERENCES dimDate(dimDateID) NOT NULL,
    dimLocationID INTEGER FOREIGN KEY REFERENCES dimLocation(dimLocationID) NOT NULL,
	SourceSalesHeaderID INT NOT NULL, 
    SourceSalesDetailID INT NOT NULL,
    SalesAmount DECIMAL(18,2) NOT NULL,
    SalesQuantity INT NOT NULL,
    SalesUnitPrice DECIMAL(18,2) NOT NULL,
    SalesExtendedCost DECIMAL(18,2) NOT NULL,
    SalesTotalProfit DECIMAL(18,2) NOT NULL
    );
END
GO

--create fact sales target
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'factSRCSalesTarget')
BEGIN
	CREATE TABLE dbo.factSRCSalesTarget
	(
	factSRCSalesTargetID INT IDENTITY(1,1) CONSTRAINT PK_factSRCSalesTarget PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	dimStoreID INTEGER FOREIGN KEY REFERENCES dimStore(dimStoreID) NOT NULL,
	dimResellerID INTEGER FOREIGN KEY REFERENCES dimReseller(dimResellerID) NOT NULL,
	dimChannelID INTEGER FOREIGN KEY REFERENCES dimChannel(dimChannelID) NOT NULL,
	dimTargetDateID INTEGER FOREIGN KEY REFERENCES dimDate(dimDateID) NOT NULL,
    SalesTargetAmountPerDay DECIMAL(18,2) NOT NULL
    );
END
GO

--create fact product target 
IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'factProductSalesTarget')
BEGIN
	CREATE TABLE dbo.factProductSalesTarget
	(
	factProductSalesTargetID INT IDENTITY(1,1) CONSTRAINT PK_factProductSalesTarget PRIMARY KEY CLUSTERED NOT NULL, --add index constraint on PK 
	dimProductID INTEGER FOREIGN KEY REFERENCES dimProduct(dimProductID) NOT NULL,
	dimTargetDateID INTEGER FOREIGN KEY REFERENCES dimDate(dimDateID) NOT NULL,
    ProductTargetSalesQuantityPerDay INT NOT NULL
    );
END
GO
© 2021 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
