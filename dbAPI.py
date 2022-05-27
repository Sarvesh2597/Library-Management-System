#***************************************************************************************************
#File Name : dbAPI.py
#Author : Sarvesh Rembhotkar & Aishwarya Jadhav
#Date Created : 18-NOV-21
#Description : 
#This Python script contains the code for connecting to MYSQL Database and contains the API's for 
# inserting, showing and updating data on user-interface side.

import collections
import flask
from flask import request, jsonify
import cx_Oracle
import json
from flask_cors import CORS, cross_origin
from datetime import timedelta, date, datetime

app = flask.Flask(__name__)
CORS(app)
app.config["DEBUG"] = True

def connect_to_Orcl():
    con = cx_Oracle.connect(
       user = "c##admin",
       password = "manager",
       dsn = "localhost/XE"
    #    user="sxr6297",
    #    password="Sarveshr6297",
    #    dsn= "acaddbprod-2.uta.edu:1523/PCSE19P.DATA.UTA.EDU"
    )
    if con:
        print ("Connected to Oracle")
        return con
    else:
        return None


@app.route('/', methods=['GET'])
def home():
    return '''<h1>Distant Reading Archive</h1>
<p>A prototype API for distant reading of science fiction novels.</p>'''

@app.route('/api/v1/resources/books/all', methods=['GET'])
def api_all():
    con = connect_to_Orcl()
    cur = con.cursor()
    books = cur.execute('''SELECT B.BOOK_ID, A.ISBN, A.SUBJECT_AREA, A.TITLE, A.VOLUME,A.AUTHOR, 
    A.DESCRIPTION, A.BINDING, A.LANGUAGE, A.EDITION, A.BOOK_TYPE, A.AVAILABILITY, 
    B.STATUS, A.STATUS_TYPE FROM BOOK A LEFT JOIN COPY B ON A.ISBN = B.ISBN''')
    lst_records = []
    for b in books:
        d = collections.OrderedDict()
        d["BOOK_ID"] = b[0]
        d["ISBN"] = b[1]
        d["SUBJECT_AREA"] = b[2]
        d["TITLE"] = b[3]
        d["VOLUME"] = b[4]
        d["AUTHOR"] = b[5]
        d["DESCRIPTION"] = b[6]
        d["BINDING"] = b[7]
        d["LANGUAGE"] = b[8]
        d["EDITION"] = b[9]
        d["BOOK_TYPE"] = b[10]
        d["AVAILABILITY"] = b[11]
        d["STATUS"] = b[12]
        d["STATUS_TYPE"] = b[13]
        lst_records.append(d)
    return jsonify(lst_records)

    

#API for showing all members
@app.route('/api/v1/resources/members/showMembers', methods=['GET'])
def api_showMembers():
    con = connect_to_Orcl()
    cur = con.cursor()
    members = cur.execute('''SELECT A.SSN,A.NAME,B.CARD_ID, B.ISSUE_DATE, B.EXPIRY_DATE, A.BORROW_PERIOD, A.GRACE_PERIOD FROM MEMBER A, CARD B''')
    lst_records = []
    for b in members:
        d = collections.OrderedDict()
        d["SSN"] = b[0]
        d["NAME"] = b[1]
        d["CARD_ID"] = b[2]
        d["ISSUE_DATE"] = b[3]
        d["EXPIRY_DATE"] = b[4]
        d["BORROW_PERIOD"] = b[5]
        d["GRACE_PERIOD"] = b[6]
        lst_records.append(d)
    return jsonify(lst_records)

#API for showing all available books only
@app.route('/api/v1/resources/books/allAvailableBooks', methods=['GET'])
def api_allAvailableBooks():
    con = connect_to_Orcl()
    cur = con.cursor()
    books = cur.execute("SELECT B.BOOK_ID, A.ISBN, A.SUBJECT_AREA, A.TITLE, A.VOLUME,A.AUTHOR, A.DESCRIPTION, A.BINDING, A.LANGUAGE, A.EDITION, A.BOOK_TYPE, A.AVAILABILITY, B.STATUS FROM BOOK A, COPY B WHERE (B.ISBN = A.ISBN AND B.STATUS = 'Available')")
    lst_records = []
    for b in books:
        d = collections.OrderedDict()
        d["BOOK_ID"] = b[0]
        d["ISBN"] = b[1]
        d["SUBJECT_AREA"] = b[2]
        d["TITLE"] = b[3]
        d["VOLUME"] = b[4]
        d["AUTHOR"] = b[5]
        d["DESCRIPTION"] = b[6]
        d["BINDING"] = b[7]
        d["LANGUAGE"] = b[8]
        d["EDITION"] = b[9]
        d["BOOK_TYPE"] = b[10]
        d["AVAILABILITY"] = b[11]
        d["STATUS"] = b[12]
        lst_records.append(d)
    return jsonify(lst_records)

