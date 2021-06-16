/*==================================================================================FUNCTIONS=============================================================================*/
/*===================================================================================TRIGGERS==============================================================================*/

DROP TRIGGER IF EXISTS KhachHangInsertTrigger;
DELIMITER $$
CREATE TRIGGER KhachHangInsertTrigger BEFORE INSERT
ON KhachHang FOR EACH ROW
BEGIN
	IF (NEW.NgayDangKy = '0/0/0') THEN
    	SET NEW.NgayDangKy = CURRENT_DATE;
    END IF;
END;
$$
DELIMITER ;

DROP TRIGGER IF EXISTS KhachHangAfterInsert;
DELIMITER $$
CREATE TRIGGER KhachHangAfterInsert AFTER INSERT ON KHACHHANG FOR EACH ROW
BEGIN
    IF (EXISTS(SELECT * FROM KHACHHANG WHERE MaKH > NEW.MaKH)) THEN
        CALL ThrowException('FU001');
    END IF;
END;
$$
DELIMITER ;

/*===================================================================================QUERRIES==============================================================================*/