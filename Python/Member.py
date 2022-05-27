from tabulate import tabulate

def updateMember(cursor,connection):
    ssn = int(input("Enter SSN Number of the member you want to update:"))
    cursor.execute("Select * from member where SSN=:ssno",ssno=ssn)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["SSN", "Name", "Home Address", "Campus Address", "Phone No.", "Member Type",
                                  "Grace Period(days)", "Borrow Period(days)", "Employee Type", "Staff Type"]))

    print("Enter the details to Update Member Record:")
    name = input("Enter Name:")
    ha = input("Enter Home Address:")
    ca = input("Enter Campus Address:")
    ph_no = int(input("Enter Phone/Mobile Number:"))
    ch2=input("Do you want to change the Member Type (Y/N) :")
    if ch2=='Y':
        ch1 = int(input("\nDo you want to Update data to \n1. New Staff \n2. New Professor: "))
        if ch1 == 2:
            grace = 14
            borrow = 90
            member = "Employee"
            employee = "Professor"
            staff = None
        elif ch1==1:
            grace = 7
            borrow = 21
            member = "Employee"
            employee = "Staff"
            s = int(input("Enter the designation of the New Staff Member:\n1. CHIEF LIBRARIAN \n2. DEPARTMENTAL ASSOCIATE LIBRARIAN \n3. REFERENCE LIBRARIAN \n4. CHECK-OUT STAFF \n5. LIBRARY ASSISTANT:"))
            if s == 1:
                staff = "CHIEF LIBRARIAN"
            elif s == 2:
                staff = "DEPARTMENTAL ASSOCIATE LIBRARIAN"
            elif s == 3:
                staff = "REFERENCE LIBRARIAN"
            elif s == 4:
                staff = "CHECK-OUT STAFF"
            elif s == 5:
                staff = "LIBRARY ASSISTANT"
            else:
                print("Incorrect Staff Designation")
                return
        else:
            print("Incorrect Member Type!!")
            return
        cursor.execute("update MEMBER set NAME=:1, HOME_ADDRESS=:2, CAMPUS_ADDRESS=:3, PHONE_NO=:4, MEMBER_TYPE=:5, GRACE_PERIOD=:6, BORROW_PERIOD=:7,EMPLOYEE_TYPE=:8, STAFF_TYPE=:9 where SSN=:10",(name, ha, ca, ph_no, member, grace, borrow, employee, staff,ssn))
        connection.commit()
        print("\nMember is Updated!!")
    else:
        cursor.execute("update member set NAME=:1, HOME_ADDRESS=:2, CAMPUS_ADDRESS=:3, PHONE_NO=:4 where SSN=:5",(name, ha, ca, ph_no, ssn))
        connection.commit()
        print("\nMember is Updated!!")


    cursor.execute("Select * from member where SSN=:ssno", ssno=ssn)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["SSN", "Name", "Home Address", "Campus Address", "Phone No.", "Member Type",
                              "Grace Period(days)", "Borrow Period(days)", "Employee Type", "Staff Type"]))


def displayCard(cursor):
    cursor.execute("Select * from Card")
    rows = cursor.fetchall()
    print("\n")
    l=[]
    for i in rows:
        k=[]
        k.append(i[0])
        k.append(i[1])
        k.append(i[2])
        k.append(i[3])
        k.append(i[4])
        k.append(i[5].read)
        l.append(k)
    print(tabulate(l, headers=["Card ID","Member SSN Number", "Issue Date", "Expiry Date","Validity Status","Photo"]))

def displayMember(cursor):
    cursor.execute("Select * from MEMBER")
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["SSN", "Name", "Home Address", "Campus Address", "Phone No.", "Member Type","Grace Period(days)", "Borrow Period(days)", "Employee Type", "Staff Type"]))

def inputMember(cursor,connection):
    ch1 = int(input("\nDo you want to Insert data for \n1. New Student \n2. New Staff \n3. New Professor: "))
    print("Enter data for New Member:")
    ssn = int(input("Enter SSN Number:"))
    name = input("Enter Name:")
    ha = input("Enter Home Address:")
    ca = input("Enter Campus Address:")
    ph_no = int(input("Enter Phone/Mobile Number:"))
    if ch1 == 3:
        grace = 14
        borrow = 90
        member = "Employee"
        employee = "Professor"
        staff = None
    elif ch1 == 1:
        grace = 7
        borrow = 21
        member = "Student"
        staff = None
        employee = None
    else:
        grace = 7
        borrow = 21
        member = "Employee"
        employee = "Staff"
        s = int(input("Enter the designation of the New Staff Member:\n1. CHIEF LIBRARIAN \n2. DEPARTMENTAL ASSOCIATE LIBRARIAN \n3. REFERENCE LIBRARIAN \n4. CHECK-OUT STAFF \n5. LIBRARY ASSISTANT:"))
        if s == 1:
            staff = "CHIEF LIBRARIAN"
        elif s == 2:
            staff = "DEPARTMENTAL ASSOCIATE LIBRARIAN"
        elif s == 3:
            staff = "REFERENCE LIBRARIAN"
        elif s == 4:
            staff = "CHECK-OUT STAFF"
        elif s == 5:
            staff = "LIBRARY ASSISTANT"
        else:
            print("Incorrect Staff Designation")
            return
    cursor.execute("insert into MEMBER (SSN, NAME, HOME_ADDRESS, CAMPUS_ADDRESS, PHONE_NO, MEMBER_TYPE, GRACE_PERIOD, BORROW_PERIOD,EMPLOYEE_TYPE, STAFF_TYPE) values (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10)",(ssn, name, ha, ca, ph_no, member, grace, borrow, employee, staff))
    connection.commit()
    print("\nNew Member is added!!")
    cursor.execute("Select * from member where SSN=:ssno", ssno=ssn)
    rows = cursor.fetchall()
    print("\n")
    print(tabulate(rows, headers=["SSN", "Name", "Home Address", "Campus Address", "Phone No.", "Member Type",
                              "Grace Period(days)", "Borrow Period(days)", "Employee Type", "Staff Type"]))


def renewMembership(cursor,connection):
    ssn = int(input("Enter the SSN Number of the member:"))
    cursor.execute("update card set EXPIRY_DATE = add_months(sysdate,48), VALIDITY='Valid', flag=0 where M_SSN=:ssno",ssno=ssn)
    connection.commit()
    print("\nMembership has been renewed!!")