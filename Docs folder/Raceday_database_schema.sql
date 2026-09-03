/* ============================================================================
   RaceDay - Database Schema
   ============================================================================ */

SET NOCOUNT ON;
GO

-- ----------------------------------------------------------------------------
-- 1. DATABASE CREATION
-- ----------------------------------------------------------------------------
IF DB_ID('RaceDay') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDay SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDay;
END
GO

CREATE DATABASE RaceDay;
GO

USE RaceDay;
GO

-- ----------------------------------------------------------------------------
-- 2. TABLE CREATION
-- ----------------------------------------------------------------------------

CREATE TABLE Organisers (
    OrganiserID     INT IDENTITY(1,1)      NOT NULL,
    FullName        NVARCHAR(100)          NOT NULL,
    Email           NVARCHAR(150)          NOT NULL,
    PasswordHash    NVARCHAR(255)          NOT NULL,
    CONSTRAINT PK_Organisers PRIMARY KEY CLUSTERED (OrganiserID)
);
GO

-- "User" per the team's ERD: the participant-facing account table, separate
-- from Organisers. Role is currently always 'Participant' (per team
-- decision - legacy/unused today, kept for future extensibility rather than
-- removed).
CREATE TABLE Users (
    UserId          INT IDENTITY(1,1)      NOT NULL,
    FullName        NVARCHAR(100)          NOT NULL,
    Email           NVARCHAR(150)          NOT NULL,
    PasswordHash    NVARCHAR(255)          NOT NULL,
    Role            NVARCHAR(20)           NOT NULL DEFAULT 'Participant',
    DateCreated     DATETIME2              NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId)
);
GO

CREATE TABLE Events (
    EventID         INT IDENTITY(1,1)      NOT NULL,
    OrganiserID     INT                    NOT NULL,
    EventName       NVARCHAR(150)          NOT NULL,
    Description     NVARCHAR(MAX)          NULL,
    EventDate       DATE                   NOT NULL,
    Location        NVARCHAR(200)          NOT NULL,
    Distance        DECIMAL(5,2)           NOT NULL,
    EventType       NVARCHAR(50)           NOT NULL,
    CONSTRAINT PK_Events PRIMARY KEY CLUSTERED (EventID),
    CONSTRAINT FK_Events_Organisers FOREIGN KEY (OrganiserID)
        REFERENCES Organisers (OrganiserID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CHK_Events_Distance CHECK (Distance > 0)
);
GO

CREATE TABLE Categories (
    CategoryID      INT IDENTITY(1,1)      NOT NULL,
    EventID         INT                    NOT NULL,
    CategoryName    NVARCHAR(100)          NOT NULL,
    CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryID),
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventID)
        REFERENCES Events (EventID)
        ON DELETE CASCADE ON UPDATE NO ACTION
);
GO

