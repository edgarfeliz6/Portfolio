/*

Cleaning Data in SQL Queries

Data CSV File: NashvilleHousing.csv

*/

-- Taking a look at the data

SELECT *
FROM [Portfolio].[dbo].[NashvilleHousing]


-- Standardize Date Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM [Portfolio].[dbo].[NashvilleHousing]

UPDATE [Portfolio].[dbo].[NashvilleHousing]
SET SaleDate = CONVERT(Date,SaleDate)


-- Populate Property Address Data
-- After checking the data, discovered a few NULL PropertyAddress for the same ParcelID 

SELECT *
FROM [Portfolio].[dbo].[NashvilleHousing]
--WHERE PropertyAddress is null
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM [Portfolio].[dbo].[NashvilleHousing] a
JOIN [Portfolio].[dbo].[NashvilleHousing] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null



SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) AS AddressCheck
FROM [Portfolio].[dbo].[NashvilleHousing] a
JOIN [Portfolio].[dbo].[NashvilleHousing] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null



UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [Portfolio].[dbo].[NashvilleHousing] a
JOIN [Portfolio].[dbo].[NashvilleHousing] b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null



-- Breaking out Address into Individual Columns (Address, City, State) to make it more useful


SELECT PropertyAddress
FROM [Portfolio].[dbo].[NashvilleHousing]


SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM [Portfolio].[dbo].[NashvilleHousing]



ALTER TABLE [Portfolio].[dbo].[NashvilleHousing]
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE [Portfolio].[dbo].[NashvilleHousing]
ADD PropertySplitCity NVARCHAR(255);


UPDATE [Portfolio].[dbo].[NashvilleHousing]
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

Update [Portfolio].[dbo].[NashvilleHousing]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




SELECT OwnerAddress
FROM [Portfolio].[dbo].[NashvilleHousing]


SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) AS OwnerSplitAddress
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) AS OwnerSplitCity
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) AS OwnerSplitState
FROM [Portfolio].[dbo].[NashvilleHousing]



ALTER TABLE [Portfolio].[dbo].[NashvilleHousing]
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE [Portfolio].[dbo].[NashvilleHousing]
ADD OwnerSplitCity NVARCHAR(255);

ALTER TABLE [Portfolio].[dbo].[NashvilleHousing]
ADD OwnerSplitState NVARCHAR(255);


UPDATE [Portfolio].[dbo].[NashvilleHousing]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

UPDATE [Portfolio].[dbo].[NashvilleHousing]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

UPDATE [Portfolio].[dbo].[NashvilleHousing]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)




-- Change Y and N to Yes and No in "Sold as Vacant" field
-- Some rows had Y or N instead of Yes or No


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Counter
FROM [Portfolio].[dbo].[NashvilleHousing]
GROUP BY SoldAsVacant
ORDER BY 2



SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END 
AS Conversion
FROM [Portfolio].[dbo].[NashvilleHousing]


UPDATE [Portfolio].[dbo].[NashvilleHousing]
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END



-- Remove Duplicates
-- Found 104 duplicates with the key created


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM [Portfolio].[dbo].[NashvilleHousing]

)
--SELECT *
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress



-- Delete Unused Columns
-- Columns that were changed and one that was never used


ALTER TABLE [Portfolio].[dbo].[NashvilleHousing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress



-- Checking data final time after transformations

SELECT *
FROM [Portfolio].[dbo].[NashvilleHousing]