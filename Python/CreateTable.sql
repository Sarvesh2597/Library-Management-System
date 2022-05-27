SPOOL CreateTableSpool.txt

Drop table VISITS;
Drop table CARD;
Drop table BORROW;
Drop table COPY;
Drop table BOOK;
Drop table MEMBER;
DROP SEQUENCE Card_id_seq;
DROP SEQUENCE Book_id_seq;
DROP SEQUENCE Pass_id_seq;
DROP SEQUENCE Visitor_counter;


CREATE SEQUENCE Card_id_seq
    INCREMENT BY 1
    START WITH 100000
    MINVALUE 100000
    MAXVALUE 999999999999999
    CYCLE
    CACHE 2;

CREATE SEQUENCE Book_id_seq
    INCREMENT BY 1
    START WITH 1000000
    MINVALUE 1000000
    MAXVALUE 999999999999999
    CYCLE
    CACHE 2;

CREATE SEQUENCE Pass_id_seq
    INCREMENT BY 1
    START WITH 1000000
    MINVALUE 1000000
    MAXVALUE 999999999999999
    CYCLE
    CACHE 2;

CREATE SEQUENCE Visitor_counter
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    MAXVALUE 999999999999999
    CYCLE
    CACHE 2;

CREATE TABLE MEMBER
(
SSN NUMBER,
NAME VARCHAR2(50),
HOME_ADDRESS VARCHAR2(1000),
CAMPUS_ADDRESS VARCHAR2(1000),
PHONE_NO VARCHAR2(50),
MEMBER_TYPE VARCHAR2(50),
GRACE_PERIOD NUMBER,
BORROW_PERIOD NUMBER, 
EMPLOYEE_TYPE VARCHAR(50),
STAFF_TYPE VARCHAR(50),
PRIMARY KEY(SSN)
);


CREATE TABLE CARD
(
CARD_ID NUMBER,
M_SSN NUMBER,
ISSUE_DATE DATE,
EXPIRY_DATE DATE,
VALIDITY VARCHAR(10),
PHOTO BLOB,
Flag int,
PRIMARY KEY (CARD_ID),
FOREIGN KEY (M_SSN) REFERENCES MEMBER(SSN) ON DELETE CASCADE
);



CREATE TABLE BOOK
(
ISBN NUMBER,
TITLE VARCHAR2(100),
BINDING VARCHAR2(20),
LANGUAGE VARCHAR2(100),
EDITION VARCHAR2(30),
AUTHOR VARCHAR2(50),
DESCRIPTION CLOB,
VOLUME VARCHAR2(30),
SUBJECT_AREA VARCHAR2(100),
BOOK_TYPE VARCHAR2(30), /*'Map', 'Reference books', 'Rare books'*/
AVAILABILITY CHAR(1) NOT NULL ENABLE CHECK(AVAILABILITY IN('Y', 'N')),
STATUS_TYPE VARCHAR2(30),/*'Lent', 'Unloanable', 'Acquire'*/
PRIMARY KEY(ISBN)
);

CREATE TABLE COPY( 
BOOK_ID NUMBER, 
ISBN NUMBER, 
STATUS VARCHAR2(20), 
PRIMARY KEY(BOOK_ID),
FOREIGN KEY(ISBN) REFERENCES BOOK(ISBN) ON DELETE CASCADE
); 

CREATE TABLE BORROW
(
BOOK_ID NUMBER,
M_SSN NUMBER,
ISSUED_BY NUMBER,
ISSUE_DATE DATE,
DUE_DATE DATE,
RETURN_DATE DATE,
GRACE_PERIOD DATE,
STATUS VARCHAR2(20),
Flag int,
PRIMARY KEY(BOOK_ID,M_SSN,ISSUE_DATE),
FOREIGN KEY(BOOK_ID) REFERENCES COPY(BOOK_ID),
FOREIGN KEY(M_SSN) REFERENCES MEMBER(SSN),
FOREIGN KEY(ISSUED_BY) REFERENCES MEMBER(SSN)
);