CREATE TABLE Enrolments (
    EnrolmentID     INT IDENTITY(1,1)      NOT NULL,
    UserId          INT                    NOT NULL,
    EventID         INT                    NOT NULL,
    CategoryID      INT                    NOT NULL,
    EnrolmentDate   DATETIME2              NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Enrolments PRIMARY KEY CLUSTERED (EnrolmentID),
    CONSTRAINT FK_Enrolments_Users FOREIGN KEY (UserId)
        REFERENCES Users (UserId)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    -- NO ACTION: see the cascade design note at the top of this script.
    CONSTRAINT FK_Enrolments_Events FOREIGN KEY (EventID)
        REFERENCES Events (EventID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (CategoryID)
        REFERENCES Categories (CategoryID)
        ON DELETE CASCADE ON UPDATE NO ACTION
);
GO

CREATE TABLE Results (
    ResultID                INT IDENTITY(1,1)  NOT NULL,
    EnrolmentID             INT                NOT NULL,
    FinishTime              TIME               NULL,
    [Position]              INT                NULL,
    CONSTRAINT PK_Results PRIMARY KEY CLUSTERED (ResultID),
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (EnrolmentID)
        REFERENCES Enrolments (EnrolmentID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT CHK_Results_Position CHECK ([Position] IS NULL OR [Position] > 0)
);
GO

-- ----------------------------------------------------------------------------
-- 3. INDEXES ON FOREIGN KEYS (SQL Server does not create these automatically)
-- ----------------------------------------------------------------------------
CREATE INDEX IX_Events_OrganiserID ON Events (OrganiserID);
CREATE INDEX IX_Categories_EventID ON Categories (EventID);
CREATE INDEX IX_Enrolments_UserId ON Enrolments (UserId);
CREATE INDEX IX_Enrolments_EventID ON Enrolments (EventID);
CREATE INDEX IX_Enrolments_CategoryID ON Enrolments (CategoryID);
CREATE INDEX IX_Results_EnrolmentID ON Results (EnrolmentID);
GO

-- ----------------------------------------------------------------------------
-- 4. SEED DATA
--    NOTE: PasswordHash values below are placeholder strings for demo seed
--    data only (not real bcrypt hashes). Part 2's /api/auth/register
--    endpoint will generate genuine salted hashes for real accounts.
-- ----------------------------------------------------------------------------

DECLARE @OrganiserID_Sipho INT, @OrganiserID_Amanda INT;
DECLARE @UserId_Thabo INT, @UserId_Lerato INT;
DECLARE @EventID_CTCT INT, @EventID_Soweto INT, @EventID_Durban INT;
DECLARE @CatID_CTCT_Half INT, @CatID_CTCT_Family INT;
DECLARE @CatID_Soweto_Full INT, @CatID_Soweto_Half INT, @CatID_Soweto_10k INT;
DECLARE @CatID_Durban_5k INT, @CatID_Durban_10k INT;
DECLARE @EnrolID_Lerato_Durban_5k INT, @EnrolID_Thabo_Durban_10k INT;

-- 4.1 Organisers (2 minimum)
INSERT INTO Organisers (FullName, Email, PasswordHash)
VALUES ('Sipho Ndlovu', 'sipho.ndlovu@raceday.co.za', '$2a$demo$hash_placeholder_01');
SET @OrganiserID_Sipho = SCOPE_IDENTITY();

INSERT INTO Organisers (FullName, Email, PasswordHash)
VALUES ('Amanda van der Merwe', 'amanda.vdm@raceday.co.za', '$2a$demo$hash_placeholder_02');
SET @OrganiserID_Amanda = SCOPE_IDENTITY();

-- 4.2 Users (2 minimum). Role defaults to 'Participant' - see the CREATE
-- TABLE comment above for why the column exists but only holds one value today.
INSERT INTO Users (FullName, Email, PasswordHash)
VALUES ('Thabo Mokoena', 'thabo.mokoena@example.com', '$2a$demo$hash_placeholder_03');
SET @UserId_Thabo = SCOPE_IDENTITY();

INSERT INTO Users (FullName, Email, PasswordHash)
VALUES ('Lerato Dlamini', 'lerato.dlamini@example.com', '$2a$demo$hash_placeholder_04');
SET @UserId_Lerato = SCOPE_IDENTITY();

-- 4.3 Events (3 minimum). Distance is the event's flagship/primary distance -
-- individual category names (e.g. "Half Marathon" vs "10km Fun Run") no
-- longer carry their own distance figure now that Distance lives on Event.
INSERT INTO Events (OrganiserID, EventName, Description, EventDate, Location, Distance, EventType)
VALUES (@OrganiserID_Sipho, 'Cape Town Cycle Tour Community Ride',
        'A scenic community cycling event around the Cape Peninsula, open to all skill levels.',
        '2026-11-08', 'Cape Town, Western Cape', 45.00, 'Cycling');
SET @EventID_CTCT = SCOPE_IDENTITY();

INSERT INTO Events (OrganiserID, EventName, Description, EventDate, Location, Distance, EventType)
VALUES (@OrganiserID_Amanda, 'Soweto Marathon',
        'An iconic road running event through the historic streets of Soweto.',
        '2026-11-15', 'Soweto, Johannesburg', 42.20, 'Running');
SET @EventID_Soweto = SCOPE_IDENTITY();

INSERT INTO Events (OrganiserID, EventName, Description, EventDate, Location, Distance, EventType)
VALUES (@OrganiserID_Sipho, 'Durban Beachfront Park Run Challenge',
        'A family-friendly timed run along the Durban beachfront promenade.',
        '2026-09-20', 'Durban, KwaZulu-Natal', 10.00, 'Running');
SET @EventID_Durban = SCOPE_IDENTITY();

-- 4.4 Categories (every event has at least one category)
INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_CTCT, 'Half Century Ride');
SET @CatID_CTCT_Half = SCOPE_IDENTITY();

INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_CTCT, 'Family Fun Ride');
SET @CatID_CTCT_Family = SCOPE_IDENTITY();

INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_Soweto, 'Full Marathon');
SET @CatID_Soweto_Full = SCOPE_IDENTITY();

INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_Soweto, 'Half Marathon');
SET @CatID_Soweto_Half = SCOPE_IDENTITY();

INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_Soweto, '10km Fun Run');
SET @CatID_Soweto_10k = SCOPE_IDENTITY();

INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_Durban, '5km Park Run');
SET @CatID_Durban_5k = SCOPE_IDENTITY();

INSERT INTO Categories (EventID, CategoryName) VALUES (@EventID_Durban, '10km Challenge');
SET @CatID_Durban_10k = SCOPE_IDENTITY();

-- 4.5 Sample Enrolments (EventID set from the same event each category belongs to)
INSERT INTO Enrolments (UserId, EventID, CategoryID)
VALUES (@UserId_Thabo, @EventID_CTCT, @CatID_CTCT_Half);

INSERT INTO Enrolments (UserId, EventID, CategoryID)
VALUES (@UserId_Thabo, @EventID_Soweto, @CatID_Soweto_Full);

INSERT INTO Enrolments (UserId, EventID, CategoryID)
VALUES (@UserId_Lerato, @EventID_CTCT, @CatID_CTCT_Family);

INSERT INTO Enrolments (UserId, EventID, CategoryID)
VALUES (@UserId_Lerato, @EventID_Durban, @CatID_Durban_5k);
SET @EnrolID_Lerato_Durban_5k = SCOPE_IDENTITY();

INSERT INTO Enrolments (UserId, EventID, CategoryID)
VALUES (@UserId_Thabo, @EventID_Durban, @CatID_Durban_10k);
SET @EnrolID_Thabo_Durban_10k = SCOPE_IDENTITY();

-- 4.6 Sample Results (for two enrolments already completed, to demonstrate the full model)
INSERT INTO Results (EnrolmentID, FinishTime, [Position])
VALUES (@EnrolID_Lerato_Durban_5k, '00:24:37', 3);

INSERT INTO Results (EnrolmentID, FinishTime, [Position])
VALUES (@EnrolID_Thabo_Durban_10k, '00:48:12', 7);
GO

-- ----------------------------------------------------------------------------
-- 5. VERIFICATION QUERY
--    Run this after the script completes to confirm every table was created
--    and seeded correctly. Expected: Organisers=2, Users=2, Events=3,
--    Categories=7, Enrolments=5, Results=2.
-- ----------------------------------------------------------------------------
SELECT 'Organisers'   AS TableName, COUNT(*) AS RowCount FROM Organisers
UNION ALL
SELECT 'Users',        COUNT(*) FROM Users
UNION ALL
SELECT 'Events',       COUNT(*) FROM Events
UNION ALL
SELECT 'Categories',   COUNT(*) FROM Categories
UNION ALL
SELECT 'Enrolments',   COUNT(*) FROM Enrolments
UNION ALL
SELECT 'Results',      COUNT(*) FROM Results;
GO



