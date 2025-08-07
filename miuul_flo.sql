--1. tabloyu görüntüle
select * from flo_data

-- 2. Kaç farklı müşterinin alışveriş yaptığını gösterecek sorgu
select distinct count(master_id) from flo_data

--3. Toplam yapılan alışveriş sayısı ve ciroyu getirecek sorgu
--online alisveris
select sum(order_num_total_ever_online) as toplam_alisveris_sayisi,
		sum(customer_value_total_ever_online) as ciro
		from flo_data
--offline alisveris
select sum(order_num_total_ever_offline) as toplam_alisveris_sayisi, 
		sum(customer_value_total_ever_offline) as ciro
		from flo_data
--toplam alisveris sonucu
select sum(order_num_total_ever_online+order_num_total_ever_offline) as toplam_alisveris_sayisi, 
		sum(customer_value_total_ever_online+customer_value_total_ever_offline) as ciro
		from flo_data

--4. Alışveriş başına ortalama ciroyu getirecek sorgu

select sum(customer_value_total_ever_online+customer_value_total_ever_offline) /
		sum(order_num_total_ever_online+order_num_total_ever_offline) 
		from flo_data

--5. En son alışveriş yapılan kanal üzerinden yapılan alışverişlerin toplam ciro ve alışveriş sayılarını getirecek sorgu
select last_order_channel,
		sum(customer_value_total_ever_online+customer_value_total_ever_offline) as ciro,
		sum(order_num_total_ever_online+order_num_total_ever_offline) as adet 
		from flo_data
		group by last_order_channel

--6. Store type kırılımında elde edilen toplam ciroyu getiren sorguyu yazınız. 
select store_type ,
		sum(customer_value_total_ever_online+customer_value_total_ever_offline)
		from flo_data
		group by store_type

--7. Yıl kırılımında alışveriş sayılarını getirecek sorguyu yazınız (Yıl olarak müşterinin ilk alışveriş tarihi yılını baz al)
select extract(year from first_order_date) as years,
		sum(order_num_total_ever_online+order_num_total_ever_offline)
		from flo_data
		group by years
		order by years desc

-- 8. En son alışveriş yapılan kanal kırılımında alışveriş başına ortalama ciroyu hesaplayacak sorgu
select last_order_channel ,
		sum(customer_value_total_ever_online+customer_value_total_ever_offline) /
		sum(order_num_total_ever_online+order_num_total_ever_offline) 
		from flo_data
		group by last_order_channel

-- 9. Son 12 ayda en çok ilgi gören kategoriyi getiren sorgu

with son_siparis_tarihi as(
	select max(last_order_date) as son_tarih
	from flo_data
)

select 
		interested_in_categories_12, 
		sum(order_num_total_ever_online+order_num_total_ever_offline) as siparis_adedi
		from flo_data --,son_siparis_tarihi
		cross join son_siparis_tarihi
		where age(son_siparis_tarihi.son_tarih::date, last_order_date::date) < INTERVAL '1 year'  --1 yıl farkı alınır
		group by interested_in_categories_12
		order by siparis_adedi desc


-- 10. En çok tercih edilen store_type bilgisini getiren sorgu

select store_type,
		--tablodaki kategori başına siparişlerin toplamı
		sum(order_num_total_ever_online+order_num_total_ever_offline) as toplam_siparis 
		from flo_data
		group by store_type
		order by toplam_siparis desc
		limit 1

--------------------------------------------
select store_type,
		--tabloda yer alan kategori sayısı
		count(*) frekans  
		from flo_data
		group by store_type
		order by frekans desc
		limit 1

		
--11. En son alışveriş yapılan kanal bazında, en çok ilgi gören kategoriyi ve bu kategoriden ne kadarlık alışveriş yapıldığını getiren sorgu

WITH category_totals AS (
    SELECT
        last_order_channel,
        interested_in_categories_12 AS kategori,
        SUM(order_num_total_ever_online + order_num_total_ever_offline) AS alisveris_sayisi,
        ROW_NUMBER() OVER (
            PARTITION BY last_order_channel 
            ORDER BY SUM(order_num_total_ever_online + order_num_total_ever_offline) DESC
        ) AS rn
    FROM flo_data
    GROUP BY last_order_channel, interested_in_categories_12
)
SELECT
    last_order_channel,
    kategori,
    alisveris_sayisi
FROM category_totals
WHERE rn = 1;


-- 12. En çok alışveriş yapan kişinin ID’ sini getiren sorgu
select 	master_id,
		sum(order_num_total_ever_online+order_num_total_ever_offline) as  adet
		from flo_data
		group by master_id
		order by adet desc
		limit 1

