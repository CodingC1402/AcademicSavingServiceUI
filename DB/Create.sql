DROP DATABASE IF EXISTS AcademicSavingService;
CREATE DATABASE AcademicSavingService;
USE AcademicSavingService;

CREATE TABLE QUYDINH (
	MaQD INT NOT NULL AUTO_INCREMENT,
	SoTienNapNhoNhat DECIMAL(15, 2) NOT NULL,
    SoTienMoTaiKhoanNhoNhat DECIMAL(15, 2) NOT NULL,
    SoNgayToiThieu TINYINT NOT NULL,
    NgayTao DATETIME NOT NULL DEFAULT '0/0/0',
    
    PRIMARY KEY(MaQD),
    CHECK(SoNgayToiThieu >= 0),
    CHECK(SoTienMoTaiKhoanNhoNhat >= 0),
    CHECK(SoTienNapNhoNhat >= 0)
);

CREATE TABLE LOAIKYHAN (
	MaKyHan INT NOT NULL AUTO_INCREMENT,
    KyHan TINYINT NOT NULL,
    LaiSuat FLOAT NOT NULL,
    NgayTao DATE NOT NULL DEFAULT '0/0/0',
    NgayNgungSuDung DATE,
    
    PRIMARY KEY(MaKyHan),
    CHECK(KyHan >= 0),
    CHECK(LaiSuat >= 0),
    CHECK(NgayNgungSuDung >= NgayTao)
)  CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE KHACHHANG (
	MaKH INT NOT NULL AUTO_INCREMENT,
    HoTen VARCHAR (30) NOT NULL,
	CMND VARCHAR(15) NOT NULL,
    SDT VARCHAR(15),
    NgayDangKy DATE NOT NULL DEFAULT '0/0/0',
    DiaChi TEXT NOT NULL,
    
    PRIMARY KEY(MaKH)
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE SOTIETKIEM (
	MaSo INT NOT NULL AUTO_INCREMENT,
    MaKH INT NOT NULL,
    NgayTao DATE NOT NULL DEFAULT '0/0/0',
    NgayDongSo DATE,
    MaKyHan INT NOT NULL,
    SoTienBanDau DECIMAL(15, 2) NOT NULL,
    SoDu DECIMAL(15, 2) NOT NULL DEFAULT 0,
	LanCapNhatCuoi DATE,
    
    FOREIGN KEY(MaKH) REFERENCES KHACHHANG(MaKH),
    FOREIGN KEY(MaKyHan) REFERENCES LOAIKYHAN(MaKyHan),
    CHECK (SoDu >= 0),
    PRIMARY KEY(MaSo)
)  CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE PHIEURUT (
	MaPhieu INT NOT NULL AUTO_INCREMENT,
    NgayTao DATE NOT NULL DEFAULT '0/0/0',
    SoTien DECIMAL(15, 2) NOT NULL,
    GhiChu TEXT,
    MaSo INT NOT NULL,
    
    CHECK (SoTien >= 0),
    FOREIGN KEY(MaSo) REFERENCES SOTIETKIEM(MaSo),
    PRIMARY KEY(MaPhieu)
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE PHIEUGUI (
	MaPhieu INT NOT NULL AUTO_INCREMENT,
    NgayTao DATE NOT NULL DEFAULT '0/0/0',
    SoTien DECIMAL(15, 2) NOT NULL,
    GhiChu TEXT,
    MaSo INT NOT NULL,
    
    CHECK (SoTien >= 0),
    FOREIGN KEY(MaSo) REFERENCES SOTIETKIEM(MaSo),
    PRIMARY KEY(MaPhieu)
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE BAOCAONGAY (
	Ngay DATE NOT NULL,
    KyHan INT NOT NULL,
    
    TongThu DECIMAL(15, 2) NOT NULL,
    TongChi DECIMAL(15, 2) NOT NULL,
    ChenhLech DECIMAL(15, 2) NOT NULL DEFAULT 0,
    
    PRIMARY KEY(Ngay, KyHan),
    CHECK(TongThu >= 0),
    CHECK(TongChi >= 0)
);

CREATE TABLE BAOCAOTHANG (
	Thang TINYINT NOT NULL,
    Nam INT NOT NULL,
    KyHan INT NOT NULL,
    
    SoMo INT NOT NULL,
    SoDong  INT NOT NULL,
    ChenhLech INT NOT NULL DEFAULT 0,
    
    PRIMARY KEY(Thang, Nam, KyHan),
    CHECK(SoMo >= 0),
    CHECK(SoDong >= 0)
);

CREATE TABLE GLOBALTABLE (
	DangCapNhatSTK BOOL NOT NULL DEFAULT FALSE,
    DangCapNhatPH BOOL NOT NULL DEFAULT FALSE,
    DangCapNhatLKH BOOL NOT NULL DEFAULT FALSE,
    DangCapNhatBCN BOOL NOT NULL DEFAULT FALSE,
    DangCapNhatBCT BOOL NOT NULL DEFAULT FALSE,
    DangCapNhatUQ BOOL NOT NULL DEFAULT FALSE,
    ForceDelete BOOL NOT NULL DEFAULT FALSE
);
INSERT INTO GLOBALTABLE VALUES ();

CREATE TABLE ERRORTABLE (
	MaLoi VARCHAR(5),
    GhiChu TEXT,
    
    PRIMARY KEY(MaLoi)
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;