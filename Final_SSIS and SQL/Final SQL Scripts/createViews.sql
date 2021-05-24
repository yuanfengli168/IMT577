-- ====================================
-- Author: Yuanfeng Li
-- Date: 5/24/2021


-- create Views of all Dimension and fact Tables. 
-- ====================================



USE [DestinationSystem]
GO

/****** Object:  View [dbo].[vdimChannel]    Script Date: 5/24/2021 1:49:49 PM ******/
DROP VIEW [dbo].[vdimChannel]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimChannel]
AS
SELECT  dimChannelID, SourceChannelID, SourceCategoryID, ChannelCategoryName, ChannelName
FROM    dbo.dimChannel
GO

USE [DestinationSystem]
GO


/****** Object:  View [dbo].[vdimCustomer]    Script Date: 5/24/2021 1:57:21 PM ******/
DROP VIEW [dbo].[vdimCustomer]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimCustomer]
AS
SELECT  dimCustomerID, dimLocationID, SourceCustomerID, CustomerFullName, CustomerFirstName, CustomerLastName, CustomerGender
FROM    dbo.dimCustomer
GO

USE [DestinationSystem]
GO

/****** Object:  View [dbo].[vdimDate]    Script Date: 5/24/2021 1:57:56 PM ******/
DROP VIEW [dbo].[vdimDate]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimDate]
AS
SELECT  dimDateID, FullDate, DayNumberOfWeek, DayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekdayFlag, WeekNumberOfYear, MonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear, CalendarSemester, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy
FROM    dbo.dimDate
GO

USE [DestinationSystem]
GO

/****** Object:  View [dbo].[vdimLocation]    Script Date: 5/24/2021 1:59:03 PM ******/
DROP VIEW [dbo].[vdimLocation]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimLocation]
AS
SELECT  dimLocationID, Address, City, PostalCode, StateProvince, Country
FROM    dbo.dimLocation
GO


/****** Object:  View [dbo].[vdimProduct]    Script Date: 5/24/2021 1:59:30 PM ******/
DROP VIEW [dbo].[vdimProduct]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimProduct]
AS
SELECT  dimProductID AS Expr1, SourceProductID AS Expr2, SourceProductTypeID, SourceProductCategoryID, ProductName, ProductType, ProductCategoryName, ProductRetailPrice, ProductWholesalePrice, ProductCost, ProductRetailProfit, ProductWholesaleUnitProfit, ProductProfitMarginUnitPercent
FROM    dbo.dimProduct
GO



/****** Object:  View [dbo].[vdimReseller]    Script Date: 5/24/2021 2:00:21 PM ******/
DROP VIEW [dbo].[vdimReseller]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimReseller]
AS
SELECT  dimResellerID, dimLocationID, SourceResellerID, ResellerName, ContactName, PhoneNumber, Email
FROM    dbo.dimReseller
GO

/****** Object:  View [dbo].[vdimStore]    Script Date: 5/24/2021 2:00:50 PM ******/
DROP VIEW [dbo].[vdimStore]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vdimStore]
AS
SELECT  dimStoreID, dimLocationID, SourceStoreID, StoreName, StoreNumber, StoreManager
FROM    dbo.dimStore
GO


/****** Object:  View [dbo].[vfactProductSalesTarget]    Script Date: 5/24/2021 2:01:19 PM ******/
DROP VIEW [dbo].[vfactProductSalesTarget]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vfactProductSalesTarget]
AS
SELECT  factProductSalesTargetID, dimProductID, dimTargetDateID, ProductTargetSalesQuantityPerDay
FROM    dbo.factProductSalesTarget
GO


/****** Object:  View [dbo].[vfactSalesActual]    Script Date: 5/24/2021 2:01:46 PM ******/
DROP VIEW [dbo].[vfactSalesActual]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vfactSalesActual]
AS
SELECT  factSalesActualID, dimProductID, dimStoreID, dimResellerID, dimCustomerID, dimChannelID, dimSalesDateID, dimLocationID, SourceSalesHeaderID, SourceSalesDetailID, SalesAmount, SalesQuantity, SalesUnitPrice, SalesExtendedCost, SalesTotalProfit
FROM    dbo.factSalesActual
GO

/****** Object:  View [dbo].[vfactSRCSalesTarget]    Script Date: 5/24/2021 2:02:13 PM ******/
DROP VIEW [dbo].[vfactSRCSalesTarget]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vfactSRCSalesTarget]
AS
SELECT  factSRCSalesTargetID, dimStoreID, dimResellerID, dimChannelID, dimTargetDateID, SalesTargetAmountPerDay
FROM    dbo.factSRCSalesTarget
GO
