WITH RankedOrders AS (
    SELECT 
        TO_NUMBER(SUBSTR(odr.ORDER_REF_NUMBER, 3)) AS Order_num,
        TO_CHAR(odr.ORDER_DATE, 'MONTH DD, YYYY') AS Order_date,
        UPPER(sup.SUPPLIER_NAME) AS order_supp,
        TO_CHAR(odr.ORDER_TOTAL_AMOUNT, 'fm999G999G999D00') AS order_total,
        odr.ORDER_STATUS,
        il.INVOICE_NUMBER AS invoice_reference,
        DENSE_RANK() OVER (ORDER BY odr.ORDER_TOTAL_AMOUNT DESC) AS r
    FROM 
        XXBCM_ORDER_HEADERS odr
    JOIN 
        XXBCM_SUPPLIERS sup ON odr.SUPPLIER_ID = sup.SUPPLIER_ID
    JOIN 
        XXBCM_ORDER_LINES odrl ON odr.ORDER_HEADER_ID = odrl.ORDER_HEADER_ID
    JOIN 
        XXBCM_INVOICE_LINES il ON il.ORDER_LINE_ID = odrl.ORDER_LINE_ID
    JOIN 
        XXBCM_INVOICE_HEADERS ih ON ih.INVOICE_HEADER_ID = il.INVOICE_HEADER_ID
)
SELECT 
    ro.Order_num AS "Order Reference",
    ro.Order_date AS "Order Date",
    ro.order_supp AS "Supplier Name",
    ro.order_total AS "Order Total Amount",
    ro.ORDER_STATUS AS "Order Status",
    LISTAGG(ro.invoice_reference, '|') WITHIN GROUP (ORDER BY ro.invoice_reference) AS "Invoice References"
FROM 
    RankedOrders ro
WHERE 
    ro.r = 2
GROUP BY 
    ro.Order_num,
    ro.Order_date,
    ro.order_supp,
    ro.order_total,
    ro.ORDER_STATUS;
