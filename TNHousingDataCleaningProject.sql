/*
Cleaning Data in SQL Queries
*/


Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select saleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select [ParcelID], [PropertyAddress]
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv
--Where PropertyAddress is null
order by ParcelID


--Self join to identify where a knowns address might be missing in another column. Same ParcelID (same property) <> UniqueID (different sale)
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv as a
JOIN NashvilleHousingProject..NashvilleHousingDataCleaningCsv as b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv as a
JOIN NashvilleHousingProject..NashvilleHousingDataCleaningCsv as b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv
--Where PropertyAddress is null
--order by ParcelID


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address--3 expression of the SUBSTRING Function
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv


ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousingProject..NashvilleHousingDataCleaningCsv
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousingProject..NashvilleHousingDataCleaningCsv
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select *
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv





Select OwnerAddress
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv

--Parsename return info delimited by dots up to 4 pieces.
select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv



ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousingProject..NashvilleHousingDataCleaningCsv
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousingProject..NashvilleHousingDataCleaningCsv
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousingProject..NashvilleHousingDataCleaningCsv
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv
Group by SoldAsVacant
order by 2

ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
ALTER COLUMN [SoldAsVacant]varchar(50) not null; 


Select SoldAsVacant
, CASE When SoldAsVacant = '1' THEN 'Yes'
	   When SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
	   END
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv



Update NashvilleHousingProject..NashvilleHousingDataCleaningCsv
SET SoldAsVacant = CASE When SoldAsVacant = '1' THEN 'Yes'
	   When SoldAsVacant = '0' THEN 'No'
	   ELSE SoldAsVacant
	   END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From NashvilleHousingProject..NashvilleHousingDataCleaningCsv
--order by ParcelID
)
select *
From RowNumCTE
Where row_num > 1
--Order by PropertyAddress



Select *
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From NashvilleHousingProject..NashvilleHousingDataCleaningCsv


ALTER TABLE NashvilleHousingProject..NashvilleHousingDataCleaningCsv
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO
