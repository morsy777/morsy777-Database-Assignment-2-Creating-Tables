CREATE DATABASE BidNile;
GO

USE BidNile;

CREATE TABLE Country
(
    CountryId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    CountryCode CHAR(2) NOT NULL UNIQUE,

    CONSTRAINT CK_Country_CountryCode
        CHECK (CountryCode IN ('EG', 'SA', 'AE'))
);
GO

CREATE TABLE City
(
    CityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(60) NOT NULL,
    CountryId INT NOT NULL,

	CONSTRAINT FK_City_Country
		FOREIGN KEY(CountryId) REFERENCES Country(CountryId),

	CONSTRAINT UQ_City_Name_Country
		UNIQUE (Name, CountryId)
		
);
GO

CREATE TABLE Member
(
    MemberId UNIQUEIDENTIFIER PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email VARCHAR(254) NOT NULL UNIQUE,
    PhoneNo VARCHAR(16) NOT NULL,
    NationalIdOrPassport VARCHAR(20) NOT NULL UNIQUE,
    BirthDate DATE NOT NULL,
    IsVerified BIT NOT NULL DEFAULT 0,
    RegisteredAt DATETIME2(3) NOT NULL,
    CityId INT NOT NULL,
    InvitedByMemberId UNIQUEIDENTIFIER NULL,

    CONSTRAINT FK_Member_City
        FOREIGN KEY (CityId) REFERENCES City(CityId),

    CONSTRAINT FK_Member_InvitedBy
        FOREIGN KEY (InvitedByMemberId) REFERENCES Member(MemberId),

    CONSTRAINT CK_Member_NotSelfInvited
        CHECK (InvitedByMemberId IS NULL OR InvitedByMemberId <> MemberId)
);
GO

CREATE TABLE Wallet
(
    WalletId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId UNIQUEIDENTIFIER NOT NULL UNIQUE,
    Balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    AmountOnHold DECIMAL(12,2) NOT NULL DEFAULT 0,
    Currency CHAR(3) NOT NULL DEFAULT 'EGP',
    LastUpdatedAt DATETIME2(3) NOT NULL,

    CONSTRAINT FK_Wallet_Member
        FOREIGN KEY (MemberId) REFERENCES Member(MemberId),

    CONSTRAINT CK_Wallet_Balance
        CHECK (Balance >= 0),

    CONSTRAINT CK_Wallet_AmountOnHold
        CHECK (AmountOnHold >= 0 AND AmountOnHold <= Balance)
);
GO

-- I will use alter to add FK on ManagerEmployeeId, because it doesn't created yet
CREATE TABLE Warehouse
(
    WarehouseId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(80) NOT NULL UNIQUE,
    Capacity INT NOT NULL,
    CityId INT NOT NULL,
    Latitude DECIMAL(10,7) NOT NULL,
    Longitude DECIMAL(11,7) NOT NULL,
    ManagerEmployeeId INT NULL UNIQUE,
    ManageStartDate DATE NULL,

    CONSTRAINT FK_Warehouse_City
        FOREIGN KEY (CityId) REFERENCES City(CityId),

    CONSTRAINT CK_Warehouse_Capacity
        CHECK (Capacity > 0),

    CONSTRAINT CK_Warehouse_Latitude
        CHECK (Latitude BETWEEN -90 AND 90),

    CONSTRAINT CK_Warehouse_Longitude
        CHECK (Longitude BETWEEN -180 AND 180)
);
GO

CREATE TABLE Employee
(
    EmployeeId INT IDENTITY(1,1) PRIMARY KEY,
    MemberId UNIQUEIDENTIFIER NULL UNIQUE,
    WarehouseId INT NOT NULL,

    CONSTRAINT FK_Employee_Member
        FOREIGN KEY (MemberId) REFERENCES Member(MemberId),

    CONSTRAINT FK_Employee_Warehouse
        FOREIGN KEY (WarehouseId) REFERENCES Warehouse(WarehouseId),

    CONSTRAINT UQ_Employee_Id_Warehouse
        UNIQUE (EmployeeId, WarehouseId)
);
GO

ALTER TABLE Warehouse 
ADD CONSTRAINT FK_Warehouse_Manager
	FOREIGN KEY (ManagerEmployeeId) REFERENCES Employee(EmployeeId);
GO

CREATE TABLE Category
(
    CategoryCode INT PRIMARY KEY,
    EnglishName NVARCHAR(50) NOT NULL,
    ArabicName NVARCHAR(50) NULL,
    CommissionPercentage DECIMAL(4,2) NOT NULL,
    ParentCategoryCode INT NULL,

	CONSTRAINT UQ_Category_EnglishName 
		UNIQUE (EnglishName),

    CONSTRAINT FK_Category_Parent
        FOREIGN KEY (ParentCategoryCode) REFERENCES Category(CategoryCode),

    CONSTRAINT CK_Category_Commission
        CHECK (CommissionPercentage BETWEEN 0 AND 30),

    CONSTRAINT CK_Category_NotSelfParent
        CHECK (ParentCategoryCode IS NULL OR ParentCategoryCode <> CategoryCode)
);
GO

