DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS images;

CREATE TABLE users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  password text NOT NULL UNIQUE
);

CREATE TABLE images (
  id serial PRIMARY KEY,
  url text NOT NULL UNIQUE,
  username text NOT NULL
);