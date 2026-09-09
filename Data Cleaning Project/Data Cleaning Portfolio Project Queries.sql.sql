/*
============================================================
NASHVILLE HOUSING DATA CLEANING
============================================================

Skills Used:
- Data Cleaning
- Data Type Conversion
- String Functions
- Self Joins
- CASE Statements
- CTEs
- Window Functions
- Duplicate Removal
- ALTER TABLE / UPDATE

Database:
portfolio_project

Table:
NashvilleHousing
============================================================
*/


/*
============================================================
1. INITIAL DATA EXPLORATION
============================================================
*/

SELECT *
FROM portfolio_project..NashvilleHousing;


/*
============================================================
2. STANDARDIZE SALE DATE FORMAT
   Create a new column with the standardized DATE format.
============================================================
*/

-- Validate date conversion
SELECT
    SaleDate,
    CAST(SaleDate AS DATE) AS Sale_Date
FROM portfolio_project..NashvilleHousing;


-- Add standardized date column
ALTER TABLE portfolio_project..NashvilleHousing
ADD Sale_Date DATE;


-- Populate the new column
UPDATE portfolio_project..NashvilleHousing
SET Sale_Date = CAST(SaleDate AS DATE);


/*
============================================================
3. POPULATE MISSING PROPERTY ADDRESSES
   Use ParcelID to find matching property addresses
   from other records.
============================================================
*/

-- Identify records with missing PropertyAddress
SELECT
    A.ParcelID,
    A.PropertyAddress,
    B.ParcelID,
    B.PropertyAddress,
    ISNULL(A.PropertyAddress, B.PropertyAddress) AS Updated_Address
FROM portfolio_project..NashvilleHousing AS A
JOIN portfolio_project..NashvilleHousing AS B
    ON A.ParcelID = B.ParcelID
    AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL;


-- Populate missing PropertyAddress values
UPDATE A
SET A.PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM portfolio_project..NashvilleHousing AS A
JOIN portfolio_project..NashvilleHousing AS B
    ON A.ParcelID = B.ParcelID
    AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL;


/*
============================================================
4. SPLIT PROPERTY ADDRESS INTO SEPARATE COLUMNS
   Separate PropertyAddress into:
   - PropertySplitAddress
   - PropertySplitCity
============================================================
*/

-- Review PropertyAddress
SELECT
    PropertyAddress
FROM portfolio_project..NashvilleHousing;


-- Validate address splitting
SELECT
    LEFT(PropertyAddress, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(
        PropertyAddress,
        CHARINDEX(',', PropertyAddress) + 1,
        LEN(PropertyAddress)
    ) AS City
FROM portfolio_project..NashvilleHousing;


-- Add PropertySplitAddress column
ALTER TABLE portfolio_project..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);


-- Populate PropertySplitAddress
UPDATE portfolio_project..NashvilleHousing
SET PropertySplitAddress =
    SUBSTRING(
        PropertyAddress,
        1,
        CHARINDEX(',', PropertyAddress) - 1
    );


-- Add PropertySplitCity column
ALTER TABLE portfolio_project..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);


-- Populate PropertySplitCity
UPDATE portfolio_project..NashvilleHousing
SET PropertySplitCity =
    SUBSTRING(
        PropertyAddress,
        CHARINDEX(',', PropertyAddress) + 1,
        LEN(PropertyAddress)
    );


/*
============================================================
5. SPLIT OWNER ADDRESS INTO SEPARATE COLUMNS
   Separate OwnerAddress into:
   - OwnerSplitAddress
   - OwnerSplitCity
   - OwnerSplitState
============================================================
*/

-- Review OwnerAddress
SELECT
    OwnerAddress
FROM portfolio_project..NashvilleHousing;


-- Validate address splitting
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM portfolio_project..NashvilleHousing;


-- Add OwnerSplitAddress column
ALTER TABLE portfolio_project..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);


-- Populate OwnerSplitAddress
UPDATE portfolio_project..NashvilleHousing
SET OwnerSplitAddress =
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);


-- Add OwnerSplitCity column
ALTER TABLE portfolio_project..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);


-- Populate OwnerSplitCity
UPDATE portfolio_project..NashvilleHousing
SET OwnerSplitCity =
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);


-- Add OwnerSplitState column
ALTER TABLE portfolio_project..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);


-- Populate OwnerSplitState
UPDATE portfolio_project..NashvilleHousing
SET OwnerSplitState =
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


/*
============================================================
6. STANDARDIZE SOLD AS VACANT VALUES
   Convert:
   Y → Yes
   N → No
============================================================
*/

-- Check existing values
SELECT
    SoldAsVacant,
    COUNT(*) AS Record_Count
FROM portfolio_project..NashvilleHousing
GROUP BY SoldAsVacant;


-- Validate the transformation
SELECT
    SoldAsVacant,
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS Standardized_SoldAsVacant
FROM portfolio_project..NashvilleHousing;


-- Apply the transformation
UPDATE portfolio_project..NashvilleHousing
SET SoldAsVacant =
    CASE
        WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END;


/*
============================================================
7. IDENTIFY AND REMOVE DUPLICATE RECORDS
   Duplicates are identified using:
   - ParcelID
   - LandUse
   - PropertyAddress
   - SaleDate
   - SalePrice
   - LegalReference
============================================================
*/

WITH RowNumCTE AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY
                ParcelID,
                LandUse,
                PropertyAddress,
                SaleDate,
                SalePrice,
                LegalReference
            ORDER BY [UniqueID ]
        ) AS Row_Num

    FROM portfolio_project..NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE Row_Num > 1;


/*
============================================================
8. REVIEW DATA BEFORE REMOVING UNUSED COLUMNS
============================================================
*/

SELECT *
FROM portfolio_project..NashvilleHousing;


/*
============================================================
9. REMOVE UNUSED COLUMNS
============================================================
*/

ALTER TABLE portfolio_project..NashvilleHousing
DROP COLUMN
    PropertyAddress,
    SaleDate,
    OwnerAddress;
