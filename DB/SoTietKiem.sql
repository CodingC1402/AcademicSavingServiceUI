/*=================================================================================PROCEDURE=============================================================================*/

DROP PROCEDURE IF EXISTS ThemSoTietKiem;
DELIMITER $$
CREATE PROCEDURE ThemSoTietKiem(IN MaKH INT, IN KyHan TINYINT, IN SoTienBanDau DECIMAL(15, 2), IN NgayTao DATE)
BEGIN
	SELECT LKH.MaKyHan INTO @MaKyHan FROM LOAIKYHAN LKH WHERE LKH.KyHan = KyHan AND LKH.NgayTao <= NgayTao ORDER BY LKH.NgayTao DESC LIMIT 1;
    INSERT INTO SOTIETKIEM(MaKH, MaKyHan, NgayTao, SoTienBanDau) VALUES(MaKH, @MaKyHan, NgayTao, SoTienBanDau);
END;
$$
DELIMITER ;

DROP PROCEDURE IF EXISTS ThemSoTietKiemVaReturn;
DELIMITER $$
CREATE PROCEDURE ThemSoTietKiemVaReturn(IN MaKH INT, IN KyHan TINYINT, IN SoTienBanDau DECIMAL(15, 2), IN NgayTao DATE)
BEGIN
	CALL ThemSoTietKiem(MaKH, KyHan, SoTienBanDau, NgayTao);
    PREPARE Stmt FROM 'SELECT * FROM SOTIETKIEM ORDER BY MaSo DESC LIMIT 0, 1';
    EXECUTE Stmt;
    DEALLOCATE PREPARE Stmt;
END;
$$
DELIMITER ;

DROP PROCEDURE IF EXISTS ForceDeleteAllSoTietKiem;
DELIMITER $$
CREATE PROCEDURE ForceDeleteAllSoTietKiem()
BEGIN
	DECLARE i INT;
    SET i = 0;
    SELECT COUNT(*) INTO @Size FROM SOTIETKIEM;
    WHILE (i < @Size) DO
		CALL ForceDeleteSoTietKiem((SELECT MaSo FROM SOTIETKIEM LIMIT 1));
        SET i = i + 1;
    END WHILE;
END;
$$
DELIMITER ;

DROP PROCEDURE IF EXISTS ForceDeleteSoTietKiem;
DELIMITER $$
CREATE PROCEDURE ForceDeleteSoTietKiem(IN MaSoDelete INT)
BEGIN
    CALL StartForceDelete();
    DELETE FROM PHIEUGUI PG WHERE PG.MaSo = MaSoDelete;
    DELETE FROM PHIEURUT PR WHERE PR.MaSo = MaSoDelete;
    DELETE FROM SOTIETKIEM STK WHERE STK.MaSo = MaSoDelete;
    CALL EndForceDelete();
END;
$$
DELIMITER ;

