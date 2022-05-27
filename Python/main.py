import cx_Oracle as co
from tabulate import tabulate
import Book as b
import Member as m
import Visit as v
connection=None


try:
    #Establish Connection to the Database9
    connection = co.connect(user="SYSTEM",password ="Tiger",dsn ='10.219.168.219:1521/XE')
    print("Sucessful connection to Database!")
    cursor = connection.cursor()

    #start the application:
    ch=-1
    while(ch != 0):
        print("\n\n************************************************************ MENU ************************************************************")
        print("1.  Insert Data for New Member       2.  Update Member details       3.  View Member Data        4.  View Card Data")
        print("5.  Insert Data for New Book         6.  Update Book details         7.  Display Books           8.  Borrow Book")
        print("9.  Display Borrow Records           10. Return Borrowed Book        11. Incoming Visitor        12. Outgoing Visitor")
        print("13. View Visitor Records             14. View Book Copies            15. Renew Membership        0.  EXIT")

        ch=int(input("\nPlease enter your choice: "))
        if ch == 1: #Insert Data for New Member
            m.inputMember(cursor,connection)

        elif ch ==2: #Update Member details
            m.updateMember(cursor,connection)

        elif ch == 3: #View Member Data
            m.displayMember(cursor)

        elif ch == 4: #View Card Data
            cursor.execute("select count(*) from card where flag=0")
            cnt = cursor.fetchone()
            m.displayCard(cursor)
            cursor.execute("select count(*) from card where flag=0")
            cnt1 = cursor.fetchone()
            if cnt[0] != cnt1[0]:
                print("\n\nTriggered has been executed! User has been informed to Renew Membership!")

        elif ch == 5: #Insert Data for New Book
            b.insertBook(cursor,connection)

        elif ch == 6: #Update Book details
            b.updateBook(cursor,connection)

        elif ch == 7:#Display Books
            b.displayBook(cursor)

        elif ch == 8: #Borrow Book
            cursor.execute("select count(*) from BORROW where flag=0")
            cnt = cursor.fetchone()
            b.borrowBook(cursor,connection)
            cursor.execute("select count(*) from BORROW where flag=0")
            cnt1 = cursor.fetchone()
            if cnt[0] != cnt1[0]:
                print("Triggered has been executed! User has been informed to return book!")

        elif ch == 9: #Display Borrow Records

            ch1 = int(input("\nPress \n1. To View all Records\n2. Records of past 7 days\nEnter your choice:"))
            if ch1 == 1:
                b.displayBorrow(cursor)
            elif ch1 == 2:
                b.BorrowReport(cursor)
            else:
                print("Wrong input!")


        elif ch ==10: #Return Borrowed Book
            cursor.execute("select count(*) from BORROW where flag=0")
            cnt = cursor.fetchone()
            b.returnBook(cursor,connection)
            cursor.execute("select count(*) from BORROW where flag=0")
            cnt1 = cursor.fetchone()
            if cnt[0] != cnt1[0]:
                print("\n\nTriggered has been executed! User has been informed to return book!")

        elif ch == 11: #Incoming Visitor
            cursor.execute("select count(*) from card where flag=0")
            cnt = cursor.fetchone()
            v.incomingVisitor(cursor,connection)
            cursor.execute("select count(*) from card where flag=0")
            cnt1 = cursor.fetchone()
            if cnt[0] != cnt1[0]:
                print("\n\nTriggered has been executed! User has been informed to Renew Membership!")

        elif ch == 12: #Outgoing Visitor
            cursor.execute("select count(*) from card where flag=0")
            cnt = cursor.fetchone()
            v.outgoingVisitor(cursor,connection)
            cursor.execute("select count(*) from card where flag=0")
            cnt1 = cursor.fetchone()
            if cnt[0] != cnt1[0]:
                print("\n\nTriggered has been executed! User has been informed to Renew Membership!")

        elif ch == 13: #View Visitor Records
            ch1=int(input("\n1. To View all Records\t\t2. Records of past 7 days\t\t3. Records by Member SSN number\t\tEnter your choice:"))
            if ch1==1:
                v.displayVisits(cursor)
            elif ch1 == 2:
                v.display7Visits(cursor)
            elif ch1 == 3:
                v.displayUserVisits(cursor)
            else:
                print("Incorrect input!")

        elif ch ==14: #View Book Copies
            b.viewCopy(cursor)

        elif ch == 15: #Renew membership
            cursor.execute("select count(*) from card where flag=0")
            cnt = cursor.fetchone()
            m.renewMembership(cursor,connection)
            cursor.execute("select count(*) from card where flag=0")
            cnt1 = cursor.fetchone()
            if cnt[0] != cnt1[0]:
                print("\n\nTriggered has been executed! User has been informed to Renew Membership!")

        elif ch == 0:
            break
        else:
            continue

finally:
    print("\n************************************************** THANK YOU **************************************************")
if connection:
    connection.close()
    #print("\nConnection is closed")

