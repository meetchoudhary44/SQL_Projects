/*

Cleaning Data in SQL Queries

*/

select *
from portfolio_project..NashvilleHousing

--Standardize date format (As new column sale_date) :-

	--Validate_date_conversion :-
		select SaleDate, cast(saledate as date) 
		from portfolio_project..NashvilleHousing
	
alter table Portfolio_Project..NashvilleHousing
add sale_date date ;

update portfolio_project..NashvilleHousing
set sale_date = cast(saledate as date)


--Populate property address :-


select A.ParcelID,A.PropertyAddress,B.ParcelID,B.PropertyAddress , ISNULL( A.PropertyAddress, B.PropertyAddress )
from portfolio_project..NashvilleHousing A
join portfolio_project..NashvilleHousing B
  on A.ParcelID = B.ParcelID
  and A.[UniqueID ] <> B.[UniqueID ]
where A.PropertyAddress is null

update A
set PropertyAddress =  ISNULL( A.PropertyAddress, B.PropertyAddress )
from portfolio_project..NashvilleHousing A
join portfolio_project..NashvilleHousing B
  on A.ParcelID = B.ParcelID
  and A.[UniqueID ] <> B.[UniqueID ]
where A.PropertyAddress is null

--Breaking out Address in coloumns (Address, City, State) :-

	-----For Property Address :-


		select PropertyAddress
		from portfolio_project..NashvilleHousing

select
	Left(PropertyAddress, CHARINDEX(',',PropertyAddress)-1) as address,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) as city
from portfolio_project..NashvilleHousing

alter table portfolio_project..NashvilleHousing
add PropertySplitAddress nvarchar(255) ;

update portfolio_project..NashvilleHousing
set PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

alter table portfolio_project..NashvilleHousing
add PropertySplitCity nvarchar(255) ;

update portfolio_project..NashvilleHousing
set PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) 


-----For Owner Address :-


select OwnerAddress
from portfolio_project..NashvilleHousing

select
PARSENAME(replace(OwnerAddress,',','.'), 3),
PARSENAME(replace(OwnerAddress,',','.'), 2),
PARSENAME(replace(OwnerAddress,',','.'), 1)
from portfolio_project..NashvilleHousing

alter table Portfolio_Project..NashvilleHousing
add OwnerSplitAddress nvarchar(255) ;

update portfolio_project..NashvilleHousing
set OwnerSplitAddress = PARSENAME(replace(OwnerAddress,',','.'), 3)

alter table portfolio_project..NashvilleHousing 
add OwnerSplitCity nvarchar(255) ;

update portfolio_project..NashvilleHousing
set OwnerSplitCity = PARSENAME(replace(OwnerAddress,',','.'), 2)

alter table portfolio_project..NashvilleHousing
add OwnerSplitState nvarchar(255) ;

update portfolio_project..NashvilleHousing
set OwnerSplitState = PARSENAME(replace(OwnerAddress,',','.'), 1)


--Change 'y' to yes and 'n' to no in SoldAsVacant :-


select Distinct(SoldAsVacant),COUNT(*) as Record_Count
from portfolio_project..NashvilleHousing
group by SoldAsVacant ;


select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end 
from portfolio_project..NashvilleHousing

update portfolio_project..NashvilleHousing
set SoldAsVacant = case when SoldAsVacant = 'Y' then 'Yes'
     when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end 
from portfolio_project..NashvilleHousing


--Identifying and Removing duplicates records based on matchig property,legal-reference attributes and transaction :-


with RowNumCTE As(
select * ,
        ROW_NUMBER()  over (
		partition by  ParcelID,
		              LandUse,
					  PropertyAddress,
					  SaleDate,
					  SalePrice,
					  LegalReference
					  order by UniqueID ) Row_num
from portfolio_project..NashvilleHousing
                        
)
Delete
from RowNumCTE
where  Row_num > 1


--Delete Unused Cooumns :-


select *
from portfolio_project..NashvilleHousing

alter table portfolio_project..NashvilleHousing
drop column PropertyAddress, SaleDate, OwnerAddress  
