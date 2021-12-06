create database QUANLYBH
use QUANLYBH

--PHAN I
-- tao cac quan he va khai bao khoa chinh, khoa phu
create table KHACHHANG
(
	MAKH char(4) primary key,
	HOTEN varchar(40),
	Dchi varchar(50),
	SODT varchar(20),
	NGSINH smalldatetime,
	NGDK smalldatetime,
	DOANHSO money
)

create table NHANVIEN
( 
	MANV char(4) primary key,
	HOTEN varchar(40),
	SODT varchar(20),
	NGVL smalldatetime
)

create table SANPHAM
(
	MASP char(4) primary key,
	TENSP varchar(40),
	DVT varchar(20),
	NUOCSX varchar(40),
	GIA money
)

create table HOADON
(
	SOHD int primary key,
	NGHD smalldatetime,
	MAKH char(4),
	MANV char(4),
	TRIGIA money
)

create table CTHD 
(
	SOHD int not null,
	MASP char(4) not null,
	SL int
)
alter table CTHD 
add constraint PK_CTHD primary key (SOHD,MASP)

alter table HOADON
add constraint FK_HD_KH foreign key (MAKH)
references KHACHHANG (MAKH)

alter table HOADON
add constraint FK_HD_NV foreign key (MANV)
references NHANVIEN (MANV)

-- them vao thuoc tinh GHICHU co kieu du lieu varchar(2) cho quan he SANPHAM
alter table SANPHAM
add GHICHU varchar(20)

-- them vao thuoc tinh LOAKH co kieu du lieu tinyint cho quan he KHACHHANG
alter table KHACHHANG
add LOAIKH tinyint

-- sua kieu du lieu GHICHU trong quan he SANPHAM thanh varchar(20)
alter table SANPHAM
alter column GHICHU varchar(100)

-- xoa thuoc tinh GHICHU trong SANPHAM
alter table SANPHAM
drop column GHICHU 

-- lam the nao de thuoc tinh LOAIKH trog quan he KHACHHANG co the luu cac gia tri la "Vng lia", "Thuong xuyen","Vip:,....
alter table KHACHHANG
alter column LOAIKH varchar(50)

alter table KHACHHANG
add constraint check_LOAIKH check( LOAIKH in ('Vang lai', 'Thuong xuyen', 'Vip'))

-- Don vi tinh cua san pham chi co the la ('cay', 'hop', 'cai', 'quyen', 'chuc')
alter table SANPHAM
add constraint check_DVT check(DVT in ('cay', 'hop', 'cai', 'quyen', 'chuc'))

-- gia ban cua san pham tu 500 dong tro len
alter table SANPHAM
add constraint check_GIA check (GIA >= 500)

-- mois lan mua khach hang phai mua it nhat mot san pham
alter table CTHD
add constraint check_SL check (SL >= 1)

-- ngang khach hang dang ky la khach hang thanh vien phai lon hon ngay sinh ca nguoi do
alter table KHACHHANG
add constraint check_NGDK_NGSINH check (NGDK > NGSINH)

-- ngay mua hang cua mot khach hang thanh vien se lon hon hoac bang ngay khach hang do dang ki lam thanh vien
create trigger KH_NGHD_NGDL 
on KHACHHANG
after update
as 
	if update(NGDK)
	begin
		if (exists (select *
					from inserted i join HOADON hd on i.MAKH = hd.MAKH
					where i.NGDK > hd.NGHD
					)
			)
		begin 
			print 'Ngay mua hang phai lon hon hoac bang ngay dang ki cua khach hang do.'
			rollback transaction
		end
		else
		begin
			print 'Khach hang sua thanh cong'
		end
	end;

create trigger HD_NGHD_NGDK
on HOADON
after update, insert
as 
	if update(NGHD) or update(MAKH)
	begin 
		if (exists (select *
					from inserted i join KHACHHANG kh on i.MAKH = kh.MAKH
					where i.NGHD < kh.NGDK
					)
			)
		begin 
			print 'Ngay mua hang phai lon hon hoac bang ngay dang ky cua khach hang do'
			rollback transaction
		end
		else
		begin
			print 'Hoa don sua hoac them thanh cong'
		end
	end;