CREATE TABLE VISITS
(
VISITOR_ID NUMBER,
M_SSN NUMBER,
CHECK_IN DATE,
CHECK_OUT DATE,
NAME VARCHAR2(50),
PASS_ID NUMBER,
VISITOR_TYPE VARCHAR2(50), /*Member, Relative, Guest*/
VALIDITY_DATE DATE,
PRIMARY KEY (VISITOR_ID,M_SSN),
FOREIGN KEY (M_SSN)REFERENCES MEMBER(SSN)
);

commit;

CREATE OR REPLACE TRIGGER Member_after_insert
AFTER INSERT
   ON MEMBER
   FOR EACH ROW
DECLARE
v number;
book number;
BEGIN
INSERT INTO CARD (M_SSN,CARD_ID,ISSUE_DATE,EXPIRY_DATE,VALIDITY,PHOTO,FLAG)
VALUES(:NEW.SSN,Card_id_seq.NEXTVAL,sysdate,add_months(sysdate,48),'Valid',utl_raw.cast_to_raw('C:\Users\aishw\Pictures\Default.jpg'),0);
select count(*) into v from card where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
IF v> 0 THEN
update card set flag=1 where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
END IF;
select count(*) into book from BORROW where trunc(Due_Date-sysdate) = 0 and flag=0 and status='Borrowed';
IF book > 0 THEN
update BORROW set flag=1 where trunc(Due_Date-sysdate) = 0 and flag=0;
END IF;
END;
/

CREATE OR REPLACE TRIGGER BOOK_INSERT 
AFTER INSERT
ON BOOK 
FOR EACH ROW
DECLARE
book number;
v number;
BEGIN
IF :NEW.AVAILABILITY = 'Y' AND :NEW.STATUS_TYPE = 'Loanable' THEN
INSERT INTO COPY VALUES (Book_id_seq.NEXTVAL,:NEW.ISBN,'Available');
INSERT INTO COPY VALUES (Book_id_seq.NEXTVAL,:NEW.ISBN,'Available');
INSERT INTO COPY VALUES (Book_id_seq.NEXTVAL,:NEW.ISBN,'Available');
END IF;
IF :NEW.AVAILABILITY = 'Y' AND :NEW.STATUS_TYPE = 'Unloanable' THEN
INSERT INTO COPY VALUES (Book_id_seq.NEXTVAL,:NEW.ISBN,'Available');
END IF;
select count(*) into book from BORROW where trunc(Due_Date-sysdate) = 0 and flag=0 and status='Borrowed';
IF book > 0 THEN
update BORROW set flag=1 where trunc(Due_Date-sysdate) = 0 and flag=0;
END IF;
select count(*) into v from card where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
IF v> 0 THEN
update card set flag=1 where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
END IF;
END;
/

commit;

CREATE OR REPLACE TRIGGER visit
AFTER INSERT or update
   ON VISITS
DECLARE
v number;
book number;
BEGIN
select count(*) into v from card where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
IF v> 0 THEN
update card set flag=1 where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
END IF;
select count(*) into book from BORROW where trunc(Due_Date-sysdate) = 0 and flag=0 and status='Borrowed';
IF book > 0 THEN
update BORROW set flag=1 where trunc(Due_Date-sysdate) = 0 and flag=0;
END IF;
END;
/


CREATE OR REPLACE TRIGGER borr
AFTER INSERT
   ON BORROW
DECLARE
v number;
book number;
BEGIN
select count(*) into v from card where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
IF v> 0 THEN
update card set flag=1 where trunc(EXPIRY_DATE-sysdate) <= 30 and flag = 0;
END IF;
select count(*) into book from BORROW where trunc(Due_Date-sysdate) = 0 and flag=0 and status='Borrowed';
IF book > 0 THEN
update BORROW set flag=1 where trunc(Due_Date-sysdate) = 0 and flag=0;
END IF;
END;
/


commit;


INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785960,'Harry Potter and the Half-Blood Prince','hardcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785961,'Harry Potter and the Half-Blood Prince','softcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785962,'Harry Potter and the Half-Blood Prince','hardcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785963,'Harry Potter and the Half-Blood Prince','softcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785964,'Harry Potter and the Chamber of Secrets','hardcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785965,'Harry Potter and the Chamber of Secrets','softcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785966,'Harry Potter and the Chamber of Secrets','hardcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785967,'Harry Potter and the Chamber of Secrets','softcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785968,'Harry Potter and the Prisoner of Azkaban ','hardcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785969,'Harry Potter and the Prisoner of Azkaban ','hardcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785970,'Harry Potter and the Prisoner of Azkaban ','softcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785971,'Harry Potter and the Prisoner of Azkaban ','softcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785972,'Harry Potter and the Goblet of Fire','hardcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785973,'Harry Potter and the Goblet of Fire','hardcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785974,'Harry Potter and the Goblet of Fire','softcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785975,'Harry Potter and the Goblet of Fire','softcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785976,'Harry Potter and the Order of the Phoenix','hardcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785977,'Harry Potter and the Order of the Phoenix','hardcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785978,'Harry Potter and the Order of the Phoenix','softcover','EPO','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785979,'Harry Potter and the Order of the Phoenix','softcover','ENG','1st','J.K. Rowling',TO_CLOB('Harry Potter is a series of seven fantasy novels written by British author J. K. Rowling. the books have found immense popularity, positive reviews, and commercial success worldwide. The success of the books and films has allowed the Harry Potter franchise to expand with numerous derivative works, a travelling exhibition that premiered in Chicago in 2009, a studio tour in London that opened in 2012'),'Part 6','Fantasy','Novel','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785980,'Programming and Data Structures','softcover','ENG','1st','Gerard ORegan',TO_CLOB('Thise'),'Part 2','Fantasy','Reference books','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785981,'Programming and Data Structures','Hardcover','ENG','1st','Gerard ORegan',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 2','Computer Science','Reference books','Y','Loanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785982,'Programming and Data Structures','Hardcover','EPO','1st','Gerard ORegan',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 2','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785983,'Cambridge IGCSE Computer Science by Dave Watson','Hardcover','EPO','1st','Dave Watson',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 3','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785984,'Cambridge IGCSE Computer Science by Dave Watson','softcover','EPO','1st','Dave Watson',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 3','Computer Science','Reference books','N','Acquire');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785993,'Cambridge IGCSE Computer Science by Dave Watson','softcover','ENG','1st','Dave Watson',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 3','Computer Science','Reference books','N','Acquire');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785994,'Cambridge IGCSE Computer Science by Dave Watson','hardcover','ENG','1st','Dave Watson',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 3','Computer Science','Reference books','N','Acquire');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785985,'Computer Science Principles','Hardcover','EPO','1st','Gerard ORegan',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785986,'Computer Science Principles','Hardcover','EPO','1st','Gerard ORegan',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785987,'Computer Science Principles','softcover','ENG','1st','Gerard ORegan',TO_CLOB('This illuminating textbook provides a concise review of the core conbstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785988,'Computer Science Principles','softcover','ENG','1st','Gerard ORegan',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practtext spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785989,'The Beauty of Mathematics in Computer Science','Hardcover','EPO','1st','Jun Wu',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their hoad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785990,'The Beauty of Mathematics in Computer Science','Hardcover','EPO','1st','Jun Wu',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computing applications enabled by seemingly abstract mathematical ideas, presented within their historical context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptographyortance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785991,'The Beauty of Mathematics in Computer Science','softcover','ENG','1st','Jun Wu',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical computcal context. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');

INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE)
VALUES (0439785992,'CThe Beauty of Mathematics in Computer Science','softcover','ENG','1st','Jun Wu',TO_CLOB('This illuminating textbook provides a concise review of the core concepts in mathematics essential to computer scientists. Emphasis is placed on the practical ntext. The text spans a broad selection of key topics, ranging from the use of finite field theory to correct code and the role of number theory in cryptography, to the value of graph theory when modelling networks and the importance of formal methods for safety critical systems'),'Part 1','Computer Science','Reference books','Y','Unloanable');