#API for adding borrow
@app.route('/api/v1/resources/borrow/borrowBook', methods=['POST'])
def api_borrowBook():
    data = request.get_json()
    con = connect_to_Orcl()
    cur = con.cursor()
    #print(data["BINDING"])
    # statement = '''INSERT INTO BORROW (BOOK_ID,M_SSN,ISSUED_BY,ISSUE_DATE,DUE_DATE,
    # GRACE_PERIOD,STATUS) VALUES (:1,:2,:3,:4,:5,:6,:7)'''
    # values=(int(data["BOOK_ID"]), int(data["M_SSN"]),data["ISSUED_BY"],data["ISSUE_DATE"],data["DUE_DATE"],
    # data["GRACE_PERIOD"],data["STATUS"])
    print(data["ISSUE_DATE"])
    print(data["DUE_DATE"])
    # ISSUE_DT = datetime.strptime(data["ISSUE_DATE"], "%d-%m-%Y").strftime("%Y-%m-%d")
    # print(ISSUE_DT)
    statement = f''' 
    INSERT INTO BORROW (BOOK_ID,M_SSN,ISSUED_BY,ISSUE_DATE,DUE_DATE, RETURN_DATE,
    GRACE_PERIOD,STATUS) VALUES ({int(data["BOOK_ID"])}, {int(data["M_SSN"])}, {data["ISSUED_BY"]}, 
    TO_DATE('{data["ISSUE_DATE"]}', 'YYYY-MM-DD'), TO_DATE('{data["DUE_DATE"]}', 'YYYY-MM-DD'), NULL,
    TO_DATE('{data["GRACE_PERIOD"]}', 'YYYY-MM-DD'), '{data["STATUS"]}')
    '''
    # print(statement) 
    cur.execute(statement)
    cur.execute("commit")
    if cur:
        cur.close()
    if con:
        con.close()
    #return jsonify(data)
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}

#API for adding book information to database
@app.route('/api/v1/resources/books/addBook', methods=['POST'])
def api_addBook():
    data = request.get_json()
    con = connect_to_Orcl()
    cur = con.cursor()
    # print(data["BINDING"])
    statement = '''INSERT INTO BOOK (ISBN,SUBJECT_AREA,TITLE,VOLUME,AUTHOR,DESCRIPTION,
    BINDING,LANGUAGE,EDITION,BOOK_TYPE,AVAILABILITY, STATUS_TYPE) VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12)'''
    values=(int(data["ISBN"]), data["SUBJECT_AREA"],data["TITLE"],data["VOLUME"],data["AUTHOR"],
    data["DESCRIPTION"],data["BINDING"],data["LANGUAGE"],data["EDITION"],data["BOOK_TYPE"],
    data["AVAILABILITY"], data["STATUS_TYPE"])
    cur.execute(statement,values)
    cur.execute("commit")
    copies = int(data["COPY"])
    if (copies > 0 and data["AVAILABILITY"] == 'Y') :        
        for i in range(0, copies):
            statement = f'''INSERT INTO COPY (BOOK_ID, ISBN, STATUS) VALUES (bookid_seq.nextval, {int(data["ISBN"])},'Available')'''
            cur.execute(statement)
        cur.execute("commit")    
    if cur:
        cur.close()
    if con:
        con.close()
    #return jsonify(data)
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}

#API for adding new member to database
@app.route('/api/v1/resources/members/addMember', methods=['POST'])
def api_addMember():        
    data = request.get_json()
    con = connect_to_Orcl()
    cur = con.cursor()
    #print(data["BINDING"])
    statement = '''INSERT INTO MEMBER (SSN,NAME,HOME_ADDRESS,CAMPUS_ADDRESS,PHONE_NO,MEMBER_TYPE,
    EMPLOYEE_TYPE,STAFF_TYPE,BORROW_PERIOD,GRACE_PERIOD) VALUES (:1,:2,:3,:4,:5,:6,:7,:8,:9,:10)'''
    values=(int(data["SSN"]), data["NAME"],data["HOME_ADDRESS"],data["CAMPUS_ADDRESS"],int(data["PHONE_NO"]),
    data["MEMBER_TYPE"],data["EMPLOYEE_TYPE"],data["STAFF_TYPE"],int(data["BORROW_PERIOD"]),int(data["GRACE_PERIOD"]))
    cur.execute(statement,values)
    cur.execute("commit")
    if cur:
        cur.close()
    if con:
        con.close()
    #return jsonify(data)
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}

