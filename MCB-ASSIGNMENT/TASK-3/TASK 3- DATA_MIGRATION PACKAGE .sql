CREATE OR REPLACE PACKAGE BODY XXBCM_DATA_MIGRATION_PKG AS

    PROCEDURE XXBCM_ADD_SUPPLIER_ADDRESS IS
    BEGIN
        FOR supp_add IN (
            SELECT DISTINCT
                REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 1) AS add1,
                REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 2) AS add2,
                REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 3) AS add3,
                REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 4) AS add4,
                REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 5) AS add5
            FROM XXBCM_ORDER_MGT
        )
        LOOP
            INSERT INTO XXBCM_SUPPLIER_ADDRESS (
                ADDRESS_LINE1,
                ADDRESS_LINE2,
                ADDRESS_LINE3,
                ADDRESS_LINE4,
                ADDRESS_LINE5
            )
            VALUES (
                supp_add.add1,
                supp_add.add2,
                supp_add.add3,
                supp_add.add4,
                supp_add.add5
            );
        END LOOP;

        COMMIT;
    END XXBCM_ADD_SUPPLIER_ADDRESS;

    PROCEDURE XXBCM_ADD_SUPPLIER IS
    BEGIN
        FOR supp IN (
            SELECT DISTINCT 
                x.SUPPLIER_NAME,
                x.SUPP_CONTACT_NAME,
                x.SUPP_EMAIL,
                (SELECT ADDRESS_ID 
                 FROM XXBCM_SUPPLIER_ADDRESS a
                 WHERE REPLACE(x.SUPP_ADDRESS, ', ', ' ') = 
                       COALESCE(a.ADDRESS_LINE1, '') || 
                       COALESCE(a.ADDRESS_LINE2, '') || 
                       COALESCE(a.ADDRESS_LINE3, '') || 
                       COALESCE(a.ADDRESS_LINE4, '') || 
                       COALESCE(a.ADDRESS_LINE5, '')
                ) AS ADDRESS_ID
            FROM XXBCM_ORDER_MGT x
        )
        LOOP
            INSERT INTO XXBCM_SUPPLIERS (
                SUPPLIER_NAME,
                SUPPLIER_CONTACT_NAME,
                SUPPLIER_EMAIL,
                SUPPLIER_ADDRESS_ID
            ) 
            VALUES (
                supp.SUPPLIER_NAME,
                supp.SUPP_CONTACT_NAME,
                supp.SUPP_EMAIL,
                supp.ADDRESS_ID
            );
        END LOOP;

        COMMIT;
    END XXBCM_ADD_SUPPLIER;

    PROCEDURE XXBCM_ADD_SUPPLIER_CONTACT IS
    BEGIN
        FOR supp_con IN (
            SELECT DISTINCT 
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(TRIM(REGEXP_SUBSTR(SUPP_CONTACT_NUMBER, '[^,]+', 1, LEVEL)), 'S', '5'
                        ), 'o', '0'
                    ), 'I', '1'
                ), '.', ''
            ) AS CONTACT_NUMBER,
            (
                SELECT SUPPLIER_ID 
                FROM XXBCM_SUPPLIERS 
                WHERE SUPPLIER_NAME = x.SUPPLIER_NAME
                  AND SUPPLIER_CONTACT_NAME = x.SUPP_CONTACT_NAME
            ) AS SUPPLIER_ID
            FROM XXBCM_ORDER_MGT x
            CONNECT BY REGEXP_SUBSTR(SUPP_CONTACT_NUMBER, '[^,]+', 1, LEVEL) IS NOT NULL
        )
        LOOP
            INSERT INTO XXBCM_SUPPLIER_CONTACTS (
                SUPPLIER_ID,
                CONTACT_NUMBER
            ) 
            VALUES (
                supp_con.SUPPLIER_ID,
                supp_con.CONTACT_NUMBER
            );
        END LOOP;
        
        COMMIT;
    END XXBCM_ADD_SUPPLIER_CONTACT;

    PROCEDURE XXBCM_ADD_ORDER_LINES IS
    BEGIN
        FOR order_line IN (
            SELECT DISTINCT 
                ORDER_REF,
                (SELECT ORDER_HEADER_ID 
                 FROM XXBCM_ORDER_HEADERS 
                 WHERE ORDER_REF_NUMBER = SUBSTR(om.ORDER_REF, 1, INSTR(om.ORDER_REF, '-', 1) - 1)
                ) AS ORDER_HEADER_ID,
                ROW_NUMBER() OVER (PARTITION BY SUBSTR(ORDER_REF, 1, INSTR(ORDER_REF, '-', 1) - 1) ORDER BY ORDER_REF) AS LINE_NUMBER,
                ORDER_DESCRIPTION,
                REPLACE(REPLACE(REPLACE(REPLACE(ORDER_LINE_AMOUNT, ',', ''), 'I', '1'), 'S', '5'), 'o', '0') AS ORDER_LINE_AMOUNT,
                ORDER_STATUS
            FROM 
                XXBCM_ORDER_MGT om
            WHERE 
                ORDER_REF LIKE '%-%'
            ORDER BY 
                ORDER_REF
        )
        LOOP
            INSERT INTO XXBCM_ORDER_LINES (
                ORDER_REF,
                ORDER_HEADER_ID,
                ORDER_LINE_NUM,
                ORDER_LINE_DESC,
                ORDER_LINE_AMOUNT,
                ORDER_LINE_STATUS
            )
            VALUES (
                order_line.ORDER_REF,
                order_line.ORDER_HEADER_ID,
                order_line.LINE_NUMBER,
                order_line.ORDER_DESCRIPTION,
                order_line.ORDER_LINE_AMOUNT,
                order_line.ORDER_STATUS
            );
        END LOOP;

        COMMIT;
    END XXBCM_ADD_ORDER_LINES;

    PROCEDURE XXBCM_ADD_INVOICE_HOLDS IS
    BEGIN
        FOR hold_record IN (
            SELECT DISTINCT INVOICE_HOLD_REASON 
            FROM XXBCM_ORDER_MGT 
            WHERE INVOICE_HOLD_REASON IS NOT NULL
        ) 
        LOOP
            INSERT INTO XXBCM_INVOICE_HOLDS (INVOICE_HOLD_REASON)
            VALUES (hold_record.INVOICE_HOLD_REASON);
        END LOOP;

        COMMIT;
    END XXBCM_ADD_INVOICE_HOLDS;

    PROCEDURE XXBCM_ADD_INVOICE_HEADERS IS
    BEGIN
        FOR invh IN (
            SELECT DISTINCT
                SUBSTR(INVOICE_REFERENCE, 1, INSTR(INVOICE_REFERENCE, '.', 1) - 1) AS INVOICE_NUMBER
            FROM XXBCM_INVOICE_LINES
            WHERE INVOICE_REFERENCE IS NOT NULL
            ORDER BY INVOICE_NUMBER
        )
        LOOP
            -- Insert distinct invoice numbers into the XXBCM_INVOICE_HEADERS table
            INSERT INTO XXBCM_INVOICE_HEADERS (INVOICE_NUMBER)
            VALUES (invh.INVOICE_NUMBER);
        END LOOP;
        COMMIT;
    END XXBCM_ADD_INVOICE_HEADERS;

    PROCEDURE XXBCM_ADD_INVOICE_LINES IS
    BEGIN
        FOR invl IN (
            SELECT DISTINCT
                x.INVOICE_REFERENCE,
                (SELECT MAX(INVOICE_HEADER_ID)
                 FROM XXBCM_INVOICE_HEADERS
                 WHERE INVOICE_NUMBER = SUBSTR(x.INVOICE_REFERENCE, 1, INSTR(x.INVOICE_REFERENCE, '.', 1) - 1)
                ) AS INVOICE_HEADER_ID,
                ROW_NUMBER() OVER (PARTITION BY SUBSTR(INVOICE_REFERENCE, 1, INSTR(INVOICE_REFERENCE, '.', 1) - 1)
                                   ORDER BY INVOICE_REFERENCE
                ) AS INV_NUM,
                odr.ORDER_LINE_ID,
                TO_DATE(x.INVOICE_DATE, 'DD-MM-YYYY') AS INVOICE_DATE,
                x.INVOICE_DESCRIPTION,
                REPLACE(REPLACE(REPLACE(REPLACE(x.INVOICE_AMOUNT, ',', ''), 'I', '1'), 'S', '5'), 'o', '0') AS INVOICE_AMOUNT,
                x.INVOICE_STATUS,
                (SELECT MAX(INVOICE_HOLD_ID)
                 FROM XXBCM_INVOICE_HOLDS
                 WHERE INVOICE_HOLD_REASON = x.INVOICE_HOLD_REASON
                ) AS INVOICE_HOLD_ID
            FROM XXBCM_ORDER_MGT x
            JOIN XXBCM_ORDER_LINES odr
            ON odr.ORDER_REF = x.ORDER_REF
            AND odr.ORDER_LINE_DESC = x.ORDER_DESCRIPTION
            WHERE x.INVOICE_REFERENCE LIKE '%.%'
            ORDER BY x.INVOICE_REFERENCE
        )
        LOOP
            INSERT INTO XXBCM_INVOICE_LINES (
                INVOICE_HEADER_ID,
                INVOICE_NUMBER,
                INVOICE_REFERENCE,
                ORDER_LINE_ID,
                INVOICE_DATE,
                INVOICE_DESC,
                INVOICE_AMOUNT,
                INVOICE_STATUS,
                INVOICE_HOLD_ID
            )
            VALUES (
                invl.INVOICE_HEADER_ID,
                invl.INV_NUM,
                invl.INVOICE_REFERENCE,
                invl.ORDER_LINE_ID,
                invl.INVOICE_DATE,
                invl.INVOICE_DESCRIPTION,
                invl.INVOICE_AMOUNT,
                invl.INVOICE_STATUS,
                invl.INVOICE_HOLD_ID
            );
        END LOOP;
        COMMIT;
    END XXBCM_ADD_INVOICE_LINES;

    PROCEDURE XXBCM_ADD_ORDER_HEADERS IS
    BEGIN
        FOR odr IN (
            SELECT DISTINCT 
                ORDER_REF,
                TO_DATE(ORDER_DATE, 'DD-MM-YYYY') AS ORDER_DATE,
                ORDER_DESCRIPTION,
                TO_NUMBER(REPLACE(ORDER_TOTAL_AMOUNT, ',', '')) AS ORDER_TOTAL_AMOUNT,
                ORDER_STATUS,
                (SELECT s.SUPPLIER_ID 
                 FROM XXBCM_SUPPLIERS s
                 WHERE s.SUPPLIER_NAME = x.SUPPLIER_NAME) AS SUPPLIER_ID
            FROM XXBCM_ORDER_MGT x
            WHERE ORDER_REF NOT LIKE '%-%'
            ORDER BY ORDER_REF
        )
        LOOP
            INSERT INTO XXBCM_ORDER_HEADERS (
                ORDER_REF_NUMBER,
                ORDER_DATE,
                ORDER_DESC,
                ORDER_TOTAL_AMOUNT,
                ORDER_STATUS,
                SUPPLIER_ID
            ) 
            VALUES (
                odr.ORDER_REF,
                odr.ORDER_DATE,
                odr.ORDER_DESCRIPTION,
                odr.ORDER_TOTAL_AMOUNT,
                odr.ORDER_STATUS,
                odr.SUPPLIER_ID
            );
        END LOOP;
        COMMIT;
    END XXBCM_ADD_ORDER_HEADERS;

END XXBCM_DATA_MIGRATION_PKG;
/