-- ngay ban hang cua mot nhan vien phai lon hon hoac bang ngay nhan vien do vao lam
create trigger NV_NGAHD_NGVL
on NHANVIEN
after update
as
	if update(NGVL)
	begin
		if (exists(select *
					from inserted i join HOADON hd on i.MANV = hd.MANV
					where i.NGVL > hd.NGHD
					)
			)
		begin
			print 'Ngay ban hag cua mot nhan vien phai lon hon hoac bang ngay vao lam cua nhan vien do'
			rollback transaction
		end
		else
		begin
			print 'Nhan vien sua thanh cong'
			rollback transaction
		end
	end;

create trigger HD_NGHD_NGVL
on HOADON
after update, insert
as 
	if update(NGHD) or update(MANV)
	begin
		if (exists(select *
					from inserted i join NHANVIEN nv on i.MANV = nv.MANV
					where nv.NGVL > i.NGHD
					)
			)
		begin 
			print 'Ngay ban hang cua mot nhan vien phai lon hon hoac bang ngay vao lam cua nhan  vien do'
			rollback transaction
		end
		else
		begin
			print 'Hoa don them hoac sua thanh cong'
		end
	end;

-- Moi hoa don phai co it nhat mot chi tiet hoa don
create trigger HD_SOHD_SOHD
on HOADON
for insert
as
	declare @SOHOADON int
	select @SOHOADON = SOHD
	from inserted i 
		--insert into CTHD (SOHD, MASP, SL)
		--values (@SOHOADON, 'None', 0)
	--print 'Them thanh cong voi CTHD mac dinh la MASP = "NONE" va SL  = 0)'
	
	if (not exists (select *
					from inserted i join CTHD cthd on i.SOHD = cthd.SOHD
					)
		)
	begin
		print 'Khong ton tai SOHD thuoc HOADON ma CTHD cung co'
		print 'Nen ta se tao mot SOHD moi voi MASP = "NONE" va SL = 1'
		insert into CTHD (SOHD, MASP, SL) values (@SOHOADON, 'None', 1)
		rollback transaction
	end
	else 
	begin
		print 'Them thanh cong'
	end

create trigger CTHD_SOHD_SOHD_d_u
on CTHD
after delete, update
as
	declare @SLHD int

	select @SLHD = count(CTHD.SOHD)
	from deleted d join CTHD  on CTHD.SOHD = d.SOHD join HOADON on HOADON.SOHD = CTHD.SOHD

	if @SLHD < 1
	begin
		PRINT 'Moi HOADON phao co it nhat 1 CTHD'
		rollback transaction
	end
	else
	begin
		print'Xoa CTHD thanh cong'
	end
	
-- TRIGIA cua moi HOADON la tong thanh tien cua SL*GIA cua cac CTHD do
create trigger HD_TRIGIA_THANHTIEN_i
on HOADON
for insert
as
	declare @TRIGIA money,
		@SL int, @GIA money,
		@SOHD char(4)
	select @TRIGIA = TRIGIA, @SOHD = SOHD
	from inserted i
	update HOADON
	set TRIGIA = 0
	where @SOHD = SOHD
	print 'Them thanh cong voi HOADON co TRIGIA = 0'


create trigger HD_TRIGIA_THANHTIEN_u
on HOADON
for update
as
	declare @SOHD char(4),
			@TRIGIA_new  money,
			@TRIGIA_old money

	select @TRIGIA_new =  TRIGIA , @SOHD = SOHD
	from inserted i 


	select @TRIGIA_old = sum(GIA * SL)
	from deleted d join CTHD on @SOHD = CTHD.SOHD join SANPHAM sp on sp.MASP = CTHD.MASP

	if @TRIGIA_new <> @TRIGIA_old
	begin
		update HOADON
		set TRIGIA = @TRIGIA_new
		where @SOHD = SOHD
		print 'Cap nhat HOADON co TRIGIA = SUM(GIA*SL) moi'
		rollback transaction
	end
	else 
	begin
		print 'Cap nhat thanh cong'
		rollback transaction
	end

create trigger CTHD_THANHTIEN_TRIGIA_i
on CTHD
for insert
as 
	declare @SOHD int, @MASP char(4), @NEW_SL int,
			@GIA money, @TRIGIA money, @NEW_TRIGIA money
	
	select @SOHD =SOHD,  @NEW_SL = SL, @GIA = GIA
	from inserted join SANPHAM sp on @MASP = sp.MASP

	update HOADON
	set TRIGIA =  TRIGIA + @NEW_SL*@GIA
	where @SOHD = SOHD
	print 'Them du lieu CTHD thanh cong'
	ROLLBACK TRANSACTION

