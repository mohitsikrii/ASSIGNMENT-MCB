CREATE OR REPLACE PROCEDURE GetOrderAndInvoiceDetailsNoParams (
    o_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN o_cursor FOR
    SELECT 
        TO_NUMBER(SUBSTR(odr.ORDER_REF_NUMBER, 3, LENGTH(odr.ORDER_REF_NUMBER))) AS "Order Reference",
        TO_CHAR(odr.ORDER_DATE, 'MON-YY') AS "Order Period",
        INITCAP(sup.SUPPLIER_NAME) AS "Supplier Name",
        TO_CHAR(odr.ORDER_TOTAL_AMOUNT, 'fm999G999G999D00') AS "Order Total Amount",
        odr.ORDER_STATUS AS "Order Status",
        ih.INVOICE_NUMBER AS "Invoice Reference",
        TO_CHAR(SUM(il.INVOICE_AMOUNT), 'fm999G999G999D00') AS "Invoice Total Amount",
        CASE  
            WHEN (SUM(DECODE(il.INVOICE_STATUS, 'Paid', '0', 'Pending', '1', '-1000')) = 0)
                THEN 'OK'
            WHEN (SUM(DECODE(il.INVOICE_STATUS, 'Paid', '0', 'Pending', '1', '-1000')) > 0)
                THEN 'To follow up'
            WHEN (SUM(DECODE(il.INVOICE_STATUS, 'Paid', '0', 'Pending', '1', '-1000')) < 0)
                THEN 'To verify'
        END AS "Action"
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
    GROUP BY 
        odr.ORDER_REF_NUMBER,
        TO_CHAR(odr.ORDER_DATE, 'MON-YY'),
        sup.SUPPLIER_NAME,
        TO_CHAR(odr.ORDER_TOTAL_AMOUNT, 'fm999G999G999D00'),
        odr.ORDER_STATUS,
        ih.INVOICE_NUMBER
    ORDER BY 
        odr.ORDER_REF_NUMBER;
END;
/
