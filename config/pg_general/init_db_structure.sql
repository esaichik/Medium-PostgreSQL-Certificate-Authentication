-- creating extension for password encryption
CREATE EXTENSION pgcrypto;

-- global sequence(s) begin

CREATE SEQUENCE global_id_sequence AS BIGINT START WITH 1 INCREMENT BY 1;

-- global sequence(s) end

-- users table begin

CREATE TABLE users
(
    id BIGINT NOT NULL DEFAULT nextval('global_id_sequence'),
    login VARCHAR(64) NOT NULL,
    password VARCHAR NOT NULL,
    email VARCHAR(64) NOT NULL,
    first_name VARCHAR(64),
    last_name VARCHAR(64),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id),
    UNIQUE (email)
);

CREATE UNIQUE INDEX users_login_idx ON users(login);

CREATE FUNCTION hash_user_password_on_insert_or_update()
RETURNS TRIGGER
AS $$
BEGIN
    NEW.password = crypt(NEW.password, gen_salt('bf'));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER hash_user_password_on_insert_or_update_trigger BEFORE INSERT OR UPDATE ON users
FOR EACH ROW EXECUTE PROCEDURE hash_user_password_on_insert_or_update();

-- check password example
-- SELECT (crypt('password_string', password) = password) AS is_password_correct
-- FROM users WHERE login = 'login';
-- above is the example how to check whether password is correct or not.

-- users table and password-related modifications end

-- groups table begin

CREATE TABLE groups
(
    id BIGINT NOT NULL DEFAULT nextval('global_id_sequence'),
    name VARCHAR(64) NOT NULL,
    description VARCHAR(64),
    PRIMARY KEY (id),
    UNIQUE (name)
);

-- groups table end

-- users_groups join table for many-to-many relationship begin

CREATE TABLE users_groups
(
    user_id BIGINT NOT NULL,
    group_id BIGINT NOT NULL,
    UNIQUE (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

-- users_groups end