CREATE TABLE Item
(
    ItemId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ConditionScore TINYINT NOT NULL,
    Specifications NVARCHAR(MAX) NOT NULL,
    ListedAt DATETIME2(3) NOT NULL,

    SellerMemberId UNIQUEIDENTIFIER NOT NULL,
    InspectorEmployeeId INT NULL,
    CategoryCode INT NOT NULL,
    WarehouseId INT NULL,

    CONSTRAINT FK_Item_Seller
        FOREIGN KEY (SellerMemberId) REFERENCES Member(MemberId),

    CONSTRAINT FK_Item_Inspector
        FOREIGN KEY (InspectorEmployeeId) REFERENCES Employee(EmployeeId),

    CONSTRAINT FK_Item_Category
        FOREIGN KEY (CategoryCode) REFERENCES Category(CategoryCode),

    CONSTRAINT FK_Item_Warehouse
        FOREIGN KEY (WarehouseId) REFERENCES Warehouse(WarehouseId),

    CONSTRAINT CK_Item_ConditionScore
        CHECK (ConditionScore BETWEEN 1 AND 10),

    CONSTRAINT CK_Item_ValidJSON
        CHECK (ISJSON(Specifications) = 1)
);
GO

-- I intentionally used ON DELETE CASCADE because it's a week entity
CREATE TABLE ItemPhotos
(
    ItemId INT NOT NULL,
    Position TINYINT NOT NULL,
    URL VARCHAR(500) NOT NULL,
    IsMainPhoto BIT NOT NULL DEFAULT 0,

    CONSTRAINT PK_ItemPhotos
        PRIMARY KEY (ItemId, Position),

    CONSTRAINT FK_ItemPhotos_Item
        FOREIGN KEY (ItemId) REFERENCES Item(ItemId) ON DELETE CASCADE,

    CONSTRAINT CK_ItemPhotos_Position
        CHECK (Position BETWEEN 1 AND 20)
);
GO

CREATE TABLE Auction
(
    AuctionId INT IDENTITY(1,1) PRIMARY KEY,
    ItemId INT NOT NULL,
    StartingPrice DECIMAL(12,2) NOT NULL,
    ReservePrice DECIMAL(12,2) NULL,
    BidIncrement DECIMAL(12,2) NOT NULL DEFAULT 50.00,
    StartAt DATETIMEOFFSET(3) NOT NULL,
    EndAt DATETIMEOFFSET(3) NOT NULL,
    Status VARCHAR(10) NOT NULL DEFAULT 'Draft',

    CONSTRAINT FK_Auction_Item
        FOREIGN KEY (ItemId) REFERENCES Item(ItemId),

    CONSTRAINT CK_Auction_StartingPrice
        CHECK (StartingPrice > 0),

    CONSTRAINT CK_Auction_ReservePrice
        CHECK (ReservePrice IS NULL OR ReservePrice >= StartingPrice),

    CONSTRAINT CK_Auction_BidIncrement
        CHECK (BidIncrement > 0),

    CONSTRAINT CK_Auction_Dates
        CHECK (EndAt > StartAt),

    CONSTRAINT CK_Auction_Status
        CHECK (Status IN ('Draft', 'Live', 'Ended', 'Cancelled'))
);
GO

CREATE TABLE Bid
(
    BidId BIGINT IDENTITY(1,1) PRIMARY KEY,
    AuctionId INT NOT NULL,
    MemberId UNIQUEIDENTIFIER NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    PlacedAt DATETIME2(3) NOT NULL,
    IpAddress VARCHAR(45) NOT NULL,

    CONSTRAINT FK_Bid_Auction
        FOREIGN KEY (AuctionId) REFERENCES Auction(AuctionId),

    CONSTRAINT FK_Bid_Member
        FOREIGN KEY (MemberId) REFERENCES Member(MemberId),

    CONSTRAINT CK_Bid_Amount
        CHECK (Amount > 0),

    CONSTRAINT UQ_Bid_Auction_Amount
        UNIQUE (AuctionId, Amount)
);
GO

CREATE TABLE AuctionFollower
(
    MemberId UNIQUEIDENTIFIER NOT NULL,
    AuctionId INT NOT NULL,
    FollowedAt DATETIME2(3) NOT NULL,

    CONSTRAINT PK_AuctionFollower
        PRIMARY KEY (MemberId, AuctionId),

    CONSTRAINT FK_AuctionFollower_Member
        FOREIGN KEY (MemberId) REFERENCES Member(MemberId),

    CONSTRAINT FK_AuctionFollower_Auction
        FOREIGN KEY (AuctionId) REFERENCES Auction(AuctionId)
);
GO

