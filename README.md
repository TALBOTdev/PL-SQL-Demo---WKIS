# PL-SQL-Demo---WKIS
This project from my database programming and testing class is based on the fictitious We Keep It Storage (WKIS) company's accounting system. In this double entry accounting system, transactions are taken from a holding table and inserted into a detailed transaction table and a transaction history table. Additionally, the appropriate account balance is updated in an account table.

Execute the scripts in the following order and ensure that the WKIS tables have been created correctly:

1. create_wkis.sql
2. constraints_wkis.sql
3. load_wkis.sql

# The following section has been taken from the assignment literature:

It is assumed that ever transaction number is unique for each transaction. A transaction is a unit - and so it will be made up of more than one row. All rows that represent a single transaction will have the same transactional history information.
Cursers are used to make this problem easier.
As long as the debits equal the credits in each transaction, it is assumed that the accounting equation for each transasction holds true.
After a transaction has been successfully processed, it is removed from the NEW_TRANSACTIONS table. Transactions that produce an error remain in the NEW_TRANSACTIONS table.
An error is one transaction does not prevent the processing of other transactions.
Only the first error in a transaction is recorded in the error log table. If the error is a missing transaction number, a single entry is recorded in the error log table for all rows missing a transaction number.
All required tables, including the error log, are created with the provided script. Do not create any additional tables or modify the existing tables.
No use of table of records, or any other type of array.
No use of SELECT INTO againts the NEW_TRANSACTIONS table. This table is only referenced by an explicit cursor.
Completeted in one anonymous block
No use of stored programs
No use of GOTOs, EXITS, or SAVEPOINTS.
No use of hardcoded values.
Error handling //

The program handles all exceptions and writes the transactional history information that caused the error as well as the error message to the WKIS_ERROR_LOG table.

Errors Cauught :

Missing transaction number (NULL transaction number)
Debits and credits are not equal
Invalid account number
Negative value given for a transaction amount
Invalid transaction type
Unanticipated errors are also caught. The error messages for these are the system generated ones as a customized descriptive ones are a focal point.

The data in NEW_TRANSACTIONS is clean. To test error handling, modify the transactional data.
