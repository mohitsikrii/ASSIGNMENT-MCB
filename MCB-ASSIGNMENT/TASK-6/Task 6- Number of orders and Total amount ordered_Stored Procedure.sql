CREATE OR REPLACE PROCEDURE GETSUPPLIERORDERDETAILS (
    p_start_date IN DATE,
    p_end_date IN DATE,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        supp.SUPPLIER_NAME AS "Supplier Name",
        supp.SUPPLIER_CONTACT_NAME AS "Supplier Contact Name",
        MAX(CASE WHEN rn = 1 THEN REGEXP_REPLACE(supp.CONTACT_NUMBER, '\s+', '') END) AS "Supplier Contact No. 1",
        MAX(CASE WHEN rn = 2 THEN REGEXP_REPLACE(supp.CONTACT_NUMBER, '\s+', '') END) AS "Supplier Contact No. 2",
        SUM(order_count) AS "Total Orders",
        TO_CHAR(SUM(order_total_amt), 'fm999G999G999D00') AS "Order Total Amount"
    FROM (
        SELECT 
            supp.SUPPLIER_NAME,
            supp.SUPPLIER_CONTACT_NAME,
            COUNT(odr.ORDER_REF_NUMBER) AS order_count,
            DECODE(LENGTH(supp_con.CONTACT_NUMBER), 
                7, SUBSTR(supp_con.CONTACT_NUMBER, 1, 3) || '-' || SUBSTR(supp_con.CONTACT_NUMBER, 4, 7), 
                SUBSTR(supp_con.CONTACT_NUMBER, 1, 4) || '-' || SUBSTR(supp_con.CONTACT_NUMBER, 5, 8)
            ) AS CONTACT_NUMBER,
            SUM(odr.ORDER_TOTAL_AMOUNT) AS order_total_amt,
            ROW_NUMBER() OVER (PARTITION BY supp.SUPPLIER_NAME ORDER BY supp_con.CONTACT_NUMBER) AS rn
        FROM XXBCM_ORDER_HEADERS odr
        JOIN XXBCM_SUPPLIERS supp ON odr.SUPPLIER_ID = supp.SUPPLIER_ID
        JOIN XXBCM_SUPPLIER_CONTACTS supp_con ON supp.SUPPLIER_ID = supp_con.SUPPLIER_ID
        WHERE odr.ORDER_DATE BETWEEN p_start_date AND p_end_date
        GROUP BY 
            supp.SUPPLIER_NAME,
            supp.SUPPLIER_CONTACT_NAME,
            supp_con.CONTACT_NUMBER
    ) supp
    GROUP BY 
        supp.SUPPLIER_NAME, 
        supp.SUPPLIER_CONTACT_NAME
    ORDER BY 
        supp.SUPPLIER_NAME, 
        supp.SUPPLIER_CONTACT_NAME;
END GETSUPPLIERORDERDETAILS;
/