create trigger CTHD_THANHTIEN_TRIGIA_u
on CTHD
for update
as
	declare @NEW_SOHD int, @NEW_SL int,  @NEW_GIA money,
			@OLD_SOHD int, @OLD_SL int, @OLD_GIA money

	select @NEW_SOHD = SOHD, @NEW_SL = SL, @NEW_GIA = GIA
	from inserted i, SANPHAM sp
	where  i.MASP = sp.MASP

	select @OLD_SOHD = SOHD, @OLD_SL = SL, @OLD_GIA = GIA
	from deleted d, SANPHAM sp
	where  d.MASP = sp.MASP

	if @NEW_SOHD = @OLD_SOHD
	begin
		update HOADON
		set TRIGIA = TRIGIA + @NEW_GIA * @NEW_SL - @OLD_SL * @OLD_GIA
		where HOADON.SOHD = @NEW_SOHD
		print 'Cap nhat du lieu CTHD thanh cong'
		ROLLBACK TRANSACTION
	end;


create trigger CTHD_THANHTIEN_TRIGIA_d
on CTHD
for delete
as
	declare @SOHD int, @SL int, @MASP char(4),
			 @GIA money

	select @SOHD = SOHD, @SL = SL, @GIA = GIA
	from deleted d join SANPHAM sp on @MASP = sp.MASP

	update HOADON
	set TRIGIA = TRIGIA - @SL*@GIA
	where @SOHD = SOHD
	print 'Xoa du lieu CTHD thanh cong'

-- Doanh so cua mot khach hang la tong tri gia cac hoa don ma thanh vien do da mua
create trigger KH_DOANHSO_TRIGIA
on KHACHHANG
for insert
as
	declare @DOANHSO_KH money,
			@MAKHACHHANG char(4)
	select @MAKHACHHANG = MAKH
	from inserted i
	update KHACHHANG
	set DOANHSO = 0
	where @MAKHACHHANG = MAKH
	print 'Them thanh cong voi KHACHHANG co DOANHSO = 0'


create trigger KH_DOANHSO_TRIGIA_u
on KHACHHANG
for update
as
	declare @DOANHSO_cu money,
			@MAKHACHHANG char(4)

	select @MAKHACHHANG = MAKH
	from inserted i
	
	select @DOANHSO_cu = sum(TRIGIA)
	from deleted d, HOADON
	where d.MAKH = HOADON.MAKH

	update KHACHHANG
	set DOANHSO = @DOANHSO_cu
	where @MAKHACHHANG = MAKH
	print 'Sua thanh cong voi KHACHHANG co DOANHSO = @DOANHSO_cu'

create trigger HD_TRIGIA_DOANHSO_i
on HOADON
for insert
as
	declare @MAKHACHHANG char(4),
		@TRIGIA money
	
	select @MAKHACHHANG = MAKH, @TRIGIA = TRIGIA
	from inserted i

	update KHACHHANG
	set DOANHSO = DOANHSO + @TRIGIA
	where @MAKHACHHANG = MAKH
	print 'Tang DOANHSO cua KHACHHANG khi them khach hang moi vao HOADON'


create trigger HD_TRIGIA_DOANHSO_d
on HOADON
for delete
as
	declare @MAKHACHHANG char(4),
			@TRIGIA money

	select @MAKHACHHANG = MAKH
	from deleted d

	update KHACHHANG
	set DOANHSO = DOANHSO - @TRIGIA
	where @MAKHACHHANG = MAKH
	print 'Giam DOANHSO cua KHACHHANG khi xoamot khach hang trong HOADON'

create trigger HD_TRIGIA_DOANHSO_u
on HOADON
for update
as 
	declare @MAKH char(4),
		@TRIGIA_moi money,
		@TRIGIA_cu money

	select @TRIGIA_moi = TRIGIA
	from inserted i

	select @TRIGIA_cu = TRIGIA, @MAKH = MAKH 
	from deleted d

	update KHACHHANG
	set DOANHSO = DOANHSO - @TRIGIA_cu + @TRIGIA_moi
	where @MAKH = MAKH
	print 'Da sua DOANHSO cua KHACHHANG  trong HOADON'