#Access member details from the specified SSN
@app.route('/api/v1/resources/member', methods=['GET'])
def api_mssn():
    if 'mssn' in request.args:
        m_ssn = int(request.args['mssn'])
    else:
        return "Error: No ssn field provided. Please specify memeber ssn."
    data = request.get_json()
    con = connect_to_Orcl()
    cur = con.cursor()
    d = collections.OrderedDict()
    cur.execute("SELECT A.SSN,A.NAME,B.CARD_ID, B.ISSUE_DATE, B.EXPIRY_DATE, A.BORROW_PERIOD, A.GRACE_PERIOD FROM MEMBER A, CARD B WHERE A.SSN = B.M_SSN  AND A.SSN = " + str(m_ssn) ) 
    result = cur.fetchall()
    
    for b in result:
        print(b)
        d["SSN"] = b[0]
        d["NAME"] = b[1]
        d["CARD_ID"] = b[2]
        d["ISSUE_DATE"] = b[3].strftime("%Y-%m-%d")
        d["EXPIRY_DATE"] = b[4].strftime("%Y-%m-%d")
        d["BORROW_PERIOD"] = b[5]
        #d["GRACE_PERIOD"] = b[6]
        grp_dt = date. today() + timedelta(days=(b[5]-b[6]))
        d["GRACE_PERIOD"] =  grp_dt.strftime("%Y-%m-%d")
        #d["DUE_DATE"] = rrule(DAILY, byweekday=(MO,TU,WE,TH,FR))[int(b[2])]
        due_dt = date. today() + timedelta(days=int(b[5]))
        d["DUE_DATE"] = due_dt.strftime("%Y-%m-%d")

        
    if cur:
        cur.close()
    if con:
        con.close()
    return jsonify(d)    


@app.route('/api/v1/resources/books/borrowedBooks', methods=['GET'])
def api_borrowedBooks():
    con = connect_to_Orcl()
    cur = con.cursor()
    cur.execute("""SELECT A.SUBJECT_AREA, A.BOOK_ID, A.TITLE, A.AUTHOR, 
    (SELECT NAME FROM MEMBER WHERE SSN=A.M_SSN) AS MEMBER_NAME,
    (SELECT NAME FROM MEMBER WHERE SSN=A.ISSUED_BY) AS ISSUED_BY,
    TO_CHAR(A.ISSUE_DATE, 'YYYY-MM-DD'), M.BORROW_PERIOD, A.STATUS FROM VW_BORROWED_BOOKS A, MEMBER M
    WHERE A.M_SSN = M.SSN
    """)
    books = cur.fetchall()
    lst_records = []
    for b in books:
        d = collections.OrderedDict()
        d["SUBJECT_AREA"] = b[0]
        d["BOOK_ID"] = b[1]
        d["TITLE"] = b[2]
        d["AUTHOR"] = b[3]
        d["MEMBER_NAME"] = b[4]
        d["ISSUED_BY"] = b[5]
        d["ISSUE_DATE"] = b[6]
        d["BORROW_PERIOD"] = b[7]
        d["STATUS"] = b[8]
        lst_records.append(d)
    if cur:
        cur.close()
    if con:
        con.close()
    return jsonify(lst_records) 

#API for showing visits report
@app.route('/api/v1/resources/visits/showAllVisits', methods=['GET'])
def api_showAllVisits():
    con = connect_to_Orcl()
    cur = con.cursor()
    cur.execute("""SELECT V.M_SSN, M.NAME, V.NAME AS VISITOR_NAME, V.VISITOR_TYPE,
    V.PASS_ID, V.VALIDITY_DATE, V.CHECK_IN, V.CHECK_OUT
    FROM VISITS V, MEMBER M
    WHERE V.M_SSN = M.SSN
     """)
    visits = cur.fetchall()
    lst_records = []
    for b in visits:
        d = collections.OrderedDict()
        d["MEM_SSN"] = b[0]
        d["MEM_NAME"] = b[1]
        d["VISITOR_NAME"] = b[2]
        d["VISITOR_TYPE"] = b[3]
        d["PASS_ID"] = b[4]
        d["PASS_DATE"] = b[5]
        d["CHK_IN_TIME"] = b[6].strftime('%Y-%m-%d %H:%M')
        d["CHK_OUT_TIME"] = b[7].strftime('%Y-%m-%d %H:%M')
        lst_records.append(d)
    if cur:
        cur.close()
    if con:
        con.close()
    return jsonify(lst_records) 