-- I used composite FK, because the manager must be an employee in the same warehouse 
ALTER TABLE Warehouse
ADD CONSTRAINT FK_Warehouse_ManagerSameWarehouse
    FOREIGN KEY (ManagerEmployeeId, WarehouseId) REFERENCES Employee(EmployeeId, WarehouseId);
GO

-- 3.2
ALTER TABLE Member
ADD AppLanguage VARCHAR(2) NOT NULL
	CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar';
GO

-- 3.3
ALTER TABLE Item
ADD IsFeatured BIT NOT NULL
	CONSTRAINT DF_Item_IsFeatured DEFAULT 0;
GO

-- 3.4
EXEC sp_rename 
	'[dbo].Bid.IpAddress',
	'DeviceIp';
GO

ALTER TABLE Warehouse
DROP CONSTRAINT CK_Warehouse_Capacity;
GO

EXEC sp_rename 
	'[dbo].Warehouse.Capacity',
	'MaxItems';
GO

ALTER TABLE Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems 
CHECK (MaxItems > 0);
GO

-- 3.5
ALTER TABLE Member
ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

-- 3.6
ALTER TABLE Warehouse
DROP CONSTRAINT CK_Warehouse_MaxItems;
GO

ALTER TABLE Warehouse
ALTER COLUMN MaxItems SMALLINT NOT NULL;
GO

ALTER TABLE Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems
CHECK (MaxItems > 0);
GO

-- 3.7
ALTER TABLE Category
DROP CONSTRAINT CK_Category_Commission;
GO

ALTER TABLE Category
ADD CONSTRAINT CK_Category_Commission
CHECK (CommissionPercentage <= 25);
GO

-- 3.8
ALTER TABLE Auction
DROP CONSTRAINT DF__Auction__Status__70DDC3D8;
GO

ALTER TABLE Auction
DROP CONSTRAINT CK_Auction_Status;
GO

ALTER TABLE Auction
ALTER COLUMN Status VARCHAR(20) NOT NULL;
GO

ALTER TABLE Auction
ADD CONSTRAINT DF__Auction__Status 
DEFAULT ('PendingReview') FOR Status;
GO

ALTER TABLE Auction
ADD CONSTRAINT CK_Auction_Status 
CHECK (Status IN ('Draft', 'PendingReview', 'Live', 'Ended', 'Cancelled'));
GO

-- 3.9
ALTER TABLE Auction
ADD BuyNowPrice DECIMAL(12,2) NULL;
GO

-- I used with check to ensure the existng rows (old rows) satisfy the constraint.
ALTER TABLE Auction WITH CHECK
ADD CONSTRAINT CK_Auction_BuyNowPrice
CHECK (BuyNowPrice > StartingPrice);
GO

-- 3.10
ALTER TABLE Member
ADD CONSTRAINT UQ_Members_Mobile UNIQUE (PhoneNo);
GO

-- 3.11
ALTER TABLE Member
ADD VerifiedAt DATETIME2 NULL;
GO

ALTER TABLE Member
DROP CONSTRAINT DF__Member__IsVerifi__412EB0B6;
GO

ALTER TABLE Member
DROP COLUMN IsVerified;
GO

-- 3.12
CREATE SCHEMA Marketing;
GO

ALTER SCHEMA Marketing 
TRANSFER dbo.AuctionFollower;
GO

-- Task 1.3 Schemas
--	I expect that u will give us the schemas name like Marketing schema.
CREATE SCHEMA Core;
GO

ALTER SCHEMA Core 
TRANSFER dbo.Country;
GO
ALTER SCHEMA Core 
TRANSFER dbo.City;
GO
ALTER SCHEMA Core 
TRANSFER dbo.Member;
GO
ALTER SCHEMA Core 
TRANSFER dbo.Wallet;
GO


CREATE SCHEMA Operations;
GO

ALTER SCHEMA Operations 
TRANSFER dbo.Warehouse;
GO
ALTER SCHEMA Operations 
TRANSFER dbo.Employee;
GO
ALTER SCHEMA Operations 
TRANSFER dbo.Item;
GO
ALTER SCHEMA Operations 
TRANSFER dbo.ItemPhotos;
GO


CREATE SCHEMA Auctions;
GO

ALTER SCHEMA Auctions 
TRANSFER dbo.Category;
GO
ALTER SCHEMA Auctions 
TRANSFER dbo.Auction;
GO
ALTER SCHEMA Auctions 
TRANSFER dbo.Bid;
GO

-- Marketing schema already transferred in Task 3 (Marketing.AuctionFollower)