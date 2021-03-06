DROP PROCEDURE IF EXISTS
  newLogin;

DROP PROCEDURE IF EXISTS
  newToken;

DROP TRIGGER IF EXISTS
  generateRandomToken;

DROP TABLE IF EXISTS
  PlaylistTrack, Tracks, Playlists, Tokens, Users;

CREATE TABLE Users (
  id        INT           NOT NULL AUTO_INCREMENT,
  username  VARCHAR(50)   NOT NULL,
  password  VARCHAR(250)  NOT NULL,
  CONSTRAINT  pk_userId   PRIMARY KEY (id),
  CONSTRAINT  ak_username UNIQUE      (username)
);

CREATE TABLE Tokens (
  token     VARCHAR(14)   NOT NULL, /* token format: 1234-1234-1234 */
  user      INT           NOT NULL,
  createdOn DATETIME      NOT NULL  DEFAULT CURRENT_TIMESTAMP(),
  CONSTRAINT  pk_token      PRIMARY KEY (token),
  CONSTRAINT  fk_tokenUser  FOREIGN KEY (user)
              REFERENCES  Users(id)
              ON DELETE   CASCADE
              ON UPDATE   CASCADE
);

DELIMITER //
CREATE TRIGGER generateRandomToken
BEFORE INSERT ON Tokens FOR EACH ROW /* Generate token for Token on Insert */
BEGIN
  DECLARE ready INT DEFAULT 0;
  DECLARE generatedToken VARCHAR(14); /* DEFAULT needs to be an empty string, otherwise the checks on LENGTH don't work */
  WHILE NOT ready DO
    SET generatedToken := "";
    WHILE LENGTH(generatedToken) < 14 DO
      SET generatedToken := CONCAT(generatedToken, LEFT(FLOOR(RAND() * 1000000), 4)); /* RAND() generates a decimal between 0 and 1 */
      IF LENGTH(generatedToken) < 14 THEN
        SET generatedToken := CONCAT(generatedToken, "-");
      END IF;
    END WHILE;
    IF (NOT EXISTS(SELECT * FROM Tokens WHERE token = generatedToken)) AND (LENGTH(generatedToken) = 14) THEN
      SET NEW.token = generatedToken;
      SET ready := 1;
    END IF;
  END WHILE;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE newToken(userId int)
BEGIN
  INSERT INTO Tokens (user) VALUES(userId);
  SELECT token FROM Tokens WHERE user = userId ORDER BY createdOn DESC LIMIT 1;
END//
DELIMITER ;

CREATE TABLE Playlists (
  id    INT           NOT NULL  AUTO_INCREMENT,
  name  VARCHAR(50)   NOT NULL,
  owner INT           NOT NULL,
  CONSTRAINT  pk_playlistId     PRIMARY KEY (id),
  CONSTRAINT  fk_playlistOwner  FOREIGN KEY (owner)
              REFERENCES  Users(id)
              ON DELETE   RESTRICT
              ON UPDATE   CASCADE
);

CREATE TABLE Tracks (
  id              INT           NOT NULL  AUTO_INCREMENT,
  performer       VARCHAR(250)  NOT NULL,
  title           VARCHAR(250)  NOT NULL,
  url             TEXT          NOT NULL,
  duration        INT           NOT NULL,
  playcount       INT           NOT NULL   DEFAULT 0,
  album           VARCHAR(250)  NULL,     /* only for SONG  */
  publicationDate DATE          NULL,     /* only for VIDEO */
  description     TEXT          NULL,     /* only for VIDEO */
  CONSTRAINT  pk_trackId  PRIMARY KEY (id)
);

CREATE TABLE PlaylistTrack (
  playlist          INT     NOT NULL,
  track             INT     NOT NULL,
  offlineAvailable  BOOLEAN NOT NULL  DEFAULT FALSE,
  CONSTRAINT  pk_playlistTrack  PRIMARY KEY (playlist, track),
  CONSTRAINT  fk_playlist       FOREIGN KEY (playlist)
              REFERENCES  Playlists(id)
              ON DELETE   CASCADE
              ON UPDATE   CASCADE,
  CONSTRAINT  fk_track          FOREIGN KEY (track)
              REFERENCES  Tracks(id)
              ON DELETE   CASCADE
              ON UPDATE   CASCADE
);
