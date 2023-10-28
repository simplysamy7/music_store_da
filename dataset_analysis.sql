--Music Store Data Analysis

-- Q1: Who is the seniormost employee based on job title?
SELECT
	first_name,
	last_name,
	title
FROM
	employee
WHERE
	reports_to IS NULL;

-- OR
SELECT
	*
FROM
	employee
ORDER BY
	levels DESC
LIMIT
	1;

--Answer- Mohan Madan is Senior General manager

--Q2: Which countires have the most invoices?
SELECT
	*
FROM
	invoice;

SELECT
	COUNT(invoice_id),
	billing_country
FROM
	invoice
GROUP BY
	billing_country
ORDER BY
	COUNT(invoice_id) DESC
LIMIT
	1;

--Answer- USA

-- Q3: What are top 3 values of total invoice?
SELECT
	total
FROM
	invoice
ORDER BY
	total DESC
LIMIT
	3;

-- Q4:Which city has the best customers?
SELECT
	SUM(total),
	billing_city
FROM
	invoice
GROUP BY
	2
ORDER BY
	1 DESC
LIMIT
	1;

--Answer: Prague

--Q5: Who is the best customer?
-- i.e. The customer who has spent the most money.
SELECT
	customer.customer_id,
	customer.first_name,
	customer.last_name,
	SUM(invoice.total) AS invoice_total
FROM
	invoice
	JOIN customer ON invoice.customer_id = customer.customer_id
GROUP BY
	1
ORDER BY
	4 DESC
LIMIT
	1;

--Answer: R. Madhav

-- Q5:List email, first_name, last_name,genre of all rock music listeners.Order alphabeticlly by emial.
SELECT DISTINCT
	customer.email,
	customer.first_name,
	customer.last_name
FROM
	customer
	JOIN invoice ON invoice.customer_id = customer.customer_id
	JOIN invoice_line ON invoice.invoice_id = invoice.invoice_id
WHERE
	track_id IN (
		SELECT
			track_id
		FROM
			track
			JOIN genre ON track.genre_id = genre.genre_id
		WHERE
			genre.name LIKE 'Rock'
	)
ORDER BY
	1;

-- OR

SELECT DISTINCT
	customer.email,
	customer.first_name,
	customer.last_name
FROM
	customer
	JOIN invoice ON customer.customer_id = invoice.customer_id
	JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
	JOIN track ON invoice_line.track_id = track.track_id
	JOIN genre ON track.genre_id = genre.genre_id
WHERE
	genre.name = 'Rock'
ORDER BY
	customer.email ASC;

-- pull up top 10 rock artists and their total track count
SELECT
	artist.name,
	COUNT(artist.artist_id) AS total_track
FROM
	artist
	JOIN album ON artist.artist_id = album.artist_id
	JOIN track ON album.album_id = track.album_id
	JOIN genre ON track.genre_id = genre.genre_id
WHERE
	genre.name = 'Rock'
GROUP BY
	1
ORDER BY
	2 DESC
LIMIT
	10;

-- pull up songs and song-length that have longer than avg song length. Order in Descending order.
--Way 1:
SELECT
	AVG(track.milliseconds)
FROM
	track;

SELECT
	track.name,
	track.milliseconds
FROM
	track
WHERE
	milliseconds > 393599.212103910933
ORDER BY
	2 DESC;

-- Way 2:Better way to make it more dynamic:
SELECT
	track.name,
	track.milliseconds
FROM
	track
WHERE
	milliseconds > (
		SELECT
			AVG(milliseconds) AS avg_length
		FROM
			track
	)
ORDER BY
	2 DESC;

-- Q8: How much amount spent by each customer on artists?
SELECT DISTINCT
	customer.first_name,
	customer.last_name
FROM
	customer
	INNER JOIN invoice ON invoice.customer_id = customer.customer_id
	-- finding out the total prices of the songs of artists sold
	CREATE TEMPORARY TABLE best_selling_artist AS
SELECT
	artist.artist_id,
	artist.name,
	SUM(invoice_line.unit_price * invoice_line.quantity) AS total_price
FROM
	invoice_line
	JOIN track ON track.unit_price = invoice_line.unit_price
	JOIN album ON track.album_id = album.album_id
	JOIN artist ON artist.artist_id = album.artist_id
GROUP BY
	1
ORDER BY
	3 DESC;

SELECT DISTINCT
	customer.first_name,
	customer.last_name,
	best_selling_artist.name,
	best_selling_artist.total_price
FROM
	customer
	JOIN invoice ON invoice.customer_id = customer.customer_id
	JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
	JOIN track ON track.unit_price = invoice_line.unit_price
	JOIN album ON track.album_id = album.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	JOIN best_selling_artist ON artist.artist_id = best_selling_artist.artist_id