/*USED TO GET THE BALANCE WITHOUT UPDATE*/
DROP PROCEDURE IF EXISTS LaySoTienVoiNgay;
DELIMITER $$
CREATE PROCEDURE LaySoTienVoiNgay (IN NgayTao DATE, IN LanCapNhatCuoi DATE, IN NgayDongSo DATE, IN MaKyHan INT, IN MaSo INT, IN SoDuLanCapNhatCuoi DECIMAL(15, 2), IN NgayCanUpdate DATE, OUT SoDuDung DECIMAL(15, 2), OUT NgayUpdate DATE)
BEGIN
	DECLARE _counter, _kyHan, _size INT;
	DECLARE _ngayDaoHan, _nextUpdateDate, _createDate DATE;
	DECLARE _interest FLOAT;
	DECLARE _money DECIMAL(15, 2);
  	SET _counter = 0;

	IF (NgayCanUpdate > CURRENT_DATE()) THEN
		CALL ThrowException('TK004');
	END IF;
	IF (NgayDongSo IS NULL) THEN
		IF (LanCapNhatCuoi > NgayCanUpdate) THEN
			SET SoDuDung = SoDuLanCapNhatCuoi;
	        SET NgayUpdate = LanCapNhatCuoi;
		ELSE
		    SET LanCapNhatCuoi = IF (LanCapNhatCuoi IS NULL, NgayTao, LanCapNhatCuoi);
			SELECT KyHan INTO _kyHan FROM LOAIKYHAN LKH WHERE LKH.MaKyHan = MaKyHan;
			SET _ngayDaoHan = TIMESTAMPADD(MONTH, _kyHan, NgayTao);
	        SET SoDuDung = SoDuLanCapNhatCuoi;
	  		IF (NgayCanUpdate >= _ngayDaoHan) THEN
				IF (LanCapNhatCuoi < _ngayDaoHan) THEN
					SET _nextUpdateDate = IF(NgayCanUpdate < _ngayDaoHan, NgayCanUpdate, _ngayDaoHan);
					SET _interest = (SELECT LaiSuat FROM LOAIKYHAN LKH WHERE MaKyHan = LKH.MaKyHan);
					SET SoDuDung = SoDuDung * (1 + (_interest / (100 * 365)) * TIMESTAMPDIFF(DAY, LanCapNhatCuoi, _nextUpdateDate));
					SET LanCapNhatCuoi = _nextUpdateDate;
				END IF;

				SET SoDuDung = SoDuDung * (1 + LayLaiSuatKhongKyHanTrongKhoangThoiGian(LanCapNhatCuoi, NgayCanUpdate));
	    		SELECT COUNT(*) INTO _size FROM PHIEUGUI PG WHERE PG.NgayTao <= NgayCanUpdate AND PG.NgayTao >= LanCapNhatCuoi AND PG.MaSo = MaSo;
	   			WHILE (_counter < _size) DO
					SELECT PG.SoTien, PG.NgayTao INTO _money, _createDate FROM PHIEUGUI PG WHERE  PG.NgayTao <= NgayCanUpdate AND PG.NgayTao >= LanCapNhatCuoi AND PG.MaSo = MaSo ORDER BY MaPhieu LIMIT _counter, 1;
					SET SoDuDung = SoDuDung + (_money * (1 + LayLaiSuatKhongKyHanTrongKhoangThoiGian(_createDate, NgayCanUpdate)));
					SET _counter = _counter + 1;
	    		END WHILE;

	    		SET LanCapNhatCuoi = NgayCanUpdate;
	  		END IF;
			SET NgayUpdate = LanCapNhatCuoi;
		END IF;
	ELSE
		SET SoDuDung = 0;
		SET NgayUpdate = NgayDongSo;
	END IF;
END;
$$
DELIMITER ;

/*QUERY AND GET THE BALANCE (CAN'T BE USE IN TRIGGERS OF STK)*/
DROP PROCEDURE IF EXISTS LaySoTienVoiNgayQuery;
DELIMITER $$
CREATE PROCEDURE LaySoTienVoiNgayQuery(IN MaSo INT, IN NgayCanUpdate DATE, OUT SoDuDung DECIMAL(15, 2), OUT NgayUpdate DATE)
BEGIN
    DECLARE NgayTao, LanCapNhatCuoi, NgayDongSo DATE;
    DECLARE SoDu, SoDuLanCapNhatCuoi DECIMAL(15, 2);
    DECLARE MaKyHan INT;

    SELECT STK.NgayTao, STK.LanCapNhatCuoi, STK.NgayDongSo, STK.MaKyHan, STK.SoDu, STK.SoDuLanCapNhatCuoi
    INTO NgayTao, LanCapNhatCuoi, NgayDongSo, MaKyHan, SoDu, SoDuLanCapNhatCuoi
    FROM SOTIETKIEM STK
    WHERE STK.MaSo = MaSo;

    IF (NgayTao IS NULL) THEN
        SET SoDuDung = NULL;
        SET NgayUpdate = NULL;
    ELSE
        CALL LaySoTienVoiNgay(NgayTao, LanCapNhatCuoi, NgayDongSo, MaKyHan, MaSo, SoDuLanCapNhatCuoi, NgayCanUpdate, SoDuDung, NgayUpdate);
    END IF;
END;
$$
DELIMITER ;

/*==================================================================================FUNCTIONS=============================================================================*/
/*===================================================================================TRIGGERS==============================================================================*/