commit;

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8273283581,'Aishwarya','Hollywood','Standford',7575757578,'Student',7,21,NULL,NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8273283591,'Omkar','Bollywood','Standford',7575766578,'Student',7,21,NULL,NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8274483591,'Kaveri','Bollywood','Harvard',8875766578,'Student',7,21,NULL,NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8273283111,'Mahi','Gujrat','UTA',9995766578,'Student',7,21,NULL,NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8274483221,'Ananya','Punjab','UTA',8885766578,'Student',7,21,NULL,NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8273222111,'Kishor','Chennai','Plano',9991166578,'Employee',14,90,'Professor',NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (8274333221,'Rutuja','Pune','San Jose',8882266578,'Employee',14,90,'Professor',NULL);

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (5557775572,'Rodrix','Pune','UTA',7575750078,'Employee',7,21,'Staff','CHIEF LIBRARIAN');

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (5557775573,'Anna','Arlington','Plano',7005750078,'Employee',7,21,'Staff','DEPARTMENTAL ASSOCIATE LIBRARIAN');

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (5557775574,'Bob','Mumbai','Irving',7575560078,'Employee',7,21,'Staff','REFERENCE LIBRARIAN');

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (5557775575,'Robert','Atlanta','California',7500050078,'Employee',7,21,'Staff','CHECK-OUT STAFF');

INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,GRACE_PERIOD,BORROW_PERIOD, EMPLOYEE_TYPE,STAFF_TYPE)
VALUES (5557775566,'Jason','Delhi','San Diego',7500050099,'Employee',7,21,'Staff','LIBRARY ASSISTANT');

commit;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000066,8273283581,5557775566,sysdate,sysdate+21,sysdate+7,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000066;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000067,8273283581,5557775566,sysdate,sysdate+21,sysdate+7,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000067;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000068,8273283591,5557775566,sysdate,sysdate+21,sysdate+7,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000068;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000069,8273283591,5557775572,sysdate,sysdate+21,sysdate+7,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000069;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000070,8273222111,5557775572,sysdate,sysdate+90,sysdate+14,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000070;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000071,8273222111,5557775572,sysdate,sysdate+90,sysdate+14,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000071;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000072,8274333221,5557775574,sysdate,sysdate+90,sysdate+14,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000072;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000044,8274333221,5557775574,sysdate,sysdate+90,sysdate+14,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000044;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000045,8274483221,5557775575,sysdate,sysdate+21,sysdate+7,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000045;

insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (1000046,8274483221,5557775566,sysdate,sysdate+21,sysdate+7,'Borrowed',0);
update Copy set status='Unavailable' where BOOK_ID = 1000046;

commit;

insert into visits (VISITOR_ID,M_SSN,CHECK_IN,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8273283581,sysdate,'Self');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8273283591,sysdate,'Self');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8274483591,sysdate,'Self');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8273222111,sysdate,'Self');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8274333221,sysdate,'Self');

insert into visits (VISITOR_ID,M_SSN,CHECK_IN,NAME,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8273283581,sysdate,'Rohit','Relative');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,NAME,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8273283591,sysdate,'Bhagya','Relative');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,NAME,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8274483591,sysdate,'Arohi','Relative');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,NAME,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8273222111,sysdate,'Shu','Relative');
insert into visits (VISITOR_ID,M_SSN,CHECK_IN,NAME,VISITOR_TYPE) values (Visitor_counter.NEXTVAL,8274333221,sysdate,'Maya','Relative');

insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE) values (Visitor_counter.NEXTVAL,8273283581,sysdate,'Ayus',Pass_id_seq.NEXTVAL,'Guest',sysdate);
insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE) values (Visitor_counter.NEXTVAL,8273283591,sysdate,'Moni',Pass_id_seq.NEXTVAL,'Guest',sysdate);
insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE) values (Visitor_counter.NEXTVAL,8274483591,sysdate,'Thus',Pass_id_seq.NEXTVAL,'Guest',sysdate);
insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE) values (Visitor_counter.NEXTVAL,8273222111,sysdate,'Bo',Pass_id_seq.NEXTVAL,'Guest',sysdate);
insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE) values (Visitor_counter.NEXTVAL,8274333221,sysdate,'Sam',Pass_id_seq.NEXTVAL,'Guest',sysdate);

commit;

SPOOL OFF;