GROUP BY
	1,
	2,
	3,
	4
ORDER BY
	4 DESC;

-- Q8: Find out the most popular (highest selling genre) for each country

-- writing the subquery to make partitions first
SELECT
	COUNT(invoice_line.quantity) AS highest_quantity,
	invoice.billing_country AS country,
	genre.name AS genre_name,
	track.genre_id AS genre_idd,
	ROW_NUMBER() OVER (
		PARTITION BY
			invoice.billing_country
		ORDER BY
			COUNT(invoice_line.quantity) DESC
	) AS row_number -- because we want only the top genre
FROM
	invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
GROUP BY
	2,
	3,
	4
ORDER BY
	2 ASC,
	1 DESC;

-- writing outer query to pull up final results of only the top highest selling genre country-wise
SELECT
	highest_quantity,
	country,
	genre_name,
	genre_idd
FROM
	(
		SELECT
			COUNT(invoice_line.quantity) AS highest_quantity,
			invoice.billing_country AS country,
			genre.name AS genre_name,
			track.genre_id AS genre_idd,
			ROW_NUMBER() OVER (
				PARTITION BY
					invoice.billing_country
				ORDER BY
					COUNT(invoice_line.quantity) DESC
			) AS row_number -- because we want only the top genre
		FROM
			invoice_line
			JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
			JOIN customer ON customer.customer_id = invoice.customer_id
			JOIN track ON track.track_id = invoice_line.track_id
			JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY
			2,
			3,
			4
		ORDER BY
			2 ASC,
			1 DESC
	) AS sub_query
WHERE
	row_number = 1;

-- METHOD 2: USING CTE/COMMON TABLE EXPRESSION
WITH
	country_and_genre AS (
		SELECT
			COUNT(invoice_line.quantity) AS highest_quantity,
			invoice.billing_country AS country,
			genre.name AS genre_name,
			track.genre_id AS genre_idd,
			ROW_NUMBER() OVER (
				PARTITION BY
					invoice.billing_country
				ORDER BY
					COUNT(invoice_line.quantity) DESC
			) AS row_number -- because we want only the top genre
		FROM
			invoice_line
			JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
			JOIN customer ON customer.customer_id = invoice.customer_id
			JOIN track ON track.track_id = invoice_line.track_id
			JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY
			2,
			3,
			4
		ORDER BY
			2 ASC,
			1 DESC
	)
SELECT
	*
FROM
	country_and_genre
WHERE
	row_number = 1;

-- Q10: Find out country wise top customer and how much they have spent.

--THROUGH SUBQUERY METHOD
-- Step 1: creating subquery to partition and order data
SELECT
	customer.first_name AS customer_firstname,
	customer.last_name AS customer_surname,
	invoice.billing_country AS country,
	SUM(invoice.total) AS total_spent,
	ROW_NUMBER() OVER (
		PARTITION BY
			invoice.billing_country
		ORDER BY
			SUM(invoice.total) DESC
	) AS row_number
FROM
	customer
	INNER JOIN invoice ON invoice.customer_id = customer.customer_id
GROUP BY
	1,
	2,
	3
ORDER BY
	4 DESC;

-- Step 2: Writing full query to fetch final c0untry-wise highest spending customer
SELECT
	customer_firstname,
	customer_surname,
	country,
	total_spent
FROM
	(
		SELECT
			customer.first_name AS customer_firstname,
			customer.last_name AS customer_surname,
			invoice.billing_country AS country,
			SUM(invoice.total) AS total_spent,
			ROW_NUMBER() OVER (
				PARTITION BY
					invoice.billing_country
				ORDER BY
					SUM(invoice.total) DESC
			) AS row_number
		FROM
			customer
			INNER JOIN invoice ON invoice.customer_id = customer.customer_id
		GROUP BY
			1,
			2,
			3
		ORDER BY
			4 DESC
	) AS subquery
WHERE
	row_number <= 1
ORDER BY
	3 ASC,
	4 DESC;

-- METHOD 2: USING CTE/Common Table Expression
WITH
	customer_and_country AS (
		SELECT
			customer.first_name AS customer_firstname,
			customer.last_name AS customer_surname,
			invoice.billing_country AS country,
			SUM(invoice.total) AS total_spent,
			ROW_NUMBER() OVER (
				PARTITION BY
					invoice.billing_country
				ORDER BY
					SUM(invoice.total) DESC
			) AS row_number
		FROM
			customer
			INNER JOIN invoice ON invoice.customer_id = customer.customer_id
		GROUP BY
			1,
			2,
			3
		ORDER BY
			4 DESC
	)
SELECT
	*
FROM
	customer_and_country
WHERE
	row_number = 1;