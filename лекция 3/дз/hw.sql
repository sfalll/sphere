-- 1

SELECT tariff, uniqExact(idhash_view) AS view,
       uniqExactIf(idhash_order, idhash_order > 0) AS order,
       uniqExactIf(idhash_order, da_dttm IS NOT NULL) AS driver,
       uniqExactIf(idhash_order, rfc_dttm IS NOT NULL) AS car,
       uniqExactIf(idhash_order, cc_dttm IS NOT NULL) AS sit,
       uniqExactIf(idhash_order, finish_dttm IS NOT NULL) AS finish
FROM
    views
    LEFT JOIN orders USING (idhash_order)
GROUP BY tariff
ORDER BY view DESC;

-- Больше всего клиентов теряем на этапе заказа и на этапе назначения водителя


-- 2

SELECT idhash_client AS client,
       topK(4)(tariff) AS top_tarifs,
       uniqExact(tariff) AS number_of_tarifs
FROM views
GROUP BY client;


-- 3
-- беру cc_dttm, т.к. некоторые клиенты делают заказ заранее

-- топ 10 откуда уезжают с 7 до 10
SELECT geoToH3(longitude, latitude, 7) AS hexagon
FROM
    views
    JOIN orders USING (idhash_order)
WHERE status = 'CP' AND toHour(cc_dttm) BETWEEN 7 AND 10
GROUP BY hexagon
ORDER BY uniqExact(idhash_order) DESC
LIMIT 10;

-- топ 10 куда едут с 18 до 20
SELECT geoToH3(del_longitude, del_latitude, 7) AS hexagon
FROM
    views
    JOIN orders USING (idhash_order)
WHERE status = 'CP' AND toHour(cc_dttm) BETWEEN 18 AND 20
GROUP BY hexagon
ORDER BY uniqExact(idhash_order) DESC
LIMIT 10;


-- 4
-- убрал людей, которые делали заказ заранее по 99 перцентилю

SELECT median(dateDiff('second', order_dttm, da_dttm)) AS median_sec,
       quantile(0.95)(dateDiff('second', order_dttm, da_dttm)) AS percentile_sec
FROM orders
WHERE da_dttm IS NOT NULL
    AND dateDiff('second', order_dttm, da_dttm) <
        (SELECT quantile(0.99)(dateDiff('second', order_dttm, da_dttm)) FROM orders);