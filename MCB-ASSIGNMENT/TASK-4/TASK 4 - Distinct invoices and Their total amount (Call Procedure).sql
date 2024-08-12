-- Example Block to Call the Procedure and Display Results

DECLARE
    v_cursor SYS_REFCURSOR;
    v_order_reference NUMBER;
    v_order_period VARCHAR2(50);
    v_supplier_name VARCHAR2(200);
    v_order_total_amount VARCHAR2(50);
    v_order_status VARCHAR2(100);
    v_invoice_reference VARCHAR2(100);
    v_invoice_total_amount VARCHAR2(50);
    v_action VARCHAR2(50);
BEGIN
    -- Call the procedure
    GetOrderAndInvoiceDetailsNoParams(o_cursor => v_cursor);

    -- Fetch and display results
    LOOP
        FETCH v_cursor INTO v_order_reference, v_order_period, v_supplier_name, v_order_total_amount, v_order_status, v_invoice_reference, v_invoice_total_amount, v_action;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Order Reference: ' || v_order_reference);
        DBMS_OUTPUT.PUT_LINE('Order Period: ' || v_order_period);
        DBMS_OUTPUT.PUT_LINE('Supplier Name: ' || v_supplier_name);
        DBMS_OUTPUT.PUT_LINE('Order Total Amount: ' || v_order_total_amount);
        DBMS_OUTPUT.PUT_LINE('Order Status: ' || v_order_status);
        DBMS_OUTPUT.PUT_LINE('Invoice Reference: ' || v_invoice_reference);
        DBMS_OUTPUT.PUT_LINE('Invoice Total Amount: ' || v_invoice_total_amount);
        DBMS_OUTPUT.PUT_LINE('Action: ' || v_action);
        DBMS_OUTPUT.PUT_LINE('-------------------------------');
    END LOOP;

    CLOSE v_cursor;
END;
/