-- PHAN II
-- nhap du leu cho cac quan he
set dateformat dmy
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH01', 'Nguyen Van A', '731, Tran Hung Dao, Q5, TPHCM', '08823451', '22/10/1960', 13060000, '22/07/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH02', 'Tran Ngoc Han', '23/5 Nguyen Trai, Q5, TpHCM', '0908256478', '03/04/1974', 280000, '30/07/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH03', 'Tran Ngoc Linh', '45 Nguyen Canh Chan, Q1, TpHCM', '0938776266', '12/06/1980', 3860000, '05/08/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH04', 'Tran Minh Long', '50/34 Le Dai hanh, Q10, TpHCM', '0917325476', '09/03/1965', 250000, '02/10/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH05', 'Le Nhat Minh', '34 Truong Dinh, Q3, TPHCM', '08246108', '10/03/1960', 21000, '28/10/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH06', 'Le Hoai Thuong', '227 Nguyen Van Cu, Q5, TpHCM', '08631738', '31/12/1981', 915000, '24/11/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH07', 'Nguyen Van Tam', '32/3 Tran Binh Trong, Q5, TpHCM', '0916783565', '06/04/1971', 12500, '01/12/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH08', 'Phan Thi Thanh', '45/2 An Duong Vuong, Q5, TPHCM', '0938435756', '10/01/1971', 365000, '13/12/2006')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH09', 'Le Ha Vinh', '873 Le Hong Phong, Q5, TPHCM', '08654763', '03/09/1979', 70000, '14/01/2007')
INSERT INTO KHACHHANG (MAKH, HOTEN, DCHI, SODT, NGSINH, DOANHSO, NGDK) VALUES ('KH10', 'Ha Duy Lap', '34/34B Nguyen Trai, Q1, TPHCM', '08768904', '02/05/1963', 67500, '16/01/2007')
select * from KHACHHANG

set dateformat dmy
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV01', 'Nguyen Nhu Nhut', '0927345678', '13/4/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV02', 'Le Thi Phi Yen', '0987567390', '21/4/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV03', 'Nguyen Van B', '0997047382', '27/4/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV04', 'Ngo Thanh Tuan', '0913758498', '24/6/2006')
INSERT INTO NHANVIEN (MANV, HOTEN, SODT, NGVL) VALUES ('NV05', 'Nguyen Thi Truc Thanh', '0918590387', '20/7/2006')
select * from NHANVIEN

INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC01', 'But Chi', 'cay', 'Singapore', 3000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC02', 'But Chi', 'cay', 'Singapore', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC03', 'But Chi', 'cay', 'Viet Nam', 3500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BC04', 'But Chi', 'hop', 'Viet Nam', 30000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BB01', 'But bi', 'cay', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BB02', 'But bi', 'cay', 'Trung Quoc', 7000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('BB03', 'But bi', 'hop', 'Thai Lan', 100000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV01', 'Tap 100 giay mong', 'quyen', 'Trung Quoc', 2500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV02', 'Tap 200 giay mong', 'quyen', 'Trung Quoc', 4500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV03', 'Tap 100 giay tot', 'quyen', 'Viet Nam', 3000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV04', 'Tap 200 giay tot', 'quyen', 'Viet Nam', 5500)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV05', 'Tap 100 trang', 'chuc', 'Viet Nam', 23000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV06', 'Tap 200 trang', 'chuc', 'Viet Nam', 53000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('TV07', 'Tap 100 trang', 'chuc', 'Viet Nam', 34000)
update SANPHAM
set NUOCSX = 'Trung Quoc'
where MASP = 'TV07'
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST01', 'So tay 500 trang', 'quyen', 'Viet Nam', 40000)
update SANPHAM
set NUOCSX = 'Trung Quoc'
where MASP = 'ST01'
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST02', 'So tay loai 1', 'quyen', 'Viet Nam', 55000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST03', 'So tay loai 2', 'quyen', 'Viet Nam', 51000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST04', 'So tay', 'quyen', 'Thai Lan', 55000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST05', 'So tay mong', 'quyen', 'Thai Lan', 20000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST06', 'Phan viet bang', 'hop', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST07', 'Phan khong bui', 'hop', 'Viet Nam', 5000)
update SANPHAM
set GIA = 7000
where MASP = 'ST07'
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST08', 'Bong bang', 'cai', 'Viet Nam', 1000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST09', 'But long', 'cay', 'Viet Nam', 5000)
INSERT INTO SANPHAM (MASP, TENSP, DVT, NUOCSX, GIA) VALUES ('ST10', 'But long', 'cay', 'Trung Quoc', 7000)
select * from SANPHAM

