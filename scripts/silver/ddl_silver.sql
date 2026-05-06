/* creates tables in the silver layer */



-- Customer info table
DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info(
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE,
    dxh_create_date DATE DEFAULT (CURRENT_DATE)

);

-- Product info table
DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info(
	prd_id INT,
    cat_id NVARCHAR(50),
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
    dxh_create_date DATE DEFAULT (CURRENT_DATE)
    
);

-- Sales details table
DROP TABLE silver.crm_sales_details
CREATE TABLE silver.crm_sales_details(
sls_ord_num NVARCHAR(50) ,
sls_prd_key NVARCHAR(50),
sls_cust_id INT,
sls_order_dt DATE ,
sls_ship_dt DATE,
sls_due_dt DATE,
sls_sales INT,
sls_quantity INT,
sls_price INT,
dxh_create_date DATE DEFAULT (CURRENT_DATE)

);

-- Tables from the ERP

-- Customer ID and info table
DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12(
CID NVARCHAR(50),
BDATE DATE,
GEN NVARCHAR(50),
dxh_create_date DATE DEFAULT (CURRENT_DATE)
);

-- Customer locations Table
DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101(
CID NVARCHAR(50),
CNTRY NVARCHAR(50),
dxh_create_date DATE DEFAULT (CURRENT_DATE)

);

-- Service table 
DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2(
ID NVARCHAR(50),
CAT NVARCHAR(50),
SUBCAT NVARCHAR(50),
MAINTENANCE NVARCHAR(50),
dxh_create_date DATE DEFAULT (CURRENT_DATE)

);


