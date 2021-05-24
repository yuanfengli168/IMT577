
-- ====================================
-- Author: Yuanfeng Li
-- Date: 5/24/2021


-- Load fact Tables
-- ====================================



--insert sales fact actual---
DBCC CHECKIDENT ('dbo.factSalesActual', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'factSalesActual')
BEGIN

INSERT INTO dbo.factSalesActual
(
	dimProductID,
	dimStoreID,
	dimResellerID,
	dimCustomerID,
	dimChannelID,
	dimSalesDateID,
  dimLocationID,
	SourceSalesHeaderID,
  SourceSalesDetailID,
  SalesAmount,
  SalesQuantity,
  SalesUnitPrice,
  SalesExtendedCost,
  SalesTotalProfit
)
  SELECT 
	DP.dimProductID,
	CASE WHEN SH.StoreID IS NULL THEN -1 ELSE DST.dimStoreID END AS dimStoreID,
	CASE WHEN SH.ResellerID IS NULL THEN -1 ELSE DR.dimResellerID END AS dimResellerID,
	CASE WHEN SH.CustomerID IS NULL THEN -1 ELSE DCU.dimCustomerID END AS dimCustomerID,
	DC.dimChannelID,
	DD.dimDateID AS dimSalesDateID,
	CASE
		WHEN SH.StoreID IS NOT NULL THEN DST.dimLocationID 
		WHEN SH.ResellerID IS NOT NULL THEN DR.dimLocationID
		WHEN SH.CustomerID IS NOT NULL THEN DCU.dimLocationID
	END AS dimLocationID,
	SH.SalesHeaderID AS SourceSalesHeaderID,
	SD.SalesDetailID AS SourceSalesDetailID,
	SD.SalesAmount,
	SD.SalesQuantity,
	CASE WHEN SH.ResellerID IS NULL THEN DP.ProductRetailPrice ELSE DP.ProductWholesalePrice END AS SalesUnitPrice,
	(DP.ProductCost*SD.SalesQuantity) AS SalesExtendedCost,
	(SD.SalesAmount - (DP.ProductCost*SD.SalesQuantity)) AS SalesTotalProfit
	
  FROM StageSalesHeader SH
  LEFT JOIN StageSalesDetail SD ON SH.SalesHeaderID = SD.SalesHeaderID
  LEFT JOIN dimProduct DP ON DP.SourceProductID = SD.ProductID
  LEFT JOIN dimChannel DC ON DC.SourceChannelID = SH.ChannelID
  LEFT JOIN dimCustomer DCU ON SH.CustomerID = DCU.SourceCustomerID
  LEFT JOIN dimReseller DR ON SH.ResellerID =  DR.SourceResellerID
  LEFT JOIN dimStore DST ON SH.StoreID = DST.SourceStoreID
  LEFT JOIN dimDate DD ON DD.FullDate = SH.Date;
  END 
  GO
  
---------- insert product target fact ---------------------
DBCC CHECKIDENT ('dbo.factProductSalesTarget', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'factProductSalesTarget')
BEGIN

INSERT INTO dbo.factProductSalesTarget
(
  dimProductID,
	dimTargetDateID,
  ProductTargetSalesQuantityPerDay
)

  SELECT DP.dimProductID, DD.dimDateID AS dimTargetDateID, 
  (SPT.[ SalesQuantityTarget ]/365) AS ProductTargetSalesQuantityPerDay

  FROM StageProductTarget SPT
  LEFT JOIN dimProduct DP ON DP.SourceProductID = SPT.ProductID
  LEFT JOIN dimDate DD ON DD.CalendarYear = SPT.Year;
  END
  GO


  ---------insert fact target using fuzzy matching-----------
 --1.function fuzzy matching
 /* code reference: 
 code reference: https://www.kodyaz.com/articles/fuzzy-string-matching-using-levenshtein-distance-sql-server.aspx
Get helped from TA and Others
*/ 

IF EXISTS (SELECT * FROM dbo.sysobjects
           WHERE ID = object_id(N'dbo.edit_distance') AND
                 XTYPE IN (N'FN', N'IF', N'TF'))
    DROP FUNCTION dbo.edit_distance
GO


CREATE FUNCTION edit_distance(@s1 nvarchar(3999), @s2 nvarchar(3999))
RETURNS int
AS
BEGIN
 DECLARE @s1_len int, @s2_len int
 DECLARE @i int, @j int, @s1_char nchar, @c int, @c_temp int
 DECLARE @cv0 varbinary(8000), @cv1 varbinary(8000)

 SELECT
  @s1_len = LEN(@s1),
  @s2_len = LEN(@s2),
  @cv1 = 0x0000,
  @j = 1, @i = 1, @c = 0

 WHILE @j <= @s2_len
  SELECT @cv1 = @cv1 + CAST(@j AS binary(2)), @j = @j + 1

 WHILE @i <= @s1_len
 BEGIN
  SELECT
   @s1_char = SUBSTRING(@s1, @i, 1),
   @c = @i,
   @cv0 = CAST(@i AS binary(2)),
   @j = 1

  WHILE @j <= @s2_len
  BEGIN
   SET @c = @c + 1
   SET @c_temp = CAST(SUBSTRING(@cv1, @j+@j-1, 2) AS int) +
    CASE WHEN @s1_char = SUBSTRING(@s2, @j, 1) THEN 0 ELSE 1 END
   IF @c > @c_temp SET @c = @c_temp
   SET @c_temp = CAST(SUBSTRING(@cv1, @j+@j+1, 2) AS int)+1
   IF @c > @c_temp SET @c = @c_temp
   SELECT @cv0 = @cv0 + CAST(@c AS binary(2)), @j = @j + 1
 END

 SELECT @cv1 = @cv0, @i = @i + 1
 END

 RETURN @c
END

----2.insert 
DBCC CHECKIDENT ('dbo.factSRCSalesTarget', RESEED, 0);
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'factSRCSalesTarget')
BEGIN

INSERT INTO dbo.factSRCSalesTarget
(
	dimStoreID,
	dimResellerID,
	dimChannelID,
	dimTargetDateID,
  	SalesTargetAmountPerDay
)

 SELECT 
  CASE WHEN DS.StoreName IS NULL THEN -1 ELSE DS.dimStoreID END AS dimStoreID, 
  CASE WHEN DR.ResellerName IS NULL THEN -1 ELSE DR.dimResellerID END AS dimResellerID,
 DC.dimChannelID, DD.dimDateID AS dimTargetDateID,
  (SRC.[ TargetSalesAmount ]/365) AS SalesTargetAmountPerDay
FROM StageSRCSalesTarget SRC
LEFT JOIN dimChannel DC ON dbo.edit_distance(DC.ChannelName, SRC.ChannelName) <= 2
LEFT JOIN dimReseller DR ON dbo.edit_distance(DR.ResellerName, SRC.TargetName) <= 2
LEFT JOIN dimStore DS ON DS.StoreName = SRC.TargetName
LEFT JOIN dimDate DD ON DD.CalendarYear = SRC.Year;
END
GO