set dateformat dmy
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1001, '23/07/2006', 'KH01', 'NV01', 320000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1002, '12/08/2006', 'KH01', 'NV02', 840000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1003, '23/06/2006', 'KH02', 'NV01', 100000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1004, '01/09/2006', 'KH02', 'NV01', 180000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1005, '20/10/2006', 'KH01', 'NV02', 3800000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1006, '16/10/2006', 'KH01', 'NV03', 2430000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1007, '28/10/2006', 'KH03', 'NV03', 510000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1008, '28/10/2006', 'KH01', 'NV03', 440000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1009, '28/10/2006', 'KH03', 'NV04', 200000)
update HOADON
set TRIGIA = 200000
where SOHD = 1009
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1010, '01/11/2006', 'KH01', 'NV01', 5200000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1011, '04/11/2006', 'KH04', 'NV03', 250000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1012, '30/11/2006', 'KH05', 'NV03', 21000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1013, '12/12/2006', 'KH06', 'NV01', 5000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1014, '31/12/2006', 'KH03', 'NV02', 3150000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1015, '01/01/2007', 'KH06', 'NV01', 910000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1016, '01/01/2007', 'KH07', 'NV02', 12500)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1017, '02/01/2007', 'KH08', 'NV03', 35000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1018, '13/01/2007', 'KH08', 'NV03', 330000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1019, '13/01/2007', 'KH01', 'NV03', 30000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1020, '14/01/2007', 'KH09', 'NV04', 70000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1021, '16/01/2007', 'KH10', 'NV04', 67500)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1022, '16/01/2007', Null, 'NV03', 7000)
INSERT INTO HOADON (SOHD, NGHD, MAKH, MANV, TRIGIA) VALUES (1023, '17/01/2007', Null, 'NV01', 330000)
select * from HOADON

INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'ST01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'BC01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'BC02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'ST08', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BC04', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BB01', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1002, 'BB02', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1003, 'BB03', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV01', 20)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV03', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1004, 'TV04', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1005, 'TV05', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1005, 'TV06', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1001, 'TV07', 20)
update CTHD
set SOHD = 1006
where MASP = 'TV07' and SL = 20
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1006, 'ST01', 30)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1006, 'ST02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1007, 'ST03', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1008, 'ST04', 8)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1009, 'ST05', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'TV07', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'ST07', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'ST08', 100)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'ST04', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1010, 'TV03', 100)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1011, 'ST06', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1012, 'ST07', 3)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1013, 'ST08', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BC02', 80)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BB02', 100)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BC04', 60)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1014, 'BB01', 50)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1015, 'BB02', 30)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1015, 'BB03', 7)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1016, 'TV01', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1017, 'TV02', 1)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1017, 'TV03', 1)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1017, 'TV04', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1018, 'ST04', 6)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1019, 'ST05', 1)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1019, 'ST06', 2)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1020, 'ST07', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1021, 'ST08', 5)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1021, 'TV01', 7)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1021, 'TV02', 10)
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1022, 'TV02', 10)
update CTHD
set MASP = 'ST07'
where SOHD = 1022 and SL = 10
update CTHD
set SL = 1
where SOHD = 1022 and MASP = 'ST07'
INSERT INTO CTHD (SOHD, MASP, SL) VALUES (1023, 'ST04', 6)
select * from CTHD

-- tao quan he SANPHAM1 chua toan bo du lieu cua quan he SANPHAM . Tao quan he KHACHHANG chua toan bo du lieu cua quan he KHACHHANG
select *
into SANPHAM1
from SANPHAM

select *
into KHACHHANG1
from KHACHHANG

-- cap nhat gia tang 5% doi voi nhung san pham do Thai Lan san xuat cho quan he SANPHAM1
update SANPHAM1
set GIA = GIA * 1.05
where NUOCSX = 'Thai Lan' 
select * from SANPHAM
select * from SANPHAM1

-- Cap nhat gia giam 5% doi voi nhung san pham do Trung Quoc san xuat co gia tu 10.000 tro xuong cho quan he SANPHAM1
update SANPHAM1
set GIA = GIA * 0.95
where NUOCSX = 'Trung Quoc' and GIA <= 10000 
select * from SANPHAM
select * from SANPHAM1

-- cap nhat LOAIKH la 'Vip' doi voi khach hang dang ky thanh vien truoc ngay 1/1/2007 co doanh so tu 10.000.000 tro len hoac khach hang dang ki thanh vien tu 1/1/2007 tro ve sau co doanh so tu 2.000.000 tro len cho quan he KHACHHANG1
update KHACHHANG1
set LOAIKH = 'Vip'
where (NGDK < '1/1/2007' and DOANHSO >= 10000000) or (NGDK >='1/1/2007' and DOANHSO >= 2000000)
select * from KHACHHANG
select * from KHACHHANG1

