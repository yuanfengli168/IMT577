
-- ====================================
-- Author: Yuanfeng Li
-- Date: 5/24/2021


-- Load dimension Tables
-- ====================================

-------------------insert date for 2013 and 2014----------------------------
---- this code was copied from professor Sean's codes.
IF EXISTS (SELECT name FROM sys.procedures WHERE name = 'InsDimDateYearly')
BEGIN
	DROP PROCEDURE dbo.InsDimDateYearly;
END
GO

CREATE PROC [dbo].[InsDimDateYearly]
( 
	@Year INT=NULL
)
AS
SET NOCOUNT ON;

DECLARE @Date DATE, @FirstDate Date, @LastDate Date;

SELECT @Year=COALESCE(@Year,YEAR(DATEADD(d,1,MAX(DimDateID)))) FROM dbo.dimDate;

SET @FirstDate=DATEFROMPARTS(COALESCE(@Year,YEAR(GETDATE())-1), 01, 01); -- First Day of the Year
SET @LastDate=DATEFROMPARTS(COALESCE(@Year,YEAR(GETDATE())-1), 12, 31); -- Last Day of the Year

SET @Date=@FirstDate;
-- create CTE with all dates needed for load
;WITH DateCTE AS
(
SELECT @FirstDate AS StartDate -- earliest date to load in table
UNION ALL
SELECT DATEADD(day, 1, StartDate)
FROM DateCTE -- recursively select the date + 1 over and over
WHERE DATEADD(day, 1, StartDate) <= @LastDate -- last date to load in table
)

-- load date dimension table with all dates
INSERT INTO dbo.dimDate 
	(
	FullDate 
	,DayNumberOfWeek 
	,DayNameOfWeek 
	,DayNumberOfMonth 
	,DayNumberOfYear 
	,WeekdayFlag
	,WeekNumberOfYear 
	,[MonthName] 
	,MonthNumberOfYear 
	,CalendarQuarter 
	,CalendarYear 
	,CalendarSemester
	,CreatedDate
	,CreatedBy
	,ModifiedDate
	,ModifiedBy 
	)
SELECT 
	 CAST(StartDate AS DATE) AS FullDate
	,DATEPART(dw, StartDate) AS DayNumberOfWeek
	,DATENAME(dw, StartDate) AS DayNameOfWeek
	,DAY(StartDate) AS DayNumberOfMonth
	,DATEPART(dy, StartDate) AS DayNumberOfYear
	,CASE DATENAME(dw, StartDate) WHEN 'Saturday' THEN 0 WHEN 'Sunday' THEN 0 ELSE 1 END AS WeekdayFlag
	,DATEPART(wk, StartDate) AS WeekNumberOfYear
	,DATENAME(mm, StartDate) AS [MonthName]
	,MONTH(StartDate) AS MonthNumberOfYear
	,DATEPART(qq, StartDate) AS CalendarQuarter
	,YEAR(StartDate) AS CalendarYear
	,(CASE WHEN MONTH(StartDate)>=1 AND MONTH(StartDate) <=6 THEN 1 ELSE 2 END) AS CalendarSemester
	,DATEADD(dd,DATEDIFF(dd,GETDATE(), '2013-01-01'),GETDATE()) AS CreatedDate
	,'company\SQLServerServiceAccount' AS CreatedBy
	,NULL AS ModifiedDate
	,NULL AS ModifiedBy
FROM DateCTE
OPTION (MAXRECURSION 0);-- prevents infinate loop from running more than once
GO

-- ========================================================================
-- Execute the procedure for 2013 and 2014 (those are the years you need)
-- ========================================================================
EXEC InsDimDateYearly 2013;

EXEC InsDimDateYearly 2014;


SET IDENTITY_INSERT dbo.dimDate ON;


-- insert Unknown values
INSERT INTO dbo.dimDate
(
	dimDateID
    ,FullDate 
	,DayNumberOfWeek 
	,DayNameOfWeek 
	,DayNumberOfMonth 
	,DayNumberOfYear 
	,WeekdayFlag
	,WeekNumberOfYear 
	,[MonthName] 
	,MonthNumberOfYear 
	,CalendarQuarter 
	,CalendarYear 
	,CalendarSemester
	,CreatedDate
	,CreatedBy

)
VALUES
( 
	-1
    ,CAST(DATEADD(dd,DATEDIFF(dd,GETDATE(), '1900-01-01'),GETDATE()) AS DATE)
	,0
	,'Unknown'
	,0
	,0
	,0
	,0
	,'Unknown'
	,0
	,0
	,0
	,0
	,DATEADD(dd,DATEDIFF(dd,GETDATE(), '1900-01-01'),GETDATE())
	,'Unknown'

);
-- Turn the identity insert to OFF so new rows auto assign identities
SET IDENTITY_INSERT dbo.dimDate OFF;
GO




