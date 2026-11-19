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