-- PHAN III
-- in ra danh sach cac san pham (maso, tensp) do 'Trung Quoc san xuat
select MASP, TENSP
from SANPHAM
where NUOCSX = 'Trung Quoc'

-- in ra danh sach cac san pham (masp, tensp) co don vi tinh la 'cay', 'quyen'
select MASP, TENSP
from SANPHAM
where DVT in ('cay', 'quyen')

-- in ra danh sach cac san pham (masp, tensp) co ma san pham bat dau tu 'B' va ket thuc la '01'
select MASP, TENSP 
from SANPHAM
where MASP like 'B%01'

-- in ra dnh sach cac san pham (masp, tensp) do 'Trung Quoc'  san xuat co gia tu 30000 den 40000
select MASP, TENSP
from SANPHAM
where NUOCSX = 'Trung Quoc' and GIA >= 30000 and GIA <= 40000

-- in ra danh sach cac san pham (masp, tensp) do 'Trung Quoc' hoac 'Thai Lan' san xuat  co gia tu 30000 den 40000
select MASP, TENSP
from SANPHAM
where NUOCSX in ('Trung Quoc', 'Thai Lan') and GIA >= 30000 and GIA <= 40000

-- in ra cac so hoa don va tri gia hoa don ban a trong ngay '1/1/2007' va '2/1/2007'
set dateformat dmy
select SOHD, TRIGIA
from HOADON
where NGHD  = '1/1/2007' or NGHD  ='02/01/2007'

-- in ra cac so hoa don, tri gia hoa don trong thang '1/2007' va sap xep tang dan theo ngay va co gia tri tri gia giam dan
select SOHD, TRIGIA
from HOADON
where MONTH(NGHD)= 1 and YEAR(NGHD) = 2007
order by DAY(NGHD) asc , TRIGIA desc

-- in ra danh sach khach hang (MAKH, HOTEN) da mua hang trong ngay '1/1/2007'
select kh.MAKH, HOTEN
from KHACHHANG kh join HOADON hd on kh.MAKH = hd.MAKH
where NGHD = '1/1/2007'

-- in ra SOHD, TRIGIA do nhan vien co ten 'Nguyen Van B' lap trong ngay '28/10/2006'
select SOHD, TRIGIA
from HOADON hd join NHANVIEN nv on hd.MANV = nv.MANV
where HOTEN = 'Nguyen Van B' and NGHD = '28/10/2006'

-- in ra danh sach MASP, TENSP duoc khach hang co ten 'Nguyen Van A' mua trong thang 10 nam 2006
select sp.MASP, TENSP
from SANPHAM sp join CTHD on CTHD.MASP = sp.MASP join HOADON hd on hd.SOHD = CTHD.SOHD join KHACHHANG kh on kh.MAKH = hd.MAKH
where HOTEN = 'Nguyen Van A' and MONTH(NGHD) = 10 and YEAR(NGHD) = 2006

-- tim SOHD da mua san pham co MASP la 'BB01' hoac 'BB02'
select distinct SOHD
from CTHD
where MASP  in ('BB01', 'BB02')

-- tim SOHD da mua san pham co MASP la 'BB01' hoac 'BB02' va moi san pham co SL tu 10 den 20
select distinct SOHD
from CTHD
where MASP  in ('BB01', 'BB02') and SL between 10 and 20



-- tim SOHD da mua san pham co MASP la 'BB01' hoac 'BB02' va moi san pham co SL tu 10 den 20
select distinct SOHD
from CTHD
where SL between 10 and 20 and MASP = 'BB01' and SOHD in (select SOHD
														from CTHD
														where MASP ='BB02'
														)

-- in ra danh sach (MASP, TENSP) do 'Trung Quoc' san xuat hoac cac san pham duoc ban ra trong ngy '1/1/2007'
select distinct sp.MASP, TENSP
from SANPHAM sp					-- in : masp in ( select masp from where ...)
where NUOCSX = 'Trung Quoc' or exists ( select *
										from CTHD join HOADON hd on hd.SOHD = CTHD.SOHD
										where  NGHD = '1/1/2007' and sp.MASP = CTHD.MASP
										)