#This api is for returning the details of borrowed books by a specified member
#need to append ?getMemberBB= to the base URL at the time of calling this API
@app.route('/api/v1/resources/member/borrowedBooks', methods=['GET'])
def api_getMemberBB():
    # print(request.args)
    if 'getMemberBB' in request.args:
        m_ssn = int(request.args['getMemberBB'])
    else:
        return "Error: No ssn field provided. Please specify memeber ssn."
    con = connect_to_Orcl()
    cur = con.cursor()
    cur.execute("""SELECT A.SUBJECT_AREA, A.BOOK_ID, A.TITLE, A.AUTHOR, 
    (SELECT NAME FROM MEMBER WHERE SSN=A.M_SSN) AS MEMBER_NAME,
    (SELECT NAME FROM MEMBER WHERE SSN=A.ISSUED_BY) AS ISSUED_BY,
    A.ISSUE_DATE, M.BORROW_PERIOD, A.STATUS FROM VW_BORROWED_BOOKS A, MEMBER M
    WHERE A.M_SSN = M.SSN 
    AND A.STATUS = 'Lent'
    AND A.M_SSN =
    """ + str(m_ssn))
    books = cur.fetchall()
    lst_records = []
    for b in books:
        d = collections.OrderedDict()
        d["SUBJECT_AREA"] = b[0]
        d["BOOK_ID"] = b[1]
        d["TITLE"] = b[2]
        d["AUTHOR"] = b[3]
        d["MEMBER_NAME"] = b[4]
        d["ISSUED_BY"] = b[5]
        d["ISSUE_DATE"] = b[6]
        d["BORROW_PERIOD"] = b[7]
        d["STATUS"] = b[8]
        lst_records.append(d)
    if cur:
        cur.close()
    if con:
        con.close()
    return jsonify(lst_records)      

#This api is for returning the details of specified member and his/her card details
#need to append ?getCardInfo= to the base URL at the time of calling this API
@app.route('/api/v1/resources/member/card', methods=['GET'])
def api_getCardInfo():
    # print(request.args)
    if 'getCardInfo' in request.args:
        m_ssn = request.args['getCardInfo']
    else:
        return "Error: No ssn field provided. Please specify memeber ssn."
    con = connect_to_Orcl()
    cur = con.cursor()
    cur.execute("""SELECT M.SSN, M.NAME, M.PHONE_NO, M.MEMBER_TYPE,
    M.EMPLOYEE_TYPE, M.STAFF_TYPE,M.BORROW_PERIOD,
    C.CARD_ID, TO_CHAR(C.ISSUE_DATE, 'YYYY-MM-DD'), TO_CHAR(C.EXPIRY_DATE, 'YYYY-MM-DD')
    FROM MEMBER M, CARD C
    WHERE C.M_SSN = M.SSN
    AND C.M_SSN =
    """ + str(m_ssn))
    books = cur.fetchall()
    lst_records = []
    for b in books:
        d = collections.OrderedDict()
        d["SSN"] = b[0]
        d["NAME"] = b[1]
        d["PHONE_NO"] = b[2]
        d["MEMBER_TYPE"] = b[3]
        d["EMPLOYEE_TYPE"] = b[4]
        d["STAFF_TYPE"] = b[5]
        d["BORROW_PERIOD"] = b[6]
        d["CARD_ID"] = b[7]
        d["ISSUE_DATE"] = b[8]
        d["EXPIRY_DATE"] = b[9]
        lst_records.append(d)
    if cur:
        cur.close()
    if con:
        con.close()
    return jsonify(lst_records)  

#API for renewing membership
@app.route('/api/v1/resources/member/card/renewMember', methods=['POST'])
def api_renewMember():        
    data = request.get_json()
    print(data)
    con = connect_to_Orcl()
    cur = con.cursor()
    #print(data["BINDING"])
    statement = f''' UPDATE CARD SET ISSUE_DATE = TO_DATE('{data["ISSUE_DATE"]}', 'YYYY-MM-DD') , 
    EXPIRY_DATE = TO_DATE('{data["EXPIRY_DATE"]}', 'YYYY-MM-DD') WHERE M_SSN = {int(data["SSN"])}'''
    cur.execute(statement)
    cur.execute("commit")
    if cur:
        cur.close()
    if con:
        con.close()
    #return jsonify(data)
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}   

#API for returning borrowed book
@app.route('/api/v1/resources/member/returnBook', methods=['POST'])
def api_returnBook():        
    data = request.get_json()
    print(data)
    con = connect_to_Orcl()
    cur = con.cursor()
    #print(data["BINDING"])
    statement = f''' UPDATE BORROW SET RETURN_DATE = TO_DATE('{data["RETURN_DATE"]}', 'YYYY-MM-DD'), 
    STATUS = 'Available' WHERE M_SSN = {int(data["M_SSN"])} AND BOOK_ID = {int(data["BOOK_ID"])}'''
    cur.execute(statement)
    cur.execute("commit")
    statement = f''' UPDATE COPY SET STATUS = 'Available' WHERE BOOK_ID = {int(data["BOOK_ID"])} '''
    cur.execute(statement)
    cur.execute("commit")
    if cur:
        cur.close()
    if con:
        con.close()
    #return jsonify(data)
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}        

app.run()