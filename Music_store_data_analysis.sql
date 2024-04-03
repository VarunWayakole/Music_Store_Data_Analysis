USE sql_project2;

SHOW tables;

-- Q1. Who is the senior most employee based on job title?

SELECT 
	title,
    first_name,
    last_name
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2. Which countries have the most invoices?

SELECT
	billing_country AS country,
	COUNT(billing_country) AS no_of_invoices
FROM invoice
GROUP BY billing_country
ORDER BY no_of_invoices DESC;

-- Q3. What are top 3 values of total invoice?

SELECT DISTINCT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- Q4. Which city has the best customers?

SELECT
	billing_city AS city,
    SUM(total) AS invoice_total
FROM invoice
GROUP BY city
ORDER BY invoice_total DESC
LIMIT 1;

-- Q5. Who is the best customer? 

SELECT 
	c.customer_id,
	first_name,
    last_name,
    ROUND(SUM(total), 2) AS total_spending
FROM customer c
JOIN invoice i USING(customer_id)
GROUP BY 
	customer_id, 
    first_name, 
    last_name
ORDER BY 
	total_spending DESC
LIMIT 1;

-- Q6. Write query to return 
--     the email, first name, last name, & Genre of all Rock Music listeners. 
--     Return your list ordered alphabetically by email starting with A

-- Method 1
SELECT 
    DISTINCT c.email,
    c.first_name,
    c.last_name
FROM 
    customer c
    JOIN invoice USING (customer_id)
    JOIN invoice_line USING (invoice_id)
WHERE 
    track_id IN (
        SELECT track_id
        FROM track
		JOIN genre g USING (genre_id)
        WHERE g.name = 'Rock'
    )
ORDER BY c.email;

-- Method 2
SELECT 
    DISTINCT c.email,
    c.first_name,
    c.last_name,
    g.name AS genre
FROM 
    customer c
    JOIN invoice USING (customer_id)
    JOIN invoice_line USING (invoice_id)
    JOIN track USING (track_id)
    JOIN genre g USING (genre_id)
WHERE 
    g.name LIKE 'Rock'
ORDER BY 
    c.email;

-- Q7. Let's invite the artists who have written the most rock music in our dataset. 
--     Write a query that returns the Artist name and 
-- 	   total track count of the top 10 rock bands

SELECT
    artist.artist_id,
    artist.name,
    COUNT(artist.artist_id) AS number_of_songs
FROM
    track
    JOIN album USING (album_id)
    JOIN artist USING (artist_id)
    JOIN genre USING (genre_id)
WHERE
    genre.name = 'Rock'
GROUP BY
    artist.artist_id,
    artist.name
ORDER BY
    number_of_songs DESC
LIMIT 10;

-- Q8. Return all the track names that have a song length longer than the average song length. 
--     Return the Name and Milliseconds for each track. 
--     Order by the song length with the longest songs listed first

SELECT 
	DISTINCT name,
    milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS average_song_length
    FROM track
)
ORDER BY milliseconds DESC;

-- Q9. Find how much amount spent by each customer on artists? 
--     Write a query to return customer name, artist name and total spent

WITH best_selling_artist AS (
    SELECT 
        ar.artist_id AS artist_id, 
        ar.name AS artist_name, 
        ROUND(SUM(il.unit_price * il.quantity), 2) AS total_sales
    FROM 
        invoice_line il
        JOIN track USING (track_id)
        JOIN album al USING (album_id)
        JOIN artist ar USING (artist_id)
    GROUP BY 1, 2
    ORDER BY 3 DESC
    LIMIT 1
)
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name, 
    ROUND(SUM(il.unit_price * il.quantity), 2) AS amount_spent
FROM 
    invoice 
    JOIN customer c USING (customer_id)
    JOIN invoice_line il USING (invoice_id)
    JOIN track USING (track_id)
    JOIN album USING (album_id)
    JOIN best_selling_artist bsa USING (artist_id)
GROUP BY 
    c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY 
    amount_spent DESC;
    
/* 
Q10. We want to find out the most popular music Genre for each country. 
     We determine the most popular genre as the genre with the highest amount of purchases. 
     Write a query that returns each country along with the top Genre. 
     For countries where the maximum number of purchases is shared return all genres
 */
 
-- Method 1
WITH popular_genre AS 
(
    SELECT 
        COUNT(invoice_line.quantity) AS purchases, 
        customer.country, 
        genre.name, 
        genre.genre_id, 
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS rn
    FROM 
        invoice_line 
        JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
        JOIN customer ON customer.customer_id = invoice.customer_id
        JOIN track ON track.track_id = invoice_line.track_id
        JOIN genre ON genre.genre_id = track.genre_id
    GROUP BY 
        2,3,4
    ORDER BY 
        2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE rn <= 1;

-- Method 2
WITH RECURSIVE
    sales_per_country AS (
        SELECT 
            COUNT(*) AS purchases_per_genre, 
            customer.country, 
            genre.name, 
            genre.genre_id
        FROM 
            invoice_line
            JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
            JOIN customer ON customer.customer_id = invoice.customer_id
            JOIN track ON track.track_id = invoice_line.track_id
            JOIN genre ON genre.genre_id = track.genre_id
        GROUP BY 2,3,4
        ORDER BY 2
    ),
    max_genre_per_country AS (
        SELECT 
            MAX(purchases_per_genre) AS max_genre_number, 
            country
        FROM sales_per_country
        GROUP BY 2
        ORDER BY 2
    )

SELECT 
    sales_per_country.* 
FROM 
    sales_per_country
    JOIN max_genre_per_country 
    ON sales_per_country.country = max_genre_per_country.country
WHERE 
    sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* 
Q11. Write a query that determines the customer that has spent the most on music for each country. 
     Write a query that returns the country along with the top customer and how much they spent. 
     For countries where the top amount spent is shared, provide all customers who spent this amount
 */
 
-- Method 1
WITH Customter_with_country AS (
    SELECT 
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        ROUND(SUM(total), 2) AS total_spending,
        ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS rn 
    FROM 
        invoice
        JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 4 ASC, 5 DESC
)
SELECT * 
FROM Customter_with_country 
WHERE rn <= 1;

-- Method 2
WITH RECURSIVE customter_with_country AS (
    SELECT 
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        ROUND(SUM(total), 2) AS total_spending
    FROM 
        invoice
        JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 2,3 DESC
),
country_max_spending AS (
    SELECT 
        billing_country,
        MAX(total_spending) AS max_spending
    FROM customter_with_country
    GROUP BY billing_country
)

SELECT 
    cc.billing_country, 
    cc.total_spending, 
    cc.first_name, 
    cc.last_name, 
    cc.customer_id
FROM 
    customter_with_country cc
    JOIN country_max_spending ms 
    ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


 