-- in ra danh sach (MASP, TENSP) khong ban duoc
select distinct sp.MASP, TENSP
from SANPHAM sp
where not exists (select *
					from CTHD
					where CTHD.MASP = sp.MASP
					)

-- in ra danh sach (MASP, TENSP) khong ban duoc trong nam 2006
select distinct sp.MASP, TENSP
from SANPHAM sp 
where not exists (select *
				from CTHD join HOADON hd on hd.SOHD = CTHD.SOHD
				where CTHD.MASP = sp.MASP and  YEAR(NGHD) = 2006
				)

-- in ra danh sach (MASP, TENSP) do 'Trung Quoc' san xuat va khong ban duoc trong nam 2006
select distinct sp.MASP, TENSP
from SANPHAM sp 
where NUOCSX ='Trung Quoc' and not exists (select *
				from CTHD join HOADON hd on hd.SOHD = CTHD.SOHD
				where CTHD.MASP = sp.MASP and  YEAR(NGHD) = 2006
				)

-- tim SOHD da mua tat ca cac san pham do 'Singapore' san xuat
-- SOHD khong co SP nao k dc mua
select SOHD
from HOADON hd
where not exists ( select *
					from SANPHAM sp
					where NUOCSX = 'Singapore' and not exists ( select *
																from CTHD
																where CTHD.MASP = sp.MASP and CTHD.SOHD = hd.SOHD
																)
				)

-- tim SOHD trong nam 2006 da mua it nhat tat ca cac san pham do Singapore san xuat
select SOHD
from HOADON hd
where YEAR(NGHD) = 2006 and not exists ( select *
					from SANPHAM sp
					where NUOCSX = 'Singapore' and not exists ( select *
																from CTHD
																where CTHD.MASP = sp.MASP and CTHD.SOHD = hd.SOHD
																)
				)

-- Co bao nhieu hoa don khong phai khach hang thanh vien dang ky
select count(*) SLHOADON_KHONGCOPHAIKHTV
from HOADON
where MAKH is NULL

-- co bao nhieu san pham khac nhau duoc ban trong nam 2006
select count(distinct MASP) SL_SANPHAM
from CTHD join HOADON hd on hd.SOHD = CTHD.SOHD
where YEAR(NGHD) = 2006

-- cho biet gia tri hoa don cao nhat va thap nhat
select max(TRIGIA) max_TRIGIA, min(TRIGIA) min_TRIGIA
from HOADON

-- TRIGIA tb cuat tat ca cac hoa don duoc ban r trong nam 2006
select avg(TRIGIA) avg_TRIGIA
from HOADON
where YEAR(NGHD) = 2006

-- Tinh DOANHTHU ban hang trong nam 2006
select sum(TRIGIA) DOANHTHU
from HOADON
where YEAR(NGHD) = 2006

-- tim hoa don co tri gia cao nhat trong nam 2006
select max(TRIGIA) max_TRIGIA, min(TRIGIA) min_TRIGIA
from HOADON
where YEAR(NGHD) = 2006

-- tim ho ten khach hang da mua hoa don co gia tri cao nhat nam 2006
select kh.MAKH, HOTEN
from KHACHHANG kh join HOADON hd on kh.MAKH = hd.MAKH
where YEAR(NGHD) = 2006 and TRIGIA =(	select max(TRIGIA)
										from HOADON
										)

-- in ra danh sach 3 khach hang co doanh so cao nhat
select MAKH, HOTEN
from KHACHHANG
where DOANHSO in (	select top 3 DOANHSO
					from KHACHHANG
					order by DOANHSO desc
					)

-- in ra danh sach MASP, TENSP co gia ban bang 1 trong 3 muc gia cao nhat
select MASP, TENSP
from SANPHAM sp 
where GIA in (select distinct top 3  GIA
				from SANPHAM 
				order by GIA desc
				)
-- in ra danh sach (MASP, TENSP) do 'Thai Lan' san xuat co gia bang 1 trong 3 muc gia cao nhat cua tat ca cac san pham
select MASP, TENSP
from SANPHAM sp 
where NUOCSX = 'Thai Lan' and GIA in (select distinct top 3  GIA
				from SANPHAM 
				order by GIA desc
				)

-- in ra danh sach MASP, TENSP do 'Trung Quoc' san xuar co gia bang 1 trog 3 muc gia cao nhat cua cac sp do 'Trung Quoc' san xuat
select MASP, TENSP
from SANPHAM sp 
where NUOCSX = 'Trung Quoc' and GIA in (select distinct top 3  GIA
										from SANPHAM 
										where NUOCSX = 'Trung Quoc'
										order by GIA desc
											)

