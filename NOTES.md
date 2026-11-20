### 1- Your 4 schemas, their tables, and why?
- Core: Manage the member and their personal info, counteries, locations(cities), and wallets.
- Operations: Manage warehouse, employees, items and photos.
- Auctions: Manage products, categories, auctions and bids.
- Marketing: Manages members who follow auctions to track their interests.

- Why this separation?
- To achieve SOP(Separation of Concerns) , improve database organization, and allow us to assign different security privileges at each schema.


### 2- For each relationship type (1:1, 1:N, M:N, recursive, circular, weak entity): where it is in BidNile and how you mapped it.
- 1:1: Member & Wallet, Mapped using a UNIQUE FK in Wallet.

- 1:N: Country & City, Mapped using CountryId as an FK in City.

- M:N: Member & Auction, Mapped using AuctionFollower as a junction table with a composite PK.

- Recursive: Member invites Member, Mapped using a self reference FK InvitedByMemberId.

- Circular: Warehouse & Employee, Mapped using FKs in both tables and a composite FK to ensure the manager works at the same warehouse.

- Weak Entity: Item & ItemPhotos, Mapped using a composite PK ItemId and Position.

### 3- Why GUID for members and BIGINT for bids? Why FLOAT for GPS but DECIMAL for money? Why DATETIMEOFFSET for auctions?
- GUID: To give each member a unique Id, even across different databases.

- BIGINT: Because the system may have millions of bids, and BIGINT can store very large numbers.

- FLOAT: Because GPS coordinates contain decimal values, and small precision differences are acceptable. However, we used decimal in BidNile for better precision.

- DECIMAL: Because money needs exact values, and FLOAT may cause rounding errors.

- DATETIMEOFFSET: Because users can join auctions from different countries with different time zones.

### 4- Why can't the circular relationship be created inside CREATE TABLE?
- Because both tables reference each other using Foreign Keys. When creating the first table, the second table does not exist yet, so we create the first table then use ALTER TABLE to add the FK.

### 5- The order you filled the tables in, and why?
- I got a permission from Eng. Abdulrahman to skip filling the tables using edit top 200 rows, because I had llimited time.

- However, if I had to fill the tables, I would start with the tables that do not have any FKs, then move to the tables that have FKs, and finally fill the junction tables.

- Country, City, Member, Wallet, Warehouse, Employee, Category, Item, ItemPhotos, Auction, Bid and then AuctionFollower.

### 6- The errors in 3.6 and 3.11, and how you fixed them.?
- Both errors happened because the columns had dependent constraints. I fixed them by dropping the CHECK constraint in 3.6 and the DEFAULT constraint in 3.11.

### 7. The Hand Trace from Task 5

I explained the hand trace in detail in Notion and exported it as a PDF so you can read it easily. The explanation is written in Egyptian Arabic to make it easier to understand. It was a great problem to solve!

**File Path:** `dsa/Explain_PS_238_product_of_array_except_self.pdf`