DROP TRIGGER IF EXISTS SoTietKiemBeforeUpdate;
DELIMITER $$
CREATE TRIGGER SoTietKiemBeforeUpdate BEFORE UPDATE ON SOTIETKIEM FOR EACH ROW
BEGIN
    DECLARE SoDuDung DECIMAL(15, 2);
    DECLARE NgayDung DATE;

	IF (NOT CoTheCapNhatSoTietKiem()) THEN
	    IF (NEW.MaSo != OLD.MaSo OR
	        NEW.SoDu != OLD.SoDu OR
	        NEW.SoDuLanCapNhatCuoi != OLD.SoDuLanCapNhatCuoi OR
	        NEW.LanCapNhatCuoi != OLD.LanCapNhatCuoi OR
	        NEW.NgayDongSo != OLD.NgayDongSo OR
	        NEW.NgayTao != OLD.NgayTao OR
	        NEW.MaKyHan != OLD.MaKyHan) THEN
		    CALL ThrowException('TK003');
        END IF;
    END IF;

    IF (NEW.MaKH != OLD.MaKH) THEN
        IF (NEW.NgayTao < (SELECT NgayDangKy FROM KHACHHANG WHERE MaKH = NEW.MaKH)) THEN
            CALL ThrowException('TK008');
        END IF;
    END IF;

	IF (NEW.SoTienBanDau != OLD.SoTienBanDau) THEN
        IF (KiemTraKyHan(NEW.MaKyHan, NEW.NgayTao) = FALSE) THEN
	    	CALL ThrowException('TK002');
	    END IF;
	    IF (EXISTS(SELECT * FROM PHIEURUT PR WHERE PR.MaSo = NEW.MaSo)) THEN
            CALL ThrowException('TK005');
        END IF;
        IF (NEW.SoTienBanDau < LaySoTienMoTaiKhoanNhoNhat(NEW.NgayTao)) THEN
            CALL ThrowException('TK001');
        END IF;
	    IF (EXISTS(SELECT * FROM PHIEUGUI PG WHERE PG.MaSo = NEW.MaSo AND PG.NgayTao < NEW.NgayTao)) THEN
            CALL ThrowException('TK006');
        END IF;
    END IF;

	IF (NEW.SoDuLanCapNhatCuoi != OLD.SoDuLanCapNhatCuoi) THEN
        IF (NEW.SoDuLanCapNhatCuoi = 0) THEN
            SET NEW.SoDU = 0;
            SET NEW.NgayDongSo = NEW.LanCapNhatCuoi;
        ELSE
            SET NEW.NgayDongSo = NULL;
	        CALL LaySoTienVoiNgay(NEW.NgayTao, NEW.LanCapNhatCuoi,
	            NEW.NgayDongSo, NEW.MaKyHan, NEW.MaSo,
	            NEW.SoDuLanCapNhatCuoi, CURRENT_DATE(), SoDuDung, NgayDung);
            SET NEW.SoDu = SoDuDung;
        END IF;
    END IF;

    IF (NEW.SoDuLanCapNhatCuoi != OLD.SoDuLanCapNhatCuoi OR
        NEW.NgayTao != OLD.NgayTao OR
        NEW.SoTienBanDau != OLD.SoTienBanDau) THEN
        CALL CapNhatBaoCaoNgayXoaSoTietKiem(OLD.SoTienBanDau, OLD.NgayTao, OLD.MaKyHan);
        CALL CapNhatBaoCaoThangXoaSoTietKiem(OLD.NgayTao, OLD.MaKyHan, OLD.NgayDongSo);

        CALL CapNhatBaoCaoNgayTaoSoTietKiem(NEW.SoTienBanDau, NEW.NgayTao, NEW.MaKyHan);
        CALL CapNhatBaoCaoThangTaoSoTietKiem(NEW.NgayTao, NEW.MaKyHan, NEW.NgayDongSo);
    END IF;
END;
$$
DELIMITER ;

DROP TRIGGER IF EXISTS SoTietKiemAfterInsert;
DELIMITER $$
CREATE TRIGGER SoTietKiemAfterInsert AFTER INSERT ON SOTIETKIEM FOR EACH ROW
BEGIN
    IF (EXISTS(SELECT * FROM SOTIETKIEM WHERE MaSo > NEW.MaSo)) THEN
        CALL ThrowException('FU006');
    END IF;