------------------------- insert dim product-------------------------------
DBCC CHECKIDENT ('dbo.dimProduct', RESEED, 0);
GO

--1. load data
IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimProduct')
BEGIN
INSERT INTO dbo.dimProduct
(
	SourceProductID,
	SourceProductTypeID,
    SourceProductCategoryID,
    ProductName,
    ProductType,
	ProductCategoryName,
	ProductRetailPrice,
    ProductWholesalePrice,
    ProductCost,
    ProductRetailProfit,
    ProductWholesaleUnitProfit,
    ProductProfitMarginUnitPercent
)
SELECT 
P.ProductID AS SourceProductID,
PT.ProductTypeID AS SourceProductTypeID,
PC.ProductCategoryID AS SourceProductCategoryID,
P.Product AS ProductName,
PT.ProductType AS ProductType,
PC.ProductCategory AS ProductCategoryName,
P.Price AS ProductRetailPrice, 
P.WholesalePrice AS ProductWholesalePrice,
P.Cost AS ProductCost,
(P.Price - P.Cost) AS ProductRetailProfit,
(P.WholesalePrice - P.Cost) AS ProductWholesaleUnitProfit,
100*(P.Price - P.Cost)/P.Price AS ProductProfitMarginUnitPercent

FROM dbo.StageProduct P
INNER JOIN dbo.StageProductType PT 
ON P.ProductTypeID = PT.ProductTypeID
INNER JOIN dbo.StageProductCategory PC
ON PT.ProductCategoryID = PC.ProductCategoryID;
END
GO

--2 insert Unknown values
SET IDENTITY_INSERT dbo.dimProduct ON;

INSERT INTO dbo.dimProduct
(
	dimProductID,
    SourceProductID,
	SourceProductTypeID,
    SourceProductCategoryID,
    ProductName,
    ProductType,
	ProductCategoryName,
    ProductRetailPrice,
    ProductWholesalePrice,
    ProductCost,
    ProductRetailProfit,
    ProductWholesaleUnitProfit,
    ProductProfitMarginUnitPercent
)
VALUES
( 
-1,
-1,
-1,
-1,
'Unknown',
'Unknown',
'Unknown',
0,
0,
0,
0,
0,
0
);
SET IDENTITY_INSERT dbo.dimProduct OFF;
GO



