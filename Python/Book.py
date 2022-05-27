from tabulate import tabulate
def displayBook(c):
    c.execute("Select * from BOOK")
    rows = c.fetchall()
    print("\n")
    print(tabulate(rows,headers=["ISBN", "TITLE", "BINDING", "LANGUAGE", "EDITION", "AUTHOR", "DESCRIPTION", "VOLUME","SUBJECT AREA", "BOOK TYPE", "AVAILABILITY", "STATUS TYPE"]))

def borrowBook(cursor,connection):
    print("Enter details to Borrow Book:")
    ss = int(input("Enter the Borrower's SSN Number:"))
    cursor.execute("Select GRACE_PERIOD,BORROW_PERIOD from MEMBER where ssn = :ssn_id", ssn_id=ss)
    gb = cursor.fetchone()
    book = int(input("Enter the ISBN Number of the book to borrow: "))
    cursor.execute("Select STATUS_TYPE, AVAILABILITY  from book where ISBN = :id",id=book)
    status=cursor.fetchone()
    if status[1] == 'N' or status[0] != 'Loanable':
        print("This book cannot be borrowed!")
        return
    cursor.execute("Select count(*) from COPY where ISBN = :bookid and STATUS='Available'", bookid=book)
    cnt = cursor.fetchone()
    if cnt[0] <=0:
        print("This book cannot be borrowed!")
        return
    cursor.execute("Select BOOK_ID from COPY where ISBN = :bookid and STATUS='Available'",bookid=book)
    Book_id=cursor.fetchone()

    issn = int(input("Enter the Issuer's SSN Number:"))
    cursor.execute("Select count(*) from MEMBER where SSN = :issnn and Employee_Type='Staff'", issnn=issn)
    cnt=cursor.fetchone()
    if cnt[0] == 0 :
        print("Issuer is not a Staff Member!")
        return
    cursor.execute("insert into Borrow (BOOK_ID, M_SSN, ISSUED_BY, ISSUE_DATE, DUE_DATE, GRACE_PERIOD, STATUS,FLAG) values (:1,:2,:3,sysdate,sysdate+:4,sysdate+:5,:6,0)",(Book_id[0], ss, issn,gb[1],gb[0]+gb[1],'Borrowed'))
    cursor.execute("update Copy set status='Unavailable' where BOOK_ID = :bookid",bookid=Book_id[0])
    cursor.execute("Select count(*) from COPY where ISBN = :bookid and STATUS='Unavailable'", bookid=book)
    cnt=cursor.fetchone()
    if cnt[0]<=0:
        cursor.execute("update Book set Availability='N' where ISBN = :bookid", bookid=book)
    connection.commit()
    print("Book is Borrowed!")


def returnBook(cursor,connection):
    print("Enter details to Return Book:")
    ss = int(input("Enter the Borrower's SSN Number:"))
    book = int(input("Enter the ISBN Number of the book to borrow: "))
    cursor.execute("Select c.BOOK_ID from COPY c, Borrow b where c.ISBN = :1 and c.status=:2 and c.book_id = b.book_id and b.m_ssn=:3",(book,'Unavailable',ss))
    book_id1=cursor.fetchone()
    cursor.execute("update borrow set RETURN_DATE=sysdate, STATUS =:1  where BOOK_ID = :2 and M_SSN = :3 and STATUS = :4",('Returned',book_id1[0],ss,'Borrowed'))
    cursor.execute("update Copy set status='Available' where BOOK_ID = :bookid", bookid=book_id1[0])

    cursor.execute("Select count(*) from COPY where ISBN = :bookid and STATUS='Unavailable'", bookid=book)
    cnt = cursor.fetchone()
    if cnt[0] > 0:
        cursor.execute("update Book set Availability='Y' where ISBN = :bookid", bookid=book)

    connection.commit()
    print("Book is Returned!")
    cursor.execute("Select * from Book where ISBN= :isbn", isbn=book)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["ISBN", "TITLE", "BINDING", "LANGUAGE", "EDITION", "AUTHOR", "DESCRIPTION", "VOLUME",
                                  "SUBJECT AREA", "BOOK TYPE", "AVAILABILITY", "STATUS TYPE"]))
    # PRINT RETURN RECEIPT OF THE BOOK details of the book, days when it was borrowed and returned
    cursor.execute("Select BOOK_ID, issue_date,return_date,status,m_ssn,trunc(RETURN_DATE-ISSUE_DATE)days from borrow where STATUS =:1 and BOOK_ID = :2 and M_SSN = :3 and RETURN_DATE = sysdate",('Returned', book_id1[0], ss))
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["Book Id", "Issue Date", "Return Date", "Status", "Member SSN", "Days Borrowed"]))

def BorrowReport(cursor):
    #Subject area, by Author, Title
    cursor.execute("Select b.BOOK_ID,b.M_SSN,book1.TITLE, book1.AUTHOR, book1.SUBJECT_AREA, b.ISSUE_DATE, b.RETURN_DATE, b.STATUS, trunc(b.RETURN_DATE-b.ISSUE_DATE)days from Borrow b, Book book1, copy c where b.BOOK_ID=c.BOOK_ID and  c.ISBN=book1.ISBN and (b.issue_date >= sysdate -7 or b.return_date >= sysdate-7) ")
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["BOOK ID", "M_SSN", "TITLE","AUTHOR","SUBJECT AREA","ISSUE DATE","RETURN DATE","STATUS","Days borrowed"]))

def displayBorrow(cursor):
    cursor.execute("Select * from BORROW")
    rows = cursor.fetchall()
    print("\n")
    print(tabulate([[i[0],i[1],i[2],i[3],i[4],i[5],i[6],i[7]] for i in rows], headers=["BOOK ID", "M_SSN", "ISSUED BY SSN", "ISSUE DATE", "DUE DATE", "RETURN DATE","GRACE PERIOD","STATUS"]))

def viewCopy(cursor):
    cursor.execute("Select * from Copy")
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["BOOK ID", "BOOK ISBN NUMBER", "STATUS"]))

def insertBook(cursor,connection):
    s = int(input("\nEnter Status Type of the Book: \n1. Loanable \n2. Unloanable \n3. Need to Acquire:"))
    if s == 1:
        status = 'Loanable'
        avail = 'Y'
    elif s == 2:
        status = 'Unloanable'
        avail = 'Y'
    elif s == 3:
        status = 'Acquire'
        avail = 'N'
    else:
        print("Incorrect Status Type")
        return
    print("Enter data for New Book:")
    isbn = int(input("Enter ISBN Number:"))
    title = input("Enter Title:")
    binding = input("Enter Binding:")
    lang = input("Enter Language:")
    edition = input("Enter Edition:")
    author = input("Enter Author:")
    des = input("Enter Description:")
    vol = input("Enter Volume:")
    sub_area = input("Enter Subject Area:")
    book_ty = input("Enter Book Type:")
    cursor.execute(
        "INSERT INTO Book(ISBN, TITLE, BINDING, LANGUAGE, EDITION, AUTHOR, DESCRIPTION, VOLUME, SUBJECT_AREA, BOOK_TYPE, AVAILABILITY, STATUS_TYPE) VALUES (:1,:2,:3,:4,:5,:6,TO_CLOB(:7),:8,:9,:10,:11,:12)",
        (isbn, title, binding, lang, edition, author, des, vol, sub_area, book_ty, avail, status))
    connection.commit()
    print("New Book is added!!")


def updateBook(cursor,connection):
    isbn=int(input("Enter the ISBN number of the book that you want to update:"))
    cursor.execute("Select * from BOOK where ISBN=:isb",isb=isbn)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["ISBN", "TITLE", "BINDING", "LANGUAGE", "EDITION", "AUTHOR", "DESCRIPTION", "VOLUME",
                                  "SUBJECT AREA", "BOOK TYPE", "AVAILABILITY", "STATUS TYPE"]))

    title = input("Enter Title:")
    binding = input("Enter Binding:")
    lang = input("Enter Language:")
    edition = input("Enter Edition:")
    author = input("Enter Author:")
    des = input("Enter Description:")
    vol = input("Enter Volume:")
    sub_area = input("Enter Subject Area:")
    book_ty = input("Enter Book Type:")
    ch1=input("Do you want to update the Status Type and Availability (Y/N):")
    if ch1=='Y':
        s = int(input("\nEnter Status Type of the Book: \n1. Loanable \n2. Unloanable \n3. Need to Acquire:"))
        if s == 1:
            status = 'Loanable'
            avail = 'Y'
            cursor.execute("INSERT INTO COPY VALUES(Book_id_seq.NEXTVAL,:isbno,'Available')",isbno=isbn)
            cursor.execute("INSERT INTO COPY VALUES(Book_id_seq.NEXTVAL,:isbno,'Available')", isbno=isbn)
            cursor.execute("INSERT INTO COPY VALUES(Book_id_seq.NEXTVAL,:isbno,'Available')", isbno=isbn)
        elif s == 2:
            status = 'Unloanable'
            avail = 'Y'
        elif s == 3:
            status = 'Acquire'
            avail = 'N'
        else:
            print("Incorrect Status Type")
            return
        cursor.execute("update Book set TITLE=:1, BINDING=:2, LANGUAGE=:3, EDITION=:4, AUTHOR=:5, DESCRIPTION=TO_CLOB(:6), VOLUME=:7, SUBJECT_AREA=:8, BOOK_TYPE=:9, AVAILABILITY=:10, STATUS_TYPE=:11 where ISBN=:12",(title, binding, lang, edition, author, des, vol, sub_area, book_ty, avail, status,isbn))
        connection.commit()
        print("Book has been updated!!")
    else:
        cursor.execute("update Book set TITLE=:1, BINDING=:2, LANGUAGE=:3, EDITION=:4, AUTHOR=:5, DESCRIPTION=TO_CLOB(:6), VOLUME=:7, SUBJECT_AREA=:8, BOOK_TYPE=:9 where ISBN=:10",(title, binding, lang, edition, author, des, vol, sub_area, book_ty, isbn))
        connection.commit()
        print("Book has been updated!!")

    cursor.execute("Select * from BOOK where ISBN=:isb", isb=isbn)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["ISBN", "TITLE", "BINDING", "LANGUAGE", "EDITION", "AUTHOR", "DESCRIPTION", "VOLUME",
                                  "SUBJECT AREA", "BOOK TYPE", "AVAILABILITY", "STATUS TYPE"]))
