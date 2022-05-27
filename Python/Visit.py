from tabulate import tabulate

def incomingVisitor(cursor,connection):
    print("Visitor Entry Details:")
    ch1=int(input("Is the Visiting member : \n1. Seft Visiting \n2. Relative \n3. Guest\nEnter your choice:"))
    ssn=int(input("Enter SSN Number:"))
    if ch1 == 1:
        name=None
        visitor="Self"
    elif ch1 == 2:
        name=input("Enter the name of the Relative:")
        visitor = "Relative"
    elif ch1 == 3:
        name = input("Enter the name of the Guest:")
        visitor = "Guest"
        cursor.execute("insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE) values (Visitor_counter.NEXTVAL,:1,sysdate,:2,Pass_id_seq.NEXTVAL,'Guest',sysdate)",(ssn,name))
        connection.commit()
        print("Visitor has entered the Library!")
        return
    else:
        print("Incorrect Visitor details")
        return
    cursor.execute("insert into visits (VISITOR_ID,M_SSN, CHECK_IN, NAME, VISITOR_TYPE) values (Visitor_counter.NEXTVAL,:1,sysdate,:2,:3)",(ssn,name,visitor))
    connection.commit()
    print("Visitor has entered the Library!")

def outgoingVisitor(cursor,connection):
    print("Visitor Exit Details:")
    ssn = int(input("Enter SSN Number:"))
    ch1 = int(input("Is the Visiting member : \n1. Seft Visiting \n2. Relative \n3. Guest\nEnter your choice:"))
    if ch1 == 1:
        cursor.execute("select VISITOR_ID from visits where CHECK_OUT is null and VISITOR_TYPE='Self' and M_SSN=:ssno",ssno=ssn)
        id=cursor.fetchone()
        cursor.execute("update visits set CHECK_OUT=sysdate where VISITOR_ID=:id1",id1=id[0])
        connection.commit()
    elif ch1 == 2:
        name=input("Enter the name of the Relative:")
        cursor.execute("select VISITOR_ID from visits where CHECK_OUT is null and VISITOR_TYPE='Relative' and M_SSN=:1 and NAME=:2", (ssn,name))
        id = cursor.fetchone()
        cursor.execute("update visits set CHECK_OUT=sysdate where VISITOR_ID=:id", id=id[0])
        connection.commit()
    elif ch1 == 3:
        name = input("Enter the name of the Guest:")
        cursor.execute("select VISITOR_ID from visits where CHECK_OUT is null and VISITOR_TYPE='Guest' and M_SSN=:1 and NAME=:2",(ssn, name))
        id = cursor.fetchone()
        cursor.execute("update visits set CHECK_OUT=sysdate where VISITOR_ID=:id", id=id[0])
        connection.commit()
    else:
        print("Incorrect Visitor details")
        return
    print("Visitor has exited the Library!")

def displayVisits(cursor):
    cursor.execute("Select M_SSN, CHECK_IN,CHECK_OUT, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE, to_number(to_char(CHECK_OUT,'MI')) - to_number(to_char(CHECK_IN,'MI')) from visits")
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["Member SSN", "CHECK IN DATE","CHECK OUT DATE", "NAME", "PASS NUMBER", "VISITOR TYPE", "VALIDITY_DATE","MINUTES VISITED"]))

def display7Visits(cursor):
    cursor.execute("Select M_SSN, CHECK_IN,CHECK_OUT, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE, to_number(to_char(CHECK_OUT,'MI')) - to_number(to_char(CHECK_IN,'MI')) from visits where CHECK_IN >= sysdate -7 or CHECK_OUT >= sysdate-7")
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["Member SSN", "CHECK IN DATE","CHECK OUT DATE", "NAME", "PASS NUMBER", "VISITOR TYPE", "VALIDITY_DATE","MINUTES VISITED"]))

def displayUserVisits(cursor):
    ssn=int(input("Insert the SSN number of the member:"))
    cursor.execute("Select M_SSN, CHECK_IN,CHECK_OUT, NAME, PASS_ID, VISITOR_TYPE, VALIDITY_DATE, to_number(to_char(CHECK_OUT,'MI')) - to_number(to_char(CHECK_IN,'MI')) from visits where M_SSN=:ssno",ssno=ssn)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows,headers=["Member SSN", "CHECK IN DATE", "CHECK OUT DATE", "NAME", "PASS NUMBER", "VISITOR TYPE",
                            "VALIDITY_DATE", "MINUTES VISITED"]))