-------------------insert dim location-----------------------------
DBCC CHECKIDENT ('dbo.dimLocation', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimLocation')
BEGIN

INSERT INTO dbo.dimLocation
(
    Address,
    City,
	PostalCode,
	StateProvince, 
    Country
)
SELECT 
    Address, 
    City, 
    PostalCode, 
    StateProvince,
    Country
FROM dbo.StageReseller 
UNION
SELECT 
    Address, 
    City, 
    PostalCode, 
    StateProvince,
    Country
FROM dbo.StageCustomer
UNION
SELECT 
    Address, 
    City, 
    PostalCode, 
    StateProvince,
    Country
FROM dbo.StageStore;
END
GO

--2 insert Unknown values
SET IDENTITY_INSERT dbo.dimLocation ON;

INSERT INTO dbo.dimLocation
(
    dimLocationID,
    Address, 
    City, 
    PostalCode, 
    StateProvince,
    Country
)
VALUES
( 
-1,
'Unknown',
'Unknown',
'Unknown',
'Unknown',
'Unknown'
);
-- Turn the identity insert to OFF so new rows auto assign identities
SET IDENTITY_INSERT dbo.dimLocation OFF;
GO


-------------------------insert dim store------------------------------
DBCC CHECKIDENT ('dbo.dimStore', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimStore')
BEGIN

INSERT INTO dbo.dimStore
(
	dimLocationID,
    SourceStoreID,
    StoreName,  
    StoreNumber,
	StoreManager
)
SELECT 
dimLocationID, 
StoreID, 
CONCAT('Store Number ', S.StoreNumber) AS StoreNanme,
StoreNumber, 
StoreManager

FROM dbo.StageStore S
INNER JOIN dbo.dimLocation L
ON S.Address = L.Address 
AND S.PostalCode = L.PostalCode;
END
GO

-- 2 insert Unknown values
SET IDENTITY_INSERT dbo.dimStore ON;

INSERT INTO dbo.dimStore
(
	dimStoreID,
    dimLocationID,
    SourceStoreID,
    StoreName,  
    StoreNumber,
	StoreManager
)
VALUES
( 
-1,
-1,
-1,
'Unknown',
-1,
'Unknown'
);
-- Turn the identity insert to OFF so new rows auto assign identities
SET IDENTITY_INSERT dbo.dimStore OFF;
GO

-----------------insert dim reseller ------------------------
DBCC CHECKIDENT ('dbo.dimReseller', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimReseller')
BEGIN

INSERT INTO dbo.dimReseller
(
	dimLocationID,
    SourceResellerID,
    ResellerName,
	ContactName,
    PhoneNumber,
    Email 
)
SELECT 
dimLocationID, 
CAST(S.ResellerID AS VARCHAR(500)) AS SourceResellerID, 
ResellerName,
Contact, 
PhoneNumber,
EmailAddress

FROM dbo.StageReseller S
INNER JOIN dbo.dimLocation L
ON S.Address = L.Address 
AND S.PostalCode = L.PostalCode;
END
GO


-- 2 insert Unknown values
SET IDENTITY_INSERT dbo.dimReseller ON;

INSERT INTO dbo.dimReseller
(
	dimResellerID,
    dimLocationID,
    SourceResellerID,
    ResellerName,
	ContactName,
    PhoneNumber, 
    Email
)
VALUES
( 
-1,
-1,
'00000000-0000-0000-0000-000000000000',
'Unknown',
'Unknown',
'Unknown',
'Unknown'
);
-- Turn the identity insert to OFF so new rows auto assign identities
SET IDENTITY_INSERT dbo.dimReseller OFF;
GO

------------------------------insert dim customer -----------------------
DBCC CHECKIDENT ('dbo.dimCustomer', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimCustomer')
BEGIN

INSERT INTO dbo.dimCustomer
(
	dimLocationID,
    SourceCustomerID,
    CustomerFullName,
    CustomerFirstName,
    CustomerLastName,
	CustomerGender
)
SELECT 
	dimLocationID,
    CustomerID,
    CONCAT(FirstName,LastName) AS CustomerFullName,
    FirstName,
    LastName,
	Gender

FROM dbo.StageCustomer S
INNER JOIN dbo.dimLocation L
ON S.Address = L.Address 
AND S.PostalCode = L.PostalCode;
END 
GO

-- 2 insert Unknown values
SET IDENTITY_INSERT dbo.dimCustomer ON;

INSERT INTO dbo.dimCustomer
(
	dimCustomerID,
    dimLocationID,
    SourceCustomerID,
    CustomerFullName,
    CustomerFirstName,
    CustomerLastName,
	CustomerGender
)
VALUES
( 
-1,
-1,
'00000000-0000-0000-0000-000000000000',
'Unknown',
'Unknown',
'Unknown',
'Unknown'
);
-- Turn the identity insert to OFF so new rows auto assign identities
SET IDENTITY_INSERT dbo.dimCustomer OFF;
GO


-------------------insert dim channel-----------------------
DBCC CHECKIDENT ('dbo.dimChannel', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'dimChannel')
BEGIN
	INSERT INTO dbo.dimChannel
	(
	SourceChannelID
	,SourceCategoryID
	,ChannelCategoryName
	,ChannelName
	)
	SELECT 
	dbo.StageChannel.ChannelID AS dimSourceChannelID
	,dbo.StageChannel.ChannelCategoryID AS dimSourceChannelCategory
	,dbo.StageChannelCategory.ChannelCategory AS dimCategoryName
	,dbo.StageChannel.Channel AS dimChannelName

	FROM StageChannel
	INNER JOIN StageChannelCategory
	ON StageChannel.ChannelCategoryID = StageChannelCategory.ChannelCategoryID;
END
GO

SET IDENTITY_INSERT dbo.dimChannel ON;

-- 2 insert Unknown values
INSERT INTO dbo.dimChannel
(
dimChannelID
,SourceChannelID
,SourceCategoryID
,ChannelCategoryName
,ChannelName
)
VALUES
( 
-1
,-1
,-1 
,'Unknown'
,'Unknown'
);
-- Turn the identity insert to OFF so new rows auto assign identities
SET IDENTITY_INSERT dbo.dimChannel OFF;
GO

