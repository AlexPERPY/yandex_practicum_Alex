-- Часть 1.
-- 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT COUNT(*)
FROM stackoverflow.posts p
JOIN stackoverflow.post_types pt ON pt.id=p.post_type_id
WHERE pt.type='Question' AND score > 300 OR favorites_count >= 100;

-- 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
SELECT ROUND(AVG(question_cnt))
FROM (SELECT creation_date :: date AS question_date,
             COUNT(p.id) AS question_cnt
      FROM stackoverflow.posts p
      LEFT JOIN stackoverflow.post_types pt ON pt.id=p.post_type_id
      WHERE pt.type='Question' AND creation_date :: date BETWEEN '2008-11-01' AND '2008-11-18'
      GROUP BY creation_date :: date) i;

-- 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
SELECT COUNT(DISTINCT b.user_id)
FROM stackoverflow.badges b
LEFT JOIN stackoverflow.users u ON u.id=b.user_id
WHERE u.creation_date::date=b.creation_date::date

-- 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
WITH votes_cnts AS ( SELECT p.id AS id_post,
                            COUNT(v.id) AS votes_cnt
                     FROM stackoverflow.users AS u
                     JOIN stackoverflow.posts AS p ON p.user_id = u.id
                     JOIN stackoverflow.votes AS v ON v.post_id = p.id
                     WHERE display_name = 'Joel Coehoorn'
                     GROUP BY p.id )
  SELECT COUNT(id_post)
  FROM votes_cnts
  WHERE votes_cnt > 0;

-- 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
SELECT *,
       RANK() OVER (ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id

-- 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
SELECT v.user_id ,
         COUNT (v.id) 
FROM stackoverflow.votes AS v
JOIN stackoverflow.vote_types AS vt ON vt.id = v.vote_type_id
WHERE name = 'Close'  
GROUP BY v.user_id
ORDER BY COUNT (v.id) DESC,
         v.user_id DESC
LIMIT 10;

-- 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно. Отобразите несколько полей: идентификатор пользователя; число значков; место в рейтинге — чем больше значков, тем выше рейтинг. Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге. Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
SELECT user_id,
       COUNT (id) AS badges_cnt,
       DENSE_RANK() OVER (ORDER BY COUNT (id) DESC )
FROM stackoverflow.badges
WHERE creation_date :: date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY badges_cnt DESC,
         user_id
LIMIT 10;

-- 8. Сколько в среднем очков получает пост каждого пользователя? Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER(PARTITION BY user_id))
FROM stackoverflow.posts
WHERE (title IS NOT NULL) AND score!=0;

-- 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
SELECT title
FROM stackoverflow.posts
WHERE user_id IN (
              SELECT user_id 
              FROM stackoverflow.badges
              GROUP BY user_id
              HAVING COUNT(id) > 1000)
              AND title IS NOT NULL;

-- 10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей: пользователям с числом просмотров больше либо равным 350 присвойте группу 1; пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2; пользователям с числом просмотров меньше 100 — группу 3. Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
SELECT id,
       views,
       CASE
          WHEN views < 100 THEN 3
          WHEN views >= 100 AND views < 350  THEN 2
          ELSE 1
       END AS group
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views != 0
ORDER BY views DESC;

-- 11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
WITH a AS
(SELECT id,
       views,
       CASE
          WHEN views < 100 THEN 3
          WHEN views >= 100 AND views < 350  THEN 2
          ELSE 1
       END AS groupse
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views != 0
ORDER BY views DESC)

SELECT id,
       groupse,
       views
FROM (   SELECT id,
                views,
                groupse,
                MAX(views) OVER (PARTITION BY groupse ORDER BY views DESC) AS max_views
FROM a) AS max
WHERE views =  max_views
ORDER BY views DESC, id;

-- 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями: номер дня; число пользователей, зарегистрированных в этот день; сумму пользователей с накоплением.
SELECT EXTRACT(DAY FROM creation_date::date) AS day_number,
       COUNT(id),
       SUM(COUNT(id)) OVER (ORDER BY EXTRACT(DAY FROM creation_date::date))