-- in ra danh sach 3 khach hag co doanh so cao nhat( sap xep theo thu hang)
select *
from KHACHHANG
where DOANHSO in (select top 3 DOANHSO
					from KHACHHANG
					order by DOANHSO desc
					)

-- tinh tong so sp do 'Trung Quoc' san xuat
select count(MASP) count_sp_TQ
from SANPHAM
where NUOCSX = 'Trung Quoc'

-- tinh tong so san pham cua tung nuoc sx
select NUOCSX, count(MASP) count_sp
from SANPHAM
group by NUOCSX 

-- voi tung nuoc san xuat, tim gia ban cao nhat , trung binh cua cac san pham
select NUOCSX, max(Gia) max_Gia, avg(Gia) avg_Gia
from SANPHAM
group by NUOCSX 

-- tinh doanh thu ban hang moi ngay
select NGHD, sum(TRIGIA)DOANHTHU
from HOADON
group by NGHD

-- tinh tong so luong cua tung san pham ban ra trong thang 10/2006
select MASP, sum(SL) Tong_SL
from CTHD join HOADON hd on CTHD.SOHD = hd.SOHD
where MONTH(NGHD) = 10 and YEAR(NGHD) = 2006
group by MASP

-- tim doanh thu ban hang cua tung thang trong nam 2006
select MONTH(NGHD) THANG, sum(TRIGIA) DOANHTHU
from HOADON
group by MONTH(NGHD)

-- tim hoa don co mua it nhat 4 sp khac nhau
select SOHD, count(MASP) COUNT_SP
from CTHD
group by SOHD
having count(MASP) >= 4

-- tim hoa don co mua 3 sp do 'Viet Nam' san xuat (3 san pham khac nhau)
select SOHD 
from CTHD join SANPHAM sp on sp.MASP = CTHD.MASP
where NUOCSX = 'Viet Nam'
group by SOHD 
having count (sp.MASP) = 3

-- tim khach hang (MAKH, HOTEN)  co so lan mua hang nhieu nhat
select kh.MAKH, HOTEN
from KHACHHANG kh join HOADOn hd on hd.MAKH = kh.MAKH
group by  kh.MAKH

-- Thang may trong nam 2006, doanh so ban hang cao nhat
select MONTH(NGHD) THANG, sum(TRIGIA) DOANHTHU
from HOADON
where YEAR(NGHD) =2006 
group by MONTH(NGHD)
having sum(TRIGIA) >= all (select sum(TRIGIA)
							from HOADON
							where YEAR(NGHD) =2006 
							group by MONTH(NGHD)
							)

-- tim san pham MASP, TENSP co tong so luong ban ra thap nhat trong nam 2006
select sp.MASP, TENSP 
from SANPHAM sp join CTHD cthd on cthd.MASP = sp.MASP join HOADON hd on hd.SOHD = cthd.SOHD
where YEAR(NGHD) = 2006 
group by sp.MASP, TENSP 
having sum(SL) <= all (select sum(SL)
						from CTHD join HOADON on HOADON.SOHD = CTHD.SOHD
						where YEAR(NGHD) = 2006 
						group by MASP
						)

-- Moi nuoc sx tim san pham MASP TENSP co gia ban cao nhat
select MASP, TENSP
from SANPHAM a
where GIA >= all (select GIA
			from SANPHAM b
			where a.NUOCSX = b.NUOCSX
			)
group by NUOCSX, MASP, TENSP

-- Tim NUOCSX san xuat it nhat 3 san pham co gia ban khac nhau
select NUOCSX
from SANPHAM
group by NUOCSX
having count(distinct GIA) >= 3

-- trong 10 khach hang co doanh so cao nhat , tim khach hang co so lan mua hag nhieu nhat
select kh.MAKH, kh.HOTEN
from KHACHHANG kh join ( select top 10 *
						from KHACHHANG
						order by DOANHSO desc
						) as j on kh.MAKH = j.MAKH join HOADON hd on hd.MAKH = j.MAKH
group by kh.MAKH, kh.HOTEN
having count(SOHD) >= all (select count(SOHD)
							from HOADON hd1 join (select top 10 *
												from KHACHHANG 
												order by DOANHSO desc
												) as kh1 on kh1.MAKH = hd1.MAKH
							group by kh1.MAKH
							)
