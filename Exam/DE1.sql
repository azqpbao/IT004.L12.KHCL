CREATE DATABASE DE1

USE DE1

CREATE TABLE TACGIA
(
	MaTG CHAR(5) PRIMARY KEY,
	HoTen VARCHAR(20),
	DiaChi VARCHAR(50),
	NgSinh SMALLDATETIME,
	SoDT VARCHAR(15)
)

CREATE TABLE SACH
(
	MaSach CHAR(5) PRIMARY KEY,
	TenSach VARCHAR(25),
	TheLoai VARCHAR(25)
)

CREATE TABLE TACGIA_SACH
(
	MaTG CHAR(5) NOT NULL,
	MaSach CHAR(5) NOT NULL
)

ALTER TABLE TACGIA_SACH
ADD CONSTRAINT PK_TGS_TG_S PRIMARY KEY (MATG, MASACH)

CREATE TABLE PHATHANH
(
	MaPH CHAR(5) PRIMARY KEY,
	MaSach CHAR(5),
	NgayPH SMALLDATETIME,
	SoLuong INT,
	NhaXuatBan VARCHAR(20)
)

ALTER TABLE PHATHANH
ADD CONSTRAINT FK_PH_S FOREIGN KEY (MaSach)
REFERENCES SACH (MaSach)


CREATE TRIGGER U_TG_PH
ON TACGIA
FOR UPDATE
AS
BEGIN
	IF (EXISTS( SELECT *
				FROM INSERTED I JOIN TACGIA_SACH TGS ON TGS.MaTG = I.MaTG 
						JOIN PHATHANH PH ON PH.MaSach = TGS.MaSach
				WHERE NgayPH <= NgSinh
				)
		)
		BEGIN 
		PRINT 'NgayPH > NgSinh CUA TACGIA'
		ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN 
		PRINT 'SUA THANH CONG'
		END
END;

CREATE TRIGGER I_U_PH_TG
ON PHATHANH
FOR INSERT, UPDATE
AS
BEGIN
	IF (EXISTS( SELECT *
				FROM INSERTED I JOIN TACGIA_SACH TGS ON I.MaSach = TGS.MaSach
						JOIN TACGIA TG ON  TGS.MaTG = TG.MaTG 
				WHERE NgayPH <= NgSinh
				)
		)
		BEGIN 
		PRINT 'NgayPH > NgSinh CUA TACGIA'
		ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN 
		PRINT 'SUA THANH CONG'
		END
END;



CREATE TRIGGER U_S_PH
ON SACH
FOR UPDATE
AS 
BEGIN
	IF ( EXISTS (	SELECT *
					FROM INSERTED I JOIN PHATHANH PH ON I.MaSach = PH.MaSach
					WHERE (TheLoai = 'Giao khoa' and NhaXuatBan <> 'Giao duc') or (TheLoai <> 'Giao khoa' and NhaXuatBan = 'Giao duc')
				)
		)
		begin 
		print 'SACH THUOC THELOAI GIAOKHOA CHI DO NXB GIAODUC PHATHANH'
		ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
		PRINT 'SUA THANH CONG'
		END
END;

CREATE TRIGGER I_U_PH_S
ON SACH
FOR UPDATE, INSERT
AS 
BEGIN
	IF ( EXISTS (	SELECT *
					FROM INSERTED I JOIN SACH S ON I.MaSach = S.MaSach
					WHERE (TheLoai = 'Giao khoa' and NhaXuatBan <> 'Giao duc') or (TheLoai <> 'Giao khoa' and NhaXuatBan = 'Giao duc')
				)
		)
		begin 
		print 'SACH THUOC THELOAI GIAOKHOA CHI DO NXB GIAODUC PHATHANH'
		ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
		PRINT 'SUA THANH CONG'
		END
END;


SELECT TG.MaTG, HoTen, SoDT
from TACGIA TG JOIN TACGIA_SACH TGS ON TGS.MaTG = TG.MaTG
		JOIN SACH S ON S.MaSach = TGS.MaSach
		join PHATHANH PH ON PH.MaSach = S.MaSach
WHERE TheLoai = 'Van hoc' and NhaXuatBan = 'Tre'



select MaPH, PH.MaSach, NgayPh, SoLuong, NhaXuatBan
from PHATHANH PH JOIN (SELECT MaSach , count(distinct TheLoai) SoTL
						from SACH
						group by MaSach) as T on ph.MaSach = t.MaSach
where SoTL >= all (		select count(distinct TheLoai) 
						from SACH
						group by MaSach
					)



select TG.MaTG, HoTen
from TACGIA TG JOIN TACGIA_SACH TGS ON TG.MaTG = TGS.MaTG 
		JOIN SACH S ON S.MaSach = TGS.MaSach
		JOIN PHATHANH PH ON PH.MaSach = S.MaSach
GROUP BY NhaXuatBan , TG.MaTG, HoTen
HAVING COUNT(S.MaSach) >= all (select COUNT(MaSach)
							from PHATHANH
							group by NhaXuatBan 
							)



