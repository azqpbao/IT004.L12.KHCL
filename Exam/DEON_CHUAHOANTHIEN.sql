CREATE DATABASE CSDL

USE CSDL

CREATE TABLE MATHANG
(
	mahang NVARCHAR(10) PRIMARY KEY,
	tenhang NVARCHAR(50),
	soluong INT,
	donvitinh NVARCHAR(20),
	giahang MONEY
)


CREATE TABLE NHANVIEN
(
	manhanvien NVARCHAR(10) PRIMARY KEY,
	ho NVARCHAR(20),
	ten NVARCHAR(10),
	ngaysinh DATETIME,
	ngaylamviec DATETIME,
	diachi NVARCHAR(50),
	dienthoai NVARCHAR(20) 
)


CREATE TABLE KHACHHANG
(
	makhachhang NVARCHAR(10) PRIMARY KEY,
	tencongty NVARCHAR(50),
	diachi NVARCHAR(50),
	email NVARCHAR(30),
	dienthoai NVARCHAR(15)
)


CREATE TABLE HOADON
(
	sohoadon INT PRIMARY KEY,
	makhachhang NVARCHAR(10),
	manhanvien NVARCHAR(10),
	ngaydathang SMALLDATETIME,
	ngaygiaohang SMALLDATETIME,
	noigiaohang NVARCHAR(50)
)

ALTER TABLE HOADON
ADD CONSTRAINT FK_HD_KH FOREIGN KEY (makhachhang)
REFERENCES KHACHHANG (makhachhang)

ALTER TABLE HOADON
ADD CONSTRAINT FK_HD_NV FOREIGN KEY (manhanvien)
REFERENCES NHANVIEN (manhanvien)


CREATE TABLE CTHD
(
	sohoadon INT NOT NULL,
	mahang NVARCHAR(10) NOT NULL,
	giaban MONEY,
	soluong SMALLINT,
	giamgia MONEY
)

ALTER TABLE CTHD
ADD CONSTRAINT PK_CTHD_HD_MH PRIMARY KEY (sohoadon, mahang)


CREATE TRIGGER U_HD
ON HOADON
FOR UPDATE
AS
BEGIN
	DECLARE @NOIGIAOHANG NVARCHAR(50), @SOHD INT ,
			@DIACHI NVARCHAR(50), @MAKH NVARCHAR(10)

	SELECT @NOIGIAOHANG = noigiaohang, @SOHD = sohoadon, @MAKH = makhachhang
	from INSERTED I

	SELECT @DIACHI = diachi
	from KHACHHANG
	WHERE @MAKH = makhachhang

	if @SOHD <> NULL AND @MAKH <> NULL
		BEGIN
		UPDATE HOADON
		SET @NOIGIAOHANG = @DIACHI
		WHERE @MAKH = makhachhang
		rollback transaction
		end
	else 
		BEGIN
		UPDATE HOADON
		SET @NOIGIAOHANG = NULL
		end
END;
		
-------------------------------------
UPDATE HOADON
SET noigiaohang = (select diachi
					from KHACHHANG
					) 
where makhachhang = (select makhachhang
					from KHACHHANG
					) 
--------------------------------------
UPDATE HOADON
SET noigiaohang = NULL
WHERE makhachhang = NULL



ALTER TABLE HOADON
ADD CONSTRAINT CHEK_NGDH_NGGH CHECK (ngaygiaohang >= ngaydathang)


create trigger I_CTHD
ON CTHD
FOR INSERT
AS
BEGIN
	DECLARE @SOLUONG_CTHD INT, @SOLUONG_MH INT, @MAHANG NVARCHAR(10)

	SELECT @SOLUONG_CTHD = soluong , @MAHANG = mahang
	from inserted i

	select @SOLUONG_MH = soluong
	from MATHANG
	WHERE @MAHANG = mahang

	if @SOLUONG_MH >= @SOLUONG_CTHD
		BEGIN
		UPDATE MATHANG
		SET soluong = @SOLUONG_MH - @SOLUONG_CTHD
		WHERE @MAHANG = mahang
		rollback transaction
		end
	else
		begin
		print 'SOLUONG HANG HIEN CO KHONG DU'
		END
END



SELECT *
FROM KHACHHANG
WHERE diachi = 'Quan 1, Tp. HCM'


select *
from HOADON HD JOIN CTHD ON CTHD.sohoadon = HD.sohoadon
			JOIN MATHANG MH ON CTHD.mahang= MH.mahang
where tenhang= 'TU NHUA ALISA'



SELECT month(ngaydathang) THANG, (SUM(giaban*soluong)) DOANHSO
FROM CTHD JOIN HOADON HD ON HD.sohoadon = CTHD.sohoadon
WHERE YEAR(ngaydathang)  = 2019 
group by month(ngaydathang)


select NV.manhanvien, NV.ho, NV.ten
from HOADON H JOIN CTHD C ON H.sohoadon = C.sohoadon JOIN NHANVIEN NV ON H.manhanvien = NV.manhanvien
		JOIN (	SELECT manhanvien, COUNT(mahang) SL
				FROM HOADON HD JOIN CTHD ON HD.sohoadon = CTHD.sohoadon
				GROUP BY manhanvien
				) AS T ON NV.manhanvien = T.manhanvien
group by NV.manhanvien, NV.ho, NV.ten
having count(mahang) >= ALL (	SELECT COUNT(mahang) SL
							FROM HOADON D JOIN CTHD CT ON D.sohoadon = CT.sohoadon
							GROUP BY manhanvien
							)