END;
$$
DELIMITER ;

DROP TRIGGER IF EXISTS SoTietKiemInsert;
DELIMITER $$
CREATE TRIGGER SoTietKiemInsert BEFORE INSERT ON SOTIETKIEM FOR EACH ROW
BEGIN
    DECLARE SoDuDung DECIMAL(15, 2);
    DECLARE NgayDung DATE;

	IF (NEW.NgayTao = '0/0/0') THEN SET NEW.NgayTao = NOW(); END IF;
    IF (NEW.NgayTao < (SELECT NgayDangKy FROM KHACHHANG WHERE MaKH = NEW.MaKH)) THEN
        CALL ThrowException('TK008');
    END IF;
    IF (NOT EXISTS(SELECT * FROM QUYDINH WHERE quydinh.NgayTao < NEW.NgayTao)) THEN
        CALL ThrowException('TK007');
    END IF;
	IF (NEW.SoTienBanDau < LaySoTienMoTaiKhoanNhoNhat(NEW.NgayTao)) THEN CALL ThrowException('TK001'); END IF;
    IF (KiemTraKyHan(NEW.MaKyHan, NEW.NgayTao) = FALSE) THEN
		CALL ThrowException('TK002');
	END IF; 
	SET NEW.SoDu = NEW.SoTienBanDau;
    SET NEW.SoDuLanCapNhatCuoi = NEW.SoTienBanDau;

	CALL LaySoTienVoiNgay(NEW.NgayTao, NEW.LanCapNhatCuoi,
	    NEW.NgayDongSo, NEW.MaKyHan, NEW.MaSo,
	    NEW.SoDuLanCapNhatCuoi, CURRENT_DATE(), SoDuDung, NgayDung);

	SET NEW.SoDU = SoDuDung;
    SET NEW.LanCapNhatCuoi = NEW.NgayTao;
    SET NEW.NgayDongSo = NULL;

    CALL CapNhatBaoCaoNgayTaoSoTietKiem(NEW.SoTienBanDau, NEW.NgayTao, NEW.MaKyHan);
    CALL CapNhatBaoCaoThangTaoSoTietKiem(NEW.NgayTao, NEW.MaKyHan, NEW.NgayDongSo);
END;
$$
DELIMITER ;

DROP TRIGGER IF EXISTS SoTietKiemDelete;
DELIMITER $$
CREATE TRIGGER SoTietKiemDelete BEFORE DELETE ON SOTIETKIEM FOR EACH ROW
BEGIN
    CALL CapNhatBaoCaoNgayXoaSoTietKiem(OLD.SoTienBanDau, OLD.NgayTao, OLD.MaKyHan);
    CALL CapNhatBaoCaoThangXoaSoTietKiem(OLD.NgayTao, OLD.MaKyHan, OLD.NgayDongSo);
END;
$$
DELIMITER ;

/*===================================================================================SCHEDULER==============================================================================*/

DROP EVENT IF EXISTS UpdateBalance;
DELIMITER $$
CREATE EVENT UpdateBalance ON SCHEDULE EVERY 1 DAY STARTS CONCAT(TIMESTAMPADD(DAY, 1, CURRENT_DATE()), ' ' ,'00:20:00') ON COMPLETION PRESERVE ENABLE DO
BEGIN
    DECLARE _size, _counter, _maSo INT;
    DECLARE _soDuDung DECIMAL(15, 2);

    SELECT COUNT(*) INTO _size FROM SOTIETKIEM WHERE NgayDongSo IS NULL;
    SET _counter = 0;
    WHILE(_counter < _size) DO
        SELECT MaSo INTO _maSo FROM SOTIETKIEM WHERE NgayDongSo IS NULL ORDER BY MaSo LIMIT _counter, 1;
        CALL LaySoTienVoiNgayQuery(_maSo, CURRENT_DATE(), _soDuDung, @Dummy);

        UPDATE SOTIETKIEM
        SET SoDu = _soDuDung
        WHERE MaSo = _maSo;

        SET _counter = _counter + 1;
    END WHILE;
END;
$$
DELIMITER ;