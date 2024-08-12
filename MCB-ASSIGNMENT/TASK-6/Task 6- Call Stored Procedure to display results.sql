DECLARE
    l_cursor SYS_REFCURSOR;
    l_supplier_name XXBCM_SUPPLIERS.SUPPLIER_NAME%TYPE;
    l_contact_name XXBCM_SUPPLIERS.SUPPLIER_CONTACT_NAME%TYPE;
    l_contact_no1 VARCHAR2(200);
    l_contact_no2 VARCHAR2(200);
    l_total_orders NUMBER;
    l_order_total_amount VARCHAR2(50);
BEGIN
    GETSUPPLIERORDERDETAILS(
        p_start_date => TO_DATE('01-JAN-2022', 'DD-MON-YYYY'),
        p_end_date => TO_DATE('31-AUG-2022', 'DD-MON-YYYY'),
        p_cursor => l_cursor
    );
    
    LOOP
        FETCH l_cursor INTO l_supplier_name, l_contact_name, l_contact_no1, l_contact_no2, l_total_orders, l_order_total_amount;
        EXIT WHEN l_cursor%NOTFOUND;
        
        -- Process each row as needed
        DBMS_OUTPUT.PUT_LINE('Supplier Name: ' || l_supplier_name);
        DBMS_OUTPUT.PUT_LINE('Supplier Contact Name: ' || l_contact_name);
        DBMS_OUTPUT.PUT_LINE('Supplier Contact No. 1: ' || l_contact_no1);
        DBMS_OUTPUT.PUT_LINE('Supplier Contact No. 2: ' || l_contact_no2);
        DBMS_OUTPUT.PUT_LINE('Total Orders: ' || l_total_orders);
        DBMS_OUTPUT.PUT_LINE('Order Total Amount: ' || l_order_total_amount);
    END LOOP;
    
    CLOSE l_cursor;
END;
/
