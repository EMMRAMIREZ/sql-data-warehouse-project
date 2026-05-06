/*-------------------------------------

Procedure to load data into the Silver layer.
-------------------------------------*/



DELIMITER //

CREATE PROCEDURE silver.load_silver()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
        @sqlstate = RETURNED_SQLSTATE,
        @message = MESSAGE_TEXT;
        SELECT CONCAT('Error: ', @message) AS error_message;
    END;

    -- ============================================
    -- CRM TABLES
    -- ============================================

    -- Customer Info
    SELECT 'Loading silver.crm_cust_info...' AS status;
    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT 
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname) AS cst_lastname,
        CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
             WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
             ELSE 'n/a'
        END AS cst_marital_status,
        CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
             WHEN UPPER(TRIM(cst_gndr))  = 'M' THEN 'Male'
             ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
    FROM (
        SELECT 
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            NULLIF(cst_create_date, '0000-00-00') AS cst_create_date,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id != 0             
    ) t
    WHERE flag_last = 1;
    SELECT 'silver.crm_cust_info loaded successfully!' AS status;

    -- ============================================
    -- Product Info
    SELECT 'Loading silver.crm_prd_info...' AS status;
    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info(
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key,
        prd_nm,
        prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(
            LEAD(prd_start_dt,1,NULL) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) 
            AS DATE
        ) AS prd_end_dt
    FROM bronze.crm_prd_info;
    SELECT 'silver.crm_prd_info loaded successfully!' AS status;

    -- ============================================
    -- Sales Details
    SELECT 'Loading silver.crm_sales_details...' AS status;
    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details(
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        CASE 
            WHEN sls_sales IS NULL OR sls_sales <= 0 
                THEN sls_quantity * ABS(cleaned_price)
            WHEN sls_sales != sls_quantity * ABS(cleaned_price)
                THEN sls_quantity * ABS(cleaned_price)
            ELSE ABS(sls_sales)
        END AS sls_sales,
        sls_quantity,
        cleaned_price AS sls_price
    FROM (
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 10 THEN NULL
                ELSE CAST(sls_order_dt AS DATE)
            END AS sls_order_dt,
            CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 10 THEN NULL
                ELSE CAST(sls_ship_dt AS DATE)
            END AS sls_ship_dt,
            CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 10 THEN NULL
                ELSE CAST(sls_due_dt AS DATE)
            END AS sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price,
            CASE 
                WHEN sls_price IS NULL OR sls_price = 0
                    THEN ROUND(sls_sales / NULLIF(sls_quantity, 0), 0)
                WHEN sls_price < 0
                    THEN ABS(sls_price)
                ELSE sls_price
            END AS cleaned_price
        FROM bronze.crm_sales_details
    ) t;
    SELECT 'silver.crm_sales_details loaded successfully!' AS status;

    -- ============================================
    -- ERP TABLES
    -- ============================================

    -- Customer Details
    SELECT 'Loading silver.erp_cust_az12...' AS status;
    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE WHEN bdate > CURDATE() THEN NULL
            ELSE bdate
        END AS bdate,
        CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
             WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
             ELSE 'n/a'
        END AS gen
    FROM bronze.erp_cust_az12;
    SELECT 'silver.erp_cust_az12 loaded successfully!' AS status;

    -- ============================================
    -- Customer Location
    SELECT 'Loading silver.erp_loc_a101...' AS status;
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101(cid, cntry)
    SELECT 
        REPLACE(cid, '-', '') AS cid,
        CASE UPPER(TRIM(cntry))
            WHEN 'US' THEN 'United States'
            WHEN 'USA' THEN 'United States'
            WHEN 'DE' THEN 'Germany'
            WHEN '' THEN 'n/a'
            ELSE cntry
        END AS cntry
    FROM bronze.erp_loc_a101;
    SELECT 'silver.erp_loc_a101 loaded successfully!' AS status;

    -- ============================================
    -- Product Category
    SELECT 'Loading silver.erp_px_cat_g1v2...' AS status;
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
    SELECT 
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;
    SELECT 'silver.erp_px_cat_g1v2 loaded successfully!' AS status;

    SELECT 'All silver tables loaded successfully!' AS status;

END //

DELIMITER ;
    FROM bronze.crm_sales_details
) t;