FROM stackoverflow.users
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY day_number

-- 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите: идентификатор пользователя; разницу во времени между регистрацией и первым постом.
SELECT DISTINCT p.user_id,
       MIN(p.creation_date ) OVER (PARTITION BY p.user_id) - u.creation_date  AS interval
FROM stackoverflow.posts  AS p
LEFT JOIN stackoverflow.users AS u
ON p.user_id =  u.id;

-- Часть 2
-- 1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
SELECT CAST(DATE_TRUNC('month',creation_date)AS date) AS date,
       SUM(views_count) AS cnt
FROM stackoverflow.posts
WHERE EXTRACT (YEAR FROM creation_date) = '2008'
GROUP BY date
ORDER BY cnt DESC;

-- 2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT u.display_name,
       COUNT(DISTINCT p.user_id) AS us_cnt
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON u.id = p.user_id
JOIN stackoverflow.post_types pt ON p.post_type_id = pt.id
WHERE p.creation_date::date BETWEEN u.creation_date::date 
                            AND u.creation_date::date + INTERVAL '1 month' 
                            AND pt.type = 'Answer'
GROUP BY u.display_name
HAVING COUNT(DISTINCT p.id) > 100 
ORDER BY u.display_name

-- 3. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.
SELECT CAST(DATE_TRUNC('month',creation_date)AS date) AS date,
       COUNT(id) AS post_cnt
FROM stackoverflow.posts
WHERE EXTRACT (YEAR FROM creation_date) = '2008' AND user_id IN (
                  SELECT DISTINCT u.id
                    FROM stackoverflow.users AS u
                    JOIN stackoverflow.posts AS p
                      ON p.user_id = u.id
                   WHERE u.creation_date :: date BETWEEN '2008-09-01' AND '2008-09-30'
                     AND p.creation_date :: date BETWEEN '2008-12-01' AND '2008-12-31')
GROUP BY date
ORDER BY date DESC;

-- 4. Используя данные о постах, выведите несколько полей: идентификатор пользователя, который написал пост; дата создания поста; количество просмотров у текущего поста; сумма просмотров постов автора с накоплением. Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts 
ORDER BY user_id, creation_date;

-- 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.
SELECT ROUND(AVG (days_cnt))
FROM (
      SELECT user_id,
             COUNT(DISTINCT creation_date :: date) AS days_cnt
        FROM stackoverflow.posts 
       WHERE creation_date :: date BETWEEN '2008-12-01' AND '2008-12-07'
    GROUP BY user_id 
    ) AS aver; 

/* 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
*/
WITH a AS ( SELECT EXTRACT(MONTH FROM creation_date :: date) AS month_number,
                   COUNT(*) AS posts_cnt
            FROM stackoverflow.posts
            WHERE creation_date :: date BETWEEN '2008-09-01' AND '2008-12-31'
            GROUP BY month_number)
SELECT month_number,
       posts_cnt,
       ROUND((posts_cnt::numeric-LAG(posts_cnt) OVER())/LAG(posts_cnt) OVER()*100,2)
FROM a

-- 7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде: номер недели; дата и время последнего поста, опубликованного на этой неделе.
WITH a AS( SELECT EXTRACT(WEEK FROM creation_date) AS week_number,
                  MAX(creation_date) OVER (ORDER BY EXTRACT(WEEK FROM creation_date)) AS last_post_time
           FROM stackoverflow.posts 
           WHERE user_id = (SELECT user_id
                            FROM stackoverflow.posts
                            GROUP BY user_id
                            ORDER BY count(*) DESC
                            LIMIT 1) 
                 AND creation_date :: date BETWEEN '2008-10-01' AND '2008-10-31'          
          ORDER BY creation_date)
SELECT DISTINCT *
FROM a
ORDER BY week_number