--13. En çok alışveriş yapan kişinin alışveriş başına ortalama cirosunu ve alışveriş yapma gün ortalamasını (alışveriş sıklığını) getiren sorgu 

select 	master_id ,
		sum(customer_value_total_ever_online+customer_value_total_ever_offline) /
		sum(order_num_total_ever_online+order_num_total_ever_offline) as ortalama_ciro,
		(last_order_date - first_order_date)/(order_num_total_ever_online+order_num_total_ever_offline) as alisveris_frekansi_gun
		from flo_data
		group by master_id
		order by sum(order_num_total_ever_online+order_num_total_ever_offline) desc


--14. En çok alışveriş yapan (ciro bazında) ilk 100 kişinin alışveriş yapma gün ortalamasını (alışveriş sıklığını) getiren sorgu

select 	master_id ,
		ROUND(
        (last_order_date - first_order_date) / 
        SUM(order_num_total_ever_online + order_num_total_ever_offline)::numeric,1) AS alisveris_frekansi_gun,
		sum(order_num_total_ever_online+order_num_total_ever_offline) as toplam_alisveris_sayisi, 
		sum(customer_value_total_ever_online+customer_value_total_ever_offline) as ciro
		from flo_data
		group by master_id
		order by sum(customer_value_total_ever_online+customer_value_total_ever_offline)  desc
		limit 100

--15. En son alışveriş yapılan kanal (last_order_channel) kırılımında en çok alışveriş yapan müşteriyi getiren sorguyu yazınız. 

with kategori_ayrımı as(
	select
		last_order_channel,
		master_id,
		sum(order_num_total_ever_online + order_num_total_ever_offline) as alisveris_sayisi,
		row_number() over(
			PARTITION BY last_order_channel
			order by sum(order_num_total_ever_online + order_num_total_ever_offline) desc
		) as kategori
		from flo_data
		group by last_order_channel,master_id
)

select 	last_order_channel,
		master_id,
		alisveris_sayisi
		from kategori_ayrımı
		where kategori=1


--16. En son alışveriş yapan kişinin ID’ sini getiren sorguyu yazınız. (Max son tarihte birden fazla alışveriş yapan ID bulunmakta. Bunları da getiriniz.) 
with son_tarih as (
	select max(last_order_date) as son_tarih
	from flo_data
)

select 	master_id,
		last_order_date
		from flo_data
		cross join son_tarih
		where last_order_date = son_tarih.son_tarih
		group by master_id
-----------------------------------------------------------
select master_id,
		last_order_date
		from flo_data
		where last_order_date = (select max(last_order_date)
								from flo_data)

--*******************************************************************************

select customer_value_total_ever_online ,count(*) as count  --online alisveris harcamalarında 
from flo_data												--aynı harcamaların sayisi	
group by customer_value_total_ever_online
having count(*) > 1


select 	customer_value_total_ever_online ,					--dense_rank aynı değerlere aynı numarayı verir
		last_order_channel,									--row_number ise sıralar ayrı olur		
		dense_rank() over(
		PARTITION BY last_order_channel
		order by customer_value_total_ever_online desc) as sira
		from flo_data

--*******************************************************************************

SELECT *
FROM flo_data
WHERE last_order_channel IN (  			--1'den fazla benzer sayıda ifadeleri bulur
    SELECT last_order_channel
    FROM flo_data
    GROUP BY last_order_channel
    HAVING COUNT(*) > 1
)

--*******************************************************************************
--if else yapısı
SELECT  order_num_total_ever_offline,  
CASE 
WHEN  order_num_total_ever_offline = 1 THEN 'denemelik' 	
WHEN  order_num_total_ever_offline < 4 THEN 'daimi müster' 
ELSE 'alisveris manyağı' 
END AS ilgi 
FROM flo_data; 
--*******************************************************************************

--ONLİNE ALİSVERİSİ 20'DEN AZ OLAN KİSİLERİN ORDER CHANNELI
SELECT master_id,
sum(order_num_total_ever_offline) as toplam_siparis_adedi
FROM flo_data
GROUP BY  master_id
HAVING sum(order_num_total_ever_offline) > 8; 

--*******************************************************************************

--KİSİLERİN SAYİSİ
select last_order_channel,
count(*) as kisi_sayisi
from flo_data
where order_num_total_ever_offline > 8
group by last_order_channel

--*******************************************************************************
--kategorileri gruplayıp her biri için sipariş verme tarihi sırlaması
select master_id,interested_in_categories_12,
row_number() over(
PARTITION by interested_in_categories_12 order by last_order_date desc) as offline_siparis
from flo_data

--*******************************************************************************
--virgül yucarlama
select 	 master_id,
		 round(sum(customer_value_total_ever_online)::numeric,1)
from 	 flo_data
group by master_id 

--*******************************************************************************

 
